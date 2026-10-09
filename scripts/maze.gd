# Nodo che contiene un labirinto e lo disegna a schermo.
#
# Estende Node2D: un nodo 2D con posizione, rotazione e scala. Invece di usare
# sprite o immagini, disegna tutto da codice con la funzione virtuale _draw().
# Godot chiama _draw() una volta e memorizza il risultato: per ridisegnare
# bisogna chiedere esplicitamente queue_redraw() (lo facciamo dopo ogni
# generazione di un nuovo labirinto).
class_name Maze
extends Node2D

# Le variabili con @export compaiono nell'Inspector dell'editor: puoi
# cambiarne il valore cliccando sul nodo Maze in scenes/main.tscn, senza
# toccare il codice.
@export var tile_size := 48
@export var floor_color := Color("0b0b1a")
@export var wall_color := Color("1b1f4b")
@export var wall_edge_color := Color("4d7cff")
@export var wall_edge_width := 3.0

# Casella di partenza e casella d'uscita (coordinate di griglia, non pixel).
var start_cell := Vector2i.ZERO
var exit_cell := Vector2i.ZERO

# Griglia del labirinto: _grid[y][x] == true significa "muro".
var _grid: Array = []
var _width := 0
var _height := 0
# Generatore di numeri casuali dedicato: impostando rng.seed si può ottenere
# sempre lo stesso labirinto (utile per fare prove).
var _rng := RandomNumberGenerator.new()


# Crea un nuovo labirinto di `cols` x `rows` stanze e lo ridisegna.
func generate(cols: int, rows: int) -> void:
	_rng.randomize()
	_grid = MazeGenerator.generate(cols, rows, _rng)
	_height = _grid.size()
	_width = (_grid[0] as Array).size()

	# Partenza nell'angolo in alto a sinistra, uscita in quello opposto.
	start_cell = Vector2i(1, 1)
	exit_cell = Vector2i(_width - 2, _height - 2)

	queue_redraw()


# true se nella casella si può camminare (dentro la griglia e non muro).
func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= _width or cell.y >= _height:
		return false
	return not _grid[cell.y][cell.x]


# Converte una casella nella posizione (in pixel) del suo centro, relativa a
# questo nodo. Il labirinto sta in (0, 0), quindi coincide con le coordinate
# del mondo di gioco.
func cell_to_position(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * tile_size


# Dimensione totale del labirinto in pixel (serve per la telecamera).
func get_pixel_size() -> Vector2:
	return Vector2(_width, _height) * tile_size


func _draw() -> void:
	if _grid.is_empty():
		return

	# Sfondo del pavimento, un unico rettangolo grande.
	draw_rect(Rect2(Vector2.ZERO, get_pixel_size()), floor_color)

	var size := Vector2(tile_size, tile_size)
	for y in _height:
		for x in _width:
			if not _grid[y][x]:
				continue
			var top_left := Vector2(x, y) * tile_size
			draw_rect(Rect2(top_left, size), wall_color)
			# Effetto "neon": una linea luminosa solo sui lati del muro che
			# confinano con il pavimento.
			var cell := Vector2i(x, y)
			if is_walkable(cell + Vector2i.UP):
				draw_line(top_left, top_left + Vector2(size.x, 0), wall_edge_color, wall_edge_width)
			if is_walkable(cell + Vector2i.DOWN):
				draw_line(top_left + Vector2(0, size.y), top_left + size, wall_edge_color, wall_edge_width)
			if is_walkable(cell + Vector2i.LEFT):
				draw_line(top_left, top_left + Vector2(0, size.y), wall_edge_color, wall_edge_width)
			if is_walkable(cell + Vector2i.RIGHT):
				draw_line(top_left + Vector2(size.x, 0), top_left + size, wall_edge_color, wall_edge_width)
