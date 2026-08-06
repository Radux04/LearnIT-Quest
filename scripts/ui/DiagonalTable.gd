class_name DiagonalTable
extends Control

## La tabella dell'argomento diagonale: le righe sono macchine, le colonne
## sono input. Ogni cella dice se quella macchina si ferma su quell'input.
##
## Serve alla Fase 4: il giocatore costruisce la macchina D leggendo la
## diagonale e invertendola.

signal cell_clicked(row: int, column: int)

const HALTS := "SI"
const LOOPS := "NO"

var rows: Array[String] = []
var columns: Array[String] = []
var values: Array = []                   # values[riga][colonna] -> bool (si ferma)

var _grid: GridContainer = null
var _cells: Dictionary = {}              # "riga|colonna" -> Button
var _clickable: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(row_names: Array, column_names: Array, table: Array) -> void:
	for child in get_children():
		child.queue_free()
	_cells.clear()
	rows.clear()
	columns.clear()
	for row_name in row_names:
		rows.append(String(row_name))
	for column_name in column_names:
		columns.append(String(column_name))
	values = table.duplicate(true)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_grid = GridContainer.new()
	_grid.columns = columns.size() + 1
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	center.add_child(_grid)

	_grid.add_child(_header("M \\ w"))
	for column_name in columns:
		_grid.add_child(_header(column_name))

	for r in range(rows.size()):
		_grid.add_child(_header(rows[r]))
		for c in range(columns.size()):
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(74.0, 44.0)
			button.add_theme_font_size_override("font_size", 17)
			button.focus_mode = Control.FOCUS_NONE
			var row_index: int = r
			var column_index: int = c
			button.pressed.connect(func() -> void:
				if _clickable:
					cell_clicked.emit(row_index, column_index))
			_grid.add_child(button)
			_cells["%d|%d" % [r, c]] = button
			_refresh_cell(r, c)


func _header(text: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.22, 0.36, 0.95)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(74.0, 40.0)
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0))
	panel.add_child(label)
	return panel


func value_at(row: int, column: int) -> bool:
	return bool(values[row][column])


func set_value(row: int, column: int, halts: bool) -> void:
	values[row][column] = halts
	_refresh_cell(row, column)


func set_clickable(enabled: bool) -> void:
	_clickable = enabled


## Evidenzia la diagonale: è la sequenza che il giocatore deve invertire.
func mark_diagonal(color: Color) -> void:
	for i in range(mini(rows.size(), columns.size())):
		mark(i, i, color)


func mark(row: int, column: int, color: Color) -> void:
	var key: String = "%d|%d" % [row, column]
	if not _cells.has(key):
		return
	_apply_style(_cells[key], color.darkened(0.65), color)


func _refresh_cell(row: int, column: int) -> void:
	var key: String = "%d|%d" % [row, column]
	if not _cells.has(key):
		return
	var button: Button = _cells[key]
	var halts: bool = value_at(row, column)
	button.text = HALTS if halts else LOOPS
	_apply_style(button,
		Color(0.06, 0.20, 0.14) if halts else Color(0.22, 0.08, 0.10),
		Color(0.30, 0.80, 0.55) if halts else Color(0.90, 0.40, 0.42))


static func _apply_style(button: Button, base: Color, border: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(4)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(base.r * 1.7 + 0.05, base.g * 1.7 + 0.05, base.b * 1.7 + 0.05)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color(0.93, 0.98, 1.0))
