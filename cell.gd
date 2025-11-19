extends Node3D
class_name Cell

# IMPORTANT: Ne PAS utiliser @export pour les données de jeu
var grid_pos: Vector2i
var value: int = 0
var board: Array = []
var generator: MineSweeper = null
var state: int = 0  # 0 = cachée, 1 = révélée, 2 = flag
var parent_grid: Node = null
var is_dark: bool = false
var flag_mesh = null

@onready var mesh_instance = $MeshInstance3D
@onready var label = $MeshInstance3D/Label3D

var flag_scene = preload("res://flag.tscn") # Renommé pour éviter la confusion avec la variable 'flag'

# Couleurs standards du Démineur pour les chiffres 1 à 8
const NUMBER_COLORS = {
	1: Color(0.0, 0.0, 1.0),      # Bleu
	2: Color(0.0, 0.5, 0.0),      # Vert
	3: Color(1.0, 0.0, 0.0),      # Rouge
	4: Color(0.0, 0.0, 0.5),      # Bleu foncé
	5: Color(0.5, 0.0, 0.0),      # Marron/Rouge foncé
	6: Color(0.0, 0.5, 0.5),      # Cyan
	7: Color(0.0, 0.0, 0.0),      # Noir
	8: Color(0.5, 0.5, 0.5)       # Gris
}

func _ready():
	# Initialisation propre
	if label:
		label.text = ""
		# Optionnel : Désactiver le filtre de texture pour un look pixel-art net si besoin
		# label.pixel_size = 0.005 
	
	# Créer un matériau unique pour cette cellule pour pouvoir changer sa couleur
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		# Optionnel : Réduire la brillance pour un look plus "carton/terre"
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mesh_instance.material_override = mat
	
	# Attendre un frame pour s'assurer que les variables is_dark/grid_pos sont set
	await get_tree().process_frame
	update_color()

func update_color():
	if not mesh_instance or not mesh_instance.material_override:
		return
	
	var mat = mesh_instance.material_override as StandardMaterial3D
	
	match state:
		0:  # CACHÉE (Case NON cliquée) → couleur sombre
			if is_dark:
				mat.albedo_color = Color(0.55, 0.50, 0.40) # Cachée sombre
			else:
				mat.albedo_color = Color(0.65, 0.60, 0.50) # Cachée claire

			if label: label.text = ""
			_remove_flag()


		1:  # RÉVÉLÉE → couleur claire (par défaut maintenant)
			if is_dark:
				mat.albedo_color = Color(0.70, 0.65, 0.55) # Cachée sombre
			else:
				mat.albedo_color = Color(0.75, 0.70, 0.60) # Cachée claire

			_remove_flag()

			if label:
				if value == -1:
					label.text = "💣"
					label.modulate = Color(0, 0, 0)
					mat.albedo_color = Color(1, 0.3, 0.3)
				elif value > 0:
					label.text = str(value)
					label.modulate = NUMBER_COLORS.get(value, Color.BLACK)
				else:
					label.text = ""


		2:  # FLAG
			if is_dark:
				mat.albedo_color = Color(0.78, 0.70, 0.65)
			else:
				mat.albedo_color = Color(0.83, 0.75, 0.70)

			if label: label.text = ""

			if not flag_mesh and flag_scene:
				flag_mesh = flag_scene.instantiate()
				add_child(flag_mesh)



# Helper pour nettoyer le code
func _remove_flag():
	if flag_mesh:
		flag_mesh.queue_free()
		flag_mesh = null

func reveal():
	if not parent_grid or parent_grid.get_is_finish():
		return
	if state != 0: # On ne révèle pas si c'est déjà révélé ou s'il y a un drapeau
		return
	
	# Premier clic (génération)
	if not board or board.size() == 0:
		parent_grid.on_cell_clicked(self)
		return
	
	if not generator:
		print("ERREUR: generator non initialisé")
		return
	
	# Flood fill
	var changed_cells = generator.flood_fill_reveal(board, grid_pos.y, grid_pos.x, board.size(), board[0].size())
	parent_grid.update_specific_cells(changed_cells)
	
	# Gestion Explosion
	if board[grid_pos.y][grid_pos.x]["mine"]:
		var explosion = preload("res://explosion.tscn")
		if explosion:
			var explosion_mesh = explosion.instantiate()
			add_child(explosion_mesh)
	
	# Vérification fin de partie
	var game_status = is_finished()
	if game_status["finished"]:
		parent_grid.set_is_finish(game_status)
		# Le délai de restart est géré ici
		parent_grid.restart_after_delay(5 if game_status["won"] else 3)

func toggle_flag():
	if not parent_grid or parent_grid.get_is_finish():
		return
	
	# Empêche le flag avant la génération du plateau
	if not board or board.size() == 0:
		parent_grid.on_cell_right_clicked(self)
		return
	
	if state == 0: # De caché vers Flag
		state = 2
		board[grid_pos.y][grid_pos.x]["flag"] = true
		update_color() # Appel direct à update_color qui gère l'instanciation
		
	elif state == 2: # De Flag vers caché
		state = 0
		board[grid_pos.y][grid_pos.x]["flag"] = false
		update_color() # Appel direct à update_color qui gère la suppression

func is_finished() -> Dictionary:
	if not board or board.size() == 0:
		return {"finished": false, "won": false}
	
	var rows = board.size()
	var cols = board[0].size()
	var mine_revealed := false
	var all_safe_revealed := true
	
	for r in range(rows):
		for c in range(cols):
			var cell_data = board[r][c]
			
			if cell_data["mine"] and cell_data["revealed"]:
				mine_revealed = true
			
			if not cell_data["mine"] and not cell_data["revealed"]:
				all_safe_revealed = false
	
	if mine_revealed:
		return {"finished": true, "won": false}
	
	if all_safe_revealed:
		return {"finished": true, "won": true}
	
	return {"finished": false, "won": false}
