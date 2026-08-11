extends Control

## Livello 3 — Fondamenti dell'informatica teorica.
##
## A differenza dei primi due livelli qui non c'è una sola struttura dati che
## si trasforma: ogni fase porta in scena il proprio strumento (automa, nastro,
## tabella diagonale, interprete). Il controller espone quindi un "palco"
## (Stage) che le fasi riempiono e svuotano.

## I due array sono PARALLELI: stessa lunghezza, stesso ordine.
##
## Phase4.gd (il problema dell'arresto con l'argomento diagonale) esiste ancora
## ma è fuori rotazione: per rimetterlo in gioco basta aggiungere il suo
## percorso qui sotto e il banner corrispondente. La teoria resta comunque
## nell'introduzione, perché fa parte del programma.
const PHASE_SCRIPTS: Array[String] = [
	"res://scripts/phases/lvl3/Phase1.gd",
	"res://scripts/phases/lvl3/Phase2.gd",
	"res://scripts/phases/lvl3/Phase3.gd",
	"res://scripts/phases/lvl3/Phase5.gd",
]

const PHASE_BANNERS: Array = [
	["FASE 1 — AUTOMI DETERMINISTICI", "Esegui l'automa sulla parola: uno stato alla volta.", Color(0.4, 0.85, 1.0)],
	["FASE 2 — NON DETERMINISMO", "Trasforma l'automa non deterministico nel suo equivalente deterministico.", Color(0.4, 1.0, 0.7)],
	["FASE 3 — MACCHINE DI TURING", "Applica le quintuple e guarda il nastro cambiare.", Color(1.0, 0.82, 0.35)],
	["FASE 4 — IL LINGUAGGIO WHILE", "Tre costrutti bastano per calcolare tutto il calcolabile.", Color(0.75, 0.65, 1.0)],
]

var is_over: bool = false
var current_phase: int = 0
var solved_count: int = 0
var pause_menu: PauseMenu = null
## La fase in esecuzione. Serve alle fasi stesse e al bot di collaudo.
var phase_node: Lvl3PhaseBase = null

var _toast_tween: Tween = null

@onready var stage: Control = $Stage
@onready var action_bar: Control = $ActionBar
@onready var hud: Control = $HUD
@onready var phase_title: Label = $HUD/PhaseTitle
@onready var objective_label: Label = $HUD/Objective
@onready var timer_label: Label = $HUD/TimerLabel
@onready var timer_bar: ProgressBar = $HUD/TimerBar
@onready var toast_label: Label = $HUD/Toast
@onready var hint_label: Label = $HUD/Hint
@onready var banner: Panel = $Overlays/Banner
@onready var banner_title: Label = $Overlays/Banner/BannerTitle
@onready var banner_sub: Label = $Overlays/Banner/BannerSub
@onready var end_screen: Control = $Overlays/EndScreen
@onready var end_title: Label = $Overlays/EndScreen/Title
@onready var end_subtitle: Label = $Overlays/EndScreen/Subtitle
@onready var restart_button: Button = $Overlays/EndScreen/RestartButton
@onready var menu_button: Button = $Overlays/EndScreen/MenuButton


func _ready() -> void:
	_style_hud()
	end_screen.visible = false
	restart_button.pressed.connect(func() -> void: GameManager.go_to_intro_3())
	menu_button.pressed.connect(func() -> void: GameManager.go_to_menu())

	GameManager.time_updated.connect(_on_time_updated)
	GameManager.time_expired.connect(_on_time_expired)

	pause_menu = PauseMenu.new()
	pause_menu.restart_requested.connect(func() -> void: GameManager.go_to_intro_3())
	$Overlays.add_child(pause_menu)

	GameManager.start_level(GameManager.LEVEL3_DURATION)
	_run_level()


func _unhandled_input(event: InputEvent) -> void:
	if is_over or pause_menu == null:
		return
	if event.is_action_pressed("ui_cancel"):
		pause_menu.toggle()
		get_viewport().set_input_as_handled()


func _run_level() -> void:
	for i in range(PHASE_SCRIPTS.size()):
		if is_over:
			return
		current_phase = i + 1
		var data: Array = PHASE_BANNERS[i]
		await show_banner(String(data[0]), String(data[1]), data[2])
		if is_over:
			return
		var script: GDScript = load(PHASE_SCRIPTS[i])
		var phase: Lvl3PhaseBase = script.new()
		phase.name = "Phase%d" % current_phase
		phase.level = self
		add_child(phase)
		phase_node = phase
		await phase.run()
		phase_node = null
		if is_instance_valid(phase):
			phase.queue_free()
	if not is_over:
		_show_victory()


# ------------------------------------------------------------------ palco ---

## Le fasi montano qui la loro vista. Il palco viene svuotato a ogni cambio.
func clear_stage() -> void:
	# remove_child() prima di queue_free(): altrimenti il nodo resta nell'albero
	# fino a fine frame e la vista nuova si sovrappone alla vecchia.
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()


func mount(view: Control) -> Control:
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.add_child(view)
	return view


func make_action_button(text: String, center: Vector2, button_size: Vector2 = Vector2(220.0, 54.0)) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size = button_size
	button.position = center - button_size * 0.5
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_NONE
	SqlConsole._style_button(button, Color(0.14, 0.20, 0.36), Color(0.45, 0.7, 1.0))
	action_bar.add_child(button)
	return button


func clear_action_bar() -> void:
	for child in action_bar.get_children():
		action_bar.remove_child(child)
		child.queue_free()


# ------------------------------------------------------------- HUD tools ----

func set_phase_header(title: String, color: Color) -> void:
	phase_title.text = title
	phase_title.add_theme_color_override("font_color", color)


func set_objective(text: String) -> void:
	objective_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func toast(text: String, color: Color = Color.WHITE) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.2)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)


func show_banner(title: String, subtitle: String, color: Color) -> void:
	banner_title.text = title
	banner_title.add_theme_color_override("font_color", color)
	banner_sub.text = subtitle
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.35)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(1.5)
	tween.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	await tween.finished


func penalty(seconds: float) -> void:
	GameManager.apply_penalty(seconds)
	var label: Label = Label.new()
	label.text = "-%d s" % int(seconds)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = timer_label.position + Vector2(70.0, 44.0)
	hud.add_child(label)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 44.0, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)


# ------------------------------------------------------------------ timer ---

func _on_time_updated(_time_left: float, ratio: float) -> void:
	timer_label.text = GameManager.formatted_time()
	timer_bar.value = ratio
	var color: Color = Color(0.3, 1.0, 0.55)
	if ratio < 0.15:
		color = Color(1.0, 0.25, 0.25)
	elif ratio < 0.35:
		color = Color(1.0, 0.75, 0.2)
	timer_label.add_theme_color_override("font_color", color)
	var fill: StyleBoxFlat = timer_bar.get_theme_stylebox("fill")
	if fill is StyleBoxFlat:
		fill.bg_color = color


func _on_time_expired() -> void:
	if is_over:
		return
	is_over = true
	Sfx.play("fail")
	end_title.text = "TEMPO SCADUTO"
	end_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	end_subtitle.text = "Il collaudo non è stato completato in tempo.\nProve superate: %d." % solved_count
	_show_end_screen()


func _show_victory() -> void:
	is_over = true
	GameManager.complete_level()
	Sfx.play("victory")
	end_title.text = "COLLAUDO COMPLETATO"
	end_title.add_theme_color_override("font_color", Color(0.75, 0.65, 1.0))
	end_subtitle.text = "Hai completato il Livello 3 con %s sul cronometro.\n\nHai eseguito automi deterministici, determinizzato un automa non deterministico,\nfatto girare e progettato macchine di Turing e programmato nel linguaggio WHILE.\n\nProve superate: %d." % [
		GameManager.formatted_time(), solved_count]
	restart_button.text = "Gioca di nuovo"
	_show_end_screen()


func _show_end_screen() -> void:
	clear_action_bar()
	end_screen.visible = true
	end_screen.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(end_screen, "modulate:a", 1.0, 0.5)


# ------------------------------------------------------------------ style ---

func _style_hud() -> void:
	phase_title.add_theme_font_size_override("font_size", 24)
	phase_title.add_theme_color_override("font_color", Color(0.75, 0.65, 1.0))
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	timer_label.add_theme_font_size_override("font_size", 38)
	timer_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.06))
	toast_label.add_theme_constant_override("outline_size", 8)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color(0.66, 0.72, 0.95))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_title.add_theme_font_size_override("font_size", 36)
	banner_title.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.06))
	banner_title.add_theme_constant_override("outline_size", 8)
	banner_sub.add_theme_font_size_override("font_size", 18)
	banner_sub.add_theme_color_override("font_color", Color(0.82, 0.86, 1.0))
	banner.pivot_offset = Vector2(470.0, 96.0)
	end_title.add_theme_font_size_override("font_size", 50)
	end_subtitle.add_theme_font_size_override("font_size", 18)
	end_subtitle.add_theme_color_override("font_color", Color(0.82, 0.88, 1.0))
	end_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	SqlConsole._style_button(restart_button, Color(0.12, 0.42, 0.28), Color(0.35, 1.0, 0.7))
	SqlConsole._style_button(menu_button, Color(0.16, 0.24, 0.44), Color(0.45, 0.7, 1.0))
