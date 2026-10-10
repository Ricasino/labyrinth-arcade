# Variante "Ghiaccio": il pavimento scivola. Una volta partito, il giocatore
# si ferma solo contro un muro o a un incrocio, dove può scegliere la strada.
extends LevelModifier

@export var ice_color := Color("123a5c")


func level_started() -> void:
	game.player.slippery = true
	# Il pavimento diventa azzurro ghiaccio (Maze lo rimette com'era quando
	# genera il labirinto successivo).
	game.maze.floor_color = ice_color
	game.maze.queue_redraw()
