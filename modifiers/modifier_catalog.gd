# L'elenco di tutte le varianti del gioco, salvato in modifiers/catalog.tres.
#
# Lo usano sia il gioco (per pescare le regole a caso) sia il menu (per i
# pulsanti dell'allenamento). Per aggiungere una variante basta trascinare la
# sua scheda .tres nella lista "Modifiers" di catalog.tres, nell'Inspector.
class_name ModifierCatalog
extends Resource

@export var modifiers: Array[ModifierDef] = []
