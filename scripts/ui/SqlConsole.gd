class_name SqlConsole
extends Control

## La "mini finestra" in cui il giocatore scrive le query.
## Contiene l'editor di testo, i pulsanti e la griglia del risultato.

signal query_submitted(sql: String)

const OK_COLOR := Color(0.35, 1.0, 0.6)
const ERR_COLOR := Color(1.0, 0.42, 0.45)
const INFO_COLOR := Color(0.6, 0.82, 1.0)

var editor: TextEdit
var run_button: Button
var clear_button: Button

var _status: Label
var _result_box: VBoxContainer
var _result_scroll: ScrollContainer


func _ready() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title: Label = Label.new()
	title.text = "CONSOLE SQL"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	root.add_child(title)

	# Corpo su due colonne: a sinistra si scrive, a destra si legge il risultato.
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	editor = TextEdit.new()
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.custom_minimum_size = Vector2(0.0, 96.0)
	editor.placeholder_text = "Scrivi qui la query e premi Esegui (Ctrl+Invio)"
	editor.add_theme_font_size_override("font_size", 16)
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_style_editor()
	left.add_child(editor)

	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	left.add_child(buttons)

	run_button = Button.new()
	run_button.text = "▶  Esegui"
	run_button.custom_minimum_size = Vector2(150.0, 44.0)
	run_button.add_theme_font_size_override("font_size", 18)
	run_button.focus_mode = Control.FOCUS_NONE
	_style_button(run_button, Color(0.1, 0.42, 0.3), Color(0.35, 1.0, 0.7))
	run_button.pressed.connect(_on_run_pressed)
	buttons.add_child(run_button)

	clear_button = Button.new()
	clear_button.text = "Pulisci"
	clear_button.custom_minimum_size = Vector2(110.0, 44.0)
	clear_button.add_theme_font_size_override("font_size", 16)
	clear_button.focus_mode = Control.FOCUS_NONE
	_style_button(clear_button, Color(0.16, 0.2, 0.32), Color(0.4, 0.55, 0.8))
	clear_button.pressed.connect(func(): editor.text = ""; editor.grab_focus())
	buttons.add_child(clear_button)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", INFO_COLOR)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0.0, 52.0)
	left.add_child(_status)

	var result_panel: PanelContainer = PanelContainer.new()
	result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.06, 0.11, 0.9)
	panel_style.border_color = Color(0.16, 0.4, 0.65, 0.7)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(8)
	result_panel.add_theme_stylebox_override("panel", panel_style)
	body.add_child(result_panel)

	_result_scroll = ScrollContainer.new()
	result_panel.add_child(_result_scroll)

	_result_box = VBoxContainer.new()
	_result_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_box.add_theme_constant_override("separation", 4)
	_result_scroll.add_child(_result_box)

	show_message("Le tabelle sono a sinistra. Scrivi una query per iniziare.", INFO_COLOR)


func _style_editor() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.05, 0.1, 0.95)
	style.border_color = Color(0.25, 0.6, 0.95, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	editor.add_theme_stylebox_override("normal", style)
	var focus_style: StyleBoxFlat = style.duplicate()
	focus_style.border_color = Color(0.4, 0.9, 1.0)
	editor.add_theme_stylebox_override("focus", focus_style)
	editor.add_theme_color_override("font_color", Color(0.85, 1.0, 0.9))
	editor.add_theme_color_override("caret_color", Color(0.4, 1.0, 0.8))


static func _style_button(button: Button, base: Color, border: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(6)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(base.r * 1.5 + 0.05, base.g * 1.5 + 0.05, base.b * 1.5 + 0.05)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(base.r * 0.7, base.g * 0.7, base.b * 0.7)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.13, 0.15, 0.19, 0.8)
	disabled.border_color = Color(0.3, 0.34, 0.4, 0.6)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62))


func _on_run_pressed() -> void:
	var sql: String = editor.text.strip_edges()
	if sql == "":
		show_message("Scrivi una query prima di eseguire.", INFO_COLOR)
		return
	query_submitted.emit(sql)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			if not run_button.disabled:
				_on_run_pressed()
				get_viewport().set_input_as_handled()


func set_enabled(enabled: bool) -> void:
	run_button.disabled = not enabled
	editor.editable = enabled


func focus_editor() -> void:
	editor.grab_focus()


func prefill(text: String) -> void:
	editor.text = text
	editor.set_caret_column(text.length())


func show_message(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func clear_result() -> void:
	for child in _result_box.get_children():
		child.queue_free()


## Mostra il risultato di una SELECT come griglia.
func show_result(result: Dictionary) -> void:
	clear_result()
	var columns: Array = result.get("columns", [])
	var rows: Array = result.get("rows", [])

	if columns.is_empty():
		return

	var grid: GridContainer = GridContainer.new()
	grid.columns = columns.size()
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_result_box.add_child(grid)

	for column in columns:
		grid.add_child(_result_cell(String(column), Color(0.13, 0.34, 0.55), true))

	for i in range(rows.size()):
		for value in rows[i]:
			grid.add_child(_result_cell(SqlDatabase.format_value(value),
				Color(0.06, 0.1, 0.16, 0.9) if i % 2 == 0 else Color(0.08, 0.13, 0.2, 0.9), false))

	if rows.is_empty():
		var empty: Label = Label.new()
		empty.text = "(nessuna riga)"
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8))
		_result_box.add_child(empty)


func _result_cell(text: String, background: Color, header: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(84.0, 0.0)
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color",
		Color(0.85, 0.95, 1.0) if header else Color(0.9, 0.94, 1.0))
	panel.add_child(label)
	return panel
