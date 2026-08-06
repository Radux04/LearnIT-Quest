class_name StateNode
extends Control

## Uno stato di un automa: un cerchio con l'etichetta dentro.
## Doppio cerchio se è uno stato finale, freccetta entrante se è iniziale.

signal clicked(node: StateNode)

const NODE_SIZE := Vector2(72.0, 72.0)

enum Mode { IDLE, ACTIVE, SUCCESS, ERROR, SELECTED, DIM }

const COLORS := {
	Mode.IDLE: Color(0.30, 0.55, 0.85),
	Mode.ACTIVE: Color(1.00, 0.80, 0.30),
	Mode.SUCCESS: Color(0.35, 1.00, 0.60),
	Mode.ERROR: Color(1.00, 0.40, 0.42),
	Mode.SELECTED: Color(0.75, 0.60, 1.00),
	Mode.DIM: Color(0.28, 0.34, 0.45),
}

var label_text: String = ""
var is_start: bool = false
var is_accepting: bool = false
var clickable: bool = false

var _mode: Mode = Mode.IDLE
var _pulse: float = 0.0
var _pulsing: bool = false


func _init(text: String = "") -> void:
	label_text = text
	custom_minimum_size = NODE_SIZE
	size = NODE_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	pivot_offset = NODE_SIZE * 0.5
	set_process(true)


func _process(delta: float) -> void:
	if _pulsing:
		_pulse = fmod(_pulse + delta * 3.0, TAU)
		queue_redraw()


func set_mode(mode: Mode) -> void:
	_mode = mode
	queue_redraw()


func get_mode() -> Mode:
	return _mode


func set_pulsing(active: bool) -> void:
	_pulsing = active
	if not active:
		_pulse = 0.0
	queue_redraw()


func set_label(text: String) -> void:
	label_text = text
	queue_redraw()


func center() -> Vector2:
	return position + NODE_SIZE * 0.5


func move_center_to(target: Vector2) -> void:
	position = target - NODE_SIZE * 0.5


func pop() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)


func shake() -> void:
	var origin: Vector2 = position
	var tween: Tween = create_tween()
	for i in range(4):
		tween.tween_property(self, "position", origin + Vector2(7.0 if i % 2 == 0 else -7.0, 0.0), 0.045)
	tween.tween_property(self, "position", origin, 0.045)


func _gui_input(event: InputEvent) -> void:
	if not clickable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
		accept_event()


func _draw() -> void:
	var middle: Vector2 = NODE_SIZE * 0.5
	var radius: float = 27.0
	var tint: Color = COLORS[_mode]
	var glow: float = 0.0
	if _pulsing:
		glow = 0.5 + 0.5 * sin(_pulse)

	# alone
	draw_circle(middle, radius + 8.0 + glow * 5.0, Color(tint.r, tint.g, tint.b, 0.16 + glow * 0.18))
	# corpo
	draw_circle(middle, radius, Color(0.05, 0.09, 0.16, 0.97))
	draw_arc(middle, radius, 0.0, TAU, 48, tint, 3.0, true)
	# doppio cerchio per gli stati finali
	if is_accepting:
		draw_arc(middle, radius - 6.0, 0.0, TAU, 48, tint, 2.0, true)
	# freccia entrante per lo stato iniziale
	if is_start:
		var tip: Vector2 = middle - Vector2(radius + 2.0, 0.0)
		var tail: Vector2 = tip - Vector2(18.0, 0.0)
		draw_line(tail, tip, tint, 2.5, true)
		draw_colored_polygon(PackedVector2Array([
			tip, tip + Vector2(-7.0, -5.0), tip + Vector2(-7.0, 5.0)]), tint)

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 19 if label_text.length() <= 3 else 14
	var width: float = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, middle + Vector2(-width * 0.5, font_size * 0.36),
		label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.93, 0.98, 1.0))
