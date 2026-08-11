class_name RuleTableView
extends Control

## La tabella delle quintuple di una macchina di Turing.
## Ogni riga è cliccabile: il giocatore sceglie la regola che si applica alla
## configurazione corrente.

signal rule_clicked(key: String)

const ROW_HEIGHT := 34.0
const ROW_SEPARATION := 5.0
const TITLE_HEIGHT := 26.0
const PADDING := 24.0

var _box: VBoxContainer = null
var _buttons: Dictionary = {}          # chiave regola -> Button
var _row_count: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.06, 0.11, 0.92)
	style.border_color = Color(0.20, 0.45, 0.70, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", int(ROW_SEPARATION))
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_box)


## `keys` elenca le regole da mostrare, nell'ordine desiderato.
func setup(machine: TuringMachine, keys: Array) -> void:
	# queue_free() libera il nodo solo a fine frame: finché non succede il
	# contenitore continua a disporlo, e le regole nuove finirebbero sopra le
	# vecchie. remove_child() lo toglie subito dall'albero.
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	_buttons.clear()

	var title: Label = Label.new()
	title.text = "REGOLE DELLA MACCHINA"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(title)

	for key in keys:
		var rule: Dictionary = machine.rules.get(String(key), {})
		if rule.is_empty():
			continue
		var button: Button = Button.new()
		button.text = describe(rule)
		button.custom_minimum_size = Vector2(340.0, ROW_HEIGHT)
		button.add_theme_font_size_override("font_size", 15)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		_style(button, Color(0.10, 0.18, 0.30), Color(0.35, 0.65, 0.95))
		var rule_key: String = String(key)
		button.pressed.connect(func() -> void: rule_clicked.emit(rule_key))
		_box.add_child(button)
		_buttons[rule_key] = button
	_row_count = _buttons.size()


## Altezza che serve davvero: le macchine hanno un numero di regole diverso e
## una tabella a dimensione fissa finirebbe fuori dallo schermo.
func preferred_height() -> float:
	var rows: float = float(maxi(_row_count, 1))
	return TITLE_HEIGHT + rows * ROW_HEIGHT + (rows - 1.0) * ROW_SEPARATION + PADDING


## δ(stato, letto) = (scrive, direzione, nuovo stato)
static func describe(rule: Dictionary) -> String:
	var direction: String = "→"
	if int(rule["move"]) == TuringMachine.LEFT:
		direction = "←"
	elif int(rule["move"]) == TuringMachine.STAY:
		direction = "•"
	return "δ(%s, %s) = (%s, %s, %s)" % [
		String(rule["from"]), String(rule["read"]),
		String(rule["write"]), direction, String(rule["next"])]


func set_enabled(enabled: bool) -> void:
	for button in _buttons.values():
		button.disabled = not enabled


func highlight(key: String, base: Color, border: Color) -> void:
	if _buttons.has(key):
		_style(_buttons[key], base, border)


func reset_colors() -> void:
	for button in _buttons.values():
		_style(button, Color(0.10, 0.18, 0.30), Color(0.35, 0.65, 0.95))


static func _style(button: Button, base: Color, border: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(6)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(base.r * 1.6 + 0.04, base.g * 1.6 + 0.04, base.b * 1.6 + 0.04)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(base.r * 0.7, base.g * 0.7, base.b * 0.7)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.12, 0.14, 0.19, 0.85)
	disabled.border_color = Color(0.3, 0.34, 0.4, 0.6)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62))
