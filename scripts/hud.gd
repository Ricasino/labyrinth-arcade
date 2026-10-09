# HUD (Heads-Up Display): le scritte sovrapposte al gioco.
#
# Estende CanvasLayer: tutto ciò che sta sotto un CanvasLayer viene disegnato
# su un livello separato che NON si muove con la telecamera. Così le scritte
# restano ferme sullo schermo mentre il labirinto scorre sotto.
class_name Hud
extends CanvasLayer

# Il simbolo % indica un "nodo con nome unico" nella scena (nell'editor:
# clic destro sul nodo > "Accedi come nome unico"). Si trova anche se in
# futuro lo sposti dentro un altro contenitore, a differenza di un percorso
# come $TopBar/HBox/LevelLabel.
#
# @onready assegna la variabile quando il nodo è pronto, cioè quando i figli
# esistono già: prima di quel momento non si potrebbero trovare.
@onready var _level_label: Label = %LevelLabel
@onready var _time_label: Label = %TimeLabel
@onready var _message_label: Label = %MessageLabel

var _message_tween: Tween


func set_level(level: int) -> void:
	_level_label.text = "Livello %d" % level


func set_time(seconds: float) -> void:
	_time_label.text = format_time(seconds)


# Mostra un messaggio al centro dello schermo e lo fa svanire dopo `duration`
# secondi.
func show_message(text: String, duration := 1.5) -> void:
	# Se c'era un messaggio precedente ancora in animazione, lo interrompe.
	if _message_tween:
		_message_tween.kill()
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_tween = create_tween()
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.5)


# Formatta i secondi come "mm:ss.cc". È `static` perché non usa nessun dato
# del nodo: si può chiamare anche come Hud.format_time(12.5).
static func format_time(seconds: float) -> String:
	var minutes := floori(seconds / 60.0)
	var whole_seconds := floori(seconds) % 60
	var hundredths := floori(seconds * 100.0) % 100
	return "%02d:%02d.%02d" % [minutes, whole_seconds, hundredths]
