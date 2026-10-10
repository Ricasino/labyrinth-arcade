# La "scheda" di una variante: una risorsa (Resource) che contiene solo dati.
#
# Ogni variante ne ha una, salvata come file .tres nella sua cartella (es.
# modifiers/memory/memory.tres). Facendo doppio clic su quel file si apre
# nell'Inspector e si possono cambiare titolo, descrizione e frequenza senza
# toccare il codice. Game sceglie la variante leggendo queste schede.
class_name ModifierDef
extends Resource

# Nome mostrato all'inizio del livello e in alto nell'HUD.
@export var title := ""
# Spiegazione breve (una riga) della regola speciale.
@export var description := ""
# La scena della variante (il suo nodo principale estende LevelModifier).
@export var scene: PackedScene
# Primo livello in cui la variante può comparire.
@export var min_level := 2
# Quanto spesso esce rispetto alle altre: 2 = il doppio di 1, 0 = mai.
@export_range(0.0, 10.0, 0.1) var weight := 1.0
# Etichette per evitare combinazioni impossibili o troppo confuse: due
# varianti con un'etichetta in comune non escono mai nello stesso livello.
# Per esempio tutte quelle con dei nemici hanno l'etichetta "nemici".
@export var tags: PackedStringArray = []


# true se questa variante può stare nello stesso livello di `other`.
func is_compatible_with(other: ModifierDef) -> bool:
	if other == self:
		return false
	for tag in tags:
		if other.tags.has(tag):
			return false
	return true
