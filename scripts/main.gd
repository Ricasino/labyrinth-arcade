# Script della scena principale: è il "regista" del gioco.
#
# Non disegna niente e non muove niente direttamente: coordina gli altri nodi.
# - chiede a Maze di generare un labirinto;
# - mette Player e Exit al posto giusto;
# - pesca una o più varianti (regole speciali) e le aggiunge al livello;
# - conta il tempo e aggiorna l'HUD;
# - quando il giocatore raggiunge l'uscita, passa al livello successivo.
#
# Con `class_name Game` le varianti possono scrivere `var game: Game` e usare
# le variabili e le funzioni pubbliche qui sotto (maze, player, hud, ...).
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

@export_group("Varianti")
# Le varianti che il gioco può pescare. Per aggiungerne una nuova: crea la sua
# cartella in modifiers/ (scena, script e scheda .tres), poi trascina la
# scheda in questa lista dall'Inspector del nodo Main.
@export var modifier_defs: Array[ModifierDef] = []
# Da questo livello in poi ogni labirinto ha almeno una variante...
@export var first_modifier_level := 2
# ...da questo livello spesso due insieme...
@export var double_modifier_level := 5
# ...e da questo a volte tre.
@export var triple_modifier_level := 9
# Per provare una variante: se la imposti qui, esce a ogni livello (anche al
# primo) al posto della scelta casuale. Lasciala vuota per giocare normalmente.
@export var forced_modifier: ModifierDef

@export_group("Nemici")
# Secondi aggiunti al tempo quando un nemico ti prende.
@export var catch_penalty := 3.0
# Dopo essere stato preso, per questi secondi non si può essere ripresi.
@export var catch_grace_time := 1.5

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
# Le varianti attive nel livello in corso, e le schede di quelle del livello
# precedente (per non ripeterle subito).
var _modifiers: Array[LevelModifier] = []
var _last_defs: Array[ModifierDef] = []
# Caselle già occupate da qualcosa (stelle, chiavi, portali...), usato come
# "insieme": la chiave è la casella, il valore non conta.
var _reserved_cells := {}
# Momento (in secondi di gioco) in cui il giocatore potrà di nuovo essere preso.
var _catchable_after := 0.0


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

	# Le varianti possono mostrare una riga di stato (es. "Stelle 2/5").
	var texts: PackedStringArray = []
	for modifier in _modifiers:
		var text := modifier.status_text()
		if text != "":
			texts.append(text)
	hud.set_info("     ".join(texts))


# true se il giocatore può entrare nella casella: non deve essere un muro e
# nessuna variante deve bloccarla.
func can_enter(cell: Vector2i) -> bool:
	if not maze.is_walkable(cell):
		return false
	for modifier in _modifiers:
		if modifier.blocks_cell(cell):
			return false
	return true


# Un nemico ha preso il giocatore: torna alla partenza e il tempo aumenta.
func catch_player() -> void:
	if not _timer_running or _elapsed < _catchable_after:
		return
	_catchable_after = _elapsed + catch_grace_time
	_elapsed += catch_penalty
	player.place_at(maze.start_cell)
	_camera.reset_smoothing()
	hud.show_message("Preso!\n+%d secondi" % catch_penalty, 1.0)
	for modifier in _modifiers:
		modifier.player_caught()


# Sceglie `count` stanze libere a caso per metterci degli oggetti, e le segna
# come occupate così due varianti non mettono cose nella stessa casella.
# Le stanze sono ad almeno `min_distance` caselle dalla partenza. Con
# `prefer_dead_ends` sceglie prima i vicoli ciechi (bisogna esplorare!).
func pick_rooms(count: int, min_distance := 3.0, prefer_dead_ends := false) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for room in maze.get_rooms():
		if not _reserved_cells.has(room) and Vector2(room - maze.start_cell).length() >= min_distance:
			candidates.append(room)
	shuffle(candidates)
	if prefer_dead_ends:
		# sort_custom ordina con una funzione: qui mette prima i vicoli ciechi.
		candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return maze.count_exits(a) == 1 and maze.count_exits(b) != 1)

	var picked: Array[Vector2i] = candidates.slice(0, count)
	for room in picked:
		reserve_cell(room)
	return picked


func reserve_cell(cell: Vector2i) -> void:
	_reserved_cells[cell] = true


func is_reserved(cell: Vector2i) -> bool:
	return _reserved_cells.has(cell)


func _start_level(new_level: int) -> void:
	level = new_level
	_remove_modifiers()

	var cols := first_cols + (level - 1) * cols_per_level
	var rows := first_rows + (level - 1) * rows_per_level
	maze.generate(cols, rows)

	exit_marker.position = maze.cell_to_position(maze.exit_cell)
	exit_marker.size = maze.tile_size
	exit_marker.locked = false
	player.reset_effects()
	player.place_at(maze.start_cell)
	_reserved_cells.clear()
	reserve_cell(maze.start_cell)
	reserve_cell(maze.exit_cell)

	_update_camera_limits()
	# La telecamera di solito "insegue" il giocatore con un movimento morbido;
	# dopo un teletrasporto la facciamo saltare subito nella nuova posizione.
	_camera.reset_smoothing()

	_elapsed = 0.0
	_catchable_after = 0.0
	_timer_running = true
	hud.set_level(level)
	hud.set_time(_elapsed)

	var defs := _pick_modifier_defs()
	_last_defs = defs
	var titles: PackedStringArray = []
	var message := "Livello %d" % level
	for modifier_def in defs:
		_add_modifier(modifier_def)
		titles.append(modifier_def.title)
		message += "\n%s: %s" % [modifier_def.title, modifier_def.description]
	hud.set_twist(" + ".join(titles))
	if defs.is_empty():
		hud.show_message(message + "\nRaggiungi l'uscita!")
	else:
		hud.show_message(message, 2.0 + defs.size())

	for modifier in _modifiers:
		modifier.level_started()
	player.active = true


# Sceglie le varianti del livello: quante dipende dal livello, quali è un po'
# a caso (tenendo conto del "peso"), senza ripetere quelle del livello appena
# giocato e senza mettere insieme varianti incompatibili.
func _pick_modifier_defs() -> Array[ModifierDef]:
	var picked: Array[ModifierDef] = []
	if forced_modifier:
		picked.append(forced_modifier)
		return picked
	if level < first_modifier_level:
		return picked

	var count := 1
	if level >= triple_modifier_level and rng.randf() < 0.4:
		count = 3
	elif level >= double_modifier_level and rng.randf() < 0.6:
		count = 2

	for i in count:
		var candidates: Array[ModifierDef] = []
		for modifier_def in modifier_defs:
			if modifier_def.min_level > level or modifier_def.weight <= 0.0:
				continue
			if _last_defs.has(modifier_def):
				continue
			var fits := true
			for other in picked:
				if not modifier_def.is_compatible_with(other):
					fits = false
			if fits:
				candidates.append(modifier_def)
		if candidates.is_empty():
			break
		picked.append(_weighted_choice(candidates))
	return picked


# Estrazione "pesata": immagina i pesi come segmenti messi in fila e un punto
# scelto a caso sulla fila; vince il segmento su cui cade il punto.
func _weighted_choice(candidates: Array[ModifierDef]) -> ModifierDef:
	var total_weight := 0.0
	for modifier_def in candidates:
		total_weight += modifier_def.weight
	var point := rng.randf() * total_weight
	for modifier_def in candidates:
		point -= modifier_def.weight
		if point <= 0.0:
			return modifier_def
	return candidates.back()


# Mescola un array usando il generatore del gioco (algoritmo di Fisher-Yates).
func shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp


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
	if _timer_running and player.cell == maze.exit_cell and _exit_allowed():
		_complete_level()


# true se nessuna variante impedisce di uscire (es. stelle ancora da prendere).
func _exit_allowed() -> bool:
	for modifier in _modifiers:
		if not modifier.allows_exit():
			return false
	return true


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
