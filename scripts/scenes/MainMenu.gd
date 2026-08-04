extends Control

## Menu principale segnaposto: verrà ampliato quando arriveranno gli altri livelli.

@onready var play_button: Button = $Buttons/PlayButton
@onready var quit_button: Button = $Buttons/QuitButton
@onready var diagram: Control = $Diagram

var _time: float = 0.0


func _ready() -> void:
	diagram.draw.connect(_on_diagram_draw)
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	play_button.grab_focus()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	diagram.queue_redraw()


func _on_play_pressed() -> void:
	Sfx.play("correct")
	GameManager.restart_game()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_diagram_draw() -> void:
	# Sfondo animato: nodi e cavi che pulsano.
	var nodes: Array[Vector2] = [
		Vector2(980.0, 210.0), Vector2(870.0, 340.0), Vector2(1090.0, 340.0),
		Vector2(806.0, 470.0), Vector2(936.0, 470.0), Vector2(1156.0, 470.0),
	]
	var edges: Array = [[0, 1], [0, 2], [1, 3], [1, 4], [2, 5]]
	for edge in edges:
		var a: Vector2 = nodes[edge[0]]
		var b: Vector2 = nodes[edge[1]]
		var color: Color = Color(0.25, 0.7, 1.0, 0.5)
		diagram.draw_line(a, b, color, 2.0, true)
		var t: float = fposmod(_time * 0.35 + float(edge[1]) * 0.13, 1.0)
		diagram.draw_circle(a.lerp(b, t), 4.0, Color(0.4, 1.0, 0.8, sin(t * PI) * 0.9))
	for i in range(nodes.size()):
		var pulse: float = sin(_time * 2.0 + float(i)) * 0.5 + 0.5
		diagram.draw_circle(nodes[i], 27.0, Color(0.06, 0.13, 0.24, 0.92))
		diagram.draw_arc(nodes[i], 27.0, 0.0, TAU, 44, Color(0.3, 0.75, 1.0, 0.4 + pulse * 0.4), 2.0, true)
