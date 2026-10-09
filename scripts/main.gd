# Script della scena principale: è il "regista" del gioco.
#
# Non disegna niente e non muove niente direttamente: coordina gli altri nodi.
# - chiede a Maze di generare un labirinto;
# - mette Player e Exit al posto giusto;
# - conta il tempo e aggiorna l'HUD;
# - quando il giocatore raggiunge l'uscita, passa al livello successivo.
extends Node2D

# Dimensioni del primo labirinto (in stanze) e crescita a ogni livello.
@export var first_cols := 7
@export var first_rows := 4
@export var cols_per_level := 2
@export var rows_per_level := 1
# Pausa (in secondi) tra l'arrivo all'uscita e il labirinto successivo.
@export var level_transition_time := 1.5
# Spazio vuoto (in pixel) che la telecamera lascia attorno al labirinto.
@export var camera_margin := 64

# `$NomeNodo` è una scorciatoia per get_node("NomeNodo"): trova un figlio
# tramite il suo percorso nella scena.
@onready var _maze: Maze = $Maze
@onready var _exit: ExitMarker = $Exit
@onready var _player: Player = $Player
@onready var _camera: Camera2D = $Player/Camera2D
@onready var _hud: Hud = $HUD

var _level := 0
var _elapsed := 0.0
var _timer_running := false


# _ready viene chiamata una volta, quando il nodo e tutti i suoi figli sono
# entrati nella scena. È il posto giusto per collegare i segnali e iniziare.
func _ready() -> void:
	# Collega il segnale del giocatore a una funzione di questo script.
	_player.reached_cell.connect(_on_player_reached_cell)
	# Se la finestra cambia dimensione (o il telefono ruota), ricalcola i
	# limiti della telecamera.
	get_viewport().size_changed.connect(_update_camera_limits)
	_start_level(1)


func _process(delta: float) -> void:
	if _timer_running:
		_elapsed += delta
		_hud.set_time(_elapsed)


func _start_level(level: int) -> void:
	_level = level
	var cols := first_cols + (level - 1) * cols_per_level
	var rows := first_rows + (level - 1) * rows_per_level
	_maze.generate(cols, rows)

	_exit.position = _maze.cell_to_position(_maze.exit_cell)
	_exit.size = _maze.tile_size
	_player.place_at(_maze.start_cell)

	_update_camera_limits()
	# La telecamera di solito "insegue" il giocatore con un movimento morbido;
	# dopo un teletrasporto la facciamo saltare subito nella nuova posizione.
	_camera.reset_smoothing()

	_elapsed = 0.0
	_timer_running = true
	_hud.set_level(level)
	_hud.set_time(_elapsed)
	_hud.show_message("Livello %d\nRaggiungi l'uscita!" % level)
	_player.active = true


# Chiamata dal segnale Player.reached_cell ogni volta che il giocatore
# completa un passo.
func _on_player_reached_cell(cell: Vector2i) -> void:
	if _timer_running and cell == _maze.exit_cell:
		_complete_level()


func _complete_level() -> void:
	_timer_running = false
	_player.active = false
	_hud.show_message("Uscita trovata!\nTempo: %s" % Hud.format_time(_elapsed), level_transition_time)
	# `await` sospende questa funzione finché il timer non scade, senza
	# bloccare il gioco: nel frattempo Godot continua a disegnare e animare.
	await get_tree().create_timer(level_transition_time).timeout
	_start_level(_level + 1)


# I limiti impediscono alla telecamera di mostrare il vuoto oltre il
# labirinto. Se il labirinto è più piccolo dello schermo, i limiti vengono
# allargati in modo uguale sui due lati, così il labirinto resta centrato.
func _update_camera_limits() -> void:
	var view_size := get_viewport_rect().size / _camera.zoom
	var maze_rect := Rect2(Vector2.ZERO, _maze.get_pixel_size()).grow(camera_margin)
	var extra := (view_size - maze_rect.size).max(Vector2.ZERO) / 2.0
	maze_rect = maze_rect.grow_individual(extra.x, extra.y, extra.x, extra.y)
	_camera.limit_left = floori(maze_rect.position.x)
	_camera.limit_top = floori(maze_rect.position.y)
	_camera.limit_right = ceili(maze_rect.end.x)
	_camera.limit_bottom = ceili(maze_rect.end.y)
