# Variante "Caccia alle stelle": nel labirinto ci sono alcune stelle e
# l'uscita resta chiusa finché non le hai raccolte tutte.
#
# Le stelle non sono nodi: sono solo un elenco di caselle, disegnate da
# _draw(). Per poche cose semplici è il modo più leggero.
extends LevelModifier

@export var star_color := Color("ffe066")

var _stars: Array[Vector2i] = []
var _total := 0
var _spin := 0.0


func level_started() -> void:
	# Più stelle nei livelli alti, al massimo 8. I vicoli ciechi hanno la
	# precedenza, così bisogna esplorare.
	var count := clampi(2 + floori(game.level / 3.0), 3, 8)
	_stars = game.pick_rooms(count, 3.0, true)
	_total = _stars.size()
	game.exit_marker.locked = _total > 0
	queue_redraw()


func player_stepped(cell: Vector2i) -> void:
	if not _stars.has(cell):
		return
	_stars.erase(cell)
	queue_redraw()
	if _stars.is_empty():
		game.exit_marker.locked = false
		game.hud.show_message("Uscita aperta!", 1.0)


# Finché mancano stelle, l'uscita non fa finire il livello. Si può comunque
# camminarci sopra: a volte una stella è proprio in un vicolo dietro l'uscita!
func allows_exit() -> bool:
	return _stars.is_empty()


func status_text() -> String:
	return "Stelle %d/%d" % [_total - _stars.size(), _total]


func _process(delta: float) -> void:
	# Le stelle ruotano piano: ridisegnamo a ogni fotogramma.
	_spin += delta
	queue_redraw()


func _draw() -> void:
	var outer := game.maze.tile_size * 0.32
	for cell in _stars:
		var center := game.maze.cell_to_position(cell)
		var points := PackedVector2Array()
		# Una stella a 5 punte: 10 punti alternati tra raggio grande e piccolo.
		for i in 10:
			var radius := outer if i % 2 == 0 else outer * 0.45
			var angle := _spin + i * TAU / 10.0 - PI / 2.0
			points.append(center + Vector2.from_angle(angle) * radius)
		draw_colored_polygon(points, star_color)
