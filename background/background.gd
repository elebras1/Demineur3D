extends Node3D

@export_group("Terrain Settings")
@export var terrain_size: Vector2 = Vector2(100, 100) # Agrandir pour l'horizon
@export var height_scale: float = 15.0
@export var subdivisions: int = 100 # Plus de détails

@export_group("Sand Colors")
# Couleur des crêtes (Sable sec, exposé au soleil) - Doré clair
@export var peak_color: Color = Color(0.96, 0.8, 0.4)
# Couleur des creux (Sable tassé, ombre) - Orange brûlé/Rougeâtre
@export var valley_color: Color = Color(0.75, 0.45, 0.2)

var noise_base: FastNoiseLite
var noise_detail: FastNoiseLite

func _ready():
	generate_terrain()

func generate_terrain():
	# 1. Bruit pour les GROSSES DUNES (Forme générale)
	noise_base = FastNoiseLite.new()
	noise_base.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_base.seed = randi()
	noise_base.frequency = 0.015 # Fréquence basse = dunes larges
	noise_base.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise_base.fractal_octaves = 3

	# 2. Bruit pour le GRAIN/DÉTAIL (Pour que ça ne fasse pas lisse)
	noise_detail = FastNoiseLite.new()
	noise_detail.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_detail.seed = randi()
	noise_detail.frequency = 0.1 # Fréquence haute = petites bosses
	
	var mesh_instance = $TerrainMesh
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var step_x = terrain_size.x / subdivisions
	var step_z = terrain_size.y / subdivisions
	
	for z in range(subdivisions + 1):
		for x in range(subdivisions + 1):
			var pos_x = (x * step_x) - terrain_size.x / 2
			var pos_z = (z * step_z) - terrain_size.y / 2
			
			# --- HAUTEUR COMPLEXE ---
			# On combine la dune principale et un peu de détail
			var h_base = noise_base.get_noise_2d(pos_x, pos_z)
			# Astuce : abs(h_base) crée des crêtes plus nettes par endroits
			var final_height = (h_base * height_scale) + (noise_detail.get_noise_2d(pos_x, pos_z) * 1.5)
			
			var vertex = Vector3(pos_x, final_height, pos_z)
			
			# --- COULEUR DYNAMIQUE (Vertex Color) ---
			# On calcule un facteur entre 0 et 1 selon la hauteur pour la couleur
			# On normalise grossièrement la hauteur entre -height_scale et +height_scale
			var height_factor = clamp((final_height + (height_scale * 0.5)) / height_scale, 0.0, 1.0)
			# Lerp entre couleur foncée (bas) et claire (haut)
			var final_color = valley_color.lerp(peak_color, height_factor)
			
			var uv = Vector2(float(x) / subdivisions, float(z) / subdivisions) * 4.0
			
			surface_tool.set_color(final_color) # Applique la couleur au sommet
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(vertex)
	
	# Création des triangles
	for z in range(subdivisions):
		for x in range(subdivisions):
			var i = z * (subdivisions + 1) + x
			surface_tool.add_index(i)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + subdivisions + 1)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + subdivisions + 2)
			surface_tool.add_index(i + subdivisions + 1)
	
	surface_tool.generate_normals()
	# generate_tangents est CRUCIAL pour que la lumière de tes soleils réagisse bien
	surface_tool.generate_tangents()
	
	var new_mesh = surface_tool.commit()
	
	# --- MATÉRIAU ---
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	
	new_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = new_mesh
	
	create_collision(new_mesh)

func create_collision(mesh_geo):
	# Nettoyage propre
	for child in get_children():
		if child is StaticBody3D:
			child.queue_free()
			
	var static_body = StaticBody3D.new()
	add_child(static_body)
	var collision_shape = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh_geo.get_faces())
	collision_shape.shape = shape
	static_body.add_child(collision_shape)

# Fonction utilitaire pour placer tes objets au bon endroit
func get_terrain_height(x: float, z: float) -> float:
	if noise_base == null: return 0.0
	var h_base = noise_base.get_noise_2d(x, z)
	# On doit répliquer exactement le calcul de generate_terrain
	var detail = noise_detail.get_noise_2d(x, z) * 1.5
	return (h_base * height_scale) + detail
