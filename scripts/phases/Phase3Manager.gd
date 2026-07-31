extends Node

var game_manager
var phase_ui: Control
var canvas: Control

var current_traversal_index: int = 0
var traversal_types: Array[String] = ["Preorder", "Inorder", "Postorder", "BFS"]
var current_traversal_type: String = ""
var expected_sequence: Array[int] = []
var clicked_sequence: Array[int] = []

var node_positions: Dictionary = {}
var node_visuals: Dictionary = {}

var phase_label: Label = Label.new()
var instruction_label: Label = Label.new()
var error_label: Label = Label.new()

func _ready() -> void:
	game_manager = GameManager
	phase_ui = get_parent()
	setup_phase_3_ui()
	initialize_phase_3()

func setup_phase_3_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_left = 0.1
	bg.anchor_top = 0.15
	bg.anchor_right = 0.9
	bg.anchor_bottom = 0.88
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.2)
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)
	
	phase_label.text = "Fase 3: Scansione della Rete - Scegli i router nell'ordine corretto"
	phase_label.anchor_left = 0.1
	phase_label.anchor_top = 0.15
	phase_label.add_theme_font_size_override("font_size", 16)
	phase_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	phase_ui.add_child(phase_label)
	
	instruction_label.text = "Clicca i router nell'ordine di visita che ti viene indicato"
	instruction_label.anchor_left = 0.1
	instruction_label.anchor_top = 0.2
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	phase_ui.add_child(instruction_label)
	
	error_label.anchor_left = 0.1
	error_label.anchor_top = 0.24
	error_label.add_theme_font_size_override("font_size", 12)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(error_label)
	
	canvas = Control.new()
	canvas.anchor_left = 0.15
	canvas.anchor_top = 0.3
	canvas.anchor_right = 0.85
	canvas.anchor_bottom = 0.8
	phase_ui.add_child(canvas)

func initialize_phase_3() -> void:
	if not game_manager or not game_manager.bst_root:
		return
	
	_draw_bst_interactive()
	_start_next_traversal()

func _draw_bst_interactive() -> void:
	_draw_node_recursive(game_manager.bst_root, canvas.size.x / 2, 40, canvas.size.x / 4)

func _draw_node_recursive(node, x: float, y: float, offset: float) -> void:
	if not node:
		return
	
	var node_container: Control = Control.new()
	node_container.position = Vector2(x - 30, y)
	node_container.custom_minimum_size = Vector2(60, 60)
	node_container.mouse_entered.connect(func(): _on_node_hover(node.value, true))
	node_container.mouse_exited.connect(func(): _on_node_hover(node.value, false))
	node_container.gui_input.connect(func(event): _on_node_clicked(event, node.value, node_container))
	canvas.add_child(node_container)
	
	node_positions[node.value] = Vector2(x, y + 30)
	
	var node_visual: Panel = Panel.new()
	node_visual.anchor_right = 1.0
	node_visual.anchor_bottom = 1.0
	var node_style: StyleBoxFlat = StyleBoxFlat.new()
	node_style.bg_color = Color(0, 0.4, 0.8, 0.7)
	node_visual.add_theme_stylebox_override("panel", node_style)
	node_container.add_child(node_visual)
	
	var label: Label = Label.new()
	label.text = str(node.value)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -10
	label.offset_top = -10
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	node_container.add_child(label)
	
	node_visuals[node.value] = node_visual
	
	if node.left:
		_draw_connection(Vector2(x, y + 30), Vector2(x - offset, y + 90), Color.BLUE)
		_draw_node_recursive(node.left, x - offset, y + 120, offset / 2)
	
	if node.right:
		_draw_connection(Vector2(x, y + 30), Vector2(x + offset, y + 90), Color.GREEN)
		_draw_node_recursive(node.right, x + offset, y + 120, offset / 2)

func _draw_connection(from: Vector2, to: Vector2, color: Color) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = color
	canvas.add_child(line)

func _start_next_traversal() -> void:
	if current_traversal_index >= traversal_types.size():
		_on_phase_3_complete()
		return
	
	current_traversal_type = traversal_types[current_traversal_index]
	clicked_sequence.clear()
	
	# Calcola la sequenza corretta
	match current_traversal_type:
		"Preorder":
			expected_sequence = game_manager.get_preorder()
		"Inorder":
			expected_sequence = game_manager.get_inorder()
		"Postorder":
			expected_sequence = game_manager.get_postorder()
		"BFS":
			expected_sequence = game_manager.get_bfs()
	
	instruction_label.text = "Visita %s: clicca i router nell'ordine corretto" % current_traversal_type
	error_label.text = "Ordine atteso: %s" % str(expected_sequence)
	error_label.add_theme_color_override("font_color", Color(0.7, 1, 1))

func _on_node_hover(value: int, is_entering: bool) -> void:
	if value in node_visuals:
		var node_style: StyleBoxFlat = node_visuals[value].get_theme_stylebox("panel")
		if is_entering:
			node_style.bg_color = Color(0, 0.7, 1, 0.9)
		else:
			node_style.bg_color = Color(0, 0.4, 0.8, 0.7)

func _on_node_clicked(event: InputEvent, value: int, node_container: Control) -> void:
	if event is InputEventMouseButton and event.pressed:
		var expected_value: int = expected_sequence[clicked_sequence.size()] if clicked_sequence.size() < expected_sequence.size() else -1
		
		if value == expected_value:
			clicked_sequence.append(value)
			
			# Highlight verde
			var node_style: StyleBoxFlat = node_visuals[value].get_theme_stylebox("panel")
			node_style.bg_color = Color(0, 1, 0, 0.9)
			
			if clicked_sequence.size() == expected_sequence.size():
				# Traversal completato!
				error_label.text = "Perfetto! Visita %s completata" % current_traversal_type
				error_label.add_theme_color_override("font_color", Color(0, 1, 0))
				await get_tree().create_timer(1.0).timeout
				
				# Reset per la prossima visita
				for i in range(expected_sequence.size()):
					var val: int = expected_sequence[i]
					var node_style2: StyleBoxFlat = node_visuals[val].get_theme_stylebox("panel")
					node_style2.bg_color = Color(0, 0.4, 0.8, 0.7)
				
				current_traversal_index += 1
				_start_next_traversal()
		else:
			# Sbagliato!
			error_label.text = "Sbagliato! Dovevi cliccare %d, hai cliccato %d - Tempo -10 sec" % [expected_value, value]
			error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			game_manager.time_remaining -= 10.0
			
			# Reset
			var tween: Tween = create_tween()
			tween.tween_callback(func(): var node_style2 = node_visuals[value].get_theme_stylebox("panel"); node_style2.bg_color = Color(1, 0.2, 0.2, 0.9))
			tween.tween_callback(func(): await get_tree().create_timer(0.5).timeout)
			tween.tween_callback(func(): var node_style3 = node_visuals[value].get_theme_stylebox("panel"); node_style3.bg_color = Color(0, 0.4, 0.8, 0.7))
			
			clicked_sequence.clear()

func _on_phase_3_complete() -> void:
	var complete_label: Label = Label.new()
	complete_label.text = "Fase 3 completata! Scansione della rete finita"
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
