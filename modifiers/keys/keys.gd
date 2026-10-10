# Variante "Chiavi e porte": sulla strada per l'uscita ci sono delle porte
# colorate. Si aprono solo dopo aver raccolto la chiave dello stesso colore.
#
# La parte difficile è mettere le chiavi nel posto giusto: la chiave di una
# porta deve essere raggiungibile SENZA passare da quella porta (e da quelle
# dopo), altrimenti il livello sarebbe impossibile. Per questo si usa una
# visita in ampiezza che tratta le porte chiuse come muri.
extends LevelModifier

const COLORS: Array[Color] = [Color("ff5c5c"), Color("4da6ff"), Color("ffd23f")]
const COLOR_NAMES: Array[String] = ["rossa", "blu", "gialla"]

# Ogni porta e ogni chiave è un piccolo dizionario: {cell, color_index}.
var _doors: Array[Dictionary] = []
var _keys: Array[Dictionary] = []
var _taken := 0


func level_started() -> void:
	var pairs := 1 if game.level < 6 else 2
	var path := game.maze.find_path(game.maze.start_cell, game.maze.exit_cell)

	# Possibili porte: i passaggi (caselle tra due stanze) del percorso giusto,
	# lontani dalla partenza e dall'uscita.
	var passages: Array[Vector2i] = []
	for i in range(int(path.size() * 0.3), int(path.size() * 0.85)):
		var cell := path[i]
		if cell.x % 2 != cell.y % 2 and not game.is_reserved(cell):
			passages.append(cell)
	if passages.size() < pairs:
		pairs = passages.size()

	# Divide i passaggi in `pairs` gruppi in fila e prende una porta per gruppo:
	# così le porte sono distanziate e già in ordine lungo il percorso.
	var door_cells: Array[Vector2i] = []
	for k in pairs:
		var first := int(passages.size() * k / float(pairs))
		var last := int(passages.size() * (k + 1) / float(pairs)) - 1
		door_cells.append(passages[game.rng.randi_range(first, last)])

	var previous_region := {}
	for k in door_cells.size():
		# Zona raggiungibile con chiuse questa porta e le successive.
		var closed := {}
		for door in door_cells.slice(k):
			closed[door] = true
		var region := _reachable_from_start(closed)
		var key_cell := _pick_key_cell(region, previous_region)
		if key_cell == Vector2i(-1, -1):
			break
		game.reserve_cell(door_cells[k])
		game.reserve_cell(key_cell)
		_doors.append({"cell": door_cells[k], "color_index": k})
		_keys.append({"cell": key_cell, "color_index": k})
		previous_region = region
	queue_redraw()


func player_stepped(cell: Vector2i) -> void:
	for key in _keys:
		if key.cell == cell:
			_keys.erase(key)
			_taken += 1
			# Apre (cioè toglie) la porta dello stesso colore.
			for door in _doors:
				if door.color_index == key.color_index:
					_doors.erase(door)
					break
			game.hud.show_message("Chiave %s presa!" % COLOR_NAMES[key.color_index], 1.0)
			queue_redraw()
			return


func blocks_cell(cell: Vector2i) -> bool:
	for door in _doors:
		if door.cell == cell:
			return true
	return false


func status_text() -> String:
	var total := _taken + _keys.size()
	return "Chiavi %d/%d" % [_taken, total] if total > 0 else ""


# Tutte le caselle raggiungibili dalla partenza senza passare da `closed`.
func _reachable_from_start(closed: Dictionary) -> Dictionary:
	var start := game.maze.start_cell
	var reached := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for dir in MazeGenerator.DIRECTIONS:
			var next := cell + dir
			if game.maze.is_walkable(next) and not closed.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	return reached


# Sceglie una stanza libera nella zona raggiungibile, preferendo i vicoli
# ciechi e le stanze "nuove" (non raggiungibili prima della porta
# precedente). Vector2i(-1, -1) = nessuna stanza adatta.
func _pick_key_cell(region: Dictionary, previous_region: Dictionary) -> Vector2i:
	var best: Array[Vector2i] = []
	var others: Array[Vector2i] = []
	for cell: Vector2i in region:
		if cell.x % 2 == 0 or cell.y % 2 == 0 or game.is_reserved(cell):
			continue
		if Vector2(cell - game.maze.start_cell).length() < 3.0:
			continue
		if not previous_region.has(cell) and game.maze.count_exits(cell) == 1:
			best.append(cell)
		else:
			others.append(cell)
	var pool := best if not best.is_empty() else others
	if pool.is_empty():
		return Vector2i(-1, -1)
	return pool[game.rng.randi_range(0, pool.size() - 1)]


func _draw() -> void:
	var tile := float(game.maze.tile_size)
	for door in _doors:
		var center := game.maze.cell_to_position(door.cell)
		var color: Color = COLORS[door.color_index]
		var rect := Rect2(center - Vector2(tile, tile) / 2.0, Vector2(tile, tile))
		draw_rect(rect, color.darkened(0.6))
		# Tre sbarre verticali.
		for i in 3:
			var x := rect.position.x + tile * (0.25 + 0.25 * i)
			draw_line(Vector2(x, rect.position.y + 4), Vector2(x, rect.end.y - 4), color, 4.0)
	for key in _keys:
		var center := game.maze.cell_to_position(key.cell)
		var color: Color = COLORS[key.color_index]
		# Chiave stilizzata: un anello e un'asta con un dente.
		draw_circle(center + Vector2(-tile * 0.15, 0), tile * 0.14, color, false, 4.0)
		draw_line(center + Vector2(-tile * 0.02, 0), center + Vector2(tile * 0.28, 0), color, 4.0)
		draw_line(center + Vector2(tile * 0.2, 0), center + Vector2(tile * 0.2, tile * 0.12), color, 4.0)
