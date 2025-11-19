extends Node3D

class_name Pyramid

var pyramid_mesh: MeshInstance3D
var pyramid_body: StaticBody3D
var pyramid_height: float

func create(grid_width: int, grid_height: int, cell_size: float, parent: Node3D):
	var static_body = StaticBody3D.new()
	parent.add_child(static_body)
	pyramid_body = static_body
	pyramid_body.collision_layer = 2
	pyramid_body.collision_mask = 1

	var mesh_instance = MeshInstance3D.new()
	static_body.add_child(mesh_instance)
	
	var top_width = grid_width * cell_size
	var top_depth = grid_height * cell_size
	
	var base_multiplier = 12.0
	var base_width = top_width * base_multiplier
	var base_depth = top_depth * base_multiplier
	
	var horizontal_distance = (base_width - top_width) / 2.0
	pyramid_height = horizontal_distance * 0.65
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Sommets de la tête plate (en haut)
	var top_positions = [
		Vector3(-0.5, 0, -0.5),
		Vector3(top_width - 0.5, 0, -0.5),
		Vector3(top_width - 0.5, 0, top_depth - 0.5),
		Vector3(-0.5, 0, top_depth - 0.5)
	]
	
	# Sommets de la base (en bas)
	var base_offset_x = (base_width - top_width) / 2.0
	var base_offset_z = (base_depth - top_depth) / 2.0
	
	var base_positions = [
		Vector3(-base_offset_x, -pyramid_height, -base_offset_z),
		Vector3(top_width + base_offset_x, -pyramid_height, -base_offset_z),
		Vector3(top_width + base_offset_x, -pyramid_height, top_depth + base_offset_z),
		Vector3(-base_offset_x, -pyramid_height, top_depth + base_offset_z)
	]
	
	# Face avant
	add_quad(surface_tool, base_positions[0], base_positions[1], top_positions[1], top_positions[0])
	
	# Face droite
	add_quad(surface_tool, base_positions[1], base_positions[2], top_positions[2], top_positions[1])
	
	# Face arrière
	add_quad(surface_tool, base_positions[2], base_positions[3], top_positions[3], top_positions[2])
	
	# Face gauche
	add_quad(surface_tool, base_positions[3], base_positions[0], top_positions[0], top_positions[3])

	# Face du bas
	add_quad(surface_tool, base_positions[3], base_positions[2], base_positions[1], base_positions[0])
	
	surface_tool.generate_normals()
	surface_tool.generate_tangents()
	
	var mesh = surface_tool.commit()
	mesh_instance.mesh = mesh
	
	# Charger et appliquer la texture
	var texture = load("res://pyramide.png")
	
	# --- CORRECTION DU MATÉRIAU (Mapping Triplanaire) ---
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	
	# Active le mode triplanar pour projeter la texture proprement sur les pentes
	material.uv1_triplanar = true
	
	# Ajuste la netteté du mélange des textures aux angles
	material.uv1_triplanar_sharpness = 5.0
	
	material.uv1_scale = Vector3(0.2, 0.2, 0.2) 
	
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh_instance.material_override = material
	
	pyramid_mesh = mesh_instance
	
	# CRÉER LA COLLISION
	create_collision(static_body, top_positions, base_positions, grid_width, grid_height, cell_size)

# Crée les CollisionShape pour la pyramide
func create_collision(body: StaticBody3D, top_pos: Array, base_pos: Array, grid_width: int, grid_height: int, cell_size: float):
	# Face du dessus (plate) - simple BoxShape
	var top_collision = CollisionShape3D.new()
	var top_shape = BoxShape3D.new()
	var top_width_val = grid_width * cell_size # Renommé pour éviter conflit de nom
	var top_depth_val = grid_height * cell_size
	top_shape.size = Vector3(top_width_val + 1.0, 0.2, top_depth_val + 1.0)
	top_collision.shape = top_shape
	top_collision.position = Vector3(top_width_val / 2.0 - 0.5, 0.1, top_depth_val / 2.0 - 0.5)
	body.add_child(top_collision)
	
	# Pour les faces inclinées, utiliser des ConvexPolygonShape
	add_face_collision(body, [base_pos[0], base_pos[1], top_pos[1], top_pos[0]]) # Avant
	add_face_collision(body, [base_pos[1], base_pos[2], top_pos[2], top_pos[1]]) # Droite
	add_face_collision(body, [base_pos[2], base_pos[3], top_pos[3], top_pos[2]]) # Arrière
	add_face_collision(body, [base_pos[3], base_pos[0], top_pos[0], top_pos[3]]) # Gauche

# Ajoute une collision pour une face de la pyramide
func add_face_collision(body: StaticBody3D, vertices: Array):
	var collision = CollisionShape3D.new()
	var shape = ConvexPolygonShape3D.new()
	
	# Convertir Array en PackedVector3Array
	var points = PackedVector3Array()
	for v in vertices:
		points.append(v)
	
	shape.points = points
	collision.shape = shape
	body.add_child(collision)

func add_quad(st: SurfaceTool, v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3):
	# Calculer la normale pour cette face
	var edge1 = v2 - v1
	var edge2 = v4 - v1
	var normal = edge1.cross(edge2).normalized()
	
	# Ajouter les 6 vertices (2 triangles). 
	# Note: Les UVs définis ici sont ignorés par le rendu Triplanar activé plus haut,
	# mais on les laisse pour la propreté du mesh.
	
	# Triangle 1: v1 -> v2 -> v3
	st.set_normal(normal)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(v2)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v3)
	
	# Triangle 2: v1 -> v3 -> v4
	st.set_normal(normal)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(v3)
	
	st.set_normal(normal)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(v4)
