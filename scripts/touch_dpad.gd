# Croce direzionale virtuale per schermi touch.
#
# È un Control (un nodo dell'interfaccia) disegnato da codice. Quando viene
# toccato, calcola la direzione in base a dove si trova il dito rispetto al
# centro e "finge" la pressione dell'azione di input corrispondente
# (move_up, move_left...). In questo modo il giocatore non deve sapere nulla
# del touch: legge le stesse azioni usate da tastiera e gamepad.
#
# Si può far scivolare il dito senza staccarlo per cambiare direzione.
extends Control

const DIRECTION_ACTIONS := {
	Vector2i.UP: &"move_up",
	Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left",
	Vector2i.RIGHT: &"move_right",
}

# Se true, il D-pad è sempre visibile (comodo per provarlo sul PC).
# Altrimenti compare solo sui dispositivi touch o al primo tocco/clic.
@export var always_visible := false
# Zona centrale, in frazione del raggio, in cui il tocco non ha effetto.
@export_range(0.0, 0.9) var dead_zone := 0.25
@export var base_color := Color(1, 1, 1, 0.12)
@export var arrow_color := Color(1, 1, 1, 0.45)
@export var active_color := Color("ffd23f")

# Indice del dito che sta usando il D-pad (-1 = nessuno). Con il multitouch
# ogni dito ha un indice diverso: seguiamo solo il primo.
var _touch_index := -1
# Azione attualmente "premuta" dal D-pad (&"" = nessuna).
var _current_action := &""


func _ready() -> void:
	visible = always_visible or DisplayServer.is_touchscreen_available()


# _input riceve TUTTI gli eventi, prima dell'interfaccia. Lo usiamo solo per
# mostrare il D-pad la prima volta che qualcuno tocca lo schermo.
func _input(event: InputEvent) -> void:
	if not visible and event is InputEventScreenTouch:
		visible = true


# _gui_input riceve solo gli eventi che cadono su questo Control. Le
# coordinate dell'evento sono già relative all'angolo in alto a sinistra.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_update_direction(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_set_action(&"")
		accept_event()  # L'evento è gestito: non passa ad altri nodi.
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_direction(drag.position)
			accept_event()


func _update_direction(touch_position: Vector2) -> void:
	var offset := touch_position - size / 2.0
	if offset.length() < _radius() * dead_zone:
		_set_action(&"")
		return
	# Prevale l'asse su cui il dito si è spostato di più.
	var direction: Vector2i
	if absf(offset.x) > absf(offset.y):
		direction = Vector2i.RIGHT if offset.x > 0.0 else Vector2i.LEFT
	else:
		direction = Vector2i.DOWN if offset.y > 0.0 else Vector2i.UP
	_set_action(DIRECTION_ACTIONS[direction])


# Rilascia l'azione precedente e preme quella nuova.
func _set_action(action: StringName) -> void:
	if action == _current_action:
		return
	if _current_action != &"":
		_send_action(_current_action, false)
	_current_action = action
	if action != &"":
		_send_action(action, true)
	queue_redraw()  # Per evidenziare la freccia attiva.


# Crea un evento "azione" e lo inietta nel sistema di input di Godot, come se
# arrivasse da una tastiera vera. Lo riceveranno _unhandled_input e il
# singleton Input (Input.is_action_pressed).
func _send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _radius() -> float:
	return minf(size.x, size.y) / 2.0


func _draw() -> void:
	var center := size / 2.0
	var radius := _radius()
	draw_circle(center, radius, base_color)
	for direction: Vector2i in DIRECTION_ACTIONS:
		var is_active: bool = DIRECTION_ACTIONS[direction] == _current_action
		var color := active_color if is_active else arrow_color
		_draw_arrow(center + Vector2(direction) * radius * 0.6, Vector2(direction), radius * 0.22, color)


# Disegna un triangolo che punta verso `direction`.
func _draw_arrow(arrow_center: Vector2, direction: Vector2, arrow_size: float, color: Color) -> void:
	var side := direction.orthogonal()
	var points := PackedVector2Array([
		arrow_center + direction * arrow_size,
		arrow_center - direction * arrow_size + side * arrow_size,
		arrow_center - direction * arrow_size - side * arrow_size,
	])
	draw_colored_polygon(points, color)
