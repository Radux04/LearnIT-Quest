class_name TreeNodeView
extends Control

## A single visual node of the BST.
## Handles its own visual state, hover, click and optional drag & drop.

@warning_ignore("unused_signal")
signal clicked(node: TreeNodeView)
## Emesso entrando e uscendo col mouse: serve alla vista per evidenziare i
## collegamenti di questo nodo.
@warning_ignore("unused_signal")
signal hovered(node: TreeNodeView, inside: bool)
signal drag_started(node: TreeNodeView)
signal dropped(node: TreeNodeView, global_pos: Vector2)

enum State { IDLE, ACTIVE, SUCCESS, ERROR, SCANNED, HACKED, GHOST }

const NODE_SIZE := Vector2(58.0, 58.0)
const NODE_TEXTURE := "res://assets/generated/node_core_frame_0.png"

const COLOR_IDLE := Color(0.35, 0.72, 1.0)
const COLOR_ACTIVE := Color(0.35, 0.95, 1.0)
const COLOR_SUCCESS := Color(0.25, 1.0, 0.6)
const COLOR_ERROR := Color(1.0, 0.28, 0.32)
const COLOR_SCANNED := Color(0.55, 1.0, 0.45)
const COLOR_HACKED := Color(1.0, 0.35, 0.25)
const COLOR_GHOST := Color(0.45, 0.6, 0.8)

var value: float = 0.0
var draggable: bool = false
var clickable: bool = false
var home_position: Vector2 = Vector2.ZERO
var state: State = State.IDLE

var _texture_rect: TextureRect
var _label: Label
var _badge: Label
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _hovered: bool = false
var _pulse_time: float = 0.0
var _pulsing: bool = false
var _badge_color: Color = Color(0.3, 1.0, 0.55)


func _init(node_value: float = 0.0) -> void:
	value = node_value


func _ready() -> void:
	custom_minimum_size = NODE_SIZE
	size = NODE_SIZE
	pivot_offset = NODE_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP

	_texture_rect = TextureRect.new()
	_texture_rect.texture = load(NODE_TEXTURE)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.size = NODE_SIZE
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)

	_label = Label.new()
	_label.text = BSTModel.fmt(value)
	_label.size = NODE_SIZE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.12))
	_label.add_theme_constant_override("outline_size", 6)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	_badge = Label.new()
	_badge.visible = false
	_badge.position = Vector2(NODE_SIZE.x - 24.0, -14.0)
	_badge.size = Vector2(36.0, 22.0)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.add_theme_font_size_override("font_size", 14)
	_badge.add_theme_color_override("font_color", Color(0.04, 0.09, 0.06))
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_badge)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	set_process(true)
	_apply_state()


func set_value(new_value: float) -> void:
	value = new_value
	if _label != null:
		_label.text = BSTModel.fmt(new_value)


func center() -> Vector2:
	return position + NODE_SIZE * 0.5


func set_center(p: Vector2) -> void:
	position = p - NODE_SIZE * 0.5


func set_state(new_state: State) -> void:
	state = new_state
	_apply_state()


func state_color() -> Color:
	match state:
		State.ACTIVE:
			return COLOR_ACTIVE
		State.SUCCESS:
			return COLOR_SUCCESS
		State.ERROR:
			return COLOR_ERROR
		State.SCANNED:
			return COLOR_SCANNED
		State.HACKED:
			return COLOR_HACKED
		State.GHOST:
			return COLOR_GHOST
	return COLOR_IDLE


func set_pulsing(enabled: bool) -> void:
	_pulsing = enabled
	if not enabled:
		scale = Vector2.ONE
	queue_redraw()


func show_badge(text: String, color: Color = Color(0.3, 1.0, 0.55)) -> void:
	_badge.text = text
	_badge.visible = true
	_badge_color = color
	_badge.add_theme_color_override("font_color",
		Color(0.04, 0.09, 0.06) if color.get_luminance() > 0.45 else Color(0.95, 0.98, 1.0))
	queue_redraw()


func hide_badge() -> void:
	_badge.visible = false


func _apply_state() -> void:
	if _texture_rect == null:
		return
	var c: Color = state_color()
	_texture_rect.modulate = Color(c.r * 0.9 + 0.1, c.g * 0.9 + 0.1, c.b * 0.9 + 0.1, 1.0)
	if state == State.GHOST:
		_texture_rect.modulate.a = 0.35
		_label.modulate.a = 0.4
	else:
		_label.modulate.a = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _pulsing:
		var s: float = 1.0 + sin(_pulse_time * 6.0) * 0.07
		scale = Vector2(s, s)
	if _pulsing or _hovered:
		queue_redraw()
	if _dragging:
		global_position = get_global_mouse_position() - _drag_offset


func _draw() -> void:
	var c: Color = state_color()
	var mid: Vector2 = NODE_SIZE * 0.5
	var base_radius: float = 30.0
	var glow: float = 0.18
	if _pulsing:
		glow = 0.18 + (sin(_pulse_time * 6.0) * 0.5 + 0.5) * 0.35
	if _hovered and clickable:
		glow += 0.2
	# Outer halo
	for i in range(4):
		var r: float = base_radius + float(i) * 3.0
		draw_circle(mid, r, Color(c.r, c.g, c.b, glow * (1.0 - float(i) / 5.0) * 0.6))
	# Ring
	draw_arc(mid, base_radius - 2.0, 0.0, TAU, 40, Color(c.r, c.g, c.b, 0.85), 2.0, true)
	if _badge.visible:
		var badge_center: Vector2 = Vector2(NODE_SIZE.x - 6.0, -3.0)
		draw_circle(badge_center, 17.0, Color(_badge_color.r, _badge_color.g, _badge_color.b, 0.25))
		draw_circle(badge_center, 14.0, Color(_badge_color.r, _badge_color.g, _badge_color.b, 0.97))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if draggable:
				_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
				z_index = 200
				drag_started.emit(self)
				accept_event()
			elif clickable:
				clicked.emit(self)
				accept_event()


func _input(event: InputEvent) -> void:
	# Il rilascio viene gestito qui (e non in _gui_input) così il drop funziona
	# anche se il cursore esce dal controllo durante un trascinamento veloce.
	if not _dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		z_index = 0
		dropped.emit(self, get_global_mouse_position())
		get_viewport().set_input_as_handled()


func is_dragging() -> bool:
	return _dragging


func return_home(duration: float = 0.25) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", home_position, duration)


func move_to_center(target_center: Vector2, duration: float = 0.3) -> Tween:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_center - NODE_SIZE * 0.5, duration)
	return tween


func flash(color: Color, duration: float = 0.35) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_texture_rect, "modulate", color, duration * 0.3)
	tween.tween_callback(_apply_state)


func shake(intensity: float = 8.0) -> void:
	var origin: Vector2 = position
	var tween: Tween = create_tween()
	for i in range(5):
		var off: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity * 0.4, intensity * 0.4))
		tween.tween_property(self, "position", origin + off, 0.045)
	tween.tween_property(self, "position", origin, 0.05)


func pop() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)


func _on_mouse_entered() -> void:
	_hovered = true
	if clickable or draggable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hovered.emit(self, true)
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	hovered.emit(self, false)
	queue_redraw()
