# Variante "A ritmo": sulla strada per l'uscita ci sono dei cancelli che si
# aprono e si chiudono a tempo di metronomo. Metà sono aperti quando l'altra
# metà è chiusa: bisogna passare al momento giusto.
#
# Il suono "tic-toc" non viene da un file: è creato dal codice, scrivendo uno
# per uno i campioni di un'onda sinusoidale dentro un AudioStreamWAV.
extends LevelModifier

# Durata di un battito, in secondi.
@export var beat_time := 0.7
@export var gate_color := Color("ff4fd8")

@onready var _audio: AudioStreamPlayer = $Audio

var _gates: Array[Vector2i] = []
var _beat := 0
var _time_in_beat := 0.0
var _tick: AudioStreamWAV
var _tock: AudioStreamWAV


func level_started() -> void:
	_tick = _make_beep(880.0)
	_tock = _make_beep(660.0)

	# Un cancello ogni 6 caselle circa del percorso giusto, solo sui passaggi.
	var path := game.maze.find_path(game.maze.start_cell, game.maze.exit_cell)
	for i in range(4, path.size() - 3, 6):
		var cell := path[i]
		if cell.x % 2 == cell.y % 2:
			cell = path[i + 1]  # Se è una stanza, prende il passaggio dopo.
		if not game.is_reserved(cell):
			game.reserve_cell(cell)
			_gates.append(cell)


func _process(delta: float) -> void:
	_time_in_beat += delta
	if _time_in_beat >= beat_time:
		_time_in_beat -= beat_time
		_beat += 1
		_audio.stream = _tick if _beat % 2 == 0 else _tock
		_audio.play()
	queue_redraw()


# I cancelli pari sono chiusi nei battiti pari, quelli dispari nei dispari.
func _is_closed(gate_index: int) -> bool:
	return (gate_index + _beat) % 2 == 0


func blocks_cell(cell: Vector2i) -> bool:
	var index := _gates.find(cell)
	return index != -1 and _is_closed(index)


# Crea un "bip" breve: un'onda sinusoidale che si spegne gradualmente.
func _make_beep(frequency: float, duration := 0.07) -> AudioStreamWAV:
	var mix_rate := 22050
	var samples := int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)  # 2 byte per campione (16 bit).
	for i in samples:
		var fade := 1.0 - float(i) / samples
		var value := sin(TAU * frequency * i / mix_rate) * fade * 0.4
		data.encode_s16(i * 2, int(value * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.data = data
	return wav


func _draw() -> void:
	var tile := float(game.maze.tile_size)
	# Subito dopo il battito i cancelli "lampeggiano" un po' più forte.
	var flash := 1.0 - _time_in_beat / beat_time
	for i in _gates.size():
		var center := game.maze.cell_to_position(_gates[i])
		var rect := Rect2(center - Vector2(tile, tile) * 0.45, Vector2(tile, tile) * 0.9)
		if _is_closed(i):
			draw_rect(rect, gate_color.darkened(0.5 - flash * 0.3))
			draw_rect(rect, gate_color, false, 3.0)
		else:
			draw_rect(rect, Color(gate_color, 0.35), false, 2.0)
