extends Node

var game_manager
var phase_ui: Control
var canvas: Control

var phase_start_time: float = 0.0
var phase_duration: float = 45.0  # 45 secondi per la Fase 4
var current_challenge_index: int = 0
var challenges_completed: int = 0

var phase_label: Label = Label.new()
var instruction_label: Label = Label.new()
var timer_label: Label = Label.new()
var error_label: Label = Label.new()

var current_challenge_type: String = ""
var input_field: LineEdit = LineEdit.new()
var random_seed_val: int = 0

func _ready() -> void:
	game_manager = GameManager
	phase_ui = get_parent()
	random_seed_val = randi()
	phase_start_time = game_manager.time_remaining
	setup_phase_4_ui()
	initialize_phase_4()
	set_process(true)

func setup_phase_4_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_left = 0.1
	bg.anchor_top = 0.15
	bg.anchor_right = 0.9
	bg.anchor_bottom = 0.88
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.15)
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)
	
	phase_label.text = "Fase 4: Attacco Finale - L'Hacker sta modificando la rete!"
	phase_label.anchor_left = 0.1
	phase_label.anchor_top = 0.15
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	phase_ui.add_child(phase_label)
	
	timer_label.text = "45s"
	timer_label.anchor_left = 0.8
	timer_label.anchor_top = 0.17
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(timer_label)
	
	instruction_label.text = ""
	instruction_label.anchor_left = 0.1
	instruction_label.anchor_top = 0.22
	instruction_label.add_theme_font_size_override("font_size", 16)
	instruction_label.add_theme_color_override("font_color", Color.WHITE)
	phase_ui.add_child(instruction_label)
	
	error_label.anchor_left = 0.1
	error_label.anchor_top = 0.27
	error_label.add_theme_font_size_override("font_size", 14)
	error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	phase_ui.add_child(error_label)
	
	canvas = Control.new()
	canvas.anchor_left = 0.15
	canvas.anchor_top = 0.35
	canvas.anchor_right = 0.85
	canvas.anchor_bottom = 0.8
	phase_ui.add_child(canvas)

func initialize_phase_4() -> void:
	_show_next_challenge()

func _process(_delta: float) -> void:
	var elapsed: float = phase_start_time - game_manager.time_remaining
	var remaining: float = phase_duration - elapsed
	
	if remaining <= 0:
		_on_phase_4_complete()
		set_process(false)
	else:
		timer_label.text = "%.0fs" % remaining
		
		if remaining < 10:
			timer_label.add_theme_color_override("font_color", Color(1, 0, 0))
		elif remaining < 20:
			timer_label.add_theme_color_override("font_color", Color(1, 1, 0))

func _show_next_challenge() -> void:
	# Rimuovi input precedente
	if input_field.get_parent():
		input_field.queue_free()
	
	for child in phase_ui.get_children():
		if child.name in ["SubmitBtn", "LeftChoiceBtn", "RightChoiceBtn"]:
			child.queue_free()
	
	# Scegli una sfida casuale
	var challenge_types: Array[String] = ["insert", "delete", "search"]
	current_challenge_type = challenge_types[randi() % challenge_types.size()]
	
	match current_challenge_type:
		"insert":
			_show_insert_challenge()
		"delete":
			_show_delete_challenge()
		"search":
			_show_search_challenge()

func _show_insert_challenge() -> void:
	var value_to_insert: int = randi() % 100
	instruction_label.text = "INSERISCI il router con valore: %d" % value_to_insert
	
	input_field = LineEdit.new()
	input_field.anchor_left = 0.3
	input_field.anchor_top = 0.6
	input_field.anchor_right = 0.7
	input_field.placeholder_text = "Scrivi il valore..."
	input_field.custom_minimum_size = Vector2(200, 40)
	phase_ui.add_child(input_field)
	input_field.grab_focus()
	
	var submit_btn: Button = Button.new()
	submit_btn.text = "Inserisci"
	submit_btn.name = "SubmitBtn"
	submit_btn.anchor_left = 0.42
	submit_btn.anchor_top = 0.68
	submit_btn.custom_minimum_size = Vector2(80, 35)
	submit_btn.pressed.connect(func():
		if input_field.text.to_int() == value_to_insert:
			error_label.text = "Corretto! Router inserito."
			error_label.add_theme_color_override("font_color", Color(0, 1, 0))
			challenges_completed += 1
		else:
			error_label.text = "Sbagliato! Tempo -15 sec"
			error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			game_manager.time_remaining -= 15.0
		
		await get_tree().create_timer(0.7).timeout
		_show_next_challenge()
	)
	phase_ui.add_child(submit_btn)

func _show_delete_challenge() -> void:
	var value_to_delete: int = game_manager.phase1_values[randi() % game_manager.phase1_values.size()]
	instruction_label.text = "ELIMINA il router compromesso: %d" % value_to_delete
	error_label.text = ""
	
	# Mostra 3 opzioni di scelta
	var options: Array[int] = [value_to_delete]
	while options.size() < 3:
		var random_val: int = randi() % 100
		if not random_val in options:
			options.append(random_val)
	
	options.shuffle()
	
	for i in range(options.size()):
		var btn: Button = Button.new()
		btn.text = str(options[i])
		btn.name = "ChoiceBtn%d" % i
		btn.anchor_left = 0.25 + i * 0.2
		btn.anchor_top = 0.65
		btn.custom_minimum_size = Vector2(80, 40)
		btn.pressed.connect(func():
			if options[i] == value_to_delete:
				error_label.text = "Corretto! Router eliminato."
				error_label.add_theme_color_override("font_color", Color(0, 1, 0))
				challenges_completed += 1
			else:
				error_label.text = "Sbagliato! Tempo -15 sec"
				error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				game_manager.time_remaining -= 15.0
			
			await get_tree().create_timer(0.7).timeout
			_show_next_challenge()
		)
		phase_ui.add_child(btn)

func _show_search_challenge() -> void:
	var value_to_find: int = game_manager.phase1_values[randi() % game_manager.phase1_values.size()]
	var path: Array[int] = game_manager.search_in_bst(value_to_find)
	
	instruction_label.text = "TROVA il router con valore: %d" % value_to_find
	instruction_label.add_theme_color_override("font_color", Color(0.7, 1, 1))
	error_label.text = "Scegli il percorso: %s" % ("L" if path.size() > 0 and path[0] == 0 else "R" if path.size() > 0 else "ROOT")
	error_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	
	if path.is_empty():
		# È la radice
		var btn: Button = Button.new()
		btn.text = "RADICE"
		btn.anchor_left = 0.42
		btn.anchor_top = 0.65
		btn.custom_minimum_size = Vector2(80, 40)
		btn.pressed.connect(func():
			error_label.text = "Corretto!"
			error_label.add_theme_color_override("font_color", Color(0, 1, 0))
			challenges_completed += 1
			await get_tree().create_timer(0.7).timeout
			_show_next_challenge()
		)
		phase_ui.add_child(btn)
	else:
		# Scegli la direzione
		var left_btn: Button = Button.new()
		left_btn.text = "Vai SINISTRA"
		left_btn.name = "LeftChoiceBtn"
		left_btn.anchor_left = 0.25
		left_btn.anchor_top = 0.65
		left_btn.custom_minimum_size = Vector2(100, 40)
		left_btn.pressed.connect(func():
			if path[0] == 0:
				error_label.text = "Corretto!"
				error_label.add_theme_color_override("font_color", Color(0, 1, 0))
				challenges_completed += 1
			else:
				error_label.text = "Sbagliato! Tempo -15 sec"
				error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				game_manager.time_remaining -= 15.0
			
			await get_tree().create_timer(0.7).timeout
			_show_next_challenge()
		)
		phase_ui.add_child(left_btn)
		
		var right_btn: Button = Button.new()
		right_btn.text = "Vai DESTRA"
		right_btn.name = "RightChoiceBtn"
		right_btn.anchor_left = 0.55
		right_btn.anchor_top = 0.65
		right_btn.custom_minimum_size = Vector2(100, 40)
		right_btn.pressed.connect(func():
			if path[0] == 1:
				error_label.text = "Corretto!"
				error_label.add_theme_color_override("font_color", Color(0, 1, 0))
				challenges_completed += 1
			else:
				error_label.text = "Sbagliato! Tempo -15 sec"
				error_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
				game_manager.time_remaining -= 15.0
			
			await get_tree().create_timer(0.7).timeout
			_show_next_challenge()
		)
		phase_ui.add_child(right_btn)

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
