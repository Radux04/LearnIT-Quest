class_name TapeView
extends Control

## Il nastro di una macchina di Turing: una fila di celle con la testina al
## centro. Il nastro scorre sotto la testina, non viceversa: così la posizione
## interessante resta sempre visibile.

const CELL := Vector2(56.0, 62.0)
const VISIBLE_CELLS := 13

var machine: TuringMachine = null

var _layer: Control = null
var _offset: float = 0.0                # scorrimento animato in celle
var _flash: float = 0.0
var _flash_color: Color = Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer = Control.new()
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.draw.connect(_draw_tape)
	add_child(_layer)
	set_process(true)


func setup(model: TuringMachine) -> void:
	machine = model
	_offset = 0.0
	refresh()


func refresh() -> void:
	if _layer != null:
		_layer.queue_redraw()


func _process(delta: float) -> void:
	if not is_zero_approx(_offset):
		_offset = move_toward(_offset, 0.0, delta * 6.0)
		refresh()
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 2.0, 0.0)
		refresh()


## Chiamata dopo un passo: fa scorrere il nastro nella direzione opposta al moto.
func slide(direction: int) -> void:
	_offset = float(direction)
	refresh()


func flash(color: Color) -> void:
	_flash_color = color
	_flash = 1.0
	refresh()


func _draw_tape() -> void:
	if machine == null:
		return
	var font: Font = ThemeDB.fallback_font
	var middle_x: float = size.x * 0.5
	var top: float = size.y * 0.5 - CELL.y * 0.5
	var half: int = int(floor(float(VISIBLE_CELLS) * 0.5))

	for i in range(-half, half + 1):
		var cell_index: int = machine.head + i
		var x: float = middle_x + (float(i) - _offset) * CELL.x - CELL.x * 0.5
		var is_head: bool = (i == 0)
		var rect: Rect2 = Rect2(Vector2(x, top), CELL)

		var background: Color = Color(0.05, 0.09, 0.16, 0.95)
		var border: Color = Color(0.25, 0.45, 0.7, 0.8)
		if is_head:
			background = Color(0.10, 0.18, 0.28, 0.98)
			border = Color(1.0, 0.80, 0.30)
			if _flash > 0.0:
				border = _flash_color.lerp(border, 1.0 - _flash)
		_layer.draw_rect(rect, background, true)
		_layer.draw_rect(rect, border, false, 2.0)

		var symbol: String = machine.cell(cell_index)
		var width: float = font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		_layer.draw_string(font, Vector2(x + CELL.x * 0.5 - width * 0.5, top + CELL.y * 0.62),
			symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 24,
			Color(1.0, 0.92, 0.72) if is_head else Color(0.80, 0.88, 1.0))

	# testina
	var head_x: float = middle_x
	var head_y: float = top - 12.0
	_layer.draw_colored_polygon(PackedVector2Array([
		Vector2(head_x, head_y),
		Vector2(head_x - 12.0, head_y - 18.0),
		Vector2(head_x + 12.0, head_y - 18.0),
	]), Color(1.0, 0.80, 0.30))

	# stato corrente
	var state_text: String = "stato: %s" % machine.state
	var state_width: float = font.get_string_size(state_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	_layer.draw_string(font, Vector2(middle_x - state_width * 0.5, head_y - 30.0),
		state_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.55, 0.95, 1.0))
