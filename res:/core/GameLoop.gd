extends Node

# GameLoop.gd
# Master orchestrator glue for running scenarios and integrating campaign flow.
# Responsibilities added here for Phase 4 MVP:
# - Ensure ScenarioManager and CampaignManager exist (autoload or child)
# - Connect scenario_started / scenario_ended signals
# - Spawn units from scenario definitions (best-effort: looks for res://units/<unit_type>.tscn)
# - Apply campaign results and autosave on scenario end
# - Use DeploymentManager for deployment-aware spawn placement
# - Handle player + enemy deployment, with D6 roll to decide who deploys first

@tool
class_name GameLoop

var scenario_manager: Node = null
var campaign_manager: Node = null
var deployment_manager: Node = null
var rng := RandomNumberGenerator.new()

# Where to parent spawned units (set in inspector or discovered at runtime)
@export_node_path(NodePath) var units_root_path: NodePath = NodePath("/root/Main/Board/Units")
var units_root: Node = null

func _ready() -> void:
	print("GameLoop: initializing Phase 4 hooks...")
	rng.randomize()
	# Find or create managers
	scenario_manager = _find_or_create_manager("/root/ScenarioManager", "res://managers/ScenarioManager.gd")
	campaign_manager = _find_or_create_manager("/root/CampaignManager", "res://managers/CampaignManager.gd")
	deployment_manager = _find_or_create_manager("/root/DeploymentManager", "res://managers/DeploymentManager.gd")

	# Resolve units root
	if has_node(units_root_path):
		units_root = get_node(units_root_path)
	else:
		units_root = get_node_or_null("/root/Main/Board/Units")
		if units_root == null:
			print("GameLoop: units_root not found; spawned units will be added to GameLoop node")
			units_root = self

	# Connect signals
	if scenario_manager:
		if not scenario_manager.is_connected("scenario_started", Callable(self, "_on_scenario_started")):
			scenario_manager.connect("scenario_started", Callable(self, "_on_scenario_started"))
		if not scenario_manager.is_connected("scenario_ended", Callable(self, "_on_scenario_ended")):
			scenario_manager.connect("scenario_ended", Callable(self, "_on_scenario_ended"))

func _find_or_create_manager(node_path:String, script_path:String) -> Node:
	var node = get_node_or_null(node_path)
	if node != null:
		return node
	# Try to find by name in the scene tree
	node = get_node_or_null("/root/%s" % node_path.get_file())
	if node != null:
		return node
	# As a fallback instantiate the manager and add as child of root
	var script = load(script_path)
	if script == null:
		push_error("Failed to load manager script: %s" % script_path)
		return null
	var inst = script.new()
	get_tree().get_root().add_child(inst)
	inst.name = node_path.get_file()
	print("GameLoop: created manager %s from %s" % [inst.name, script_path])
	return inst

func _on_scenario_started(scenario_id:String) -> void:
	print("GameLoop: scenario started -> %s" % scenario_id)
	# Attempt to spawn forces using the scenario definition if available
	var scenario = null
	if scenario_manager:
		scenario = scenario_manager.get_scenario(scenario_id)
	if scenario != null and scenario.size() > 0:
		# Start deployment flow (player + enemy)
		start_deployment_flow(scenario)

func _on_scenario_ended(scenario_id:String, result:Dictionary) -> void:
	print("GameLoop: scenario ended -> %s | result: %s" % [scenario_id, result])
	# Apply results to campaign and autosave
	if campaign_manager:
		campaign_manager.apply_scenario_result(result)
		# campaign_manager.apply_scenario_result already saves, but ensure a save here too
		var ok = campaign_manager.save_campaign()
		if ok:
			print("GameLoop: campaign autosaved after scenario end")
		else:
			push_error("GameLoop: failed to autosave campaign after scenario end")

# ---------------- Deployment Flow -----------------
func start_deployment_flow(scenario:Dictionary) -> void:
	# Determine rosters
	var player_roster: Array = []
	if scenario.has("player_roster"):
		player_roster = scenario.get("player_roster")
	elif campaign_manager != null:
		player_roster = campaign_manager.get_roster()
	
	var enemy_roster: Array = scenario.get("enemy_roster", [])

	# Determine spawn zones
	var enemy_zone = "north"
	# try to read zone from scenario enemy_roster first entry
	if enemy_roster.size() > 0 and enemy_roster[0] is Dictionary and enemy_roster[0].has("spawn_zone"):
		enemy_zone = str(enemy_roster[0].get("spawn_zone"))
	var player_zone = scenario.get("player_zone", opposite_zone(enemy_zone))

	# Decide who deploys first by rolling D6 each (reroll ties)
	var rolls := {}
	var winner = ""
	while true:
		var player_roll = roll_d6()
		var enemy_roll = roll_d6()
		rolls["player"] = player_roll
		rolls["enemy"] = enemy_roll
		print("Deployment rolls -> player: %d, enemy: %d" % [player_roll, enemy_roll])
		if player_roll > enemy_roll:
			winner = "player"
			break
		elif enemy_roll > player_roll:
			winner = "enemy"
			break
		else:
			print("Tie on deployment roll (%d). Rerolling..." % player_roll)

	print("Deployment order decided: %s deploys first (rolls: %s)" % [winner, str(rolls)])

	# Perform deployments: winner deploys full force then loser
	if winner == "player":
		spawn_roster(player_roster, player_zone, true)
		spawn_roster(enemy_roster, enemy_zone, false)
	else:
		spawn_roster(enemy_roster, enemy_zone, false)
		spawn_roster(player_roster, player_zone, true)

func roll_d6() -> int:
	return rng.randi_range(1, 6)

func opposite_zone(zone:String) -> String:
	var z = zone.to_lower()
	match z:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
		"ne", "northeast": return "sw"
		"nw", "northwest": return "se"
		"se", "southeast": return "nw"
		"sw", "southwest": return "ne"
		_:
			return "south"

# Spawn a roster (either scenario-formatted roster entries or campaign roster entries)
func spawn_roster(roster:Array, zone:String, is_player:bool=false) -> void:
	if roster == null or roster.size() == 0:
		print("spawn_roster: empty roster for %s" % (is_player ? "player" : "enemy"))
		return

	# Build a flat list of unit types to spawn and keep original unit dicts (for unit_id mapping)
	var spawn_list := []
	for entry in roster:
		if typeof(entry) == TYPE_DICTIONARY:
			# scenario-style entry may have unit_type and count
			if entry.has("unit_type"):
				var count = int(entry.get("count", 1))
				for i in range(count):
					spawn_list.append({"unit_type": entry.get("unit_type"), "meta": entry})
			# campaign roster entries might have 'type' or 'unit_type'
			elif entry.has("type") or entry.has("unit_id"):
				var ut = entry.get("type", entry.get("unit_type", "Generic"))
				spawn_list.append({"unit_type": ut, "meta": entry})
		else:
			# fallback: entry is string type
			spawn_list.append({"unit_type": str(entry), "meta": {}})

	var total = spawn_list.size()
	if total == 0:
		return

	# Ask deployment_manager for positions
	var board_node = get_node_or_null("/root/Main/Board")
	var positions = []
	if deployment_manager and deployment_manager.has_method("get_positions"):
		positions = deployment_manager.call("get_positions", zone, total, board_node)
	else:
		# fallback compute
		positions = _compute_fallback_positions(zone, total)

	# Spawn units at assigned positions
	for i in range(total):
		var spec = spawn_list[i]
		var utype = spec.get("unit_type", "Generic")
		var meta = spec.get("meta", {})
		var pos = positions[i] if i < positions.size() else Vector3.ZERO
		spawn_unit_by_type(utype, meta, pos)

# Existing spawn helper (unchanged)
func spawn_unit_by_type(unit_type:String, unit_def:Dictionary, position:Vector3 = Vector3.ZERO) -> Node:
	# Best-effort: look for PackedScene at res://units/<unit_type>.tscn
	var scene_path = "res://units/%s.tscn" % unit_type
	if ResourceLoader.exists(scene_path):
		var ps = load(scene_path)
		var inst = ps.instantiate()
		# Attempt to set persistent unit id if the Unit script exposes one
		if inst.has_method("set_unit_id"):
			# prefer unit_def.unit_id if present
			var uid = ""
			if typeof(unit_def) == TYPE_DICTIONARY and unit_def.has("unit_id"):
				uid = str(unit_def.get("unit_id"))
			if uid == "":
				uid = "%s_%s" % [unit_type, str(OS.get_unix_time())]
			inst.call("set_unit_id", uid)
		# Place at position
		if inst is Node3D:
			inst.global_transform.origin = position
		# Add to units root
		units_root.add_child(inst)
		print("GameLoop: spawned unit %s from %s at %s" % [unit_type, scene_path, str(position)])
		return inst
	else:
		print("GameLoop: no scene found for %s at %s — creating placeholder" % [unit_type, scene_path])
		# Create a minimal placeholder Node3D with Unit.gd attached if available
		var unit_scene_script = load("res://units/Unit.gd")
		var node = Node3D.new()
		if unit_scene_script:
			node.set_script(unit_scene_script)
			node.name = "%s_placeholder" % unit_type
			# Try to set unit_id if method exists
			if node.has_method("set_unit_id") and typeof(unit_def) == TYPE_DICTIONARY and unit_def.has("unit_id"):
				node.call("set_unit_id", str(unit_def.get("unit_id")))
			elif node.has_method("set_unit_id"):
				node.call("set_unit_id", "%s_%s" % [unit_type, str(OS.get_unix_time())])
		# Place at position
		node.global_transform.origin = position
		units_root.add_child(node)
		return node

func _compute_fallback_positions(zone:String, count:int) -> Array:
	# Basic fallback: assume board extents if Board not present
	var board = get_node_or_null("/root/Main/Board")
	var width = 100.0
	var depth = 100.0
	var y = 0.0
	if board != null:
		# Try to read bounds from common properties
		if board.has_meta("width"):
			width = float(board.get_meta("width"))
		elif board.has_method("get_width"):
			width = float(board.call("get_width"))
		if board.has_meta("depth"):
			depth = float(board.get_meta("depth"))
		elif board.has_method("get_depth"):
			depth = float(board.call("get_depth"))

	var half_w = width * 0.5
	var half_d = depth * 0.5
	var deploy_dist = 12.0
	var positions := []
	for i in range(count):
		var t = 0.0
		if count > 1:
			t = float(i) / float(count - 1)
		else:
			t = 0.5
		match zone.to_lower():
			"north":
				var x = lerp(-half_w + 5.0, half_w - 5.0, t)
				var z = half_d - deploy_dist
				positions.append(Vector3(x, y, z))
			"south":
				var x = lerp(-half_w + 5.0, half_w - 5.0, t)
				var z = -half_d + deploy_dist
				positions.append(Vector3(x, y, z))
			"east":
				var z = lerp(-half_d + 5.0, half_d - 5.0, t)
				var x = half_w - deploy_dist
				positions.append(Vector3(x, y, z))
			"west":
				var z = lerp(-half_d + 5.0, half_d - 5.0, t)
				var x = -half_w + deploy_dist
				positions.append(Vector3(x, y, z))
			"opposite":
				# place on opposite edge relative to player; default to north
				var x = lerp(-half_w + 5.0, half_w - 5.0, t)
				var z = half_d - deploy_dist
				positions.append(Vector3(x, y, z))
			_:
				# default to north
				var x = lerp(-half_w + 5.0, half_w - 5.0, t)
				var z = half_d - deploy_dist
				positions.append(Vector3(x, y, z))
	return positions
