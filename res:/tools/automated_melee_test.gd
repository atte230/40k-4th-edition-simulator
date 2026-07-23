extends Node

# tools/automated_melee_test.gd
# Automated check: spawn 3v3, run formation.resolve_overlaps and assert no overlaps remain.

func _run_test() -> void:
	var fm = preload("res://rules/FormationManager.gd").new()
	var atk_scene = load("res://units/Space_Marine_Assault.tscn")
	var def_scene = load("res://units/Space_Marine_Devastator.tscn")
	var attackers = []
	var defenders = []
	for i in range(3):
		var a = atk_scene.instantiate()
		a.name = "TestAtk_%d" % i
		get_tree().get_root().add_child(a)
		attackers.append(a)
	for i in range(3):
		var d = def_scene.instantiate()
		d.name = "TestDef_%d" % i
		get_tree().get_root().add_child(d)
		defenders.append(d)

	var all = attackers.duplicate(true) + defenders.duplicate(true)
	fm.arrange_formation(all)
	fm.resolve_overlaps(all, 0.2, 10)

	# assert no overlaps
	var ok = true
	for i in range(all.size()):
		for j in range(i+1, all.size()):
			var a = all[i]
			var b = all[j]
			var d = a.global_transform.origin.distance_to(b.global_transform.origin)
			var min_dist = float(a.get("radius",0.5)) + float(b.get("radius",0.5))
			if d < min_dist - 0.001:
				ok = false
				print("Overlap detected between %s and %s: dist=%f min=%f" % [a.name, b.name, d, min_dist])
	if ok:
		print("Automated melee formation test: PASS - no overlaps")
	else:
		print("Automated melee formation test: FAIL")

func _ready() -> void:
	if Engine.is_editor_hint():
		_run_test()
