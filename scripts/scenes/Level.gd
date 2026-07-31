extends Control

var game_manager: Node
var current_phase: int = 0
var timer_label: Label = Label.new()
var timer_bar: ColorRect
var phase_container: Node = Node.new()
var phase_indicator: Label = Label.new()
var is_game_over: bool = false

func _ready() -> void:
	game_manager = GameManager
	setup_ui()
	
	if game_manager:
		game_manager.phase_changed.connect(_on_phase_changed)
		game_manager.time_updated.connect(_on_time_updated)
		game_manager.time_expired.connect(_on_time_expired)
		game_manager.initialize_bst()
		# Start the game timer now (not from introduction screen)
		game_manager.start_game()

func setup_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.2)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)
	
	# Timer background bar
	var timer_bg: ColorRect = ColorRect.new()
	timer_bg.anchor_left = 0.7
	timer_bg.anchor_top = 0.01
	timer_bg.anchor_right = 0.98
	timer_bg.anchor_bottom = 0.05
	timer_bg.color = Color(0.1, 0.1, 0.2, 0.7)
	add_child(timer_bg)
	
	timer_bar = ColorRect.new()
	timer_bar.anchor_left = 0.7
	timer_bar.anchor_top = 0.01
	timer_bar.anchor_right = 0.98
	timer_bar.anchor_bottom = 0.05
	timer_bar.color = Color(0, 0.8, 0.3, 0.6)
	add_child(timer_bar)
	
	timer_label.anchor_left = 0.72
	timer_label.anchor_top = 0.01
	timer_label.anchor_bottom = 0.05
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(timer_label)
	
	# Phase indicator
	phase_indicator.anchor_left = 0.01
	phase_indicator.anchor_top = 0.01
	phase_indicator.add_theme_font_size_override("font_size", 16)
	phase_indicator.add_theme_color_override("font_color", Color(0.4, 0.7, 1))
	add_child(phase_indicator)
	
	phase_container.name = "PhaseContainer"
	add_child(phase_container)

func _on_phase_changed(new_phase: int) -> void:
	current_phase = new_phase
	is_game_over = false
	
	# Nomi delle fasi
	var phase_names: Array[String] = ["", "Ricostruzione Rete", "Instradamento Pacchetti", "Scansione Rete", "Attacco Hacker", "Completato"]
	var phase_colors: Array[Color] = [
		Color.WHITE,
		Color(0.2, 0.8, 1),
		Color(0.3, 1, 0.5),
		Color(0.8, 0.6, 1),
		Color(1, 0.4, 0.4),
		Color(0, 1, 0.3)
	]
	
	if new_phase >= 1 and new_phase <= 5:
		phase_indicator.text = "Fase %d: %s" % [new_phase, phase_names[new_phase]]
		phase_indicator.add_theme_color_override("font_color", phase_colors[new_phase])
	
	for child in phase_container.get_children():
		child.queue_free()
	
	match new_phase:
		1:
			_load_phase_1()
		2:
			_load_phase_2()
		3:
			_load_phase_3()
		4:
			_load_phase_4()
		5:
			_show_level_complete()

func _on_time_updated(time_left: float) -> void:
	var minutes: int = int(time_left) / 60
	var seconds: int = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Update timer bar
	var ratio: float = time_left / game_manager.max_time
	timer_bar.anchor_right = 0.3 + ratio * 0.68  # 0.7 to 0.98 range
	
	if ratio > 0.5:
		timer_bar.color = Color(0, 0.8, 0.3, 0.6)
		timer_label.add_theme_color_override("font_color", Color.WHITE)
	elif ratio > 0.25:
		timer_bar.color = Color(1, 0.8, 0, 0.7)
		timer_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	else:
		timer_bar.color = Color(1, 0.2, 0.2, 0.7)
		timer_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

func _on_time_expired() -> void:
	if is_game_over:
		return
	is_game_over = true
	_show_game_over()

func _load_phase_1() -> void:
	var phase1: Node = Node.new()
	phase1.script = load("res://scripts/phases/Phase1Manager.gd")
	phase_container.add_child(phase1)

func _load_phase_2() -> void:
	var phase2: Node = Node.new()
	phase2.script = load("res://scripts/phases/Phase2Manager.gd")
	phase_container.add_child(phase2)

func _load_phase_3() -> void:
	var phase3: Node = Node.new()
	phase3.script = load("res://scripts/phases/Phase3Manager.gd")
	phase_container.add_child(phase3)

func _load_phase_4() -> void:
	var phase4: Node = Node.new()
	phase4.script = load("res://scripts/phases/Phase4Manager.gd")
	phase_container.add_child(phase4)

func _show_game_over() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.8)
	add_child(overlay)
	
	var label: Label = Label.new()
	label.text = "⏰ TEMPO SCADUTO!"
	label.anchor_left = 0.5
	label.anchor_top = 0.3
	label.offset_left = -200
	label.add_theme_font_size_override("font_size", 52)
	label.add_theme_color_override("font_color", Color(1, 0.1, 0.1))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	
	var desc: Label = Label.new()
	desc.text = "L'hacker ha vinto... La rete non è stata ripristinata in tempo."
	desc.anchor_left = 0.5
	desc.anchor_top = 0.42
	desc.offset_left = -220
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(desc)
	
	# Bottone Ricomincia
	var restart_btn: Button = Button.new()
	restart_btn.text = "🔄 Ricomincia il Gioco"
	restart_btn.anchor_left = 0.5
	restart_btn.anchor_top = 0.55
	restart_btn.offset_left = -150
	restart_btn.custom_minimum_size = Vector2(300, 50)
	restart_btn.add_theme_font_size_override("font_size", 18)
	restart_btn.pressed.connect(_on_restart_pressed)
	add_child(restart_btn)
	
	# Bottone Menu Principale
	var menu_btn: Button = Button.new()
	menu_btn.text = "🏠 Torna al Menu Principale"
	menu_btn.anchor_left = 0.5
	menu_btn.anchor_top = 0.65
	menu_btn.offset_left = -150
	menu_btn.custom_minimum_size = Vector2(300, 50)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(_on_menu_pressed)
	add_child(menu_btn)

func _on_restart_pressed() -> void:
	game_manager.start_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/introduction.tscn")

func _show_level_complete() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)
	
	var label: Label = Label.new()
	label.text = "🎉 LIVELLO COMPLETATO!"
	label.anchor_left = 0.5
	label.anchor_top = 0.25
	label.offset_left = -250
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	add_child(label)
	
	var desc: Label = Label.new()
	desc.text = "Hai imparato come funzionano i Binary Search Tree!\n\n✓ Ricostruzione della rete\n✓ Instradamento dei pacchetti\n✓ Scansione dell'albero\n✓ Attacco hacker respinto\n\nOttimo lavoro, campione!"
	desc.anchor_left = 0.5
	desc.anchor_top = 0.4
	desc.offset_left = -200
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color.WHITE)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(desc)
	
	var menu_btn: Button = Button.new()
	menu_btn.text = "🏠 Menu Principale"
	menu_btn.anchor_left = 0.5
	menu_btn.anchor_top = 0.7
	menu_btn.offset_left = -120
	menu_btn.custom_minimum_size = Vector2(240, 50)
	menu_btn.add_theme_font_size_override("font_size", 18)
	menu_btn.pressed.connect(_on_menu_pressed)
	add_child(menu_btn)
