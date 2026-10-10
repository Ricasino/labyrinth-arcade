# Variante "Il tuo fantasma": dopo qualche secondo un fantasma comincia a
# rifare esattamente la tua strada. Se torni indietro o ti fermi troppo, ti
# raggiunge!
#
# Funziona come una registrazione: a ogni fotogramma salviamo il momento e la
# posizione del giocatore; il fantasma "riproduce" la registrazione con
# qualche secondo di ritardo.
extends LevelModifier

# Quanti secondi dietro di te cammina il fantasma.
@export var delay := 3.0
@export var ghost_color := Color(0.85, 0.9, 1.0, 0.55)

var _clock := 0.0
var _times: PackedFloat32Array = []
var _positions: PackedVector2Array = []
var _ghost_position := Vector2.ZERO
var _ghost_visible := false


func level_started() -> void:
	if game.level >= 8:
		delay = 2.5


func _process(delta: float) -> void:
	# Si comincia a registrare solo quando il giocatore si muove la prima volta.
	var at_start := game.player.position == game.maze.cell_to_position(game.maze.start_cell)
	if _times.is_empty() and at_start:
		return
	_clock += delta
	_times.append(_clock)
	_positions.append(game.player.position)

	# Cerca la posizione registrata `delay` secondi fa e butta via quelle più
	# vecchie, che non servono più.
	var replay_time := _clock - delay
	_ghost_visible = _times[0] <= replay_time
	while _times.size() > 1 and _times[1] <= replay_time:
		_times.remove_at(0)
		_positions.remove_at(0)
	if _ghost_visible:
		_ghost_position = _positions[0]
		if _ghost_position.distance_to(game.player.position) < game.maze.tile_size * 0.5:
			game.catch_player()
	queue_redraw()


func player_caught() -> void:
	# Ricomincia da capo: il fantasma sparisce finché non riparti.
	_clock = 0.0
	_times.clear()
	_positions.clear()
	_ghost_visible = false
	queue_redraw()


func _draw() -> void:
	if not _ghost_visible:
		return
	var radius := game.maze.tile_size * 0.35
	draw_circle(_ghost_position, radius, ghost_color)
	for side: float in [-1.0, 1.0]:
		var eye := _ghost_position + Vector2(side * radius * 0.35, -radius * 0.15)
		draw_circle(eye, radius * 0.16, Color(0.1, 0.1, 0.25, 0.8))
