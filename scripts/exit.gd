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
	draw_rect(outer, color)
	draw_rect(outer.grow(-size * 0.1), color.darkened(0.5))
