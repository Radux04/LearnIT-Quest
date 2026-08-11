class_name CodeView
extends Control

## Mostra uno spezzone di codice Java con i numeri di riga, e permette di
## cliccare le righe. È la vista della revisione del codice: il gesto del
## revisore è indicare la riga che non va, e qui è esattamente quello.

signal line_clicked(index: int)

enum Mark { IDLE, SELECTED, CORRECT, WRONG, DIM }

const COLORS := {
	Mark.IDLE: [Color(0.05, 0.07, 0.12, 0.0), Color(0.30, 0.40, 0.55, 0.0)],
	Mark.SELECTED: [Color(0.18, 0.14, 0.34, 0.95), Color(0.70, 0.55, 1.00, 0.95)],
	Mark.CORRECT: [Color(0.05, 0.20, 0.13, 0.95), Color(0.35, 1.00, 0.60, 0.95)],
	Mark.WRONG: [Color(0.24, 0.07, 0.10, 0.95), Color(1.00, 0.40, 0.42, 0.95)],
	Mark.DIM: [Color(0.05, 0.07, 0.12, 0.0), Color(0.30, 0.40, 0.55, 0.0)],
}

var lines: PackedStringArray = PackedStringArray()
var clickable: bool = false

var _rows: Array[Button] = []
var _marks: Array = []
var _box: VBoxContainer = null
var _title: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.09, 0.95)
	style.border_color = Color(0.28, 0.34, 0.62, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", Color(0.62, 0.82, 1.0))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 1)
	scroll.add_child(_box)


func setup(code: String, header: String = "") -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	_rows.clear()
	_marks.clear()

	_title.text = header
	lines = code.split("\n")

	for index in range(lines.size()):
		var row: Button = Button.new()
		row.text = "%3d   %s" % [index + 1, lines[index]]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.focus_mode = Control.FOCUS_NONE
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		row.custom_minimum_size = Vector2(0.0, 24.0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var line_index: int = index
		row.pressed.connect(func() -> void:
			if clickable:
				line_clicked.emit(line_index))
		_box.add_child(row)
		_rows.append(row)
		_marks.append(Mark.IDLE)
		_apply(index)


func set_header(text: String) -> void:
	_title.text = text


func mark(index: int, value: Mark) -> void:
	if index < 0 or index >= _marks.size():
		return
	_marks[index] = value
	_apply(index)


func mark_of(index: int) -> Mark:
	if index < 0 or index >= _marks.size():
		return Mark.IDLE
	return _marks[index]


func clear_marks() -> void:
	for index in range(_marks.size()):
		_marks[index] = Mark.IDLE
		_apply(index)


func selected_lines() -> Array[int]:
	var out: Array[int] = []
	for index in range(_marks.size()):
		if _marks[index] == Mark.SELECTED:
			out.append(index)
	return out


func toggle(index: int) -> void:
	mark(index, Mark.IDLE if mark_of(index) == Mark.SELECTED else Mark.SELECTED)


func shake_row(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row: Button = _rows[index]
	var origin: Vector2 = row.position
	var tween: Tween = row.create_tween()
	for i in range(4):
		tween.tween_property(row, "position", origin + Vector2(6.0 if i % 2 == 0 else -6.0, 0.0), 0.04)
	tween.tween_property(row, "position", origin, 0.04)


func _apply(index: int) -> void:
	var row: Button = _rows[index]
	var pair: Array = COLORS[_marks[index]]
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = pair[0]
	normal.border_color = pair[1]
	normal.set_border_width_all(2 if pair[1].a > 0.0 else 0)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	var hover: StyleBoxFlat = normal.duplicate()
	if _marks[index] == Mark.IDLE:
		hover.bg_color = Color(0.12, 0.16, 0.28, 0.8)
	row.add_theme_stylebox_override("normal", normal)
	row.add_theme_stylebox_override("hover", hover)
	row.add_theme_stylebox_override("pressed", hover)
