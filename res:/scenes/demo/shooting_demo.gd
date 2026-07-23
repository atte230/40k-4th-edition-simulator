extends Node3D

# shooting_demo.gd
# Simple shooting demo: spawns shooters and targets, resolves a shooting phase, and logs results.

func _ready() -> void:
	var shooter_scene = load("res://units/Space_Marine_Devastator.tscn")
	var target_scene = load("res://units/Ork_Boy.tscn")
	var shooters = []
	var targets = []
	# spawn 2 shooters
	for i in range(2):
		var s = shooter_scene.instantiate()
		s.name = "Shooter_%d" % i
		get_tree().get_root().add_child(s)
		s.global_transform.origin = Vector3(-4 + i*2, 0, -2)
		shooters.append(s)
	# spawn 4 targets
	for i in range(4):
		var t = target_scene.instantiate()
		t.name = "Target_%d" % i
		get_tree().get_root().add_child(t)
		t.global_transform.origin = Vector3(2 + (i%2), 0, i)
		targets.append(t)

	# Ensure units have weapons if their templates didn't provide them
	for s in shooters:
		if not s.has_method("to_persistent_dict"):
			continue
		var d = s.call("to_persistent_dict")
		if d.get("weapons", []) == []:
			s.set("weapons", [{"name":"Bolter","shots":1,"S":4,"AP":0,"damage":1}])

	# Resolve shooting
	var Shooting = preload("res://rules/ShootingSystem.gd").new()
	var res = Shooting.resolve_shooting_phase(shooters, targets, {})
	print("Shooting demo result:", res)

	# Ensure Combat Log is visible
	var cl = get_tree().get_root().get_node_or_null("CombatLogManager")
	if cl:
		cl.visible = true
