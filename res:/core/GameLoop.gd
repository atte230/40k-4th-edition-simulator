extends Node

# GameLoop.gd
# Master orchestrator glue for running scenarios and integrating campaign flow.
# Responsibilities added here for Phase 4 MVP:
# - Ensure ScenarioManager and CampaignManager exist (autoload or child)
# - Connect scenario_started / scenario_ended signals
# - Spawn units from scenario definitions (best-effort: looks for res://units/<unit_type>.tscn)
# - Apply campaign results and autosave on scenario end

@tool
class_name GameLoop

var scenario_manager: Node = null
var campaign_manager: Node = null

# Where to parent spawned units (set in inspector or discovered at runtime)
@export_node_path(NodePath) var units_root_path: NodePath = NodePath("/root/Main/Board/Units")
var units_root: Node = null

func _ready() -> void:
	print("GameLoop: initializing Phase 4 hooks...")
	# Find or create managers
	scenario_manager = _find_or_create_manager("/root/ScenarioManager", "res://managers/ScenarioManager.gd")
	campaign_manager = _find_or_create_manager("/root/CampaignManager", "res://managers/CampaignManager.gd")

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
		spawn_forces_from_scenario(scenario)

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

func spawn_forces_from_scenario(scenario:Dictionary) -> void:
	var roster = scenario.get("enemy_roster", [])
	for unit_def in roster:
		# unit_def expected keys: unit_type, count, spawn_zone
		var unit_type = unit_def.get("unit_type", "")
		var count = int(unit_def.get("count", 1))
		for i in range(count):
			spawn_unit_by_type(unit_type, unit_def)

func spawn_unit_by_type(unit_type:String, unit_def:Dictionary) -> Node:
	# Best-effort: look for PackedScene at res://units/<unit_type>.tscn
	var scene_path = "res://units/%s.tscn" % unit_type
	if ResourceLoader.exists(scene_path):
		var ps = load(scene_path)
		var inst = ps.instantiate()
		# Attempt to set persistent unit id if the Unit script exposes one
		if inst.has_method("set_unit_id"):
			inst.call("set_unit_id", "%s_%s" % [unit_type, str(OS.get_unix_time())])
		# Add to units root
		units_root.add_child(inst)
		print("GameLoop: spawned unit %s from %s" % [unit_type, scene_path])
		return inst
	else:
		print("GameLoop: no scene found for %s at %s — creating placeholder" % [unit_type, scene_path])
		# Create a minimal placeholder Node with Unit.gd attached if available
		var unit_scene_script = load("res://units/Unit.gd")
		var node = Node3D.new()
		if unit_scene_script:
			node.set_script(unit_scene_script)
			node.set_name("%s_placeholder" % unit_type)
			# Try to set unit_id if method exists
			if node.has_method("set_unit_id"):
				node.call("set_unit_id", "%s_%s" % [unit_type, str(OS.get_unix_time())])
		units_root.add_child(node)
		return node

# Utility: manual trigger to end scenario (useful for testing)
func end_current_scenario_manual(scenario_id:String, victory:bool=true) -> void:
	var result = {"scenario_id":scenario_id, "victory":victory, "roster_updates":[], "casualties":[]}
	if scenario_manager:
		scenario_manager.end_scenario(scenario_id, result)
