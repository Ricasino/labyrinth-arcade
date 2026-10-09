# Il giocatore: si muove sulla griglia del labirinto una casella alla volta,
# scivolando in modo fluido da un centro di casella al successivo.
#
# Non usa la fisica di Godot (CharacterBody2D, collisioni...): in un labirinto
# a griglia basta chiedere al labirinto se la casella di destinazione è
# libera. È il modo più semplice e preciso per un gioco "alla Pac-Man".
class_name Player
extends Node2D

# Un segnale è un "evento" che altri nodi possono ascoltare. Il giocatore non
# sa cosa succede quando arriva in una casella: lo annuncia e basta. Sarà
# Main (scripts/main.gd) a controllare se quella casella è l'uscita.
signal reached_cell(cell: Vector2i)

# Associa ogni azione di input (definita in Progetto > Impostazioni progetto >
# Mappa input) alla direzione corrispondente sulla griglia.
const ACTION_DIRECTIONS := {
	&"move_up": Vector2i.UP,
	&"move_down": Vector2i.DOWN,
	&"move_left": Vector2i.LEFT,
	&"move_right": Vector2i.RIGHT,
}

# Riferimento al labirinto. È assegnato nell'Inspector di scenes/main.tscn
# (proprietà "Maze" del nodo Player).
@export var maze: Maze
# Velocità in caselle al secondo.
@export var speed := 8.0
@export var color := Color("ffd23f")

# Casella in cui si trova (o verso cui sta andando) il giocatore.
var cell := Vector2i.ZERO
# Quando è false il giocatore ignora i comandi (es. durante il cambio livello).
var active := false

var _moving := false
var _target_position := Vector2.ZERO
# Ultima azione di movimento premuta: ha la precedenza sulle altre.
var _last_action := &""
# Direzione premuta anche solo per un istante: viene ricordata finché il
# giocatore non è pronto a fare il prossimo passo, così un tocco veloce non
# va perso mentre è ancora in movimento.
var _queued_direction := Vector2i.ZERO


# Teletrasporta il giocatore su una casella (usato a inizio livello).
func place_at(new_cell: Vector2i) -> void:
	cell = new_cell
	position = maze.cell_to_position(cell)
	_moving = false
	_queued_direction = Vector2i.ZERO
	queue_redraw()


# _unhandled_input riceve gli eventi di input che nessun altro nodo (ad
# esempio l'interfaccia) ha già "consumato". Qui ci servono solo per sapere
# QUANDO viene premuta una direzione; se è tenuta premuta lo chiediamo
# direttamente al singleton Input in _pick_direction().
func _unhandled_input(event: InputEvent) -> void:
	for action: StringName in ACTION_DIRECTIONS:
		if event.is_action_pressed(action):
			_last_action = action
			_queued_direction = ACTION_DIRECTIONS[action]


# _process viene chiamata da Godot a ogni fotogramma; `delta` è il tempo in
# secondi trascorso dal fotogramma precedente. Moltiplicare la velocità per
# delta rende il movimento uguale a 30, 60 o 144 FPS.
func _process(delta: float) -> void:
	if _moving:
		position = position.move_toward(_target_position, speed * maze.tile_size * delta)
		if position == _target_position:
			_moving = false
			reached_cell.emit(cell)

	# Nello stesso fotogramma in cui arriva può già ripartire: così, tenendo
	# premuto un tasto, il movimento resta continuo senza scatti.
	if not _moving and active:
		var direction := _pick_direction()
		if direction != Vector2i.ZERO:
			cell += direction
			_target_position = maze.cell_to_position(cell)
			_moving = true


# Sceglie in che direzione andare, in ordine di priorità:
# 1. la direzione toccata per ultima (anche se già rilasciata);
# 2. l'ultima direzione premuta, se è ancora tenuta;
# 3. qualunque altra direzione tenuta premuta.
# Viene scelta la prima che porta in una casella libera. Così, tenendo premuti
# due tasti (es. destra + su), il giocatore svolta appena trova un'apertura.
func _pick_direction() -> Vector2i:
	var candidates: Array[Vector2i] = []
	if _queued_direction != Vector2i.ZERO:
		candidates.append(_queued_direction)
	if _last_action != &"" and Input.is_action_pressed(_last_action):
		candidates.append(ACTION_DIRECTIONS[_last_action])
	for action: StringName in ACTION_DIRECTIONS:
		if Input.is_action_pressed(action):
			candidates.append(ACTION_DIRECTIONS[action])
	_queued_direction = Vector2i.ZERO

	for direction in candidates:
		if maze.is_walkable(cell + direction):
			return direction
	return Vector2i.ZERO


func _draw() -> void:
	# Il disegno è centrato sull'origine del nodo, che coincide con il centro
	# della casella. La dimensione dipende da quella delle caselle.
	var radius := maze.tile_size * 0.35
	draw_circle(Vector2.ZERO, radius, color)
	draw_circle(Vector2.ZERO, radius, color.darkened(0.4), false, 3.0)
