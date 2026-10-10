# Script della scena principale: è il "regista" del gioco.
#
# Non disegna niente e non muove niente direttamente: coordina gli altri nodi.
# - chiede a Maze di generare un labirinto;
# - mette Player e Exit al posto giusto;
# - pesca una variante (una regola speciale) e la aggiunge al livello;
# - conta il tempo e aggiorna l'HUD;
# - quando il giocatore raggiunge l'uscita, passa al livello successivo.
#
# Con `class_name Game` le varianti possono scrivere `var game: Game` e usare
# le variabili pubbliche qui sotto (maze, player, hud, ...).
class_name Game
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

# Le varianti che il gioco può pescare. Per aggiungerne una nuova: crea la sua
# cartella in modifiers/ (scena, script e scheda .tres), poi trascina la
# scheda in questa lista dall'Inspector del nodo Main.
@export var modifier_defs: Array[ModifierDef] = []
# Da questo livello in poi ogni labirinto ha una variante.
@export var first_modifier_level := 2
# Per provare una variante: se la imposti qui, esce a ogni livello (anche al
# primo) al posto della scelta casuale. Lasciala vuota per giocare normalmente.
@export var forced_modifier: ModifierDef

# `$NomeNodo` è una scorciatoia per get_node("NomeNodo"): trova un figlio
# tramite il suo percorso nella scena. Queste variabili sono pubbliche (senza
# trattino basso) perché le usano anche le varianti.
@onready var maze: Maze = $Maze
@onready var exit_marker: ExitMarker = $Exit
@onready var player: Player = $Player
@onready var hud: Hud = $HUD
@onready var _modifiers_root: Node2D = $Modifiers
@onready var _camera: Camera2D = $Player/Camera2D

# Generatore di numeri casuali condiviso, a disposizione delle varianti.
var rng := RandomNumberGenerator.new()
var level := 0

var _elapsed := 0.0
var _timer_running := false
# Le varianti attive nel livello in corso, e la scheda dell'ultima pescata.
var _modifiers: Array[LevelModifier] = []
var _last_modifier_def: ModifierDef


# _ready viene chiamata una volta, quando il nodo e tutti i suoi figli sono
# entrati nella scena. È il posto giusto per collegare i segnali e iniziare.
func _ready() -> void:
	rng.randomize()
	# Il giocatore chiederà a questa funzione se può entrare in una casella.
	player.can_enter = can_enter
	# Collega il segnale del giocatore a una funzione di questo script.
	player.reached_cell.connect(_on_player_reached_cell)
	# Se la finestra cambia dimensione (o il telefono ruota), ricalcola i
	# limiti della telecamera.
	get_viewport().size_changed.connect(_update_camera_limits)
	_start_level(1)


func _process(delta: float) -> void:
	if _timer_running:
		_elapsed += delta
		hud.set_time(_elapsed)


# true se il giocatore può entrare nella casella: non deve essere un muro e
# nessuna variante deve bloccarla.
func can_enter(cell: Vector2i) -> bool:
	if not maze.is_walkable(cell):
		return false
	for modifier in _modifiers:
		if modifier.blocks_cell(cell):
			return false
	return true


func _start_level(new_level: int) -> void:
	level = new_level
	_remove_modifiers()

	var cols := first_cols + (level - 1) * cols_per_level
	var rows := first_rows + (level - 1) * rows_per_level
	maze.generate(cols, rows)

	exit_marker.position = maze.cell_to_position(maze.exit_cell)
	exit_marker.size = maze.tile_size
	player.place_at(maze.start_cell)

	_update_camera_limits()
	# La telecamera di solito "insegue" il giocatore con un movimento morbido;
	# dopo un teletrasporto la facciamo saltare subito nella nuova posizione.
	_camera.reset_smoothing()

	_elapsed = 0.0
	_timer_running = true
	hud.set_level(level)
	hud.set_time(_elapsed)

	var modifier_def := _pick_modifier_def()
	if modifier_def:
		_add_modifier(modifier_def)
		hud.set_twist(modifier_def.title)
		hud.show_message("Livello %d\n%s\n%s" % [level, modifier_def.title, modifier_def.description], 3.0)
	else:
		hud.set_twist("")
		hud.show_message("Livello %d\nRaggiungi l'uscita!" % level)

	for modifier in _modifiers:
		modifier.level_started()
	player.active = true


# Sceglie a caso la variante del livello, tenendo conto del "peso" di ognuna
# ed evitando di ripetere quella appena usata. null = nessuna variante.
func _pick_modifier_def() -> ModifierDef:
	if forced_modifier:
		return forced_modifier
	if level < first_modifier_level:
		return null

	var candidates: Array[ModifierDef] = []
	for modifier_def in modifier_defs:
		if modifier_def.min_level <= level and modifier_def.weight > 0.0 and modifier_def != _last_modifier_def:
			candidates.append(modifier_def)
	# Se l'unica possibile era proprio l'ultima, la si ripete.
	if candidates.is_empty() and _last_modifier_def and _last_modifier_def.min_level <= level:
		candidates.append(_last_modifier_def)
	if candidates.is_empty():
		return null

	# Estrazione "pesata": immagina i pesi come segmenti messi in fila e un
	# punto scelto a caso sulla fila; vince il segmento su cui cade.
	var total_weight := 0.0
	for modifier_def in candidates:
		total_weight += modifier_def.weight
	var point := rng.randf() * total_weight
	for modifier_def in candidates:
		point -= modifier_def.weight
		if point <= 0.0:
			_last_modifier_def = modifier_def
			return modifier_def
	_last_modifier_def = candidates.back()
	return _last_modifier_def


# Crea la scena della variante e la aggiunge sotto il nodo Modifiers.
func _add_modifier(modifier_def: ModifierDef) -> void:
	var modifier := modifier_def.scene.instantiate() as LevelModifier
	if modifier == null:
		push_error("La scena della variante '%s' deve usare uno script che estende LevelModifier." % modifier_def.title)
		return
	modifier.game = self
	_modifiers_root.add_child(modifier)
	_modifiers.append(modifier)


# Elimina le varianti del livello precedente. remove_child le toglie subito
# dalla scena (smettono di essere disegnate e aggiornate); queue_free le
# cancella dalla memoria appena possibile.
func _remove_modifiers() -> void:
	for modifier in _modifiers:
		_modifiers_root.remove_child(modifier)
		modifier.queue_free()
	_modifiers.clear()


# Chiamata dal segnale Player.reached_cell ogni volta che il giocatore
# completa un passo.
func _on_player_reached_cell(cell: Vector2i) -> void:
	for modifier in _modifiers:
		modifier.player_stepped(cell)
	if _timer_running and cell == maze.exit_cell:
		_complete_level()


func _complete_level() -> void:
	_timer_running = false
	player.active = false
	hud.show_message("Uscita trovata!\nTempo: %s" % Hud.format_time(_elapsed), level_transition_time)
	# `await` sospende questa funzione finché il timer non scade, senza
	# bloccare il gioco: nel frattempo Godot continua a disegnare e animare.
	await get_tree().create_timer(level_transition_time).timeout
	_start_level(level + 1)


# I limiti impediscono alla telecamera di mostrare il vuoto oltre il
# labirinto. Se il labirinto è più piccolo dello schermo, i limiti vengono
# allargati in modo uguale sui due lati, così il labirinto resta centrato.
func _update_camera_limits() -> void:
	var view_size := get_viewport_rect().size / _camera.zoom
	var maze_rect := Rect2(Vector2.ZERO, maze.get_pixel_size()).grow(camera_margin)
	var extra := (view_size - maze_rect.size).max(Vector2.ZERO) / 2.0
	maze_rect = maze_rect.grow_individual(extra.x, extra.y, extra.x, extra.y)
	_camera.limit_left = floori(maze_rect.position.x)
	_camera.limit_top = floori(maze_rect.position.y)
	_camera.limit_right = ceili(maze_rect.end.x)
	_camera.limit_bottom = ceili(maze_rect.end.y)
