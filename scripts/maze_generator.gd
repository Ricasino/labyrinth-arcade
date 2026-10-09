# Generatore di labirinti "puro": contiene solo l'algoritmo, non disegna nulla
# e non sa niente di nodi o scene. Tenere la logica separata dalla grafica
# rende il codice più facile da capire e da testare (vedi tests/).
#
# `class_name` registra la classe con un nome globale: da qualunque altro
# script si può scrivere `MazeGenerator.generate(...)` senza fare preload.
# Estende RefCounted perché non è un nodo: è un semplice oggetto di codice.
class_name MazeGenerator
extends RefCounted

# Le quattro direzioni in cui ci si può spostare sulla griglia.
const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT,
]


# Genera un labirinto "perfetto" (esiste esattamente un percorso tra due punti
# qualsiasi) con l'algoritmo "recursive backtracker", cioè una visita in
# profondità (DFS) con scelte casuali.
#
# Il labirinto logico è fatto di `cols` x `rows` STANZE. Il risultato però è
# una griglia di CASELLE grande (2*cols+1) x (2*rows+1), dove ogni casella è
# muro (true) o pavimento (false):
#
#   # # # # # # #      La stanza (sx, sy) sta nella casella (2*sx+1, 2*sy+1).
#   # S . . # . #      Tra due stanze vicine c'è una casella che può essere
#   # # # . # . #      muro oppure passaggio. Il bordo esterno è sempre muro.
#   # . . . . . #
#   # # # # # # #
#
# Restituisce un Array di righe: grid[y][x] == true significa "muro".
static func generate(cols: int, rows: int, rng: RandomNumberGenerator) -> Array:
	var width := cols * 2 + 1
	var height := rows * 2 + 1

	# 1) Si parte da una griglia piena di muri.
	var grid: Array = []
	for y in height:
		var row: Array[bool] = []
		row.resize(width)
		row.fill(true)
		grid.append(row)

	# 2) Visita in profondità usando uno stack esplicito (invece della
	#    ricorsione, che con labirinti grandi potrebbe esaurire lo stack).
	var visited := {}  # Dizionario usato come "insieme" di stanze visitate.
	var start_room := Vector2i.ZERO
	var stack: Array[Vector2i] = [start_room]
	visited[start_room] = true
	_open(grid, _room_to_cell(start_room))

	while not stack.is_empty():
		var current: Vector2i = stack.back()

		# Stanze vicine non ancora visitate.
		var candidates: Array[Vector2i] = []
		for dir in DIRECTIONS:
			var next := current + dir
			var inside := next.x >= 0 and next.x < cols and next.y >= 0 and next.y < rows
			if inside and not visited.has(next):
				candidates.append(next)

		if candidates.is_empty():
			# Vicolo cieco: si torna indietro di un passo ("backtracking").
			stack.pop_back()
			continue

		# Sceglie un vicino a caso, abbatte il muro in mezzo e ci entra.
		var chosen := candidates[rng.randi_range(0, candidates.size() - 1)]
		var wall_between := _room_to_cell(current) + (chosen - current)
		_open(grid, wall_between)
		_open(grid, _room_to_cell(chosen))
		visited[chosen] = true
		stack.push_back(chosen)

	return grid


# Converte le coordinate di una stanza in quelle della casella corrispondente.
static func _room_to_cell(room: Vector2i) -> Vector2i:
	return room * 2 + Vector2i.ONE


# Trasforma una casella in pavimento.
static func _open(grid: Array, cell: Vector2i) -> void:
	grid[cell.y][cell.x] = false
