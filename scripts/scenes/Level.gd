extends Control

var game_manager: Node
var current_phase: int = 0

@onready var timer_label: Label = Label.new()
@onready var phase_container: Node = Node.new()

func _ready() -> void:
	game_manager = get_tree().root.get_child(0).find_child("GameManager")
	setup_ui()
	
	if game_manager:
		game_manager.phase_changed.connect(_on_phase_changed)
		game_manager.time_updated.connect(_on_time_updated)
		game_manager.time_expired.connect(_on_time_expired)
		game_manager.initialize_bst()

func setup_ui() -> void:
	# Sfondo
	var bg: Panel = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.25)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)
	
	# Timer in alto a destra
	timer_label.anchor_left = 0.85
	timer_label.anchor_top = 0.02
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color(0, 1, 0))
	add_child(timer_label)
	
	# Container per la fase corrente
	phase_container.name = "PhaseContainer"
	add_child(phase_container)

func _on_phase_changed(new_phase: int) -> void:
	current_phase = new_phase
	print("Fase cambiata a: ", new_phase)
	
	# Pulisce il container
	for child in phase_container.get_children():
		child.queue_free()
	
	# Carica la fase corrente
	match new_phase:
		1:
			_load_phase_1()
		2:
			_load_phase_2()
		3:
			_load_phase_3()
		4:
			_load_phase_4()

func _on_time_updated(time: float) -> void:
	var minutes: int = int(time) / 60
	var seconds: int = int(time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Cambia colore se il tempo è basso
	if time < 60:
		timer_label.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		timer_label.add_theme_color_override("font_color", Color(0, 1, 0))

func _on_time_expired() -> void:
	print("TEMPO SCADUTO!")
	_show_game_over()

func _load_phase_1() -> void:
	print("Caricamento Fase 1: Ricostruzione della rete")
	
	var phase1_node: Node = Node.new()
	phase1_node.script = load("res://scripts/phases/Phase1Manager.gd")
	phase_container.add_child(phase1_node)

func _load_phase_2() -> void:
	print("Caricamento Fase 2: Instradamento pacchetti")
	# TODO: Implementare Fase 2

func _load_phase_3() -> void:
	print("Caricamento Fase 3: Scansione rete")
	# TODO: Implementare Fase 3

func _load_phase_4() -> void:
	print("Caricamento Fase 4: Attacco finale")
	# TODO: Implementare Fase 4

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
	
	# Pulsanti
	var restart_btn: Button = Button.new()
	restart_btn.text = "Ricomincia"
	restart_btn.anchor_left = 0.35
	restart_btn.anchor_top = 0.55
	restart_btn.custom_minimum_size = Vector2(150, 50)
	restart_btn.pressed.connect(_on_restart)
	add_child(restart_btn)
	
	var menu_btn: Button = Button.new()
	menu_btn.text = "Menu Principale"
	menu_btn.anchor_left = 0.55
	menu_btn.anchor_top = 0.55
	menu_btn.custom_minimum_size = Vector2(150, 50)
	menu_btn.pressed.connect(_on_main_menu)
	add_child(menu_btn)

func _on_restart() -> void:
	if game_manager:
		game_manager.current_phase = 0
		game_manager.game_active = false
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/introduction.tscn")
