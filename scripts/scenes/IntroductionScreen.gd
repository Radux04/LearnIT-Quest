extends Control

func _ready() -> void:
	setup_ui()

func setup_ui() -> void:
	var panel: Panel = Panel.new()
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.1, 0.2)
	panel.add_theme_stylebox_override("panel", style_box)
	add_child(panel)
	
	var title: Label = Label.new()
	title.text = "Binary Search Tree Network"
	title.add_theme_font_size_override("font_size", 48)
	title.anchor_left = 0.5
	title.anchor_top = 0.05
	title.offset_left = -300
	title.offset_top = 0
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)
	
	var content: Label = Label.new()
	content.text = """Cos'è un Binary Search Tree?

Un Binary Search Tree (BST) è una struttura dati che organizza i numeri in modo intelligente.

REGOLA PRINCIPALE:
• I valori MINORI del nodo vanno nel sottoalbero SINISTRO
• I valori MAGGIORI del nodo vanno nel sottoalbero DESTRO

Questo ordinamento ha una conseguenza IMPORTANTE:

RICERCA VELOCE:
Per trovare un numero, non serve controllare tutti i nodi.
Basta seguire le regole:
- Se il numero che cerchi è minore, vai a sinistra
- Se è maggiore, vai a destra
- Quando lo trovi, sei a destinazione!

La tua missione è ripristinare la rete di router danneggiata
dall'hacker e imparare come funziona questa struttura."""
	
	content.anchor_left = 0.05
	content.anchor_top = 0.2
	content.anchor_right = 0.95
	content.anchor_bottom = 0.8
	content.add_theme_color_override("font_color", Color.WHITE)
	add_child(content)
	
	var button: Button = Button.new()
	button.text = "Avanti"
	button.anchor_left = 0.5
	button.anchor_bottom = 1.0
	button.offset_left = -75
	button.offset_top = -60
	button.custom_minimum_size = Vector2(150, 50)
	button.pressed.connect(_on_next_pressed)
	add_child(button)

func _on_next_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")
