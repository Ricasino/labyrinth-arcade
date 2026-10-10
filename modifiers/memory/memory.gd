# Variante "A memoria": il labirinto si vede solo per pochi secondi, poi i
# muri diventano invisibili e bisogna ricordarsi la strada.
extends LevelModifier

# Secondi in cui i muri restano visibili, e durata della dissolvenza.
@export var visible_time := 3.0
@export var fade_time := 1.0


func level_started() -> void:
	# Il Tween aspetta, poi porta l'opacità dei muri da 1 a 0. Appartiene a
	# questo nodo: se il livello finisce prima, si ferma insieme alla variante.
	var tween := create_tween()
	tween.tween_interval(visible_time)
	tween.tween_property(game.maze, "walls_opacity", 0.0, fade_time)
