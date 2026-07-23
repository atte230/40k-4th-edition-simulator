extends Node

# TurnManager.gd (updated to prompt player for overwatch selections before charge phase)
# Coordinates a full game turn: movement -> shooting -> charge -> assault

class_name TurnManager

var rules = preload("res://rules/RulesEngine.gd")
var Shooting = preload("res://rules/ShootingSystem.gd")
var Assault = preload("res://rules/AssaultSystem.gd")
var Formation = preload("res://rules/FormationManager.gd")
var Reaction = preload("res://rules/ReactionManager.gd")
var OverwatchMgrScript = preload("res://rules/OverwatchManager.gd")

func run_turn(attackers:Array, defenders:Array, opts:Dictionary = {}) -> Dictionary:
	var out = {"movement": [], "shooting": null, "charges": [], "melee": null, "reactions": []}

	var seed = opts.get("seed", 1337)
	if rules and rules.has_method("set_seed"):
		rules.call("set_seed", seed)

	var movement_distance = float(opts.get("movement_distance", 3.0))
	var allow_overwatch = bool(opts.get("allow_overwatch", true))

	# Movement
	var def_centroid = _centroid(defenders)
	for u in attackers:
		if u == null:
			continue
		var start = u.global_transform.origin
		var dir = (def_centroid - start).normalized()
		var dest = start + dir * movement_distance
		u.global_transform = Transform(u.global_transform.basis, dest)
		out["movement"].append({"unit": u.name, "from": start, "to": dest})
		var cl = get_tree().get_root().get_node_or_null("CombatLogManager")
		if cl and cl.has_method("log_event"):
			cl.call("log_event", {"message": "%s moves towards enemy" % u.name, "type": "movement"})

	# Shooting
	var shooting_sys = Shooting.new()
	var shooting_res = shooting_sys.resolve_shooting_phase(attackers, defenders, {})
	out["shooting"] = shooting_res

	# Prompt for overwatch selections before charge phase
	if allow_overwatch:
		# Ensure OverwatchManager exists
		var ow = get_tree().get_root().get_node_or_null("OverwatchManager")
		if ow == null:
			ow = OverwatchMgrScript.new()
			ow.name = "OverwatchManager"
			get_tree().get_root().add_child(ow)
		# Prompt and wait for player selection
		var sel = yield(ow, "overwatch_confirmed")
		# sel is an Array of selected units; OverwatchManager already set meta on units
		# log selected overwatch units
		for s in sel:
			var cl2 = get_tree().get_root().get_node_or_null("CombatLogManager")
			if cl2 and cl2.has_method("log_event"):
				cl2.call("log_event", {"message": "%s is set to Overwatch" % s.name, "type": "status"})

	# Reaction manager
	var reaction_mgr = Reaction.new()

	# Charge attempts
	var charged_units := []
	for u in attackers:
		if u == null:
			continue
		var tgt = _choose_target(u, defenders)
		if tgt == null:
			continue
		var dist = u.global_transform.origin.distance_to(tgt.global_transform.origin)
		var needed = ceil(dist)
		var assault_sys = Assault.new()
		var charge_res = assault_sys.attempt_charge(u, tgt, needed)
		# Resolve reactions (overwatch) after charge declaration but before charge completes
		if allow_overwatch:
			var reactions = reaction_mgr.resolve_reactions(u, defenders)
			out["reactions"].append({"attacker": u.name, "reactions": reactions})
			# log reactions
			for r in reactions:
				var cl2 = get_tree().get_root().get_node_or_null("CombatLogManager")
				if cl2 and cl2.has_method("log_event"):
					cl2.call("log_event", {"message": "%s overwatch fires at %s" % [r.defender.name, r.attacker.name], "type": "shoot", "rolls": r.result})
			# if attacker was killed by reactions, mark as failed
			if not is_instance_valid(u) or (u.has_method("to_persistent_dict") and int(u.call("to_persistent_dict").get("wounds",0)) >= int(u.call("to_persistent_dict").get("max_wounds",1))):
				charge_res["success"] = false
				charge_res["killed_by_reaction"] = true
		# If still alive and success true, add to charged
		if charge_res.get("success", false):
			charged_units.append(u)
		out["charges"].append({"attacker": u.name, "target": tgt.name, "distance": dist, "needed": needed, "res": charge_res})

	# Melee
	var context = {"charged_units": charged_units}
	var assault_sys2 = Assault.new()
	var melee_res = assault_sys2.resolve_melee(charged_units, defenders, context)
	out["melee"] = melee_res

	return out

# Helpers (unchanged)
func _centroid(units:Array) -> Vector3:
	var c = Vector3.ZERO
	var count = 0
	for u in units:
		if u == null:
			continue
		c += u.global_transform.origin
		count += 1
	if count == 0:
		return Vector3.ZERO
	return c / float(count)

func _choose_target(shooter:Node, targets:Array) -> Node:
	if targets.empty():
		return null
	var best := null
	var best_score := 1e9
	for t in targets:
		if t == null:
			continue
		var d = shooter.global_transform.origin.distance_to(t.global_transform.origin)
		var wounds = 0
		if t.has_method("to_persistent_dict"):
			wounds = int(t.call("to_persistent_dict").get("wounds", 0))
		var score = d + wounds * 1000
		if score < best_score:
			best_score = score
			best = t
	return best
