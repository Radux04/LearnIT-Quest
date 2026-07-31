extends Node

var game_manager: Node
var phase_ui: Control
var canvas: Control

var current_traversal_index: int = 0
var traversal_types: Array[String] = []
var current_traversal_type: String = ""
var expected_sequence: Array[int] = []
var clicked_sequence: Array[int] = []

var node_positions: Dictionary = {}
var node_centers: Dictionary = {}  # value -> Vector2 in canvas
var node_panels: Dictionary = {}  # value -> Panel
var node_labels: Dictionary = {}  # value -> Label

var phase_label: Label = Label.new()
var instruction_label: Label = Label.new()
var progress_label: Label = Label.new()
var error_label: Label = Label.new()

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

	phase_label.text = "FASE 3: Scansione della Rete"
	phase_label.anchor_left = 0.05
	phase_label.anchor_top = 0.1
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1))
	phase_ui.add_child(phase_label)

	instruction_label.text = "Clicca i router nell'ordine di visita corretto"
	instruction_label.anchor_left = 0.05
	instruction_label.anchor_top = 0.14
	instruction_label.add_theme_font_size_override("font_size", 14)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	phase_ui.add_child(instruction_label)
	
	progress_label.text = ""
	progress_label.anchor_left = 0.05
	progress_label.anchor_top = 0.18
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1))
	phase_ui.add_child(progress_label)

	error_label.anchor_left = 0.05
	error_label.anchor_top = 0.22
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(error_label)

	canvas = Control.new()
	canvas.anchor_left = 0.1
	canvas.anchor_top = 0.25
	canvas.anchor_right = 0.9
	canvas.anchor_bottom = 0.78
	phase_ui.add_child(canvas)

func initialize_phase() -> void:
	if not game_manager or not game_manager.bst_root:
		return
	
	# Randomize traversal order
	var all_types: Array[String] = ["Preorder", "Inorder", "Postorder", "BFS"]
	all_types.shuffle()
	traversal_types = all_types
	
	_draw_bst_interactive()
	_start_next_traversal()

func _draw_bst_interactive() -> void:
	_draw_node_recursive(game_manager.bst_root, canvas.size.x / 2, 50, canvas.size.x / 4)

func _draw_node_recursive(node, x: float, y: float, offset: float) -> void:
	if not node:
		return
	
	var node_style: StyleBoxFlat = StyleBoxFlat.new()
	node_style.bg_color = Color(0, 0.4, 0.8, 0.8)
	node_style.corner_radius = 6
	
	var node_panel: Panel = Panel.new()
	node_panel.position = Vector2(x - 25, y)
	node_panel.custom_minimum_size = Vector2(50, 50)
	node_panel.add_theme_stylebox_override("panel", node_style)
	canvas.add_child(node_panel)
	
	node_panels[node.value] = node_panel
	node_centers[node.value] = Vector2(x, y + 25)
	
	var label: Label = Label.new()
	label.text = str(node.value)
	label.position = Vector2(x - 8, y + 14)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(label)
	node_labels[node.value] = label
	
	# Make the panel clickable
	var click_area: ColorRect = ColorRect.new()
	click_area.position = Vector2(x - 25, y)
	click_area.size = Vector2(50, 50)
	click_area.color = Color.TRANSPARENT
	click_area.mouse_filter = Control.MOUSE_FILTER_PASS
	click_area.gui_input.connect(func(event: InputEvent): _on_node_clicked(event, node.value))
	canvas.add_child(click_area)
	
	if node.left:
		_draw_connection(Vector2(x, y + 25), Vector2(x - offset, y + 100), Color(0.3, 0.7, 1))
		_draw_node_recursive(node.left, x - offset, y + 120, offset / 2)
	
	if node.right:
		_draw_connection(Vector2(x, y + 25), Vector2(x + offset, y + 100), Color(0.3, 0.7, 1))
		_draw_node_recursive(node.right, x + offset, y + 120, offset / 2)

func _draw_connection(from: Vector2, to: Vector2, color: Color) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 3.0
	line.default_color = color
	line.antialiased = true
	canvas.add_child(line)

func _start_next_traversal() -> void:
	if current_traversal_index >= traversal_types.size():
		_on_phase_3_complete()
		return
	
	current_traversal_type = traversal_types[current_traversal_index]
	clicked_sequence.clear()
	
	# Reset all node colors to default
	for val in node_panels:
		var s: StyleBoxFlat = node_panels[val].get_theme_stylebox("panel")
		s.bg_color = Color(0, 0.4, 0.8, 0.8)
	
	# Calculate the correct sequence
	match current_traversal_type:
		"Preorder":
			expected_sequence = game_manager.get_preorder()
		"Inorder":
			expected_sequence = game_manager.get_inorder()
		"Postorder":
			expected_sequence = game_manager.get_postorder()
		"BFS":
			expected_sequence = game_manager.get_bfs()
	
	instruction_label.text = "Visita [b]%s[/b]: clicca i router nell'ordine corretto" % current_traversal_type
	instruction_label.text = "Visita %s: clicca i router nell'ordine corretto" % current_traversal_type
	progress_label.text = "Passo %d di %d" % (current_traversal_index + 1, traversal_types.size())
	error_label.text = ""
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _on_node_clicked(event: InputEvent, value: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if clicked_sequence.size() >= expected_sequence.size():
			return
		
		var expected_value: int = expected_sequence[clicked_sequence.size()]
		
		if value == expected_value:
			clicked_sequence.append(value)
			
			# Highlight verde
			var s: StyleBoxFlat = node_panels[value].get_theme_stylebox("panel")
			s.bg_color = Color(0, 1, 0.3, 0.9)
			
			# Pulse effect
			var pulse: Tween = create_tween()
			pulse.tween_property(node_panels[value], "scale", Vector2(1.15, 1.15), 0.1)
			pulse.tween_property(node_panels[value], "scale", Vector2(1.0, 1.0), 0.15)
			
			if clicked_sequence.size() == expected_sequence.size():
				error_label.text = "✓ Visita %s completata!" % current_traversal_type
				error_label.add_theme_color_override("font_color", Color(0, 1, 0))
				await get_tree().create_timer(1.0).timeout
				current_traversal_index += 1
				_start_next_traversal()
		else:
			error_label.text = "Sbagliato! Il prossimo router non è %d — Tempo -10 sec" % value
			error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			game_manager.time_remaining -= 10.0
			
			# Flash rosso
			var s: StyleBoxFlat = node_panels[value].get_theme_stylebox("panel")
			s.bg_color = Color(1, 0.2, 0.2, 0.9)
			
			await get_tree().create_timer(0.5).timeout
			
			# Reset the clicked node
			if value in node_panels:
				var s2: StyleBoxFlat = node_panels[value].get_theme_stylebox("panel")
				s2.bg_color = Color(0, 0.4, 0.8, 0.8)
			
			# Reset all previously highlighted nodes
			for val in clicked_sequence:
				if val in node_panels:
					var s3: StyleBoxFlat = node_panels[val].get_theme_stylebox("panel")
					s3.bg_color = Color(0, 0.4, 0.8, 0.8)
			
			clicked_sequence.clear()

func _on_phase_3_complete() -> void:
	var complete_label: Label = Label.new()
	complete_label.text = "✓ Scansione completata! Tutte le visite eseguite con successo"
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
