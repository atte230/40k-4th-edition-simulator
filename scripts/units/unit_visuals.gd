extends Node3D
## UnitVisuals: Visual representation of a unit
## Handles colors, meshes, and faction identification

class_name UnitVisuals

var unit: Unit
var color: Color = Color.WHITE
var mesh_instance: MeshInstance3D
var faction: String = ""

func _ready() -> void:
	unit = get_parent() as Unit
	if unit:
		faction = unit.unit_type
		setup_visuals()

func setup_visuals() -> void:
	"""Create visual representation of unit"""
	# Create mesh instance
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create box mesh for unit
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 1.5, 1.0)
	mesh_instance.mesh = box_mesh
	
	# Set color based on faction
	_update_faction_color()
	
	# Add material
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.set_surface_override_material(0, material)

func _update_faction_color() -> void:
	"""Update color based on faction"""
	var campaign_data = CampaignData.get_instance()
	var player_faction = campaign_data.get_faction()
	
	if unit.get("faction", "") == player_faction:
		# Player units = blue
		color = Color.BLUE
	else:
		# Enemy units = red/green based on faction
		if unit.get("faction", "") == "orks":
			color = Color.GREEN
		else:
			color = Color.RED
	
	# Update material if it exists
	if mesh_instance and mesh_instance.get_active_material(0):
		var material = mesh_instance.get_active_material(0)
		material.albedo_color = color

func set_faction_color(faction: String) -> void:
	"""Manually set the faction color"""
	faction = faction
	_update_faction_color()

func highlight() -> void:
	"""Highlight the unit (when selected)"""
	if mesh_instance and mesh_instance.get_active_material(0):
		var material = mesh_instance.get_active_material(0)
		material.emission = color
		material.emission_energy_multiplier = 2.0

func unhighlight() -> void:
	"""Remove highlight"""
	if mesh_instance and mesh_instance.get_active_material(0):
		var material = mesh_instance.get_active_material(0)
		material.emission = Color.BLACK
		material.emission_energy_multiplier = 1.0
