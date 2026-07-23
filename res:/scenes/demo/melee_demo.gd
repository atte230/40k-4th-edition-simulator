extends Node3D

# melee_demo.gd
# Small demo scene: spawns a 3v3 melee, runs formation and resolves melee, then enables replay.

func _ready() -> void:
	# create three attackers and three defenders using existing unit scenes
	var atk_scene = load("res://units/Space_Marine_Assault.tscn")
	var def_scene = load("res://units/Space_Marine_Devastator.tscn")
	var attackers = []
	var defenders = []
	for i in range(3):
		var a = atk_scene.instantiate()
		a.name = "Attacker_%d" % i
		get_tree().get_root().add_child(a)
		a.global_transform.origin = Vector3(-3 + i, 0, -1)
		attackers.append(a)
	for i in range(3):
		var d = def_scene.instantiate()
		d.name = "Defender_%d" % i
		get_tree().get_root().add_child(d)
		d.global_transform.origin = Vector3(3 - i, 0, 1)
		defenders.append(d)

	# ensure unit templates applied if available
	# run formation and resolve melee
	var assault = preload("res://rules/AssaultSystem.gd").new()
	var ctx = {"charged_units": attackers}
	assault.resolve_melee(attackers, defenders, ctx)

	# open Combat Log automatically (it should already open)
	var cl = get_tree().get_root().get_node_or_null("CombatLogManager")
	if cl:
		cl.visible = true
	# start replay recording playback controls exist in CombatLogManager
