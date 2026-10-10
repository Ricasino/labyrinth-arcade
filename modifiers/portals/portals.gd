# Variante "Portali": coppie di portali dello stesso colore. Entrando in uno
# si esce dall'altro. Possono essere scorciatoie... o trappole.
extends LevelModifier

const COLORS: Array[Color] = [Color("c77dff"), Color("ff9f1c"), Color("2ec4b6")]

# Ogni coppia è un array di due caselle; l'indice nell'array è il colore.
var _pairs: Array = []
var _spin := 0.0


func level_started() -> void:
	var pair_count := 2 if game.level < 7 else 3
	# Nei vicoli ciechi i portali non bloccano mai il passaggio verso altre zone.
	var rooms := game.pick_rooms(pair_count * 2, 3.0, true)
	for i in range(0, rooms.size() - 1, 2):
		_pairs.append([rooms[i], rooms[i + 1]])


func player_stepped(cell: Vector2i) -> void:
	for pair: Array in _pairs:
		var index := pair.find(cell)
		if index != -1:
			# Il giocatore ricompare sull'altro portale. place_at() non emette
			# reached_cell, quindi non rimbalza subito indietro.
			game.player.place_at(pair[1 - index])
			return


func _process(delta: float) -> void:
	_spin += delta * 3.0
	queue_redraw()


func _draw() -> void:
	var radius := game.maze.tile_size * 0.34
	for i in _pairs.size():
		var color := COLORS[i % COLORS.size()]
		for cell: Vector2i in _pairs[i]:
			var center := game.maze.cell_to_position(cell)
			draw_circle(center, radius, color.darkened(0.7))
			# Un arco che gira dà l'idea di un vortice.
			draw_arc(center, radius, _spin, _spin + PI * 1.4, 16, color, 4.0)
			draw_arc(center, radius * 0.55, -_spin, -_spin + PI * 1.2, 12, color.lightened(0.3), 3.0)
