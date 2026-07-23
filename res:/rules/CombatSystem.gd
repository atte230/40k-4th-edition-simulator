extends Node

# CombatSystem.gd
# High-level combat routines that orchestrate shooting phases using RulesEngine.

class_name CombatSystem

var rules := preload("res://rules/RulesEngine.gd")

# Fire a weapon instance from attacker at target. weapon can be a Dictionary or a simple name mapped to templates
func fire_weapon(attacker:Node, weapon:Dictionary, target:Node, modifiers:Dictionary = {}) -> Dictionary:
	# Validate attacker/target
	if attacker == null or target == null:
		return {"error": "invalid actor"}
	# Ensure weapon structure
	if typeof(weapon) != TYPE_DICTIONARY:
		return {"error": "weapon must be a Dictionary"}
	# Compute range modifier / cover checks here in future
	var res = rules.resolve_shooting_attack(attacker, weapon, target, modifiers)
	# Log outcome (placeholder - integrate with CombatLog UI later)
	print("CombatSystem: %s fired %s at %s -> %s" % [attacker.name, weapon.get("name", ""), target.name, str(res)])
	return res

# Convenience: pick best target from array of potential targets using simple heuristics (lowest wounds, highest threat)
func choose_target(attacker:Node, targets:Array) -> Node:
	if targets.empty():
		return null
	# choose the target with lowest remaining wounds first
	targets.sort_custom(self, "_cmp_target_priority")
	return targets[0]

func _cmp_target_priority(a, b):
	var aw = int(a.get("wounds", 0))
	var bw = int(b.get("wounds", 0))
	if aw == bw:
		return 0
	return -1 if aw < bw else 1
