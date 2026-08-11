class_name CodeConsole
extends Control

## La console in cui si scrivono i programmi WHILE.
## A sinistra l'editor, a destra lo stato delle variabili dopo l'esecuzione.

signal code_submitted(source: String)

const OK_COLOR := Color(0.35, 1.0, 0.6)
const ERR_COLOR := Color(1.0, 0.42, 0.45)
const INFO_COLOR := Color(0.6, 0.82, 1.0)

var editor: TextEdit
var run_button: Button
var clear_button: Button

var _status: Label
var _result_box: VBoxContainer


func _ready() -> void:
	var root: VBoxContainer = VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var title: Label = Label.new()
	title.text = "INTERPRETE WHILE"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	root.add_child(title)

	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var left: VBoxContainer = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.4
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	editor = TextEdit.new()
	editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.custom_minimum_size = Vector2(0.0, 110.0)
	editor.placeholder_text = "Scrivi qui il programma e premi Esegui (Ctrl+Invio)"
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
	SqlConsole._style_button(run_button, Color(0.1, 0.42, 0.3), Color(0.35, 1.0, 0.7))
	run_button.pressed.connect(_on_run_pressed)
	buttons.add_child(run_button)

	clear_button = Button.new()
	clear_button.text = "Pulisci"
	clear_button.custom_minimum_size = Vector2(110.0, 44.0)
	clear_button.add_theme_font_size_override("font_size", 16)
	clear_button.focus_mode = Control.FOCUS_NONE
	SqlConsole._style_button(clear_button, Color(0.16, 0.2, 0.32), Color(0.4, 0.55, 0.8))
	clear_button.pressed.connect(func() -> void:
		editor.text = ""
		editor.grab_focus())
	buttons.add_child(clear_button)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", INFO_COLOR)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(0.0, 54.0)
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

	var scroll: ScrollContainer = ScrollContainer.new()
	result_panel.add_child(scroll)

	_result_box = VBoxContainer.new()
	_result_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_box.add_theme_constant_override("separation", 4)
	scroll.add_child(_result_box)

	show_message("Scrivi un programma WHILE e premi Esegui.", INFO_COLOR)


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


func _on_run_pressed() -> void:
	var source: String = editor.text.strip_edges()
	if source == "":
		show_message("Scrivi un programma prima di eseguire.", INFO_COLOR)
		return
	code_submitted.emit(source)


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
	editor.set_caret_line(editor.get_line_count())


func show_message(text: String, color: Color) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func clear_result() -> void:
	for child in _result_box.get_children():
		_result_box.remove_child(child)
		child.queue_free()


## Mostra lo stato finale delle variabili dopo l'esecuzione.
func show_state(initial_state: Dictionary, result: Dictionary) -> void:
	clear_result()

	var caption: Label = Label.new()
	caption.text = "Stato iniziale → finale"
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color(0.55, 0.75, 0.95))
	_result_box.add_child(caption)

	var final_state: Dictionary = result.get("state", {})
	var names: Array = []
	for key in initial_state.keys():
		names.append(String(key))
	for key in final_state.keys():
		if not names.has(String(key)):
			names.append(String(key))
	names.sort()

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_result_box.add_child(grid)

	grid.add_child(_cell("var", Color(0.13, 0.34, 0.55)))
	grid.add_child(_cell("prima", Color(0.13, 0.34, 0.55)))
	grid.add_child(_cell("dopo", Color(0.13, 0.34, 0.55)))

	for var_name in names:
		var before: int = int(initial_state.get(var_name, 0))
		var after: int = int(final_state.get(var_name, 0))
		grid.add_child(_cell(String(var_name), Color(0.07, 0.11, 0.18, 0.9)))
		grid.add_child(_cell(str(before), Color(0.07, 0.11, 0.18, 0.9)))
		grid.add_child(_cell(str(after),
			Color(0.06, 0.18, 0.13, 0.95) if after != before else Color(0.07, 0.11, 0.18, 0.9)))

	if not bool(result.get("terminated", true)):
		var warning: Label = Label.new()
		warning.text = "⚠ non terminato: il programma cicla"
		warning.add_theme_font_size_override("font_size", 14)
		warning.add_theme_color_override("font_color", ERR_COLOR)
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_result_box.add_child(warning)
	else:
		var steps: Label = Label.new()
		steps.text = "passi eseguiti: %d" % int(result.get("steps", 0))
		steps.add_theme_font_size_override("font_size", 13)
		steps.add_theme_color_override("font_color", Color(0.6, 0.68, 0.8))
		_result_box.add_child(steps)


func _cell(text: String, background: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(72.0, 0.0)
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	panel.add_child(label)
	return panel
