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
# Quanto sono visibili i muri: 1 = del tutto, 0 = per niente (li nasconde la
# variante "A memoria"). Il setter ridisegna il labirinto a ogni modifica, così
# un Tween può animare questa proprietà.
var walls_opacity := 1.0:
	set(value):
		walls_opacity = value
		queue_redraw()

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

	walls_opacity = 1.0  # Assegnarla chiama anche queue_redraw().


# true se nella casella si può camminare (dentro la griglia e non muro).
func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= _width or cell.y >= _height:
		return false
	return not _grid[cell.y][cell.x]


# Percorso più breve tra due caselle libere (vedi MazeGenerator.find_path).
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return MazeGenerator.find_path(_grid, from, to)


# Sposta un muro tra quelli permessi da `can_change`, senza mai lasciare
# caselle irraggiungibili (vedi MazeGenerator.shift_wall).
func shift_wall(rng: RandomNumberGenerator, can_change: Callable) -> bool:
	var changed := MazeGenerator.shift_wall(_grid, rng, can_change)
	if changed:
		queue_redraw()
	return changed


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

	# Sfondo del pavimento: un unico rettangolo che va molto oltre i bordi del
	# labirinto, così copre anche lo spazio attorno. Ha lo stesso colore dello
	# sfondo della finestra, ma a differenza di quello viene scurito dalle
	# varianti che spengono la luce (CanvasModulate).
	draw_rect(Rect2(Vector2.ZERO, get_pixel_size()).grow(10000), floor_color)

	# Con walls_opacity a 0 i muri prendono il colore del pavimento e le linee
	# diventano trasparenti: il labirinto "sparisce".
	var fill_color := floor_color.lerp(wall_color, walls_opacity)
	var edge_color := wall_edge_color
	edge_color.a *= walls_opacity

	var size := Vector2(tile_size, tile_size)
	for y in _height:
		for x in _width:
			if not _grid[y][x]:
				continue
			var top_left := Vector2(x, y) * tile_size
			draw_rect(Rect2(top_left, size), fill_color)
			# Effetto "neon": una linea luminosa solo sui lati del muro che
			# confinano con il pavimento.
			var cell := Vector2i(x, y)
			if is_walkable(cell + Vector2i.UP):
				draw_line(top_left, top_left + Vector2(size.x, 0), edge_color, wall_edge_width)
			if is_walkable(cell + Vector2i.DOWN):
				draw_line(top_left + Vector2(0, size.y), top_left + size, edge_color, wall_edge_width)
			if is_walkable(cell + Vector2i.LEFT):
				draw_line(top_left, top_left + Vector2(0, size.y), edge_color, wall_edge_width)
			if is_walkable(cell + Vector2i.RIGHT):
				draw_line(top_left + Vector2(size.x, 0), top_left + size, edge_color, wall_edge_width)
