class_name SqlTableView
extends PanelContainer

## Mostra una tabella del database come griglia: intestazione con nome e tipo
## delle colonne, poi una riga per record. Evidenzia in verde le righe nuove
## o modificate e in rosso il titolo quando delle righe vengono eliminate.

const HEADER_COLOR := Color(0.16, 0.38, 0.62)
const ROW_A := Color(0.07, 0.11, 0.18, 0.9)
const ROW_B := Color(0.09, 0.14, 0.22, 0.9)
const FLASH_NEW := Color(0.2, 0.9, 0.5)
const FLASH_GONE := Color(1.0, 0.35, 0.35)

var table_name: String = ""

var _title: Label
var _grid: GridContainer
var _box: VBoxContainer
var _previous_rows: Array = []
var _row_panels: Array = []          # [Array[PanelContainer]] una riga per record


func _init(source_table: String = "") -> void:
	table_name = source_table


func _ready() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.13, 0.92)
	style.border_color = Color(0.18, 0.45, 0.72, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 17)
	_title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	_box.add_child(_title)

	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	_box.add_child(_grid)


## Ridisegna la tabella leggendola dal database.
func refresh(db: SqlDatabase, animate: bool = true) -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		child.queue_free()
	_row_panels.clear()

	if not db.has_table(table_name):
		_title.text = "%s  (tabella eliminata)" % table_name
		_title.add_theme_color_override("font_color", FLASH_GONE)
		_previous_rows = []
		return

	var table: Dictionary = db.get_table(table_name)
	var columns: Array = table["columns"]
	var rows: Array = table["rows"]

	_title.text = "%s   ·   %d riga/e" % [String(table["name"]), rows.size()]
	_title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	_grid.columns = maxi(columns.size(), 1)

	for column in columns:
		_grid.add_child(_make_cell("%s\n%s" % [String(column["name"]), String(column["type"])],
			HEADER_COLOR, true))

	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var is_new: bool = animate and not _contains_row(_previous_rows, row)
		var cells: Array = []
		for column in columns:
			var value: Variant = row.get(String(column["name"]))
			var cell: PanelContainer = _make_cell(SqlDatabase.format_value(value),
				ROW_A if i % 2 == 0 else ROW_B, false)
			cells.append(cell)
			_grid.add_child(cell)
		_row_panels.append(cells)
		if is_new:
			_flash_row(cells, FLASH_NEW)

	if animate and rows.size() < _previous_rows.size():
		_flash_title(FLASH_GONE)

	_previous_rows = rows.duplicate(true)


func _contains_row(collection: Array, row: Dictionary) -> bool:
	for candidate in collection:
		if SqlDatabase._same_row(candidate, row):
			return true
	return false


func _make_cell(text: String, background: Color, header: bool) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.set_content_margin_all(5)
	if header:
		style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(96.0, 0.0)

	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13 if header else 14)
	label.add_theme_color_override("font_color",
		Color(0.85, 0.95, 1.0) if header else Color(0.92, 0.95, 1.0))
	panel.add_child(label)
	return panel


func _flash_row(cells: Array, color: Color) -> void:
	for cell in cells:
		var style: StyleBoxFlat = cell.get_theme_stylebox("panel")
		if style is StyleBoxFlat:
			var original: Color = style.bg_color
			style.bg_color = color
			var tween: Tween = create_tween()
			tween.tween_property(style, "bg_color", original, 1.1)


func _flash_title(color: Color) -> void:
	_title.add_theme_color_override("font_color", color)
	var tween: Tween = create_tween()
	tween.tween_interval(0.9)
	tween.tween_callback(func(): _title.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0)))
