extends Node

# AssaultSystem.gd (updated)
# Implements 4th edition assault (close combat) rules: charge roll, fight pools, WS-based to-hit, Hammer of Wrath, casualty removal, consolidation.

class_name AssaultSystem

var rules = preload("res://rules/RulesEngine.gd")

# Charge roll: attacker attempts to charge target. Returns dict with success bool and distance rolled.
# Uses 2D6 via RulesEngine.roll_2d6()
func attempt_charge(attacker:Node, target:Node, charge_distance:float) -> Dictionary:
	var total = rules.roll_2d6()
	var success = total >= int(charge_distance)
	return {"rolls": [total], "total": total, "success": success}

# Internal helper to notify via NotificationManager (if available)
func _notify(text:String) -> void:
	var nm = get_tree().get_root().get_node_or_null("NotificationManager")
	if nm == null:
		# Try to instantiate one and add it to root
		var script = load("res://managers/NotificationManager.gd")
		if script != null:
			nm = script.new()
			nm.name = "NotificationManager"
			get_tree().get_root().add_child(nm)
		else:
			return
	if nm.has_method("show_message"):
		nm.call("show_message", text)

# Resolve a close combat between two units/groups. For simplicity, accept two arrays of unit nodes.
# context: optional dictionary with keys:
#   charged_units: Array of units that charged successfully
#   ... (future hooks)
func resolve_melee(attackers:Array, defenders:Array, context:Dictionary = {}) -> Dictionary:
	var log := {"attacks": [], "casualties": {"attackers": [], "defenders": []}}
	var charged := context.get("charged_units", [])
	# Pre-melee: handle Hammer of Wrath (pre-emptive strike) for charged units
	for unit in charged:
		if unit == null:
			continue
		var specials = []
		if unit.has_method("to_persistent_dict"):
			specials = unit.call("to_persistent_dict").get("special_rules", [])
		elif unit.has_meta("special_rules"):
			specials = unit.get_meta("special_rules")
		if typeof(specials) == TYPE_ARRAY and "HammerOfWrath" in specials:
			# perform one pre-melee attack using unit's melee profile (fallback to S and AP 0)
			_notify("%s: Hammer of Wrath activated!" % unit.name)
			var melee_weapon = null
			if unit.has_method("to_persistent_dict"):
				var d = unit.call("to_persistent_dict")
				for w in d.get("weapons", []):
					if w.get("name", "").to_lower().find("chainsword") >= 0 or w.get("name","") == "Power Sword":
						melee_weapon = w
			if melee_weapon == null:
				melee_weapon = {"name":"HoW_melee","shots":1,"S":int(unit.get("s",4)),"AP":0,"damage":1}
			# choose a random defender to hit
			if defenders.size() > 0:
				var tgt = defenders[int(randi() % defenders.size())]
				var res = rules.resolve_shooting_attack(unit, melee_weapon, tgt, {})
				log["attacks"].append({"pre_melee_how": res})

	# Each unit makes its attacks (attackers first)
	for unit in attackers:
		var atk = _unit_melee_attacks(unit, context)
		# Notify if Furious Charge applies
		if unit in charged:
			var specials = []
			if unit.has_method("to_persistent_dict"):
				specials = unit.call("to_persistent_dict").get("special_rules", [])
			elif unit.has_meta("special_rules"):
				specials = unit.get_meta("special_rules")
			if typeof(specials) == TYPE_ARRAY and "FuriousCharge" in specials:
				_notify("%s gains Furious Charge (+1 Attack)" % unit.name)
		for a in range(atk):
			var roll = rules.roll_d6()
			var ws_target = int(unit.get("ws", 4))
			var hit = rules.is_success(roll, ws_target)
			log["attacks"].append({"attacker": unit.name, "roll": roll, "ws_target": ws_target, "hit": hit})
			if hit:
				if defenders.size() == 0:
					continue
				var tgt = defenders[int(rules.roll_d6() % defenders.size())]
				var wtarget = rules.to_wound_target(int(unit.get("s", 4)), int(tgt.get("t", 4)))
				var wroll = rules.roll_d6()
				var wounded = rules.is_success(wroll, wtarget)
				log["attacks"].append({"attacker": unit.name, "wroll": wroll, "wtarget": wtarget, "wounded": wounded, "target_unit": tgt.name})
				if wounded:
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv", 6)), 0)
					var sroll = rules.roll_d6()
					var saved = rules.is_success(sroll, save_needed)
					log["attacks"].append({"target": tgt.name, "save_roll": sroll, "save_needed": save_needed, "saved": saved})
					if not saved:
						var applied = rules.apply_damage_to_unit(tgt, 1)
						log["casualties"]["defenders"].append({"unit": tgt.name, "killed": applied.get("killed", false)})

	# Defenders strike back similarly
	for unit in defenders:
		var atk = _unit_melee_attacks(unit, context)
		for a in range(atk):
			var roll = rules.roll_d6()
			var ws_target = int(unit.get("ws", 4))
			var hit = rules.is_success(roll, ws_target)
			log["attacks"].append({"attacker": unit.name, "roll": roll, "ws_target": ws_target, "hit": hit})
			if hit:
				if attackers.size() == 0:
					continue
				var tgt = attackers[int(rules.roll_d6() % attackers.size())]
				var wtarget = rules.to_wound_target(int(unit.get("s", 4)), int(tgt.get("t", 4)))
				var wroll = rules.roll_d6()
				var wounded = rules.is_success(wroll, wtarget)
				log["attacks"].append({"attacker": unit.name, "wroll": wroll, "wtarget": wtarget, "wounded": wounded, "target_unit": tgt.name})
				if wounded:
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv", 6)), 0)
					var sroll = rules.roll_d6()
					var saved = rules.is_success(sroll, save_needed)
					log["attacks"].append({"target": tgt.name, "save_roll": sroll, "save_needed": save_needed, "saved": saved})
					if not saved:
						var applied = rules.apply_damage_to_unit(tgt, 1)
						log["casualties"]["attackers"].append({"unit": tgt.name, "killed": applied.get("killed", false)})

	return log

# Helper to determine number of melee attacks per unit (considers A plus aura and furious charge)
func _unit_melee_attacks(unit:Node, context:Dictionary = {}) -> int:
	if unit == null:
		return 0
	var base = int(unit.get("a", 1))
	# aura bonus
	var aura = int(unit.get_meta("aura_attack_bonus", 0))
	base += aura
	# charged bonus
	var charged_units = context.get("charged_units", [])
	if unit in charged_units:
		# Furious Charge grants +1 A if unit has special rule
		var specials = []
		if unit.has_method("to_persistent_dict"):
			specials = unit.call("to_persistent_dict").get("special_rules", [])
		elif unit.has_meta("special_rules"):
			specials = unit.get_meta("special_rules")
		if typeof(specials) == TYPE_ARRAY and "FuriousCharge" in specials:
			base += 1
	return base
