# Test automatico del generatore di labirinti, eseguibile senza aprire
# l'editor e senza finestra:
#
#   godot --headless --path . -s tests/test_maze_generator.gd
#
# Uno script lanciato con -s deve estendere SceneTree (o MainLoop): è lui
# stesso il "ciclo principale" del programma, al posto della scena del gioco.
extends SceneTree

# preload carica lo script direttamente dal percorso: così il test funziona
# anche se la cache dei class_name non è ancora stata creata dall'editor.
const Generator := preload("res://scripts/maze_generator.gd")

var _failures := 0


# _init viene eseguita appena lo SceneTree viene creato.
func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345  # Seme fisso: i labirinti sono sempre gli stessi.

	for size: Vector2i in [Vector2i(1, 1), Vector2i(2, 3), Vector2i(7, 4), Vector2i(31, 17)]:
		for attempt in 5:
			_check_maze(Generator.generate(size.x, size.y, rng), size)

	if _failures == 0:
		print("OK: tutti i labirinti sono validi.")
	quit(1 if _failures > 0 else 0)


func _check_maze(grid: Array, rooms: Vector2i) -> void:
	var width := rooms.x * 2 + 1
	var height := rooms.y * 2 + 1
	_expect(grid.size() == height, "altezza della griglia")
	_expect((grid[0] as Array).size() == width, "larghezza della griglia")

	# Il bordo esterno deve essere tutto muro.
	for x in width:
		_expect(grid[0][x] and grid[height - 1][x], "bordo orizzontale chiuso")
	for y in height:
		_expect(grid[y][0] and grid[y][width - 1], "bordo verticale chiuso")

	# Visita in ampiezza (BFS) dal punto di partenza: conta le caselle libere
	# raggiungibili.
	var start := Vector2i(1, 1)
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in Generator.DIRECTIONS:
			var next := cell + dir
			if not grid[next.y][next.x] and not reached.has(next):
				reached[next] = true
				queue.append(next)

	var floor_cells := 0
	for row: Array in grid:
		floor_cells += row.count(false)

	# Tutte le caselle libere devono essere raggiungibili (uscita compresa)...
	_expect(reached.size() == floor_cells, "tutto il labirinto è raggiungibile")
	_expect(reached.has(Vector2i(width - 2, height - 2)), "l'uscita è raggiungibile")
	# ...e in un labirinto perfetto con N stanze ci sono N stanze + (N - 1)
	# passaggi: nessun anello, un solo percorso tra due punti qualsiasi.
	var room_count := rooms.x * rooms.y
	_expect(floor_cells == room_count * 2 - 1, "labirinto perfetto (senza anelli)")


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		printerr("FALLITO: ", description)
