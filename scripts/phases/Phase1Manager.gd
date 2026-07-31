extends Node

var game_manager: Node
var phase_ui: Control
var canvas: Control
var drag_container: HBoxContainer

var router_nodes: Dictionary = {}  # value -> Control
var placed_nodes: Dictionary = {}  # value -> {node, pos, parent, direction}
var remaining_values: Array[int] = []
var tree_positions: Dictionary = {}  # value -> Vector2

var dragging_router: Control = null
var drag_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false

var error_label: Label = Label.new()
var line_container: Control

func _ready() -> void:
	game_manager = GameManager
	phase_ui = get_parent()
	setup_ui()
	initialize_phase()

func setup_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_left = 0.05
	bg.anchor_top = 0.1
	bg.anchor_right = 0.95
	bg.anchor_bottom = 0.92
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15)
	style.corner_radius = 8
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)

	var title: Label = Label.new()
	title.text = "FASE 1: Ricostruzione della Rete"
	title.anchor_left = 0.05
	title.anchor_top = 0.1
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	phase_ui.add_child(title)

	var hint: Label = Label.new()
	hint.text = "Trascina i router nella posizione corretta — minori a SINISTRA, maggiori a DESTRA"
	hint.anchor_left = 0.05
	hint.anchor_top = 0.14
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.7, 1))
	phase_ui.add_child(hint)

	error_label.anchor_left = 0.1
	error_label.anchor_top = 0.18
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	phase_ui.add_child(error_label)

	line_container = Control.new()
	line_container.anchor_left = 0.05
	line_container.anchor_top = 0.1
	line_container.anchor_right = 0.95
	line_container.anchor_bottom = 0.92
	line_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_ui.add_child(line_container)

	canvas = Control.new()
	canvas.anchor_left = 0.1
	canvas.anchor_top = 0.2
	canvas.anchor_right = 0.9
	canvas.anchor_bottom = 0.68
	phase_ui.add_child(canvas)

	drag_container = HBoxContainer.new()
	drag_container.anchor_left = 0.15
	drag_container.anchor_top = 0.72
	drag_container.anchor_right = 0.85
	drag_container.anchor_bottom = 0.86
	drag_container.add_theme_constant_override("separation", 25)
	drag_container.alignment = BoxContainer.ALIGNMENT_CENTER
	phase_ui.add_child(drag_container)

func initialize_phase() -> void:
	if not game_manager:
		return

	calculate_tree_positions()

	# Create root router
	var root_value: int = game_manager.phase1_values[0]
	var root_ui: Control = _create_router_ui(root_value, true)
	root_ui.position = tree_positions[root_value] - Vector2(30, 30)
	canvas.add_child(root_ui)
	placed_nodes[root_value] = {
		"node": root_ui,
		"pos": tree_positions[root_value],
		"parent": -1,
		"direction": ""
	}

	# Create draggable routers in the bottom bar
	for i in range(1, game_manager.phase1_values.size()):
		var val: int = game_manager.phase1_values[i]
		remaining_values.append(val)
		var router_ui: Control = _create_router_ui(val, false)
		drag_container.add_child(router_ui)
		router_nodes[val] = router_ui

func calculate_tree_positions() -> void:
	var center_x: float = canvas.size.x / 2.0
	# Level 0: root
	tree_positions[50] = Vector2(center_x, 40)
	# Level 1
	tree_positions[30] = Vector2(center_x - 100, 140)
	tree_positions[70] = Vector2(center_x + 100, 140)
	# Level 2
	tree_positions[20] = Vector2(center_x - 150, 240)
	tree_positions[40] = Vector2(center_x - 50, 240)
	tree_positions[60] = Vector2(center_x + 50, 240)
	tree_positions[80] = Vector2(center_x + 150, 240)

func _create_router_ui(value: int, is_root: bool) -> Control:
	var container: Control = Control.new()
	container.custom_minimum_size = Vector2(60, 60)
	container.mouse_filter = Control.MOUSE_FILTER_PASS

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://assets/generated/router_node_frame_0.png")
	sprite.centered = true
	sprite.scale = Vector2(1.5, 1.5) if is_root else Vector2(1.2, 1.2)
	sprite.position = Vector2(30, 30)
	container.add_child(sprite)

	var label: Label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(20, 16)
	container.add_child(label)

	container.set_meta("value", value)
	return container

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			for val in remaining_values:
				if val in router_nodes:
					var router: Control = router_nodes[val]
					if router.get_global_rect().has_point(event.global_position):
						dragging_router = router
						drag_offset = event.global_position - router.global_position
						is_dragging = true
						router.z_index = 100
						break
		else:
			if is_dragging and dragging_router:
				_on_router_dropped()
				dragging_router.z_index = 0
				dragging_router = null
				is_dragging = false

	if event is InputEventMouseMotion and is_dragging and dragging_router:
		dragging_router.global_position = event.global_position - drag_offset

func _draw_connection(from_pos: Vector2, to_pos: Vector2, color: Color = Color(0.3, 0.8, 1)) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from_pos)
	line.add_point(to_pos)
	line.width = 3.0
	line.default_color = color
	line.antialiased = true
	line_container.add_child(line)

func _find_nearest_parent(mouse_global: Vector2) -> Dictionary:
	var nearest: Dictionary = {"value": -1, "distance": 200.0}
	
	for placed_val in placed_nodes:
		var placed: Dictionary = placed_nodes[placed_val]
		var node_center: Vector2 = placed["pos"] + canvas.global_position
		var dist: float = node_center.distance_to(mouse_global)
		
		if mouse_global.y > node_center.y + 20 and dist < nearest["distance"]:
			nearest["value"] = placed_val
			nearest["distance"] = dist
	
	return nearest

func _on_router_dropped() -> void:
	if not dragging_router:
		return
	
	var value: int = dragging_router.get_meta("value", -1)
	var mouse_pos: Vector2 = get_global_mouse_position()
	var canvas_rect: Rect2 = canvas.get_global_rect()
	
	if not canvas_rect.has_point(mouse_pos):
		error_label.text = ""
		_animate_router_back(dragging_router)
		return
	
	var nearest: Dictionary = _find_nearest_parent(mouse_pos)
	if nearest["value"] == -1:
		error_label.text = "Posiziona il router sotto un router esistente!"
		_animate_router_back(dragging_router)
		return
	
	var parent_value: int = nearest["value"]
	var parent_center: Vector2 = placed_nodes[parent_value]["pos"] + canvas.global_position
	var direction: String = "left" if mouse_pos.x < parent_center.x else "right"
	
	# Check BST rules
	var is_valid: bool = false
	if direction == "left" and value < parent_value:
		is_valid = true
	elif direction == "right" and value > parent_value:
		is_valid = true
	
	if not is_valid:
		error_label.text = "Sbagliato! Valori minori a SINISTRA, maggiori a DESTRA"
		var flash: Tween = create_tween()
		flash.tween_property(dragging_router, "modulate", Color(1, 0.2, 0.2), 0.2)
		flash.tween_property(dragging_router, "modulate", Color.WHITE, 0.3)
		_animate_router_back(dragging_router)
		return
	
	# Check if position already taken
	for placed_val in placed_nodes:
		var p: Dictionary = placed_nodes[placed_val]
		if p["parent"] == parent_value and p["direction"] == direction:
			error_label.text = "Questa posizione è già occupata!"
			_animate_router_back(dragging_router)
			return
	
	_place_router(value, parent_value, direction)

func _place_router(value: int, parent_value: int, direction: String) -> void:
	error_label.text = ""
	dragging_router.reparent(canvas)
	
	var target_pos: Vector2 = tree_positions[value] - Vector2(30, 30)
	dragging_router.position = target_pos
	
	# Draw connection to parent
	var parent_pos: Vector2 = tree_positions[parent_value]
	var child_pos: Vector2 = tree_positions[value]
	_draw_connection(parent_pos, child_pos, Color(0, 1, 0.5))
	
	# Green flash
	var tween: Tween = create_tween()
	tween.tween_property(dragging_router, "modulate", Color(0, 1, 0.3), 0.15)
	tween.tween_property(dragging_router, "modulate", Color.WHITE, 0.3)
	
	placed_nodes[value] = {
		"node": dragging_router,
		"pos": tree_positions[value],
		"parent": parent_value,
		"direction": direction
	}
	remaining_values.erase(value)
	
	# Check if all placed
	if remaining_values.is_empty():
		await get_tree().create_timer(0.6).timeout
		_show_complete()

func _animate_router_back(router: Control) -> void:
	var target_global: Vector2 = drag_container.global_position + Vector2(50, 30)
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(router, "global_position", target_global, 0.4)
	
	await tween.finished
	if router.get_parent() != drag_container:
		router.reparent(drag_container)
	router.position = Vector2.ZERO

func _show_complete() -> void:
	for child in line_container.get_children():
		if child is Line2D:
			child.default_color = Color(0, 1, 0.3)
	
	var complete_label: Label = Label.new()
	complete_label.text = "✓ Rete ricostruita con successo!"
	complete_label.anchor_left = 0.3
	complete_label.anchor_top = 0.9
	complete_label.anchor_right = 0.7
	complete_label.add_theme_font_size_override("font_size", 22)
	complete_label.add_theme_color_override("font_color", Color(0, 1, 0.3))
	complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_ui.add_child(complete_label)

	var btn: Button = Button.new()
	btn.text = "Avanti →"
	btn.anchor_left = 0.42
	btn.anchor_top = 0.94
	btn.custom_minimum_size = Vector2(120, 40)
	btn.pressed.connect(func():
		if game_manager:
			game_manager.advance_phase()
	)
	phase_ui.add_child(btn)
