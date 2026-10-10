# Il segnalino dell'uscita: un quadrato verde che "pulsa".
#
# Non ha logica di gioco: è Main a posizionarlo sulla casella d'uscita e a
# controllare quando il giocatore la raggiunge. Questo script si occupa solo
# dell'aspetto grafico.
class_name ExitMarker
extends Node2D

# Una proprietà con "setter": ogni volta che qualcuno assegna `size`, viene
# eseguito il blocco set(), che salva il valore e chiede di ridisegnare.
@export var size := 48.0:
	set(value):
		size = value
		queue_redraw()
@export var color := Color("39ff88")
@export var locked_color := Color("6b6b80")
# Uscita chiusa (per esempio finché non hai raccolto tutte le stelle): viene
# disegnata grigia con una croce.
var locked := false:
	set(value):
		locked = value
		queue_redraw()


func _ready() -> void:
	# Un Tween anima una proprietà nel tempo. Qui la scala passa da 1 a 1.15 e
	# ritorna a 1, all'infinito (set_loops() senza argomenti = per sempre).
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.5)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5)


func _draw() -> void:
	# Disegnato attorno all'origine, così la scala "pulsa" dal centro.
	var half := size * 0.35
	var outer := Rect2(-half, -half, half * 2.0, half * 2.0)
	var main_color := locked_color if locked else color
	draw_rect(outer, main_color)
	draw_rect(outer.grow(-size * 0.1), main_color.darkened(0.5))
	if locked:
		var arm := half * 0.6
		draw_line(Vector2(-arm, -arm), Vector2(arm, arm), main_color, 3.0)
		draw_line(Vector2(arm, -arm), Vector2(-arm, arm), main_color, 3.0)
