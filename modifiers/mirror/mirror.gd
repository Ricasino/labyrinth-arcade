# Variante "Specchio": i comandi sono invertiti. Destra va a sinistra, su va
# giù. Tutto il lavoro lo fa Player: qui basta accendere l'effetto (Game lo
# spegne da solo all'inizio del livello successivo).
extends LevelModifier


func level_started() -> void:
	game.player.invert_controls = true


func status_text() -> String:
	return "Comandi invertiti"
