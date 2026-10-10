# Variante "Labirinto vivo": è buio e il giocatore vede solo in un cerchio di
# luce attorno a sé. Fuori dalla luce, intanto, i muri si spostano!
#
# Il buio è fatto con un CanvasModulate, che scurisce tutto il mondo di gioco
# (ma non l'HUD, che sta su un CanvasLayer separato). La luce è un
# PointLight2D: rischiara una zona a forma di cerchio sfumato, presa dalla sua
# texture. Lo spostamento dei muri lo scandisce un nodo Timer.
extends LevelModifier

# Raggio della luce attorno al giocatore, in caselle.
@export var light_radius := 3.0
# Raggio della luce che segnala l'uscita, in caselle.
@export var exit_light_radius := 1.5

@onready var _player_light: PointLight2D = $PlayerLight
@onready var _exit_light: PointLight2D = $ExitLight
@onready var _shift_timer: Timer = $ShiftTimer


func level_started() -> void:
	# La texture della luce è un cerchio largo qualche centinaio di pixel:
	# texture_scale la ingrandisce o rimpicciolisce fino al raggio voluto.
	var tile := float(game.maze.tile_size)
	_player_light.texture_scale = light_radius * 2.0 * tile / _player_light.texture.get_width()
	_exit_light.texture_scale = exit_light_radius * 2.0 * tile / _exit_light.texture.get_width()
	_exit_light.position = game.exit_marker.position
	_shift_timer.start()


func _process(_delta: float) -> void:
	# La luce segue il giocatore.
	_player_light.position = game.player.position


# Collegata al segnale timeout del ShiftTimer direttamente nella scena
# (pannello Nodo → Segnali), invece che da codice.
func _on_shift_timer_timeout() -> void:
	game.maze.shift_wall(game.rng, _is_in_darkness)


# Una casella può cambiare solo se è al buio, con una casella di margine:
# così il giocatore non vede mai un muro comparire davanti a sé.
func _is_in_darkness(cell: Vector2i) -> bool:
	return Vector2(cell - game.player.cell).length() > light_radius + 1.0
