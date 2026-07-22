extends Node3D
## Terrain: Creates and manages board terrain objects

class_name Terrain

var board: Board
var terrain_objects: Array[Node3D] = []

func _ready() -> void:
	setup_terrain()

func setup_terrain() -> void:
	"""Create terrain features on the board"""
	
	# Get board reference from parent
	board = get_parent().get_node("Board") as Board
	if not board:
		push_error("Terrain: Could not find Board node")
		return
	
	# Create central ruins (heavy cover)
	create_ruins(Vector3(0, 0, 0), Vector3(24, 3, 24), "Central Ruins", true)
	
	# Create scattered rocks (light cover)
	create_rocks(Vector3(-30, 0, 20), 4, "North Rocks")
	create_rocks(Vector3(30, 0, 20), 4, "North Rocks 2")
	create_rocks(Vector3(-30, 0, -20), 4, "South Rocks")
	create_rocks(Vector3(30, 0, -20), 4, "South Rocks 2")
	
	print("Terrain initialized with ruins and rocks")

func create_ruins(position: Vector3, size: Vector3, name: String, is_heavy_cover: bool) -> void:
	"""Create a ruin structure"""
	var ruins = Node3D.new()
	ruins.name = name
	ruins.position = position
	add_child(ruins)
	terrain_objects.append(ruins)
	
	# Create main structure
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	ruins.add_child(mesh_instance)
	
	# Material for ruins (grayish stone)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.45, 1.0)
	material.roughness = 0.9
	material.metallic = 0.0
	mesh_instance.set_surface_override_material(0, material)
	
	# Add collision for cover
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	ruins.add_child(collision_shape)
	
	# Add metadata for cover type
	ruins.set_meta("cover_type", "heavy" if is_heavy_cover else "light")
	ruins.set_meta("cover_save", 4 if is_heavy_cover else 6)

func create_rocks(position: Vector3, count: int, name: String) -> void:
	"""Create scattered rock formations (light cover)"""
	var rock_group = Node3D.new()
	rock_group.name = name
	rock_group.position = position
	add_child(rock_group)
	terrain_objects.append(rock_group)
	
	for i in range(count):
		var rock = Node3D.new()
		rock.position = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		rock_group.add_child(rock)
		
		# Create rock mesh
		var mesh_instance = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = randf_range(1.0, 2.0)
		sphere_mesh.height = randf_range(1.5, 2.5)
		mesh_instance.mesh = sphere_mesh
		rock.add_child(mesh_instance)
		
		# Material for rocks (brownish)
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.6, 0.55, 0.5, 1.0)
		material.roughness = 0.95
		mesh_instance.set_surface_override_material(0, material)
		
		# Collision
		var collision_shape = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 1.5
		collision_shape.shape = sphere_shape
		rock.add_child(collision_shape)
		
		# Metadata
		rock.set_meta("cover_type", "light")
		rock.set_meta("cover_save", 6)

func create_grid_overlay() -> void:
	"""Create visible grid lines on board"""
	if not board:
		return
	
	var grid_lines = Node3D.new()
	grid_lines.name = "GridOverlay"
	add_child(grid_lines)
	
	var grid_size = board.grid_size
	var board_width = board.board_width
	var board_height = board.board_height
	var line_count_x = int(board_width / grid_size)
	var line_count_z = int(board_height / grid_size)
	
	# Create vertical lines (X direction)
	for x in range(line_count_x):
		var start = board.grid_to_world(Vector2i(x, 0))
		var end = board.grid_to_world(Vector2i(x, line_count_z - 1))
		_create_line(grid_lines, start, end, Color(0.3, 0.3, 0.3, 0.5))
	
	# Create horizontal lines (Z direction)
	for z in range(line_count_z):
		var start = board.grid_to_world(Vector2i(0, z))
		var end = board.grid_to_world(Vector2i(line_count_x - 1, z))
		_create_line(grid_lines, start, end, Color(0.3, 0.3, 0.3, 0.5))

func _create_line(parent: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	"""Helper to create a line mesh"""
	var immediate_mesh = ImmediateMesh.new()
	var mesh_instance = MeshInstance3D.new()
	parent.add_child(mesh_instance)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.set_surface_override_material(0, material)

func get_cover_at_position(position: Vector3) -> Dictionary:
	"""Get cover information at a world position"""
	for terrain_obj in terrain_objects:
		var distance = position.distance_to(terrain_obj.global_position)
		var size = terrain_obj.get_child(0).mesh.get_aabb().size if terrain_obj.get_child_count() > 0 else Vector3(0, 0, 0)
		
		# Simple check - if close to terrain, has cover
		if distance < size.x / 2:
			var cover_type = terrain_obj.get_meta("cover_type", "light")
			var cover_save = terrain_obj.get_meta("cover_save", 6)
			return {
				"has_cover": true,
				"type": cover_type,
				"save": cover_save
			}
	
	return {"has_cover": false, "type": "none", "save": 0}

func toggle_grid_visibility(visible: bool) -> void:
	"""Toggle grid overlay visibility"""
	var grid = find_child("GridOverlay")
	if grid:
		grid.visible = visible
