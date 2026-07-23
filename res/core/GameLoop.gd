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
