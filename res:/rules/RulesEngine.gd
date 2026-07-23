extends Node

# RulesEngine.gd
# Implements core Warhammer 40k 4th Edition rules: to-hit, to-wound chart, save interactions, damage application helpers.

class_name RulesEngine

# To-wound chart for 4th edition (S vs T)
# Returns integer D6 target (2..6) or 999 if cannot wound
static func to_wound_target(strength:int, toughness:int) -> int:
	if strength >= toughness * 2:
		return 2
	elif strength > toughness:
		return 3
	elif strength == toughness:
		return 4
	elif strength * 2 < toughness:
		# strengh < half toughness -> cannot wound
		return 999
	else:
		return 5

# Compute required armour/save roll taking AP into account
# weapon_ap is the AP value as in 4e (e.g. -1, -2). A negative AP worsens the save.
# We compute required_save = unit_save - weapon_ap
static func required_save_after_ap(unit_save:int, weapon_ap:int) -> int:
	var req = int(unit_save) - int(weapon_ap)
	# Minimum target of 2+ is conventional; if req <= 1 then treat as 2
	if req <= 1:
		req = 2
	# If req > 6 then save is impossible
	return req

# Helper to determine if a die roll succeeds a target number (D6)
static func is_success(roll:int, target:int) -> bool:
	if target == 999:
		return false
	return roll >= target

# Apply damage to a Unit instance; handles multiple wounds and death
# unit should implement apply_damage(damage_amount:int) or use wounds directly
static func apply_damage_to_unit(unit:Node, damage:int) -> Dictionary:
	# Returns summary dict: {killed:bool, wounds_applied:int}
	var applied = 0
	if unit == null:
		return {"killed": false, "wounds_applied": 0}
	# If unit exposes take_damage(amount) prefer that
	if unit.has_method("take_damage"):
		unit.call("take_damage", damage)
		# assume unit's wounds tracked internally
		return {"killed": (not is_instance_valid(unit)) or unit.get("wounds", 0) >= unit.get("max_wounds", 1), "wounds_applied": damage}
	# Fallback: manipulate wounds property
	if unit.has_meta("wounds"):
		var w = int(unit.get_meta("wounds"))
		w += damage
		unit.set_meta("wounds", w)
		return {"killed": w >= int(unit.get_meta("max_wounds", 1)), "wounds_applied": damage}
	# Nothing we can do
	return {"killed": false, "wounds_applied": 0}

# Resolve a single shot from attacker weapon against target
# weapon is a Dictionary with keys: name, shots, S, AP, damage (wounds per hit), special_rules (optional)
# attacker/target are Node instances (Unit) exposing bs, sv, etc.
static func resolve_single_shot(attacker:Node, weapon:Dictionary, target:Node, modifiers:Dictionary = {}) -> Dictionary:
	# Returns a result dict with details for logging
	var result = {"hit": false, "wound": false, "saved": false, "damage_dealt": 0, "rolls": {}}
	# to-hit
	var bs = int(attacker.get("bs", 4))
	var to_hit_mod = int(modifiers.get("to_hit", 0))
	var to_hit_target = max(2, min(6, bs - to_hit_mod))
	var hit_roll = randi() % 6 + 1
	result.rolls["hit_roll"] = hit_roll
	if is_success(hit_roll, to_hit_target):
		result["hit"] = true
	else:
		return result
	# to-wound
	var s = int(weapon.get("S", attacker.get("s", 4)))
	var t = int(target.get("t", 4))
	var wound_target = to_wound_target(s, t)
	result.rolls["wound_target"] = wound_target
	if wound_target == 999:
		result["wound"] = false
		return result
	var wound_roll = randi() % 6 + 1
	result.rolls["wound_roll"] = wound_roll
	if is_success(wound_roll, wound_target):
		result["wound"] = true
	else:
		return result
	# Save
	var unit_save = int(target.get("sv", 6))
	var weapon_ap = int(weapon.get("AP", 0))
	var required_save = required_save_after_ap(unit_save, weapon_ap)
	result.rolls["required_save"] = required_save
	if required_save > 6:
		# no save possible
		result["saved"] = false
	else:
		var save_roll = randi() % 6 + 1
		result.rolls["save_roll"] = save_roll
		if is_success(save_roll, required_save):
			result["saved"] = true
			return result
	# Unsaved wound: apply damage
	var dmg = int(weapon.get("damage", 1))	# wounds per unsaved hit
	var applied_info = apply_damage_to_unit(target, dmg)
	result["damage_dealt"] = applied_info.get("wounds_applied", 0)
	result["killed"] = applied_info.get("killed", false)
	return result

# Resolve a full shooting attack: attacker fires weapon at target with given number of shots
static func resolve_shooting_attack(attacker:Node, weapon:Dictionary, target:Node, modifiers:Dictionary = {}) -> Dictionary:
	var shots = int(weapon.get("shots", 1))
	var out = {"attacker": attacker, "weapon": weapon.get("name", ""), "target": target, "shots_results": []}
	for i in range(shots):
		var res = resolve_single_shot(attacker, weapon, target, modifiers)
		out["shots_results"].append(res)
		# Stop early if target killed
		if res.get("killed", false):
			break
	return out
