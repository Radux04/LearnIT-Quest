extends Control

var game_manager
var current_phase: int = 0
var timer_label: Label = Label.new()
var phase_container: Node = Node.new()

func _ready() -> void:
	game_manager = GameManager
	setup_ui()
	
	if game_manager:
		game_manager.phase_changed.connect(_on_phase_changed)
		game_manager.time_updated.connect(_on_time_updated)
		game_manager.time_expired.connect(_on_time_expired)
		game_manager.initialize_bst()

func setup_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.25)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)
	
	timer_label.anchor_left = 0.85
	timer_label.anchor_top = 0.02
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(timer_label)
	
	phase_container.name = "PhaseContainer"
	add_child(phase_container)

func _on_phase_changed(new_phase: int) -> void:
	current_phase = new_phase
	print("Phase changed to: ", new_phase)
	
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

func _on_time_updated(time: float) -> void:
	var minutes: int = int(time) / 60
	var seconds: int = int(time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	if time < 60:
		timer_label.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		timer_label.add_theme_color_override("font_color", Color(0, 1, 0))

func _on_time_expired() -> void:
	print("TIME EXPIRED!")
	_show_game_over()

func _load_phase_1() -> void:
	print("Loading Phase 1")
	var phase1: Node = Node.new()
	phase1.script = load("res://scripts/phases/Phase1Manager.gd")
	phase_container.add_child(phase1)

func _load_phase_2() -> void:
	print("Loading Phase 2")
	var phase2: Node = Node.new()
	phase2.script = load("res://scripts/phases/Phase2Manager.gd")
	phase_container.add_child(phase2)

func _load_phase_3() -> void:
	print("Loading Phase 3")
	var phase3: Node = Node.new()
	phase3.script = load("res://scripts/phases/Phase3Manager.gd")
	phase_container.add_child(phase3)

func _load_phase_4() -> void:
	print("Loading Phase 4 - Final Attack")
	var phase4: Node = Node.new()
	phase4.script = load("res://scripts/phases/Phase4Manager.gd")
	phase_container.add_child(phase4)

func _show_game_over() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)
	
	var label: Label = Label.new()
	label.text = "TEMPO SCADUTO!"
	label.anchor_left = 0.5
	label.anchor_top = 0.4
	label.offset_left = -150
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(1, 0, 0))
	add_child(label)
	
	var desc: Label = Label.new()
	desc.text = "Il livello non è stato completato in tempo."
	desc.anchor_left = 0.5
	desc.anchor_top = 0.52
	desc.offset_left = -200
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(desc)

func _show_level_complete() -> void:
	var overlay: ColorRect = ColorRect.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.color = Color(0, 0, 0, 0.5)
	add_child(overlay)
	
	var label: Label = Label.new()
	label.text = "LIVELLO COMPLETATO!"
	label.anchor_left = 0.5
	label.anchor_top = 0.3
	label.offset_left = -280
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color(0, 1, 0.5))
	add_child(label)
	
	var desc: Label = Label.new()
	desc.text = "Hai imparato come funzionano i Binary Search Tree!\n\nHai ripristinato la rete e sconfitto l'hacker.\nOttimo lavoro, campione!"
	desc.anchor_left = 0.5
	desc.anchor_top = 0.45
	desc.offset_left = -250
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", Color.WHITE)
	add_child(desc)
	
	var button: Button = Button.new()
	button.text = "Menu Principale"
	button.anchor_left = 0.35
	button.anchor_top = 0.7
	button.custom_minimum_size = Vector2(150, 50)
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/introduction.tscn"))
	add_child(button)
