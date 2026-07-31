extends Node

var game_manager
var phase_ui: Control
var canvas: Control

var current_packet_index: int = 0
var packets_to_route: Array[int] = [25, 85, 35, 65, 45]
var correct_packets: int = 0

var phase_label: Label = Label.new()
var status_label: Label = Label.new()
var instruction_label: Label = Label.new()
var error_label: Label = Label.new()

var root_routers: Dictionary = {}
var current_path: Array[int] = []

func _ready() -> void:
	game_manager = GameManager
	phase_ui = get_parent()
	setup_phase_2_ui()
	initialize_phase_2()

func setup_phase_2_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_left = 0.1
	bg.anchor_top = 0.15
	bg.anchor_right = 0.9
	bg.anchor_bottom = 0.88
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.2)
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)
	
	phase_label.text = "Fase 2: Instrada i pacchetti"
	phase_label.anchor_left = 0.1
	phase_label.anchor_top = 0.15
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	phase_ui.add_child(phase_label)
	
	status_label.text = "Pacchetto 1/5"
	status_label.anchor_left = 0.1
	status_label.anchor_top = 0.19
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7))
	phase_ui.add_child(status_label)
	
	instruction_label.text = ""
	instruction_label.anchor_left = 0.1
	instruction_label.anchor_top = 0.22
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	phase_ui.add_child(instruction_label)
	
	error_label.anchor_left = 0.1
	error_label.anchor_top = 0.25
	error_label.add_theme_font_size_override("font_size", 12)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(error_label)
	
	canvas = Control.new()
	canvas.anchor_left = 0.15
	canvas.anchor_top = 0.3
	canvas.anchor_right = 0.85
	canvas.anchor_bottom = 0.8
	phase_ui.add_child(canvas)

func initialize_phase_2() -> void:
	if not game_manager or not game_manager.bst_root:
		return
	
	_draw_bst_tree()
	_start_next_packet()

func _draw_bst_tree() -> void:
	_draw_node_recursive(game_manager.bst_root, canvas.size.x / 2, 40, canvas.size.x / 4)

func _draw_node_recursive(node, x: float, y: float, offset: float) -> void:
	if not node:
		return
	
	var node_container: Control = Control.new()
	node_container.position = Vector2(x - 20, y)
	node_container.custom_minimum_size = Vector2(40, 40)
	canvas.add_child(node_container)
	
	root_routers[node.value] = Vector2(x, y + 20)
	
	var node_visual: Panel = Panel.new()
	node_visual.anchor_right = 1.0
	node_visual.anchor_bottom = 1.0
	var node_style: StyleBoxFlat = StyleBoxFlat.new()
	node_style.bg_color = Color(0, 0.5, 1, 0.7)
	node_visual.add_theme_stylebox_override("panel", node_style)
	node_container.add_child(node_visual)
	
	var label: Label = Label.new()
	label.text = str(node.value)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -8
	label.offset_top = -10
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	node_container.add_child(label)
	
	if node.left:
		_draw_connection(Vector2(x, y + 20), Vector2(x - offset, y + 80), Color.BLUE)
		_draw_node_recursive(node.left, x - offset, y + 100, offset / 2)
	
	if node.right:
		_draw_connection(Vector2(x, y + 20), Vector2(x + offset, y + 80), Color.GREEN)
		_draw_node_recursive(node.right, x + offset, y + 100, offset / 2)

func _draw_connection(from: Vector2, to: Vector2, color: Color) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = color
	canvas.add_child(line)

func _start_next_packet() -> void:
	if current_packet_index >= packets_to_route.size():
		_on_phase_2_complete()
		return
	
	var target_value: int = packets_to_route[current_packet_index]
	current_path.clear()
	
	instruction_label.text = "Dove devi andare per trovare il valore %d?" % target_value
	status_label.text = "Pacchetto %d/%d - Ricercare: %d" % [current_packet_index + 1, packets_to_route.size(), target_value]
	error_label.text = ""
	
	_show_routing_buttons(game_manager.bst_root)

func _show_routing_buttons(current_node) -> void:
	for child in phase_ui.get_children():
		if child.name in ["LeftBtn", "RightBtn"]:
			child.queue_free()
	
	var target_value: int = packets_to_route[current_packet_index]
	
	var left_btn: Button = Button.new()
	left_btn.text = "Vai SINISTRA"
	left_btn.name = "LeftBtn"
	left_btn.anchor_left = 0.3
	left_btn.anchor_top = 0.85
	left_btn.custom_minimum_size = Vector2(120, 40)
	left_btn.pressed.connect(func(): _handle_direction(current_node, "left", target_value))
	phase_ui.add_child(left_btn)
	
	var right_btn: Button = Button.new()
	right_btn.text = "Vai DESTRA"
	right_btn.name = "RightBtn"
	right_btn.anchor_left = 0.6
	right_btn.anchor_top = 0.85
	right_btn.custom_minimum_size = Vector2(120, 40)
	right_btn.pressed.connect(func(): _handle_direction(current_node, "right", target_value))
	phase_ui.add_child(right_btn)

func _handle_direction(current_node, direction: String, target_value: int) -> void:
	var next_node = null
	
	if direction == "left":
		next_node = current_node.left
		current_path.append(0)
	else:
		next_node = current_node.right
		current_path.append(1)
	
	if next_node == null:
		error_label.text = "Sbagliato! Tempo -10 sec"
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		game_manager.time_remaining -= 10.0
		await get_tree().create_timer(1.0).timeout
		_start_next_packet()
		return
	
	if next_node.value == target_value:
		error_label.text = "Corretto! Pacchetto consegnato!"
		error_label.add_theme_color_override("font_color", Color(0, 1, 0))
		correct_packets += 1
		await get_tree().create_timer(1.0).timeout
		current_packet_index += 1
		_start_next_packet()
	else:
		_show_routing_buttons(next_node)

func _on_phase_2_complete() -> void:
	for child in phase_ui.get_children():
		if child.name in ["LeftBtn", "RightBtn"]:
			child.queue_free()
	
	var complete_label: Label = Label.new()
	complete_label.text = "Fase 2 completata! %d/%d pacchetti consegnati" % [correct_packets, packets_to_route.size()]
	complete_label.anchor_left = 0.15
	complete_label.anchor_top = 0.88
	complete_label.add_theme_font_size_override("font_size", 14)
	complete_label.add_theme_color_override("font_color", Color(0, 1, 0))
	phase_ui.add_child(complete_label)
	
	var next_btn: Button = Button.new()
	next_btn.text = "Avanti"
	next_btn.anchor_left = 0.45
	next_btn.anchor_top = 0.93
	next_btn.custom_minimum_size = Vector2(80, 35)
	next_btn.pressed.connect(func(): if game_manager: game_manager.advance_phase())
	phase_ui.add_child(next_btn)
