extends Node

class_name Phase1Manager

var game_manager: Node
var phase_ui: Control

# Router nodes UI
var router_visual_nodes: Dictionary = {}  # value -> RouterNode control
var root_node_visual: Control = null

# Tracking placement
var placed_values: Array[int] = []
var remaining_values: Array[int] = []

var phase_label: Label = Label.new()
var complete_label: Label = Label.new()

func _ready() -> void:
	game_manager = get_tree().root.get_child(0).find_child("GameManager")
	phase_ui = get_parent()
	
	setup_phase_1_ui()
	initialize_phase_1()

func setup_phase_1_ui() -> void:
	# Title
	var title: Label = Label.new()
	title.text = "Fase 1: Ricostruzione della Rete"
	title.anchor_left = 0.5
	title.anchor_top = 0.02
	title.offset_left = -250
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0, 1, 0.5))
	phase_ui.add_child(title)
	
	# Instructions
	var instructions: Label = Label.new()
	instructions.text = "Trascinare i router nella posizione corretta secondo le regole del BST\n(valori minori a sinistra, maggiori a destra)"
	instructions.anchor_left = 0.05
	instructions.anchor_top = 0.08
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	phase_ui.add_child(instructions)
	
	# Container per i router da posizionare (bottom)
	var bottom_container: HBoxContainer = HBoxContainer.new()
	bottom_container.anchor_left = 0.05
	bottom_container.anchor_bottom = 1.0
	bottom_container.offset_top = -100
	bottom_container.add_theme_constant_override("separation", 20)
	phase_ui.add_child(bottom_container)
	bottom_container.name = "BottomContainer"
	
	# Canvas per la rete (center)
	var canvas: Control = Control.new()
	canvas.anchor_left = 0.15
	canvas.anchor_top = 0.15
	canvas.anchor_right = 0.95
	canvas.anchor_bottom = 0.85
	canvas.name = "NetworkCanvas"
	phase_ui.add_child(canvas)

func initialize_phase_1() -> void:
	if not game_manager:
		return
	
	# Crea la radice al centro
	var root_value: int = game_manager.phase1_values[0]
	root_node_visual = _create_router_control(root_value)
	root_node_visual.set_as_root(true)
	
	var canvas: Control = phase_ui.find_child("NetworkCanvas")
	root_node_visual.anchor_left = 0.5
	root_node_visual.anchor_top = 0.05
	root_node_visual.offset_left = -40
	root_node_visual.offset_top = 0
	canvas.add_child(root_node_visual)
	
	placed_values.append(root_value)
	
	# Crea i router nel bottom container
	var bottom_container: HBoxContainer = phase_ui.find_child("BottomContainer")
	for i in range(1, game_manager.phase1_values.size()):
		var val: int = game_manager.phase1_values[i]
		remaining_values.append(val)
		
		var router: Control = _create_router_control(val)
		router.custom_minimum_size = Vector2(80, 80)
		bottom_container.add_child(router)
		router_visual_nodes[val] = router

func _create_router_control(value: int) -> Control:
	var router: Control = Control.new()
	router.custom_minimum_size = Vector2(80, 80)
	
	# Sprite
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://assets/generated/router_node_frame_0.png")
	sprite.centered = true
	sprite.scale = Vector2(1.5, 1.5)
	router.add_child(sprite)
	
	# Label
	var label: Label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -15
	label.offset_top = -10
	router.add_child(label)
	
	# Store value in metadata
	router.set_meta("value", value)
	
	return router

func _process(_delta: float) -> void:
	pass

func check_all_placed() -> bool:
	return placed_values.size() == game_manager.phase1_values.size()
