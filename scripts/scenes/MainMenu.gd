class_name MainMenu
extends Control

## Hub dei percorsi di LearnIT Quest: una panoramica delle basi dell'informatica.

@onready var play_button: Button = $Buttons/PlayButton
@onready var level2_button: Button = $Buttons/Level2Button
@onready var level3_button: Button = $Buttons/Level3Button
@onready var level4_button: Button = $Buttons/Level4Button
@onready var quit_button: Button = $Buttons/QuitButton
@onready var diagram: Control = $Diagram

var _time: float = 0.0


func _ready() -> void:
	diagram.draw.connect(_on_diagram_draw)
	play_button.pressed.connect(_on_play_pressed)
	level2_button.pressed.connect(_on_level2_pressed)
	level3_button.pressed.connect(_on_level3_pressed)
	level4_button.pressed.connect(_on_level4_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	diagram.queue_redraw()


func _on_play_pressed() -> void:
	Sfx.play("correct")
	GameManager.restart_game()


func _on_level2_pressed() -> void:
	Sfx.play("correct")
	GameManager.go_to_intro_2()


func _on_level3_pressed() -> void:
	Sfx.play("correct")
	GameManager.go_to_intro_3()


func _on_level4_pressed() -> void:
	Sfx.play("correct")
	GameManager.go_to_intro_4()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_diagram_draw() -> void:
	# Una mappa concettuale delle quattro aree del gioco, non di un solo esercizio.
	var center: Vector2 = Vector2(970.0, 354.0)
	var topics: Array[Dictionary] = [
		{"pos": Vector2(850.0, 235.0), "color": Color(0.30, 0.76, 1.0), "icon": "BST"},
		{"pos": Vector2(1100.0, 235.0), "color": Color(0.42, 1.0, 0.68), "icon": "DB"},
		{"pos": Vector2(850.0, 493.0), "color": Color(1.0, 0.78, 0.30), "icon": "T"},
		{"pos": Vector2(1100.0, 493.0), "color": Color(0.75, 0.58, 1.0), "icon": ">_"},
	]
	var center_color: Color = Color(0.48, 0.86, 1.0)

	for i in range(topics.size()):
		var topic: Dictionary = topics[i]
		var pos: Vector2 = topic["pos"]
		var color: Color = topic["color"]
		diagram.draw_line(center, pos, Color(color.r, color.g, color.b, 0.20), 9.0, true)
		diagram.draw_line(center, pos, Color(color.r, color.g, color.b, 0.63), 2.0, true)
		var t: float = fposmod(_time * 0.28 + float(i) * 0.24, 1.0)
		diagram.draw_circle(center.lerp(pos, t), 4.5, Color(color.r, color.g, color.b, 0.90))

	var center_pulse: float = sin(_time * 2.0) * 0.5 + 0.5
	diagram.draw_circle(center, 56.0 + center_pulse * 5.0, Color(center_color.r, center_color.g, center_color.b, 0.08))
	diagram.draw_circle(center, 46.0, Color(0.05, 0.12, 0.22, 0.96))
	diagram.draw_arc(center, 46.0, 0.0, TAU, 48, center_color, 2.5, true)

	var font: Font = get_theme_default_font()
	if font == null:
		return
	diagram.draw_string(font, center + Vector2(-25.0, 7.0), "LEARN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color.WHITE)

	for topic_data in topics:
		var topic_pos: Vector2 = topic_data["pos"]
		var topic_color: Color = topic_data["color"]
		var icon: String = topic_data["icon"]
		var pulse: float = sin(_time * 2.1 + topic_pos.x * 0.01) * 0.5 + 0.5
		diagram.draw_circle(topic_pos, 38.0 + pulse * 3.0, Color(topic_color.r, topic_color.g, topic_color.b, 0.09))
		diagram.draw_circle(topic_pos, 31.0, Color(0.05, 0.12, 0.22, 0.96))
		diagram.draw_arc(topic_pos, 31.0, 0.0, TAU, 40, topic_color, 2.2, true)
		var icon_size: int = 18
		var icon_width: float = font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1.0, icon_size).x
		diagram.draw_string(font, topic_pos + Vector2(-icon_width * 0.5, 7.0), icon, HORIZONTAL_ALIGNMENT_LEFT, -1.0, icon_size, topic_color)
