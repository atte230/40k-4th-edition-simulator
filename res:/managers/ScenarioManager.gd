extends Node

# ScenarioManager.gd
# Responsibilities:
# - Load scenario definitions (res://scenarios/*.json)
# - Spawn forces and apply setup rules
# - Manage scenario lifecycle and emit signals

signal scenario_started(scenario_id:String)
signal scenario_ended(scenario_id:String, result:Dictionary)

var scenarios: Dictionary = {}

func _ready() -> void:
	# Attempt to preload scenario definitions at startup
	_load_all_scenarios()

func _load_all_scenarios() -> void:
	var dir = DirAccess.open("res://scenarios")
	if dir == null:
		return
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path = "res://scenarios/%s" % file_name
			var json_text = _load_text(path)
			if json_text != null:
				var parsed = JSON.parse_string(json_text)
				if parsed.error == OK:
					scenarios[parsed.result.id] = parsed.result
		file_name = dir.get_next()

func _load_text(path:String) -> String:
	var f = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if f == null:
		return null
	var txt = f.get_as_text()
	f.close()
	return txt

func get_scenario(scenario_id:String) -> Dictionary:
	return scenarios.get(scenario_id, {})

func start_scenario(scenario_id:String) -> void:
	var scenario = get_scenario(scenario_id)
	if scenario.empty():
		push_error("Scenario '%s' not found" % scenario_id)
		return
	# Emit signal to let GameLoop / UI react
	emit_signal("scenario_started", scenario_id)
	# Spawn forces (stub) — GameLoop or ScenarioManager can implement spawning logic
	spawn_forces(scenario)
	# Potentially perform additional setup here

func end_scenario(scenario_id:String, result:Dictionary) -> void:
	# result should contain keys like: "victory":bool, "summary":{}, etc.
	emit_signal("scenario_ended", scenario_id, result)

func spawn_forces(scenario:Dictionary) -> void:
	# Example stub: scenario.enemy_roster is expected to be an array of unit definitions
	# The GameLoop or a Factory class should handle actual instancing; this function
	# is a convenient hook to process the scenario data.
	print("Spawning forces for scenario: %s" % (scenario.get("name", "<unnamed>")))
	# TODO: integrate with Board/GameLoop to place units on map
