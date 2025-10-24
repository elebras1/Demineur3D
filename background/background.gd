extends Node3D
@export var terrain_size: Vector2 = Vector2(50, 50)
@export var height_scale: float = 20.0
var noise: FastNoiseLite

func _ready():
	generate_terrain()
	
func generate_terrain():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 0.05
	noise.fractal_octaves = 4
	
	var mesh_instance = $TerrainMesh
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var subdivisions_x = 50
	var subdivisions_z = 50
	var step_x = terrain_size.x / subdivisions_x
	var step_z = terrain_size.y / subdivisions_z
	
	for z in range(subdivisions_z + 1):
		for x in range(subdivisions_x + 1):
			var pos_x = (x * step_x) - terrain_size.x / 2
			var pos_z = (z * step_z) - terrain_size.y / 2
			var height = noise.get_noise_2d(pos_x, pos_z) * height_scale
			var vertex = Vector3(pos_x, height, pos_z)
			var normal = calculate_normal(pos_x, pos_z)
			var uv = Vector2(float(x) / subdivisions_x, float(z) / subdivisions_z)
			
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(vertex)
	
	# MODIFIÉ ICI : ordre des indices inversé
	for z in range(subdivisions_z):
		for x in range(subdivisions_x):
			var i = z * (subdivisions_x + 1) + x
			surface_tool.add_index(i)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + subdivisions_x + 1)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + subdivisions_x + 2)
			surface_tool.add_index(i + subdivisions_x + 1)
	
	surface_tool.generate_normals()
	var new_mesh = surface_tool.commit()
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.3, 1)
	mat.roughness = 0.9
	# RETIRÉ : mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	new_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = new_mesh
	
	# AJOUTER LA COLLISION
	var static_body = StaticBody3D.new()
	add_child(static_body)
	
	var collision_shape = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(new_mesh.get_faces())
	collision_shape.shape = shape
	static_body.add_child(collision_shape)
func calculate_normal(x: float, z: float) -> Vector3:
	var offset = 0.1
	var h_left = noise.get_noise_2d(x - offset, z) * height_scale
	var h_right = noise.get_noise_2d(x + offset, z) * height_scale
	var h_down = noise.get_noise_2d(x, z - offset) * height_scale
	var h_up = noise.get_noise_2d(x, z + offset) * height_scale
	var normal = Vector3(h_left - h_right, 2.0 * offset, h_down - h_up)
	return normal.normalized()
func get_terrain_height(x: float, z: float) -> float:
	if noise == null:
		return 0.0
	return noise.get_noise_2d(x, z) * height_scale
