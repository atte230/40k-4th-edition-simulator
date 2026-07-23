extends Node

# ShootingSystem.gd
# Handles ranged shooting phase: resolves weapons fire from shooters at targets, logs events to CombatLogManager, and records replayable shooting commands.

class_name ShootingSystem

var rules = preload("res://rules/RulesEngine.gd")

func _get_replay_manager():
	var rm = get_tree().get_root().get_node_or_null("ReplayManager")
	if rm == null and ResourceLoader.exists("res://managers/ReplayManager.gd"):
		rm = load("res://managers/ReplayManager.gd").new()
		rm.name = "ReplayManager"
		get_tree().get_root().add_child(rm)
	return rm

# Choose a target from a list using a simple heuristic: prefer nearest, then lowest wounds. Similar to melee.
func _choose_target(shooter:Node, targets:Array) -> Node:
	if targets.empty():
		return null
	var best := null
	var best_score := 1e9
	for t in targets:
		if t == null:
			continue
		var d = shooter.global_transform.origin.distance_to(t.global_transform.origin) if shooter.has_method("global_transform") and t.has_method("global_transform") else 0
		var wounds = 0
		if t.has_method("to_persistent_dict"):
			wounds = int(t.call("to_persistent_dict").get("wounds", 0))
		var score = d + wounds * 1000
		if score < best_score:
			best_score = score
			best = t
	return best

# Resolve a shooting phase for an array of shooter units against a pool of targets.
# shooters: Array of Node units
# targets: Array of Node units
# context: optional dict (e.g., overwatch flags)
func resolve_shooting_phase(shooters:Array, targets:Array, context:Dictionary = {}) -> Dictionary:
	var result = {"shots": [], "casualties": []}
	var replay_events := []
	for shooter in shooters:
		if shooter == null:
			continue
		# get weapon list from persistent dict or from 'weapons' property
		var wlist = []
		if shooter.has_method("to_persistent_dict"):
			wlist = shooter.call("to_persistent_dict").get("weapons", [])
		elif shooter.has("weapons"):
			wlist = shooter.get("weapons")
		# iterate weapons
		for weapon in wlist:
			if weapon == null:
				continue
			# pick a target for this weapon (assume single target per shooting attack for now)
			var tgt = _choose_target(shooter, targets)
			if tgt == null:
				continue
			# use RulesEngine.resolve_shooting_attack which already handles shots count
			var res = rules.resolve_shooting_attack(shooter, weapon, tgt, context)
			# append to log and replay events
			result["shots"].append(res)
			# log summary message
			var msg = "%s fires %s at %s" % [shooter.name, weapon.get("name", "weapon"), tgt.name]
			var cl = get_tree().get_root().get_node_or_null("CombatLogManager")
			if cl != null and cl.has_method("log_event"):
				cl.call("log_event", {"message": msg, "type": "shoot", "rolls": res})
			# build replay event entries from res (shots_results)
			for shot in res.get("shots_results", []):
				var ev = {
					"attacker_id": shooter.call("to_persistent_dict").get("unit_id"),
					"target_id": tgt.call("to_persistent_dict").get("unit_id"),
					"weapon": weapon.get("name", "weapon"),
					"rolls": shot.get("rolls", {}),
					"hit": shot.get("hit", false),
					"wound": shot.get("wound", false),
					"saved": shot.get("saved", false),
					"damage_dealt": shot.get("damage_dealt", 0),
					"killed": shot.get("killed", false)
				}
				replay_events.append(ev)
				# add to result casualties if any damage applied
				if ev["damage_dealt"] > 0:
					result["casualties"].append({"target": tgt.name, "damage": ev["damage_dealt"], "killed": ev["killed"]})

	# record a single replay command for the shooting phase
	var rm = _get_replay_manager()
	if rm != null:
		rm.record_command({"type": "shooting", "events": replay_events})
	return result

# Helper to perform an overwatch (optional) - for now behaves same as single shooting resolution
func resolve_overwatch(shooter:Node, target:Node, weapon:Dictionary) -> Dictionary:
	# could add reaction/initiative checks here
	return rules.resolve_shooting_attack(shooter, weapon, target, {})
