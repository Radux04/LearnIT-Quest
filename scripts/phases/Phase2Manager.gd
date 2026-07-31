extends Node

var game_manager: Node
var phase_ui: Control
var canvas: Control
var packet_anim_container: Control

var current_packet_index: int = 0
var packets_to_route: Array[int] = [30, 70, 20, 80, 40]  # valori esistenti nel BST!
var correct_packets: int = 0

var phase_label: Label = Label.new()
var status_label: Label = Label.new()
var instruction_label: Label = Label.new()
var error_label: Label = Label.new()

var node_positions: Dictionary = {}  # value -> Vector2 (global)
var current_search_value: int = 0
var current_node_value: int = 0
var is_waiting: bool = false

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
	bg.anchor_bottom = 0.9
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15)
	style.corner_radius = 8
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)

	phase_label.text = "FASE 2: Instradamento dei Pacchetti"
	phase_label.anchor_left = 0.05
	phase_label.anchor_top = 0.1
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	phase_ui.add_child(phase_label)

	status_label.text = "Pacchetto 1/5"
	status_label.anchor_left = 0.05
	status_label.anchor_top = 0.14
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1))
	phase_ui.add_child(status_label)

	instruction_label.text = ""
	instruction_label.anchor_left = 0.05
	instruction_label.anchor_top = 0.18
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	phase_ui.add_child(instruction_label)

	error_label.anchor_left = 0.05
	error_label.anchor_top = 0.22
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(error_label)

	packet_anim_container = Control.new()
	packet_anim_container.anchor_left = 0.05
	packet_anim_container.anchor_top = 0.1
	packet_anim_container.anchor_right = 0.95
	packet_anim_container.anchor_bottom = 0.9
	packet_anim_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_ui.add_child(packet_anim_container)

	canvas = Control.new()
	canvas.anchor_left = 0.1
	canvas.anchor_top = 0.22
	canvas.anchor_right = 0.9
	canvas.anchor_bottom = 0.72
	phase_ui.add_child(canvas)

func initialize_phase() -> void:
	if not game_manager or not game_manager.bst_root:
		return
	
	_draw_bst_tree()
	_start_next_packet()

func _draw_bst_tree() -> void:
	_draw_node_recursive(game_manager.bst_root, canvas.size.x / 2, 50, canvas.size.x / 4)

func _draw_node_recursive(node, x: float, y: float, offset: float) -> void:
	if not node:
		return
	
	var node_style: StyleBoxFlat = StyleBoxFlat.new()
	node_style.bg_color = Color(0, 0.5, 1, 0.8)
	node_style.corner_radius = 4
	
	var node_panel: Panel = Panel.new()
	node_panel.position = Vector2(x - 22, y)
	node_panel.custom_minimum_size = Vector2(44, 44)
	node_panel.add_theme_stylebox_override("panel", node_style)
	canvas.add_child(node_panel)
	
	node_positions[node.value] = node_panel.position + Vector2(22, 22) + canvas.global_position
	
	var label: Label = Label.new()
	label.text = str(node.value)
	label.position = Vector2(x - 8, y + 12)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(label)
	
	if node.left:
		_draw_connection(Vector2(x, y + 22), Vector2(x - offset, y + 100), Color(0.3, 0.7, 1))
		_draw_node_recursive(node.left, x - offset, y + 120, offset / 2)
	
	if node.right:
		_draw_connection(Vector2(x, y + 22), Vector2(x + offset, y + 100), Color(0.3, 0.7, 1))
		_draw_node_recursive(node.right, x + offset, y + 120, offset / 2)

func _draw_connection(from: Vector2, to: Vector2, color: Color) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 3.0
	line.default_color = color
	line.antialiased = true
	canvas.add_child(line)

func _start_next_packet() -> void:
	if current_packet_index >= packets_to_route.size():
		_on_phase_2_complete()
		return
	
	is_waiting = false
	current_search_value = packets_to_route[current_packet_index]
	current_node_value = 50  # start from root
	
	instruction_label.text = "Dove deve andare il pacchetto per il valore %d?" % current_search_value
	status_label.text = "Pacchetto %d/%d — Destinazione: %d" % [current_packet_index + 1, packets_to_route.size(), current_search_value]
	error_label.text = ""
	
	# Show which node we're currently at
	_highlight_node(current_node_value, Color(0.3, 1, 0.8))
	_show_routing_buttons()

func _get_next_value_from_bst(current_val: int, direction: String) -> int:
	var result: Array = []
	_find_node_path(game_manager.bst_root, current_val, result)
	var start_node = result[0] if result.size() > 0 else null
	if not start_node:
		return -1
	if direction == "left" and start_node.left:
		return start_node.left.value
	elif direction == "right" and start_node.right:
		return start_node.right.value
	return -1

func _find_node_path(node, target_val: int, path: Array) -> bool:
	if not node:
		return false
	if node.value == target_val:
		path.append(node)
		return true
	if _find_node_path(node.left, target_val, path) or _find_node_path(node.right, target_val, path):
		path.push_front(node)
		return true
	return false

func _find_node_by_value(node, val: int):
	if not node:
		return null
	if node.value == val:
		return node
	var left_result = _find_node_by_value(node.left, val)
	if left_result:
		return left_result
	return _find_node_by_value(node.right, val)

func _highlight_node(value: int, color: Color) -> void:
	for child in canvas.get_children():
		if child is Panel:
			var panel_label: Label = null
			for c in canvas.get_children():
				if c is Label and c.text == str(value):
					panel_label = c
					break
			var panel_pos: Vector2 = child.position
			var node_entry = node_positions.get(value, Vector2.ZERO) - canvas.global_position
			if (panel_pos - (node_entry - Vector2(22, 22))).length() < 10:
				var s: StyleBoxFlat = child.get_theme_stylebox("panel")
				if s:
					s.bg_color = color

func _show_routing_buttons() -> void:
	for child in phase_ui.get_children():
		if child.name in ["LeftBtnP2", "RightBtnP2"]:
			child.queue_free()
	
	var left_btn: Button = Button.new()
	left_btn.text = "◀ Vai a SINISTRA"
	left_btn.name = "LeftBtnP2"
	left_btn.anchor_left = 0.25
	left_btn.anchor_top = 0.84
	left_btn.custom_minimum_size = Vector2(160, 45)
	left_btn.pressed.connect(_on_left_pressed)
	phase_ui.add_child(left_btn)
	
	var right_btn: Button = Button.new()
	right_btn.text = "Vai a DESTRA ▶"
	right_btn.name = "RightBtnP2"
	right_btn.anchor_left = 0.55
	right_btn.anchor_top = 0.84
	right_btn.custom_minimum_size = Vector2(160, 45)
	right_btn.pressed.connect(_on_right_pressed)
	phase_ui.add_child(right_btn)

func _on_left_pressed() -> void:
	if is_waiting:
		return
	is_waiting = true
	
	var current_bst_node = _find_node_by_value(game_manager.bst_root, current_node_value)
	var next_node = current_bst_node.left if current_bst_node else null
	
	if not next_node:
		_handle_wrong_direction()
		return
	
	# Animate packet to next node
	await _animate_packet(node_positions[current_node_value], node_positions[next_node.value])
	
	if next_node.value == current_search_value:
		_handle_correct_arrival(next_node.value)
	else:
		current_node_value = next_node.value
		_highlight_node(current_node_value, Color(0.3, 1, 0.8))
		is_waiting = false
		_show_routing_buttons()

func _on_right_pressed() -> void:
	if is_waiting:
		return
	is_waiting = true
	
	var current_bst_node = _find_node_by_value(game_manager.bst_root, current_node_value)
	var next_node = current_bst_node.right if current_bst_node else null
	
	if not next_node:
		_handle_wrong_direction()
		return
	
	await _animate_packet(node_positions[current_node_value], node_positions[next_node.value])
	
	if next_node.value == current_search_value:
		_handle_correct_arrival(next_node.value)
	else:
		current_node_value = next_node.value
		_highlight_node(current_node_value, Color(0.3, 1, 0.8))
		is_waiting = false
		_show_routing_buttons()

func _handle_wrong_direction() -> void:
	error_label.text = "Nessun router in quella direzione! Il pacchetto è perso! Tempo -10 sec"
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	game_manager.time_remaining -= 10.0
	await get_tree().create_timer(1.5).timeout
	current_packet_index += 1
	_start_next_packet()

func _handle_correct_arrival(value: int) -> void:
	error_label.text = "✓ Pacchetto consegnato a router %d!" % value
	error_label.add_theme_color_override("font_color", Color(0, 1, 0))
	correct_packets += 1
	
	# Flash green on the node
	var node_pos: Vector2 = node_positions.get(value, Vector2.ZERO)
	VisualEffects.play_correct_feedback(canvas, node_pos - canvas.global_position)
	
	await get_tree().create_timer(1.0).timeout
	current_packet_index += 1
	_start_next_packet()

func _animate_packet(from_pos: Vector2, to_pos: Vector2) -> void:
	var packet: Sprite2D = Sprite2D.new()
	packet.texture = load("res://assets/generated/network_packet_frame_0.png")
	packet.centered = true
	packet.scale = Vector2(0.8, 0.8)
	packet.global_position = from_pos
	packet_anim_container.add_child(packet)
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(packet, "global_position", to_pos, 0.5)
	
	# Glow effect
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = load("res://assets/generated/packet_glow.png")
	glow.centered = true
	glow.scale = Vector2(0.5, 0.5)
	glow.modulate = Color(0.3, 0.8, 1, 0.6)
	glow.global_position = from_pos
	packet_anim_container.add_child(glow)
	
	var glow_tween: Tween = create_tween()
	glow_tween.set_trans(Tween.TRANS_SINE)
	glow_tween.set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(glow, "global_position", to_pos, 0.5)
	
	await tween.finished
	packet.queue_free()
	glow.queue_free()

func _on_phase_2_complete() -> void:
	for child in phase_ui.get_children():
		if child.name in ["LeftBtnP2", "RightBtnP2"]:
			child.queue_free()
	
	var complete_label: Label = Label.new()
	complete_label.text = "✓ Fase 2 completata! %d/%d pacchetti consegnati" % [correct_packets, packets_to_route.size()]
	complete_label.anchor_left = 0.15
	complete_label.anchor_top = 0.88
	complete_label.add_theme_font_size_override("font_size", 18)
	complete_label.add_theme_color_override("font_color", Color(0, 1, 0))
	phase_ui.add_child(complete_label)

	var next_btn: Button = Button.new()
	next_btn.text = "Avanti →"
	next_btn.anchor_left = 0.42
	next_btn.anchor_top = 0.94
	next_btn.custom_minimum_size = Vector2(120, 40)
	next_btn.pressed.connect(func(): if game_manager: game_manager.advance_phase())
	phase_ui.add_child(next_btn)
