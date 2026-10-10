# Base comune di tutte le varianti: le "regole speciali" che rendono ogni
# livello diverso dagli altri.
#
# Ogni variante vive nella sua cartella dentro modifiers/ ed è una scena il cui
# nodo principale ha uno script che estende LevelModifier. A inizio livello
# Game crea la scena e la aggiunge al nodo Modifiers; a fine livello la
# elimina. Quindi tutto quello che una variante crea (nodi figli, Tween,
# Timer...) sparisce da solo insieme a lei.
#
# Le funzioni qui sotto non fanno niente: ogni variante "sovrascrive"
# (ridefinisce con lo stesso nome) solo quelle che le servono.
class_name LevelModifier
extends Node2D

# Il gioco. Da qui la variante raggiunge tutto il resto: game.maze,
# game.player, game.hud, game.exit_marker, game.rng, game.level...
var game: Game


# Chiamata una volta, quando il labirinto del livello è pronto e il giocatore
# è sulla casella di partenza.
func level_started() -> void:
	pass


# Chiamata ogni volta che il giocatore arriva in una nuova casella.
func player_stepped(_cell: Vector2i) -> void:
	pass


# Se restituisce true, il giocatore non può entrare nella casella anche se
# non è un muro (per esempio una porta chiusa).
func blocks_cell(_cell: Vector2i) -> bool:
	return false
