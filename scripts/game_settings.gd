# Impostazioni condivise tra il menu e il gioco.
#
# Questo script è un "Autoload" (Progetto → Impostazioni progetto → Globali →
# Autoload): Godot crea il nodo all'avvio, lo chiama GameSettings e lo tiene
# vivo anche quando si cambia scena. Il menu ci scrive la modalità scelta e la
# scena del gioco la legge: è il modo più semplice per passare dati da una
# scena all'altra. Da qualunque script basta scrivere GameSettings.mode.
#
# Qui si salvano anche i record, in un file nella cartella "user://": è una
# cartella privata del gioco sul dispositivo (nel browser è lo spazio del sito).
extends Node

enum Mode {
	ARCADE,   # Regole a sorpresa dal livello 2, combinate nei livelli alti.
	CLASSIC,  # Solo il labirinto, senza regole speciali.
	CHAOS,    # Due o tre regole insieme fin dal primo livello.
	DAILY,    # Sfida del giorno: stessi labirinti per tutti, oggi.
	SINGLE,   # Allenamento: sempre la stessa regola.
}

const RECORDS_PATH := "user://records.cfg"

# Uno dei valori di Mode (scritto come numero intero).
var mode: int = Mode.ARCADE
# Per la modalità SINGLE: la regola scelta nel menu.
var single_modifier: ModifierDef


# La data di oggi come testo, es. "2026-10-10". Serve come "nome" della sfida
# del giorno e come chiave per il suo record.
func today() -> String:
	return Time.get_date_string_from_system()


# Miglior tempo della sfida di oggi, oppure -1 se non l'hai ancora finita.
func get_daily_record() -> float:
	var records := ConfigFile.new()
	records.load(RECORDS_PATH)  # Se il file non esiste ancora, resta vuoto.
	return records.get_value("daily", today(), -1.0)


# Salva il tempo se è un nuovo record. Restituisce true se lo è.
func save_daily_time(total_time: float) -> bool:
	var best := get_daily_record()
	if best >= 0.0 and best <= total_time:
		return false
	var records := ConfigFile.new()
	records.load(RECORDS_PATH)
	records.set_value("daily", today(), total_time)
	records.save(RECORDS_PATH)
	return true
