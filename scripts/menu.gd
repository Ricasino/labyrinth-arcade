# Il menu iniziale: si sceglie come giocare e si parte.
#
# È fatto solo di nodi dell'interfaccia (Control): contenitori che mettono in
# fila e in griglia i pulsanti da soli (VBoxContainer, GridContainer...), così
# non bisogna posizionare niente a mano e il menu si adatta a ogni schermo.
# L'aspetto dei pulsanti viene dal tema scenes/ui_theme.tres.
extends Control

const GAME_SCENE := "res://scenes/main.tscn"

# L'elenco delle varianti, per creare un pulsante di allenamento per ognuna.
@export var catalog: ModifierCatalog

@onready var _description: Label = %Description


func _ready() -> void:
	# `bind` attacca un valore alla funzione: premendo il pulsante verrà
	# chiamata _start(GameSettings.Mode.ARCADE), e così via.
	%ArcadeButton.pressed.connect(_start.bind(GameSettings.Mode.ARCADE))
	%ClassicButton.pressed.connect(_start.bind(GameSettings.Mode.CLASSIC))
	%ChaosButton.pressed.connect(_start.bind(GameSettings.Mode.CHAOS))
	%DailyButton.pressed.connect(_start.bind(GameSettings.Mode.DAILY))

	var record := GameSettings.get_daily_record()
	if record >= 0.0:
		%DailyButton.text += "\nRecord di oggi: %s" % Hud.format_time(record)
	else:
		%DailyButton.text += "\n5 livelli, uguali per tutti"

	# Un pulsante per ogni variante del catalogo, creato da codice.
	for modifier_def in catalog.modifiers:
		var button := Button.new()
		button.text = modifier_def.title
		button.custom_minimum_size = Vector2(230, 56)
		button.add_theme_font_size_override("font_size", 22)
		button.pressed.connect(_start_training.bind(modifier_def))
		_show_description_on_hover(button, modifier_def.description)
		%TrainingGrid.add_child(button)

	# Con la tastiera o il gamepad si parte già dal primo pulsante.
	%ArcadeButton.grab_focus()


# Mostra la descrizione della variante quando il mouse ci passa sopra o
# quando il pulsante viene selezionato con le frecce.
func _show_description_on_hover(button: Button, text: String) -> void:
	button.mouse_entered.connect(func() -> void: _description.text = text)
	button.focus_entered.connect(func() -> void: _description.text = text)


func _start(mode: int) -> void:
	GameSettings.mode = mode
	# Cambia scena: il menu viene eliminato e al suo posto parte il gioco.
	get_tree().change_scene_to_file(GAME_SCENE)


func _start_training(modifier_def: ModifierDef) -> void:
	GameSettings.single_modifier = modifier_def
	_start(GameSettings.Mode.SINGLE)
