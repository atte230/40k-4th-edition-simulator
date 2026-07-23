extends Node

# AssaultSystem.gd (moved from res: to res/rules)
# Polish formation/spacing and facing, added 3v3 demo, automated overlap test, replay and rule tagging

class_name AssaultSystem

var rules = preload("res://rules/RulesEngine.gd")
var formation_manager_path = "res://rules/FormationManager.gd"

func _get_formation_manager():
	var fm = get_tree().get_root().get_node_or_null("FormationManager")
	if fm == null and ResourceLoader.exists(formation_manager_path):
		var script = load(formation_manager_path)
		fm = script.new()
		fm.name = "FormationManager"
		get_tree().get_root().add_child(fm)
	return fm

# Resolve a close combat between two units/groups. Records rule events for replay ("rule").
func resolve_melee(attackers:Array, defenders:Array, context:Dictionary = {}) -> Dictionary:
	var log := {"attacks": [], "casualties": {"attackers": [], "defenders": []}}
	var charged := context.get("charged_units", [])
	var replay_events := []

	# Arrange formation before melee
	var fm = _get_formation_manager()
	if fm != null:
		var all = []
		for u in attackers:
			all.append(u)
		for u in defenders:
			all.append(u)
		fm.arrange_formation(all)
		fm.resolve_overlaps(all)
		fm.enforce_facing_towards_centroid(all)

	# Pre-melee: Hammer of Wrath
	for unit in charged:
		if unit == null:
			continue
		var specials = []
		if unit.has_method("to_persistent_dict"):
			specials = unit.call("to_persistent_dict").get("special_rules", [])
		elif unit.has_meta("special_rules"):
			specials = unit.get_meta("special_rules")
		if typeof(specials) == TYPE_ARRAY and "HammerOfWrath" in specials:
			_notify("%s: Hammer of Wrath activated!" % unit.name)
			_log_event("%s triggers Hammer of Wrath (pre-melee strike)" % unit.name)
			var melee_weapon = null
			if unit.has_method("to_persistent_dict"):
				var d = unit.call("to_persistent_dict")
				for w in d.get("weapons", []):
					if w.get("name", "").to_lower().find("chainsword") >= 0 or w.get("name","") == "Power Sword":
						melee_weapon = w
			if melee_weapon == null:
				melee_weapon = {"name":"HoW_melee","shots":1,"S":int(unit.get("s",4)),"AP":0,"damage":1}
			# choose a target
			if defenders.size() > 0:
				var tgt = _choose_target(unit, defenders)
				var hit_roll = rules.roll_d6()
				var hit = rules.is_success(hit_roll, int(unit.get("ws",4)))
				var wroll = rules.roll_d6()
				var wtarget = rules.to_wound_target(int(melee_weapon.get("S", unit.get("s",4))), int(tgt.get("t",4)))
				var wounded = rules.is_success(wroll, wtarget)
				var saved = false
				var sroll = 0
				if wounded and wtarget != 999:
					sroll = rules.roll_d6()
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv",6)), int(melee_weapon.get("AP",0)))
					saved = rules.is_success(sroll, save_needed)
					if not saved:
						var dmg = int(melee_weapon.get("damage",1))
						var applied = rules.apply_damage_to_unit(tgt, dmg)
						replay_events.append({
						"attacker_id": unit.call("to_persistent_dict").get("unit_id"),
						"target_id": tgt.call("to_persistent_dict").get("unit_id"),
						"hit_roll": hit_roll, "hit": hit,
						"wroll": wroll, "wtarget": wtarget, "wounded": wounded,
						"save_roll": sroll, "save_needed": save_needed, "saved": saved,
						"damage_dealt": applied.get("wounds_applied", 0), "killed": applied.get("killed", false),
						"rule": "HammerOfWrath"
					})
					_log_event("HoW: %s attacked %s -> hit=%s wounded=%s saved=%s" % [unit.name, tgt.name, str(hit), str(wounded), str(saved)])

	# Main melee: attackers
	for unit in attackers:
		var atk = _unit_melee_attacks(unit, context)
		# Furious Charge flag
		if unit in charged:
			var specials = []
			if unit.has_method("to_persistent_dict"):
				specials = unit.call("to_persistent_dict").get("special_rules", [])
			elif unit.has_meta("special_rules"):
				specials = unit.get_meta("special_rules")
			if typeof(specials) == TYPE_ARRAY and "FuriousCharge" in specials:
				_notify("%s gains Furious Charge (+1 Attack)" % unit.name)
				_log_event("%s: Furious Charge grants +1 Attack" % unit.name)
				# record a rule event for replay (no damage)
				replay_events.append({
					"attacker_id": unit.call("to_persistent_dict").get("unit_id"),
					"rule": "FuriousCharge"
				})
		for a in range(atk):
			var hit_roll = rules.roll_d6()
			var ws_target = int(unit.get("ws", 4))
			var hit = rules.is_success(hit_roll, ws_target)
			_log_event("%s makes melee attack roll: %d vs WS %d -> %s" % [unit.name, hit_roll, ws_target, str(hit)])
			if hit:
				if defenders.size() == 0:
					continue
				var tgt = _choose_target(unit, defenders)
				var wtarget = rules.to_wound_target(int(unit.get("s", 4)), int(tgt.get("t", 4)))
				var wroll = rules.roll_d6()
				var wounded = rules.is_success(wroll, wtarget)
				var sroll = 0
				var saved = false
				var damage_dealt = 0
				var killed = false
				if wounded and wtarget != 999:
					sroll = rules.roll_d6()
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv", 6)), 0)
					saved = rules.is_success(sroll, save_needed)
					if not saved:
						var applied = rules.apply_damage_to_unit(tgt, 1)
						damage_dealt = applied.get("wounds_applied", 0)
						killed = applied.get("killed", false)
					replay_events.append({
						"attacker_id": unit.call("to_persistent_dict").get("unit_id"),
						"target_id": tgt.call("to_persistent_dict").get("unit_id"),
						"hit_roll": hit_roll, "hit": hit,
						"wroll": wroll, "wtarget": wtarget, "wounded": wounded,
						"save_roll": sroll, "save_needed": save_needed if wounded else null, "saved": saved,
						"damage_dealt": damage_dealt, "killed": killed
					})
					_log_event("%s wound roll: %d vs target %d -> %s (target %s)" % [unit.name, wroll, wtarget, str(wounded), tgt.name])
					if wounded and not saved:
						_log_event("%s takes %d damage (killed=%s)" % [tgt.name, damage_dealt, str(killed)])

	# Defenders strike back similarly
	for unit in defenders:
		var atk = _unit_melee_attacks(unit, context)
		for a in range(atk):
			var hit_roll = rules.roll_d6()
			var ws_target = int(unit.get("ws", 4))
			var hit = rules.is_success(hit_roll, ws_target)
			_log_event("%s makes melee attack roll: %d vs WS %d -> %s" % [unit.name, hit_roll, ws_target, str(hit)])
			if hit:
				if attackers.size() == 0:
					continue
				var tgt = _choose_target(unit, attackers)
				var wtarget = rules.to_wound_target(int(unit.get("s", 4)), int(tgt.get("t", 4)))
				var wroll = rules.roll_d6()
				var wounded = rules.is_success(wroll, wtarget)
				var sroll = 0
				var saved = false
				var damage_dealt = 0
				var killed = false
				if wounded and wtarget != 999:
					sroll = rules.roll_d6()
					var save_needed = rules.required_save_after_ap(int(tgt.get("sv", 6)), 0)
					saved = rules.is_success(sroll, save_needed)
					if not saved:
						var applied = rules.apply_damage_to_unit(tgt, 1)
						damage_dealt = applied.get("wounds_applied", 0)
						killed = applied.get("killed", false)
					replay_events.append({
						"attacker_id": unit.call("to_persistent_dict").get("unit_id"),
						"target_id": tgt.call("to_persistent_dict").get("unit_id"),
						"hit_roll": hit_roll, "hit": hit,
						"wroll": wroll, "wtarget": wtarget, "wounded": wounded,
						"save_roll": sroll, "save_needed": save_needed if wounded else null, "saved": saved,
						"damage_dealt": damage_dealt, "killed": killed
					})
					_log_event("%s wound roll: %d vs target %d -> %s (target %s)" % [unit.name, wroll, wtarget, str(wounded), tgt.name])
					if wounded and not saved:
						_log_event("%s takes %d damage (killed=%s)" % [tgt.name, damage_dealt, str(killed)])

	# After resolving the melee, record the replay command with events
	var rm = _get_replay_manager()
	if rm != null:
		rm.record_command({"type":"melee", "events": replay_events})

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

# smarter target selection: prefer nearest wounded or lowest wounds, then nearest distance
func _choose_target(unit:Node, targets:Array) -> Node:
	if targets.empty():
		return null
	var best := null
	var best_score := 1e9
	for t in targets:
		if t == null:
			continue
		var d = unit.global_transform.origin.distance_to(t.global_transform.origin) if unit.has_method("global_transform") and t.has_method("global_transform") else 0
		var wounds = 0
		if t.has_method("to_persistent_dict"):
			wounds = int(t.call("to_persistent_dict").get("wounds", 0))
		# threat weight can be expanded; currently wounds*1000 + distance
		var score = wounds * 1000 + d
		if score < best_score:
			best_score = score
			best = t
	return best

# Internal helper to ensure replay manager exists
func _get_replay_manager():
	var rm = get_tree().get_root().get_node_or_null("ReplayManager")
	if rm == null and ResourceLoader.exists("res://managers/ReplayManager.gd"):
		rm = load("res://managers/ReplayManager.gd").new()
		rm.name = "ReplayManager"
		get_tree().get_root().add_child(rm)
	return rm

# Internal helper to notify via NotificationManager (if available)
func _notify(text:String) -> void:
	var nm = get_tree().get_root().get_node_or_null("NotificationManager")
	if nm == null:
		var script = load("res://managers/NotificationManager.gd")
		if script != null:
			nm = script.new()
			nm.name = "NotificationManager"
			get_tree().get_root().add_child(nm)
		else:
			return
	if nm.has_method("show_message"):
		nm.call("show_message", text)

# Internal helper to log to CombatLogManager
func _log_event(text:String) -> void:
	var cl = get_tree().get_root().get_node_or_null("CombatLogManager")
	if cl == null:
		var script = load("res://managers/CombatLogManager.gd")
		if script != null:
			cl = script.new()
			cl.name = "CombatLogManager"
			get_tree().get_root().add_child(cl)
	if cl and cl.has_method("log_event"):
		cl.call("log_event", {"message": text, "type":"combat"})
