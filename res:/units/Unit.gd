extends Node3D

# Unit.gd
# Basic unit script with persistent fields for campaign saves.
# Designed to be attached to unit scene root nodes.

class_name Unit

@export var unit_id: String = ""   # unique identifier used by campaigns
@export var unit_name: String = "Unnamed"
@export var unit_type: String = "Generic"

var xp: int = 0
var wounds: int = 0
var injuries: Array = []
var max_wounds: int = 1

func _ready() -> void:
	# Ensure there's a unit_id; if not, generate one
	if unit_id == "":
		unit_id = "%s_%s" % [unit_type, str(OS.get_unix_time())]

func set_unit_id(id:String) -> void:
	unit_id = id

func to_persistent_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"name": unit_name,
		"type": unit_type,
		"xp": xp,
		"wounds": wounds,
		"injuries": injuries.duplicate(true)
	}

func apply_persistent_dict(data:Dictionary) -> void:
	unit_id = data.get("unit_id", unit_id)
	unit_name = data.get("name", unit_name)
	unit_type = data.get("type", unit_type)
	xp = int(data.get("xp", xp))
	wounds = int(data.get("wounds", wounds))
	injuries = data.get("injuries", injuries)
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
