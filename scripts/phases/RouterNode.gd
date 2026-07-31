extends Control

class_name RouterNode

var value: int = 0
var is_root: bool = false
var is_placed: bool = false
var parent_node: RouterNode = null
var left_child: RouterNode = null
var right_child: RouterNode = null

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = Sprite2D.new()
@onready var label: Label = Label.new()
@onready var highlight: Node2D = Node2D.new()

var original_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(80, 80)
	
	# Sprite del router
	sprite.texture = load("res://assets/generated/router_node_frame_0.png")
	sprite.centered = true
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)
	
	# Label con il valore
	label.text = str(value)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -15
	label.offset_top = -10
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if is_placed and is_root:
		return  # La radice non si può trascinare
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func set_value(val: int) -> void:
	value = val
	label.text = str(value)

func set_as_root(val: bool) -> void:
	is_root = val
	is_placed = val

func set_highlight_color(color: Color) -> void:
	# Cambia il colore della highlights quando è corretto/scorretto
	modulate = Color.WHITE.lerp(color, 0.3)

func reset_highlight() -> void:
	modulate = Color.WHITE
