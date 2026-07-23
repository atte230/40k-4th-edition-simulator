extends Node

# tools/automated_shooting_test.gd
# Automated test for shooting: spawns one shooter and several targets and asserts at least one shot resolves and hits or does damage.

func _run_test() -> void:
	var shooter_scene = load("res://units/Space_Marine_Devastator.tscn")
	var target_scene = load("res://units/Ork_Boy.tscn")
	var shooter = shooter_scene.instantiate()
	shooter.name = "TestShooter"
	get_tree().get_root().add_child(shooter)
	shooter.global_transform.origin = Vector3(-2,0,0)

	var targets := []
	for i in range(3):
		var t = target_scene.instantiate()
		t.name = "TestTarget_%d" % i
		get_tree().get_root().add_child(t)
		t.global_transform.origin = Vector3(2 + i, 0, 0)
		targets.append(t)

	# Ensure weapon
	if shooter.has_method("to_persistent_dict"):
		var d = shooter.call("to_persistent_dict")
		if d.get("weapons", []) == []:
			shooter.set("weapons", [{"name":"TestGun","shots":2,"S":4,"AP":0,"damage":1}])

	var Shooting = preload("res://rules/ShootingSystem.gd").new()
	var res = Shooting.resolve_shooting_phase([shooter], targets, {})
	var ok = false
	for c in res.get("casualties", []):
		if c.get("damage", 0) > 0:
			ok = true
			break
	if ok:
		print("Automated shooting test: PASS - at least one target took damage")
	else:
		print("Automated shooting test: FAIL - no damage applied")

func _ready() -> void:
	if Engine.is_editor_hint():
		_run_test()
