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


# Trova il percorso più breve tra due caselle libere con una visita in
# ampiezza (BFS): si esplora "a cerchi" a partire da `from`, ricordando da
# dove si è arrivati in ogni casella, poi si ripercorre all'indietro da `to`.
# Restituisce l'elenco delle caselle (estremi compresi), vuoto se `to` non è
# raggiungibile.
static func find_path(grid: Array, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var previous := {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == to:
			break
		for dir in DIRECTIONS:
			var next := cell + dir
			if not previous.has(next) and not grid[next.y][next.x]:
				previous[next] = cell
				queue.append(next)

	var path: Array[Vector2i] = []
	if not previous.has(to):
		return path
	var step := to
	while step != from:
		path.push_front(step)
		step = previous[step]
	path.push_front(from)
	return path


# Sposta un muro lasciando il labirinto "perfetto".
#
# Apre un muro chiuso tra due stanze vicine: così si forma un anello, perché
# le due stanze erano già collegate da un altro percorso. Poi chiude un
# passaggio a caso su quel vecchio percorso, e l'anello sparisce. Risultato:
# il labirinto cambia forma, ma ogni casella resta raggiungibile.
#
# `can_change` è una funzione (Callable) che riceve una casella e risponde se
# si può modificare: per esempio "solo se è lontana dal giocatore".
# Restituisce true se è riuscito a spostare un muro.
static func shift_wall(grid: Array, rng: RandomNumberGenerator, can_change: Callable, attempts := 20) -> bool:
	var height := grid.size()
	var width := (grid[0] as Array).size()
	for attempt in attempts:
		# Un muro "sottile" tra due stanze ha una coordinata pari e una dispari
		# (le stanze sono dispari-dispari, gli angoli pari-pari).
		var wall := Vector2i(rng.randi_range(1, width - 2), rng.randi_range(1, height - 2))
		if wall.x % 2 == wall.y % 2:
			continue
		if not grid[wall.y][wall.x] or not can_change.call(wall):
			continue
		var side := Vector2i.RIGHT if wall.x % 2 == 0 else Vector2i.DOWN
		var path := find_path(grid, wall - side, wall + side)

		# Passaggi del vecchio percorso che si possono chiudere.
		var passages: Array[Vector2i] = []
		for cell in path:
			if cell.x % 2 != cell.y % 2 and can_change.call(cell):
				passages.append(cell)
		if passages.is_empty():
			continue

		var closed := passages[rng.randi_range(0, passages.size() - 1)]
		_open(grid, wall)
		grid[closed.y][closed.x] = true
		return true
	return false


# Apre `count` muri a caso tra due stanze vicine. Ogni muro aperto crea un
# anello: il labirinto non è più "perfetto" e tra due punti possono esserci
# più strade. Serve per poter scappare ai nemici girandoci attorno.
static func add_loops(grid: Array, rng: RandomNumberGenerator, count: int) -> void:
	var height := grid.size()
	var width := (grid[0] as Array).size()
	var opened := 0
	for attempt in count * 20:
		if opened >= count:
			return
		var wall := Vector2i(rng.randi_range(1, width - 2), rng.randi_range(1, height - 2))
		if wall.x % 2 != wall.y % 2 and grid[wall.y][wall.x]:
			_open(grid, wall)
			opened += 1


# Converte le coordinate di una stanza in quelle della casella corrispondente.
static func _room_to_cell(room: Vector2i) -> Vector2i:
	return room * 2 + Vector2i.ONE


# Trasforma una casella in pavimento.
static func _open(grid: Array, cell: Vector2i) -> void:
	grid[cell.y][cell.x] = false
