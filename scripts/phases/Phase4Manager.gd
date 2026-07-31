extends Node

var game_manager: Node
var phase_ui: Control
var canvas: Control

var challenge_types: Array[String] = []
var current_challenge_index: int = 0
var challenges_completed: int = 0
var total_challenges: int = 6

var phase_label: Label = Label.new()
var instruction_label: Label = Label.new()
var progress_label: Label = Label.new()
var error_label: Label = Label.new()

var current_challenge_type: String = ""
var input_field: LineEdit = LineEdit.new()
var current_value: int = 0
var btn_group: Array[Button] = []

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
	style.bg_color = Color(0.1, 0.06, 0.12)
	style.corner_radius = 8
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)

	phase_label.text = "FASE 4: Attacco dell'Hacker!"
	phase_label.anchor_left = 0.05
	phase_label.anchor_top = 0.1
	phase_label.add_theme_font_size_override("font_size", 20)
	phase_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(phase_label)

	progress_label.text = ""
	progress_label.anchor_left = 0.05
	progress_label.anchor_top = 0.14
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	phase_ui.add_child(progress_label)

	instruction_label.text = ""
	instruction_label.anchor_left = 0.05
	instruction_label.anchor_top = 0.18
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	phase_ui.add_child(instruction_label)

	error_label.anchor_left = 0.05
	error_label.anchor_top = 0.22
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(error_label)

	canvas = Control.new()
	canvas.anchor_left = 0.1
	canvas.anchor_top = 0.28
	canvas.anchor_right = 0.9
	canvas.anchor_bottom = 0.75
	phase_ui.add_child(canvas)

func initialize_phase() -> void:
	# Prepara una lista di sfide casuali
	var all_types: Array[String] = ["insert", "delete", "route"]
	for i in range(total_challenges):
		challenge_types.append(all_types[randi() % all_types.size()])
	
	_draw_bst_tree()
	_show_next_challenge()

func _draw_bst_tree() -> void:
	_draw_node_recursive(game_manager.bst_root, canvas.size.x / 2, 30, canvas.size.x / 4)

func _draw_node_recursive(node, x: float, y: float, offset: float) -> void:
	if not node:
		return
	
	var node_style: StyleBoxFlat = StyleBoxFlat.new()
	node_style.bg_color = Color(0.5, 0.2, 0.4, 0.8)
	node_style.corner_radius = 4
	
	var node_panel: Panel = Panel.new()
	node_panel.position = Vector2(x - 18, y)
	node_panel.custom_minimum_size = Vector2(36, 36)
	node_panel.add_theme_stylebox_override("panel", node_style)
	canvas.add_child(node_panel)
	
	var label: Label = Label.new()
	label.text = str(node.value)
	label.position = Vector2(x - 5, y + 8)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	canvas.add_child(label)
	
	if node.left:
		_draw_connection(Vector2(x, y + 18), Vector2(x - offset, y + 80), Color(1, 0.4, 0.4, 0.5))
		_draw_node_recursive(node.left, x - offset, y + 100, offset / 2)
	
	if node.right:
		_draw_connection(Vector2(x, y + 18), Vector2(x + offset, y + 80), Color(1, 0.4, 0.4, 0.5))
		_draw_node_recursive(node.right, x + offset, y + 100, offset / 2)

func _draw_connection(from: Vector2, to: Vector2, color: Color) -> void:
	var line: Line2D = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2.0
	line.default_color = color
	line.antialiased = true
	canvas.add_child(line)

func _clear_buttons() -> void:
	for child in phase_ui.get_children():
		if child.name.begins_with("BtnP4"):
			child.queue_free()
	if input_field.get_parent():
		input_field.queue_free()
	btn_group.clear()

func _show_next_challenge() -> void:
	_clear_buttons()
	
	if current_challenge_index >= challenge_types.size():
		_on_phase_4_complete()
		return
	
	current_challenge_type = challenge_types[current_challenge_index]
	progress_label.text = "Sfida %d di %d" % (current_challenge_index + 1, challenge_types.size())
	
	match current_challenge_type:
		"insert":
			_show_insert_challenge()
		"delete":
			_show_delete_challenge()
		"route":
			_show_route_challenge()

func _show_insert_challenge() -> void:
	current_value = randi() % 100
	instruction_label.text = "🛡️ Inserisci il router con valore: [b]%d[/b]" % current_value
	instruction_label.text = "INSERISCI il router: %d" % current_value
	
	input_field = LineEdit.new()
	input_field.anchor_left = 0.35
	input_field.anchor_top = 0.8
	input_field.anchor_right = 0.65
	input_field.placeholder_text = "Scrivi il valore..."
	input_field.custom_minimum_size = Vector2(150, 35)
	phase_ui.add_child(input_field)
	input_field.grab_focus()
	
	var submit_btn: Button = Button.new()
	submit_btn.text = "Conferma"
	submit_btn.name = "BtnP4_submit"
	submit_btn.anchor_left = 0.45
	submit_btn.anchor_top = 0.87
	submit_btn.custom_minimum_size = Vector2(100, 35)
	submit_btn.pressed.connect(_on_insert_submit)
	phase_ui.add_child(submit_btn)

func _on_insert_submit() -> void:
	var typed_value: int = input_field.text.to_int()
	if typed_value == current_value:
		error_label.text = "✓ Corretto! Router %d inserito nella rete." % current_value
		error_label.add_theme_color_override("font_color", Color(0, 1, 0))
		challenges_completed += 1
	else:
		error_label.text = "✗ Hai digitato %d, dovevi inserire %d — Tempo -10 sec" % [typed_value, current_value]
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		game_manager.time_remaining -= 10.0
	
	await get_tree().create_timer(1.0).timeout
	current_challenge_index += 1
	_show_next_challenge()

func _show_delete_challenge() -> void:
	current_value = game_manager.phase1_values[randi() % game_manager.phase1_values.size()]
	instruction_label.text = "🔥 ELIMINA il router compromesso: %d" % current_value
	error_label.text = ""
	
	var options: Array[int] = [current_value]
	while options.size() < 4:
		var random_val: int = 10 + (randi() % 90)
		if not random_val in options:
			options.append(random_val)
	
	options.shuffle()
	
	for i in range(options.size()):
		var btn: Button = Button.new()
		btn.text = str(options[i])
		btn.name = "BtnP4_del_%d" % i
		btn.anchor_left = 0.1 + i * 0.22
		btn.anchor_top = 0.8
		btn.custom_minimum_size = Vector2(80, 40)
		# FIX: bind the value to avoid closure bug
		var option_val: int = options[i]
		btn.pressed.connect(_on_delete_choice.bind(option_val))
		phase_ui.add_child(btn)
		btn_group.append(btn)

func _on_delete_choice(selected_value: int) -> void:
	if selected_value == current_value:
		error_label.text = "✓ Corretto! Router %d eliminato." % current_value
		error_label.add_theme_color_override("font_color", Color(0, 1, 0))
		challenges_completed += 1
	else:
		error_label.text = "✗ Sbagliato! %d non è il router compromesso — Tempo -10 sec" % selected_value
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		game_manager.time_remaining -= 10.0
	
	await get_tree().create_timer(1.0).timeout
	current_challenge_index += 1
	_show_next_challenge()

func _show_route_challenge() -> void:
	current_value = game_manager.phase1_values[randi() % game_manager.phase1_values.size()]
	var path: Array[int] = game_manager.search_in_bst(current_value)
	
	instruction_label.text = "📡 Instrada il pacchetto verso: %d" % current_value
	error_label.text = ""
	
	if path.is_empty():
		# Root
		var btn: Button = Button.new()
		btn.text = "È la RADICE"
		btn.name = "BtnP4_route_root"
		btn.anchor_left = 0.4
		btn.anchor_top = 0.8
		btn.custom_minimum_size = Vector2(120, 40)
		btn.pressed.connect(_on_route_root)
		phase_ui.add_child(btn)
		return
	
	# Show the first step direction
	var first_dir: int = path[0]
	var correct_dir: String = "SINISTRA" if first_dir == 0 else "DESTRA"
	instruction_label.text = "📡 Instrada il pacchetto verso %d — vai a %s?" % [current_value, correct_dir]
	instruction_label.text = "📡 Primo passo per %d: vai a %s?" % [current_value, correct_dir]
	
	var left_btn: Button = Button.new()
	left_btn.text = "◀ SINISTRA"
	left_btn.name = "BtnP4_left"
	left_btn.anchor_left = 0.25
	left_btn.anchor_top = 0.8
	left_btn.custom_minimum_size = Vector2(120, 40)
	left_btn.pressed.connect(_on_route_left.bind(first_dir))
	phase_ui.add_child(left_btn)
	
	var right_btn: Button = Button.new()
	right_btn.text = "DESTRA ▶"
	right_btn.name = "BtnP4_right"
	right_btn.anchor_left = 0.55
	right_btn.anchor_top = 0.8
	right_btn.custom_minimum_size = Vector2(120, 40)
	right_btn.pressed.connect(_on_route_right.bind(first_dir))
	phase_ui.add_child(right_btn)

func _on_route_root() -> void:
	error_label.text = "✓ Corretto! Il valore %d è la radice." % current_value
	error_label.add_theme_color_override("font_color", Color(0, 1, 0))
	challenges_completed += 1
	await get_tree().create_timer(1.0).timeout
	current_challenge_index += 1
	_show_next_challenge()

func _on_route_left(correct_dir: int) -> void:
	if correct_dir == 0:
		error_label.text = "✓ Corretto! Vai a SINISTRA."
		error_label.add_theme_color_override("font_color", Color(0, 1, 0))
		challenges_completed += 1
	else:
		error_label.text = "✗ Sbagliato! Dovevi andare a DESTRA — Tempo -10 sec"
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		game_manager.time_remaining -= 10.0
	await get_tree().create_timer(1.0).timeout
	current_challenge_index += 1
	_show_next_challenge()

func _on_route_right(correct_dir: int) -> void:
	if correct_dir == 1:
		error_label.text = "✓ Corretto! Vai a DESTRA."
		error_label.add_theme_color_override("font_color", Color(0, 1, 0))
		challenges_completed += 1
	else:
		error_label.text = "✗ Sbagliato! Dovevi andare a SINISTRA — Tempo -10 sec"
		error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		game_manager.time_remaining -= 10.0
	await get_tree().create_timer(1.0).timeout
	current_challenge_index += 1
	_show_next_challenge()

func _on_phase_4_complete() -> void:
	_clear_buttons()
	
	var complete_label: Label = Label.new()
	complete_label.text = "✓ Hacker sconfitto! %d/%d sfide completate" % [challenges_completed, total_challenges]
	complete_label.anchor_left = 0.15
	complete_label.anchor_top = 0.85
	complete_label.add_theme_font_size_override("font_size", 20)
	complete_label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	phase_ui.add_child(complete_label)
	
	await get_tree().create_timer(0.5).timeout
	
	if game_manager:
		game_manager.advance_phase()

func _on_phase_4_complete() -> void:
	# Pulisci UI
	for child in phase_ui.get_children():
		if child not in [phase_label, timer_label, instruction_label, error_label, canvas]:
			if child.name in ["SubmitBtn", "LeftChoiceBtn", "RightChoiceBtn", "ChoiceBtn0", "ChoiceBtn1", "ChoiceBtn2"]:
				child.queue_free()
	
	instruction_label.text = ""
	error_label.text = "Fase 4 completata! Sfide completate: %d" % challenges_completed
	error_label.add_theme_color_override("font_color", Color(0, 1, 0))
	
	await get_tree().create_timer(1.0).timeout
	
	# Passa alla schermata di completamento del livello
	if game_manager:
		game_manager.advance_phase()
