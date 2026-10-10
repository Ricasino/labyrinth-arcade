# Variante "Inseguitore": un mostro gira per il labirinto e, quando ti sente
# vicino, ti insegue lungo la strada più breve. È più lento di te: scappa!
#
# Come per la "Ronda", il labirinto riceve dei passaggi in più per poterlo
# seminare girandogli attorno.
extends LevelModifier

# Entro quante caselle di percorso il mostro ti sente e ti insegue.
@export var hearing_distance := 12
@export var base_speed := 4.0

var _monster: Enemy
var _spawn := Vector2i.ZERO
var _previous := Vector2i(-1, -1)


func level_started() -> void:
	var rooms := game.maze.get_rooms()
	game.maze.add_loops(game.rng, floori(rooms.size() / 5.0))

	# Nasce lontano dalla partenza: almeno a metà della diagonale del labirinto.
	var far := Vector2(game.maze.exit_cell - game.maze.start_cell).length() * 0.5
	var picked := game.pick_rooms(1, far)
	_spawn = picked[0] if not picked.is_empty() else game.maze.exit_cell

	_monster = Enemy.new()
	_monster.game = game
	_monster.color = Color("b5179e")
	_monster.speed = minf(base_speed + game.level * 0.1, 6.0)
	_monster.next_cell = _choose_next
	add_child(_monster)
	_monster.place_at(_spawn)


# Se il giocatore è abbastanza vicino, fa un passo verso di lui; altrimenti
# vaga a caso senza tornare subito indietro.
func _choose_next(from: Vector2i) -> Vector2i:
	var path := game.maze.find_path(from, game.player.cell)
	if path.size() > 1 and path.size() <= hearing_distance:
		_previous = from
		return path[1]

	var options: Array[Vector2i] = []
	for dir in MazeGenerator.DIRECTIONS:
		var next := from + dir
		if game.maze.is_walkable(next) and next != _previous:
			options.append(next)
	if options.is_empty():
		options.append(_previous)
	_previous = from
	return options[game.rng.randi_range(0, options.size() - 1)]


func player_caught() -> void:
	_monster.place_at(_spawn)
