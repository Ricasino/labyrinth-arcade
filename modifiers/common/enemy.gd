# Un nemico che cammina sulla griglia del labirinto, una casella alla volta,
# come il giocatore. Se lo tocca, chiama game.catch_player().
#
# Il nemico non decide da solo dove andare: ogni volta che arriva in una
# casella chiede la prossima alla funzione `next_cell` (una Callable). Così lo
# stesso nemico può fare la ronda o inseguire il giocatore, a seconda della
# variante che lo crea.
class_name Enemy
extends Node2D

@export var color := Color("ff4d6d")
var game: Game
# Velocità in caselle al secondo (il giocatore ne fa 8).
var speed := 3.0
var cell := Vector2i.ZERO
# Funzione che riceve la casella del nemico e restituisce la prossima.
var next_cell: Callable

var _moving := false
var _target_position := Vector2.ZERO
# Direzione in cui guarda: serve solo per disegnare gli occhi.
var _facing := Vector2.RIGHT


func place_at(new_cell: Vector2i) -> void:
	cell = new_cell
	position = game.maze.cell_to_position(cell)
	_moving = false


func _process(delta: float) -> void:
	if _moving:
		position = position.move_toward(_target_position, speed * game.maze.tile_size * delta)
		if position == _target_position:
			_moving = false
	if not _moving and next_cell.is_valid():
		var next: Vector2i = next_cell.call(cell)
		if next != cell:
			_facing = Vector2(next - cell)
			cell = next
			_target_position = game.maze.cell_to_position(cell)
			_moving = true
			queue_redraw()

	if position.distance_to(game.player.position) < game.maze.tile_size * 0.6:
		game.catch_player()


func _draw() -> void:
	var radius := game.maze.tile_size * 0.36
	draw_circle(Vector2.ZERO, radius, color)
	# Due occhi che guardano nella direzione di marcia.
	var side := _facing.orthogonal() * radius * 0.4
	var forward := _facing * radius * 0.3
	for eye: Vector2 in [forward + side, forward - side]:
		draw_circle(eye, radius * 0.28, Color.WHITE)
		draw_circle(eye + _facing * radius * 0.1, radius * 0.13, Color.BLACK)
