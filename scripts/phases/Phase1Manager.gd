extends Node

var game_manager: Node
var phase_ui: Control
var canvas: Control
var router_ui_nodes: Dictionary = {}
var root_node_ui: Control = null
var placed_values: Array[int] = []
var remaining_values: Array[int] = []
var error_message: Label = Label.new()

func _ready() -> void:
	game_manager = GameManager
	phase_ui = get_parent()
	setup_phase_1_ui()
	initialize_phase_1()
	get_tree().root.gui_input.connect(_on_root_gui_input)

func setup_phase_1_ui() -> void:
	var bg: Panel = Panel.new()
	bg.anchor_left = 0.1
	bg.anchor_top = 0.15
	bg.anchor_right = 0.9
	bg.anchor_bottom = 0.88
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.2)
	bg.add_theme_stylebox_override("panel", style)
	phase_ui.add_child(bg)
	
	var title: Label = Label.new()
	title.text = "Fase 1: Trascinare i router - minori a SINISTRA, maggiori a DESTRA"
	title.anchor_left = 0.1
	title.anchor_top = 0.15
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0, 1, 0.5))
	phase_ui.add_child(title)
	
	error_message.anchor_left = 0.1
	error_message.anchor_top = 0.19
	error_message.add_theme_font_size_override("font_size", 12)
	error_message.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	phase_ui.add_child(error_message)
	
	canvas = Control.new()
	canvas.anchor_left = 0.15
	canvas.anchor_top = 0.22
	canvas.anchor_right = 0.65
	canvas.anchor_bottom = 0.85
	phase_ui.add_child(canvas)
	
	var drag_container: VBoxContainer = VBoxContainer.new()
	drag_container.anchor_left = 0.68
	drag_container.anchor_top = 0.23
	drag_container.anchor_right = 0.89
	drag_container.anchor_bottom = 0.84
	drag_container.add_theme_constant_override("separation", 10)
	drag_container.name = "DragContainer"
	phase_ui.add_child(drag_container)

func initialize_phase_1() -> void:
	if not game_manager:
		return
	
	var root_value: int = game_manager.phase1_values[0]
	root_node_ui = _create_router_ui(root_value)
	root_node_ui.position = Vector2(canvas.size.x / 2 - 40, 20)
	canvas.add_child(root_node_ui)
	placed_values.append(root_value)
	
	var drag_container: VBoxContainer = phase_ui.find_child("DragContainer")
	for i in range(1, game_manager.phase1_values.size()):
		var val: int = game_manager.phase1_values[i]
		remaining_values.append(val)
		var router_ui: Control = _create_router_ui(val)
		router_ui.custom_minimum_size = Vector2(70, 70)
		drag_container.add_child(router_ui)
		router_ui_nodes[val] = router_ui

func _create_router_ui(value: int) -> Control:
	var container: Control = Control.new()
	container.custom_minimum_size = Vector2(80, 80)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://assets/generated/router_node_frame_0.png")
	sprite.centered = true
	sprite.scale = Vector2(1.5, 1.5)
	sprite.position = Vector2(40, 40)
	container.add_child(sprite)
	var label: Label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.offset_left = -10
	label.offset_top = -10
	container.add_child(label)
	container.set_meta("value", value)
	container.set_meta("is_dragging", false)
	container.set_meta("drag_offset", Vector2.ZERO)
	return container

func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		for val in remaining_values:
			if val in router_ui_nodes:
				var router = router_ui_nodes[val]
				if router.get_global_rect().has_point(event.position):
					router.set_meta("is_dragging", true)
					router.set_meta("drag_offset", event.position - router.global_position)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for val in remaining_values:
			if val in router_ui_nodes and router_ui_nodes[val].get_meta("is_dragging", false):
				_on_router_dropped(val)
				router_ui_nodes[val].set_meta("is_dragging", false)

func _process(_delta: float) -> void:
	for val in remaining_values:
		if val in router_ui_nodes:
			var router = router_ui_nodes[val]
			if router.get_meta("is_dragging", false):
				var offset: Vector2 = router.get_meta("drag_offset", Vector2.ZERO)
				router.global_position = get_global_mouse_position() - offset

func _on_router_dropped(value: int) -> void:
	error_message.text = ""
	var router_ui: Control = router_ui_nodes[value]
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	if not canvas.get_global_rect().has_point(mouse_pos):
		return
	
	var local_pos: Vector2 = mouse_pos - canvas.global_position
	var target_parent_value: int = -1
	var direction: String = ""
	var min_distance: float = 100.0
	
	for placed_val in placed_values:
		var target_ui: Control = root_node_ui if placed_val == game_manager.phase1_values[0] else (router_ui_nodes[placed_val] if placed_val in router_ui_nodes else null)
		if target_ui:
			var target_pos: Vector2 = target_ui.position
			var distance: float = target_pos.distance_to(local_pos)
			if distance < min_distance and distance < 120 and local_pos.y > target_pos.y:
				min_distance = distance
				target_parent_value = placed_val
				direction = "left" if local_pos.x < target_pos.x else "right"
	
	if target_parent_value == -1:
		error_message.text = "Posiziona sotto un router esistente!"
		return
	
	if (direction == "left" and value >= target_parent_value) or (direction == "right" and value <= target_parent_value):
		error_message.text = "Sbagliato! Minori a SINISTRA, maggiori a DESTRA"
		return
	
	router_ui.global_position = mouse_pos
	router_ui.reparent(canvas)
	placed_values.append(value)
	remaining_values.erase(value)
	
	var tween: Tween = create_tween()
	tween.tween_property(router_ui, "modulate", Color.GREEN, 0.2)
	tween.tween_property(router_ui, "modulate", Color.WHITE, 0.3)
	
	if remaining_values.is_empty():
		await get_tree().create_timer(0.5).timeout
		var complete: Label = Label.new()
		complete.text = "Perfetto! Premi AVANTI"
		complete.anchor_left = 0.2
		complete.anchor_top = 0.9
		complete.add_theme_font_size_override("font_size", 16)
		complete.add_theme_color_override("font_color", Color(0, 1, 0))
		phase_ui.add_child(complete)
		
		var btn: Button = Button.new()
		btn.text = "Avanti"
		btn.anchor_left = 0.45
		btn.anchor_top = 0.93
		btn.custom_minimum_size = Vector2(80, 35)
		btn.pressed.connect(func(): if game_manager: game_manager.advance_phase())
		phase_ui.add_child(btn)
