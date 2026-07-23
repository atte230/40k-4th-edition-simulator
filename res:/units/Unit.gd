extends Node3D

# Unit.gd
# Basic unit script with persistent fields for campaign saves.
# Designed to be attached to unit scene root nodes.

class_name Unit

@export var unit_id: String = ""   # unique identifier used by campaigns
@export var unit_name: String = "Unnamed"
@export var unit_type: String = "Generic"

# 4th edition stats
@export var ws: int = 4
@export var bs: int = 4
@export var s: int = 4
@export var t: int = 4
@export var w: int = 1
@export var a: int = 1
@export var i: int = 4
@export var ld: int = 8
@export var sv: int = 6

@export var movement: int = 6 # inches

var xp: int = 0
var wounds: int = 0
var injuries: Array = []
var max_wounds: int = 1

# weapons: array of dictionaries {name, shots, S, AP, damage}
var weapons: Array = []

func _ready() -> void:
	# Ensure there's a unit_id; if not, generate one
	if unit_id == "":
		unit_id = "%s_%s" % [unit_type, str(OS.get_unix_time())]
	# Default weapons if empty
	if weapons.empty():
		weapons = []

func set_unit_id(id:String) -> void:
	unit_id = id

func to_persistent_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"name": unit_name,
		"type": unit_type,
		"ws": ws,
		"bs": bs,
		"s": s,
		"t": t,
		"w": w,
		"a": a,
		"i": i,
		"ld": ld,
		"sv": sv,
		"movement": movement,
		"xp": xp,
		"wounds": wounds,
		"max_wounds": max_wounds,
		"injuries": injuries.duplicate(true),
		"weapons": weapons.duplicate(true)
	}

func apply_persistent_dict(data:Dictionary) -> void:
	unit_id = data.get("unit_id", unit_id)
	unit_name = data.get("name", unit_name)
	unit_type = data.get("type", unit_type)
	ws = int(data.get("ws", ws))
	bs = int(data.get("bs", bs))
	s = int(data.get("s", s))
	t = int(data.get("t", t))
	w = int(data.get("w", w))
	a = int(data.get("a", a))
	i = int(data.get("i", i))
	ld = int(data.get("ld", ld))
	sv = int(data.get("sv", sv))
	movement = int(data.get("movement", movement))
	xp = int(data.get("xp", xp))
	wounds = int(data.get("wounds", wounds))
	max_wounds = int(data.get("max_wounds", max_wounds))
	injuries = data.get("injuries", injuries)
	weapons = data.get("weapons", weapons)
	# Update visuals / healthbars here if needed
	_update_visuals()

func _update_visuals() -> void:
	# Placeholder hook — update healthbar, color, etc.
	pass

func take_damage(amount:int) -> void:
	wounds += amount
	if wounds >= max_wounds:
		_die()
	else:
		# play recoil / damage animation if available
		if has_method("on_damage"):
			call("on_damage", amount)

func _die() -> void:
	# Emit death signal / play animation
	if has_method("on_death"):
		call("on_death")
	queue_free()
