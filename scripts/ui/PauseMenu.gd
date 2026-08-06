class_name PauseMenu
extends Control

## Menu di pausa disponibile in ogni livello con ESC.
## Serve a garantire che il giocatore possa SEMPRE tornare al menu
## principale e cambiare livello, senza dover finire o perdere la partita.
## Mentre è aperto il cronometro è fermo e gli input non arrivano al gioco.

signal resumed
signal restart_requested

var _title: Label
var _built: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	if _built:
		return
	_built = true

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.05, 0.9)
	add_child(dim)

	var frame: PanelContainer = PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.custom_minimum_size = Vector2(520.0, 0.0)
	frame.offset_left = -260.0
	frame.offset_top = -190.0
	frame.offset_right = 260.0
	frame.offset_bottom = 190.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.06, 0.12, 0.98)
	style.border_color = Color(0.25, 0.6, 0.95, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(26)
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	frame.add_child(box)

	_title = Label.new()
	_title.text = "PAUSA"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	box.add_child(_title)

	var note: Label = Label.new()
	note.text = "Il cronometro è fermo."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	box.add_child(note)

	box.add_child(_make_button("Riprendi   (Esc)", Color(0.1, 0.4, 0.3), Color(0.35, 1.0, 0.7),
		func(): close()))
	box.add_child(_make_button("Ricomincia il livello", Color(0.2, 0.26, 0.42), Color(0.45, 0.7, 1.0),
		func(): restart_requested.emit()))
	box.add_child(_make_button("Torna al Menu Principale", Color(0.24, 0.16, 0.3), Color(0.75, 0.6, 1.0),
		func(): GameManager.go_to_menu()))


func _make_button(text: String, base: Color, border: Color, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 54.0)
	button.add_theme_font_size_override("font_size", 19)
	button.focus_mode = Control.FOCUS_NONE
	_style_button(button, base, border)
	button.pressed.connect(func():
		Sfx.play("click")
		action.call())
	return button


static func _style_button(button: Button, base: Color, border: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(8)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(base.r * 1.5 + 0.05, base.g * 1.5 + 0.05, base.b * 1.5 + 0.05)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(base.r * 0.7, base.g * 0.7, base.b * 0.7)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0))


func open() -> void:
	if visible:
		return
	visible = true
	GameManager.stop_timer()
	Sfx.play("click")


func close() -> void:
	if not visible:
		return
	visible = false
	GameManager.resume_timer()
	resumed.emit()


func is_open() -> bool:
	return visible


func toggle() -> void:
	if visible:
		close()
	else:
		open()


## Mentre il menu è aperto nessun tasto raggiunge il gioco sottostante.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			close()
		get_viewport().set_input_as_handled()
