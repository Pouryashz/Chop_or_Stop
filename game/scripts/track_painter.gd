@tool
extends Node3D

# Peint une voie dans une GridMap à partir d'une recette, avec les bons décalages,
# et dessine en même temps le chemin (Path3D) que le train doit suivre.
#   S = droite (1 unité)     L / R = un morceau de virage de 15° (6 de suite = 90°)
#   J / K = aiguillage gauche / droite (suit la branche, continuer avec L ou R)
#   B = butoir (le chemin s'arrête devant)     les espaces sont ignorés
# Exemple : "SSS LLLLLL SS J LLLL S B"

@export var grid: GridMap # La GridMap à peindre
@export var path: Path3D # Le chemin du train (ex. le nœud Track)
@export var start_cell := Vector3i.ZERO # Cellule de la première pièce
@export_range(0, 3) var start_turns := 0 # Direction de départ : quarts de tour vers la gauche
@export var recipe := "SSS LLLLLL SS B" # Recette de la voie
@export var rail_height := 0.077 # Hauteur du dessus des rails dans les pièces
@export var buffer_face := 0.30 # Distance du début du butoir à ses tampons
@export_tool_button("Construire la voie") var build_button = build
@export_tool_button("Effacer la voie construite") var erase_button = erase_built
@export_storage var painted: Array[Vector3i] = [] # Cellules peintes par ce script

const RADIUS := 4.0 # Rayon des virages
const STEP := PI / 12.0 # 15°
const SAMPLES := 8 # Points du chemin par morceau de virage
# Décalage (en unités) de chaque morceau de virage gauche par rapport au début du virage
const LEFT_ANCHORS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, -1), Vector2i(3, -1), Vector2i(3, -2), Vector2i(4, -3)]

var _points: Array[Vector2] = [] # Points du chemin, en unités


func build() -> void:
	if grid == null or grid.mesh_library == null:
		push_error("Assignez une GridMap avec une MeshLibrary.")
		return
	erase_built()
	_points.clear()
	var pos := Vector2i.ZERO # position actuelle en unités
	var turns := start_turns # direction actuelle
	var k := 0 # morceau de virage en cours (0 = pas de virage)
	var side := 0 # -1 = gauche, +1 = droite
	var origin := Vector2i.ZERO # début du virage en cours
	_add_point(Vector2(pos))

	for ch in recipe.to_upper():
		match ch:
			"S":
				if k != 0:
					push_error("Terminez le virage (6 morceaux) avant une droite.")
					return
				_place("Straight", pos, turns)
				pos += _rot(Vector2i(1, 0), turns)
				_add_point(Vector2(pos))
			"L", "R":
				var sd := -1 if ch == "L" else 1
				if k == 0:
					side = sd
					origin = pos
				elif sd != side:
					push_error("Impossible de changer de sens au milieu d'un virage.")
					return
				var a: Vector2i = LEFT_ANCHORS[k]
				var off := _rot(Vector2i(a.x, a.y * -side), turns)
				var label := "Left" if side == -1 else "Right"
				var item_name := label + ("0-15" if k == 0 else "%d-%d" % [15 * k, 15 * k + 15])
				_place(item_name, origin + off, turns)
				_add_arc(origin, side, turns, k)
				k += 1
				if k == 6:
					pos = origin + _rot(Vector2i(4, 4 * side), turns)
					turns = (turns + (1 if side == -1 else 3)) % 4
					k = 0
			"J", "K":
				if k != 0:
					push_error("Un aiguillage doit être posé sur une partie droite.")
					return
				side = -1 if ch == "J" else 1
				_place("Junction_Left30" if side == -1 else "Junction_Right30", pos, turns)
				origin = pos
				_add_arc(origin, side, turns, 0)
				_add_arc(origin, side, turns, 1)
				k = 2 # la branche de l'aiguillage couvre déjà 0-30°
			"B":
				_place("Buffer", pos, turns)
				_add_point(Vector2(pos) + _rotf(Vector2(buffer_face, 0.0), turns))
				break # rien après un butoir
			_:
				pass # espaces et autres caractères ignorés
	_write_path()


func erase_built() -> void:
	if grid != null:
		for cell in painted:
			grid.set_cell_item(cell, GridMap.INVALID_CELL_ITEM)
	painted.clear()


func _place(item_name: String, unit_pos: Vector2i, turns: int) -> void:
	var id := grid.mesh_library.find_item_by_name(item_name)
	if id == -1:
		push_error("Pièce introuvable dans la MeshLibrary : " + item_name)
		return
	var cell := start_cell + Vector3i(unit_pos.x * _cells_per_unit(), 0, unit_pos.y * _cells_per_unit())
	var orientation := grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, turns * PI / 2.0))
	grid.set_cell_item(cell, id, orientation)
	painted.append(cell)


# Ajoute les points d'un morceau de virage de 15° (k = 0..5) au chemin
func _add_arc(origin: Vector2i, side: int, turns: int, k: int) -> void:
	for i in range(1, SAMPLES + 1):
		var a := STEP * (k + float(i) / SAMPLES)
		var p := Vector2(RADIUS * sin(a), side * RADIUS * (1.0 - cos(a)))
		_add_point(Vector2(origin) + _rotf(p, turns))


func _add_point(p: Vector2) -> void:
	if _points.is_empty() or _points[-1].distance_to(p) > 0.001:
		_points.append(p)


# Convertit les points (unités de la GridMap) en courbe dans le Path3D
func _write_path() -> void:
	if path == null:
		return
	var base := grid.map_to_local(start_cell)
	var curve := Curve3D.new()
	for p in _points:
		var local := base + Vector3(p.x, rail_height, p.y) # les pièces sont posées au centre de la cellule
		var world := grid.global_transform * local
		curve.add_point(path.global_transform.affine_inverse() * world)
	path.curve = curve


func _cells_per_unit() -> int:
	return int(round(1.0 / grid.cell_size.x))


# Rotation d'un décalage entier (x, z) de quarts de tour vers la gauche
func _rot(v: Vector2i, turns: int) -> Vector2i:
	match turns % 4:
		1:
			return Vector2i(v.y, -v.x)
		2:
			return Vector2i(-v.x, -v.y)
		3:
			return Vector2i(-v.y, v.x)
	return v


# Même rotation pour des valeurs décimales
func _rotf(v: Vector2, turns: int) -> Vector2:
	match turns % 4:
		1:
			return Vector2(v.y, -v.x)
		2:
			return Vector2(-v.x, -v.y)
		3:
			return Vector2(-v.y, v.x)
	return v
