extends Node

# ReplayManager.gd (updated)
# Records structured combat commands (with explicit dice/outcomes) and can replay them deterministically by applying recorded results.

class_name ReplayManager

var recording := false
var commands := []
var snapshot := []
var current_index := 0
var play_timer: Timer = null
var play_speed := 1.0 # multiplier (1x default)

func start_record() -> void:
	commands.clear()
	snapshot.clear()
	current_index = 0
	recording = true
	# capture all Units in scene root
	for node in get_tree().get_root().get_children():
		if node is Node and node.has_method("to_persistent_dict"):
			var d = node.call("to_persistent_dict")
			var trans = node.global_transform
			snapshot.append({"data": d, "transform": trans, "scene_type": node.get("unit_type")})
	print("ReplayManager: recording started, snapshot size=%d" % snapshot.size())

func stop_record() -> void:
	recording = false
	print("ReplayManager: recording stopped, commands=%d" % commands.size())

func record_command(cmd:Dictionary) -> void:
	if not recording:
		return
	commands.append(cmd)

func set_play_speed(val:float) -> void:
	play_speed = max(0.01, val)
	if play_timer != null and play_timer.is_stopped() == false:
		# adjust wait_time based on new speed; base interval 0.5
		play_timer.wait_time = 0.5 / play_speed

# Reset the scene to the recorded snapshot. This destroys existing units and reinstantiates from templates.
func reset_scene_from_snapshot() -> void:
	# remove existing unit nodes that have to_persistent_dict
	for node in get_tree().get_root().get_children():
		if node is Node and node.has_method("to_persistent_dict"):
			node.queue_free()
	# instantiate units from snapshot
	for entry in snapshot:
		var d = entry.get("data")
		var scene_type = d.get("type", "")
		var scene_path = "res://units/%s.tscn" % scene_type
		var scene = null
		if ResourceLoader.exists(scene_path):
			scene = load(scene_path)
		if scene == null:
			# fallback: try by replacing spaces
			scene_path = "res://units/%s.tscn" % scene_type.replace(" ", "_")
			if ResourceLoader.exists(scene_path):
				scene = load(scene_path)
		if scene == null:
			print("ReplayManager: could not find scene for type %s" % scene_type)
			continue
		var inst = scene.instantiate()
		get_tree().get_root().add_child(inst)
		inst.global_transform = entry.get("transform")
		# apply persistent dict
		if inst.has_method("apply_persistent_dict"):
			inst.call("apply_persistent_dict", d)

func play(from_index:int = -1) -> void:
	if from_index >= 0:
		current_index = from_index
	# Reset scene
	reset_scene_from_snapshot()
	# create timer
	if play_timer == null:
		play_timer = Timer.new()
		play_timer.one_shot = false
		play_timer.pause_mode = Node.PAUSE_MODE_PROCESS
		add_child(play_timer)
	# schedule events
	var interval = 0.5 / play_speed
	play_timer.wait_time = interval
	if not play_timer.is_connected("timeout", self, "_on_play_tick"):
		play_timer.connect("timeout", Callable(self, "_on_play_tick"))
	play_timer.start()

func pause() -> void:
	if play_timer != null:
		play_timer.stop()

func stop() -> void:
	pause()
	current_index = 0

func step_forward() -> void:
	if current_index >= commands.size():
		return
	_apply_command(commands[current_index])
	current_index += 1

func step_backward() -> void:
	# implement by resetting and replaying up to index-1
	var target = max(0, current_index - 1)
	reset_scene_from_snapshot()
	for i in range(target):
		_apply_command(commands[i])
	current_index = target

func jump_to_next_rule() -> void:
	# Find next command index with an event that has a 'rule' key
	for idx in range(current_index, commands.size()):
		var cmd = commands[idx]
		if cmd.has("events"):
			for ev in cmd.events:
				if typeof(ev) == TYPE_DICTIONARY and ev.has("rule"):
					# play from this index
					play(idx)
					return
	# nothing found
	print("ReplayManager: no next rule event found")

func _on_play_tick() -> void:
	if current_index >= commands.size():
		pause()
		return
	_apply_command(commands[current_index])
	current_index += 1

func _apply_command(cmd:Dictionary) -> void:
	# Currently support melee command with explicit events list
	var t = cmd.get("type", "")
	if t == "melee":
		var events = cmd.get("events", [])
		for ev in events:
			# find attacker and target nodes by unit_id
			var atk = _find_unit_by_id(ev.get("attacker_id", ""))
			var tgt = _find_unit_by_id(ev.get("target_id", ""))
			# Optionally animate here (highlight)
			if ev.has("damage_dealt"):
				var dmg = int(ev.get("damage_dealt", 0))
				if dmg > 0 and tgt != null and tgt.has_method("take_damage"):
					tgt.call("take_damage", dmg)
			# if there's a rule marker, optionally flash an indicator on attacker
			if ev.has("rule"):
				if atk != null and atk.has_method("on_rule_triggered"):
					atk.call("on_rule_triggered", ev.get("rule"))
	else:
		print("ReplayManager: unknown command type %s" % t)

func _find_unit_by_id(uid:String) -> Node:
	for node in get_tree().get_root().get_children():
		if node is Node and node.has_method("to_persistent_dict"):
			var d = node.call("to_persistent_dict")
			if d.get("unit_id", "") == uid:
				return node
	return null
