# Variante "Ronda": alcune guardie fanno avanti e indietro in un corridoio
# laterale e ogni tanto attraversano la strada per l'uscita. Se ti toccano
# torni alla partenza (e perdi qualche secondo): passa quando sono lontane!
#
# Perché il livello sia sempre risolvibile, ogni ronda va da un incrocio sulla
# strada principale fino in fondo a un vicolo cieco: così non c'è mai niente
# di importante "dietro" una guardia, e il corridoio si può evitare.
extends LevelModifier

@export var guard_speed := 3.0


func level_started() -> void:
	var rooms := game.maze.get_rooms()
	game.maze.add_loops(game.rng, floori(rooms.size() / 8.0))

	var guard_count := clampi(1 + floori(game.level / 4.0), 1, 4)
	var path := game.maze.find_path(game.maze.start_cell, game.maze.exit_cell)
	var on_path := {}
	for cell in path:
		on_path[cell] = true

	# Incroci sulla strada principale, lontani dalla partenza, in ordine casuale.
	var junctions: Array[Vector2i] = []
	for i in range(int(path.size() * 0.25), path.size() - 2):
		var cell := path[i]
		if cell.x % 2 == 1 and cell.y % 2 == 1 and game.maze.count_exits(cell) >= 3:
			junctions.append(cell)
	game.shuffle(junctions)

	for junction in junctions:
		if get_child_count() >= guard_count:
			break
		var route := _make_route(junction, on_path)
		if route.size() >= 5:
			for cell in route.slice(1):
				game.reserve_cell(cell)
			_add_guard(route)


# Dal `junction` entra in una strada laterale e la segue fino in fondo a un
# vicolo cieco. Restituisce [] se non trova una strada adatta.
func _make_route(junction: Vector2i, on_path: Dictionary) -> Array[Vector2i]:
	for dir in MazeGenerator.DIRECTIONS:
		var passage := junction + dir
		if on_path.has(passage) or not game.maze.is_walkable(passage) or game.is_reserved(passage):
			continue
		var route: Array[Vector2i] = [junction, passage]
		var current := junction + dir * 2
		var previous := junction
		while route.size() < 18:
			if game.is_reserved(current) or on_path.has(current):
				break
			route.append(current)
			# Le stanze successive raggiungibili (senza tornare indietro).
			var options: Array[Vector2i] = []
			for next_dir in MazeGenerator.DIRECTIONS:
				var room := current + next_dir * 2
				if room != previous and game.maze.is_walkable(current + next_dir) and game.maze.is_walkable(room):
					options.append(next_dir)
			if options.is_empty():
				# Vicolo cieco: ronda perfetta.
				if game.maze.count_exits(current) == 1:
					return route
				break
			var chosen := options[game.rng.randi_range(0, options.size() - 1)]
			route.append(current + chosen)
			previous = current
			current += chosen * 2
	return []


func _add_guard(route: Array[Vector2i]) -> void:
	var guard := Enemy.new()
	guard.game = game
	guard.speed = guard_speed
	add_child(guard)
	# Lo stato della ronda (a che punto è, in che verso va) sta in un
	# dizionario: la funzione qui sotto lo può modificare a ogni passo.
	var state := {"index": 0, "step": 1}
	guard.next_cell = func(_from: Vector2i) -> Vector2i:
		var next_index: int = state.index + state.step
		if next_index < 0 or next_index >= route.size():
			state.step = -state.step
			next_index = state.index + state.step
		state.index = next_index
		return route[next_index]
	state.index = route.size() - 1
	state.step = -1
	guard.place_at(route[route.size() - 1])
