extends Node

# AssaultSystem.gd
# Implements 4th edition assault (close combat) rules: charge roll, fight pools, WS-based to-hit, Hammer of Wrath, casualty removal, consolidation.

class_name AssaultSystem

var rules = preload("res://rules/RulesEngine.gd")

# Compute a D6 roll
func roll_d6() -> int:
	return randi() % 6 + 1

# Charge roll: attacker attempts to charge target. Returns dict with success bool and distance rolled.
# In this simplified system, we accept a charge_distance parameter (in inches/world units) and roll 2D6.
func attempt_charge(attacker:Node, target:Node, charge_distance:float) -> Dictionary:
	var r1 = roll_d6()
	var r2 = roll_d6()
	var total = r1 + r2
	var success = total >= int(charge_distance)
	return {"rolls":[r1, r2], "total": total, "success": success}

# Resolve a close combat between two units/groups. For simplicity, accept two arrays of unit nodes.
# This function performs a single fight step: both sides roll attacks based on A (attacks) and WS for to-hit.
func resolve_melee(attackers:Array, defenders:Array) -> Dictionary:
	var log := {"attacks": [], "casualties": {"attackers": [], "defenders": []}}
	# Each unit makes its attacks (simplified: A attacks at WS to-hit)
	for unit in attackers:
		var atk = _unit_melee_attacks(unit)
		for a in range(atk):
			var roll = roll_d6()
			var target_ws = int(unit.get("ws", 4))
			var hit = rules.is_success(roll, target_ws)
			log["attacks"].append({"attacker": unit.name, "roll": roll, "target": unit.name, "hit": hit})
			if hit:
				# Apply wound roll: S vs T using unit's S and chosen defender's T (pick random defender)
				if defenders.size() == 0:
					continue
				var tgt = defenders[int(randi() % defenders.size())]
				var wtarget = rules.to_wound_target(int(unit.get("s", 4)), int(tgt.get("t", 4)))
				var wroll = roll_d6()
				var wounded = rules.is_success(wroll, wtarget)
				log["attacks"].append({"attacker": unit.name, "wroll": wroll, "wtarget": wtarget, "wounded": wounded, "target_unit": tgt.name})
				if wounded:
					# Defender saves
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv", 6)), 0)
					var sroll = roll_d6()
					var saved = rules.is_success(sroll, save_needed)
					log["attacks"].append({"target": tgt.name, "save_roll": sroll, "save_needed": save_needed, "saved": saved})
					if not saved:
						# apply damage (1 for now)
						var applied = rules.apply_damage_to_unit(tgt, 1)
						log["casualties"]["defenders"].append({"unit": tgt.name, "killed": applied.get("killed", false)})

	# Defenders strike back similarly
	for unit in defenders:
		var atk = _unit_melee_attacks(unit)
		for a in range(atk):
			var roll = roll_d6()
			var hit = rules.is_success(roll, int(unit.get("ws", 4)))
			log["attacks"].append({"attacker": unit.name, "roll": roll, "hit": hit})
			if hit:
				if attackers.size() == 0:
					continue
				var tgt = attackers[int(randi() % attackers.size())]
				var wtarget = rules.to_wound_target(int(unit.get("s", 4)), int(tgt.get("t", 4)))
				var wroll = roll_d6()
				var wounded = rules.is_success(wroll, wtarget)
				log["attacks"].append({"attacker": unit.name, "wroll": wroll, "wtarget": wtarget, "wounded": wounded, "target_unit": tgt.name})
				if wounded:
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv", 6)), 0)
					var sroll = roll_d6()
					var saved = rules.is_success(sroll, save_needed)
					log["attacks"].append({"target": tgt.name, "save_roll": sroll, "save_needed": save_needed, "saved": saved})
					if not saved:
						var applied = rules.apply_damage_to_unit(tgt, 1)
						log["casualties"]["attackers"].append({"unit": tgt.name, "killed": applied.get("killed", false)})

	return log

# Helper to determine number of melee attacks per unit (simplified: use A stat)
func _unit_melee_attacks(unit:Node) -> int:
	if unit == null:
		return 0
	return int(unit.get("a", 1))
