extends Node

# tools/test_save_load.gd
# Quick test script to validate SaveLoad.save_campaign / load_campaign roundtrip.
# Run this with the Godot editor or call from a tool scene.

func _run_test() -> void:
	var sl = preload("res://managers/SaveLoad.gd").new()
	var sample = {
		"id":"test_campaign",
		"version":1,
		"player_faction":"Space Marines",
		"roster":[ { "unit_id":"u1", "name":"A", "xp":5, "wounds":0 } ],
		"current_scenario":"first_blood",
		"completed_scenarios":[]
	}
	var ok = sl.save_campaign(sample)
	if not ok:
		push_error("Test save failed")
		return
	var loaded = sl.load_campaign("test_campaign")
	if loaded == null:
		push_error("Test load failed")
		return
	assert(loaded.get("id", "") == "test_campaign")
	print("Save/load roundtrip OK: %s" % loaded)

# Allow running the test from the editor
func _ready() -> void:
	if Engine.is_editor_hint():
		print("tools/test_save_load.gd: running save/load test...")
		_run_test()
