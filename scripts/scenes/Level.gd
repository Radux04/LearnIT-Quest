class_name LevelController
extends Control

## Livello 1 — Binary Search Tree Network.
## Orchestra le quattro fasi (senza caricamenti intermedi), l'HUD e il timer.

const ROOT_VALUE := 50.0

const PHASE_SCRIPTS: Array[String] = [
	"res://scripts/phases/Phase1.gd",
	"res://scripts/phases/Phase2.gd",
	"res://scripts/phases/Phase3.gd",
	"res://scripts/phases/Phase4.gd",
]

const PHASE_BANNERS: Array = [
	["FASE 1 — RICOSTRUZIONE", "L'hacker ha staccato 8 router: rimettili al loro posto. Occhio ai decimali!", Color(0.35, 0.85, 1.0)],
	["FASE 2 — INSTRADAMENTO", "Guida i pacchetti dalla radice alla destinazione... se esiste.", Color(0.35, 1.0, 0.7)],
	["FASE 3 — SCANSIONE", "Tre visite diverse: Preorder, Inorder, Postorder o BFS.", Color(0.75, 0.6, 1.0)],
	["FASE 4 — ATTACCO FINALE", "Inserimenti, cancellazioni, minimo, massimo e successore.", Color(1.0, 0.42, 0.42)],
]

@onready var network: NetworkView = $NetworkView
@onready var tray: Control = $Tray
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
@onready var background: ColorRect = $Background

var model: BSTModel = BSTModel.new()
var is_over: bool = false
var current_phase: int = 0

var _toast_tween: Tween = null
var _alert_mode: bool = false
var _alert_time: float = 0.0


func _ready() -> void:
	_style_hud()
	end_screen.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	GameManager.time_updated.connect(_on_time_updated)
	GameManager.time_expired.connect(_on_time_expired)

	model.clear()
	model.insert(ROOT_VALUE)
	network.setup(model)
	var root_router: RouterNode = network.get_router(ROOT_VALUE)
	if root_router != null:
		root_router.set_state(RouterNode.State.SUCCESS)

	GameManager.start_level()
	_run_level()


func _process(delta: float) -> void:
	if _alert_mode:
		_alert_time += delta
		var pulse: float = (sin(_alert_time * 4.0) * 0.5 + 0.5) * 0.06
		background.color = Color(0.09 + pulse, 0.03, 0.06 + pulse * 0.4, 1.0)


# ------------------------------------------------------------- phase flow ---

func _run_level() -> void:
	for i in range(PHASE_SCRIPTS.size()):
		if is_over:
			return
		current_phase = i + 1
		var banner_data: Array = PHASE_BANNERS[i]
		await show_banner(String(banner_data[0]), String(banner_data[1]), banner_data[2])
		if is_over:
			return

		var phase_script: GDScript = load(PHASE_SCRIPTS[i])
		var phase: PhaseBase = phase_script.new()
		phase.name = "Phase%d" % current_phase
		phase.level = self
		add_child(phase)
		await phase.run()
		if is_instance_valid(phase):
			phase.queue_free()
		clear_action_bar()

	if not is_over:
		_show_victory()


# -------------------------------------------------------------- HUD tools ---

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
	_toast_tween.tween_interval(2.2)
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
	tween.chain().tween_interval(1.6)
	tween.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	await tween.finished


func make_action_button(text: String, center: Vector2, button_size: Vector2,
		base_color: Color = Color(0.12, 0.35, 0.6)) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.size = button_size
	button.position = center - button_size * 0.5
	button.add_theme_font_size_override("font_size", 20)
	button.focus_mode = Control.FOCUS_NONE
	_style_button(button, base_color)
	action_bar.add_child(button)
	return button


func clear_action_bar() -> void:
	for child in action_bar.get_children():
		child.queue_free()


func flash_slot(slot: Dictionary, color: Color) -> void:
	var parent_value: float = float(slot["parent"])
	var pos: Vector2 = network.slot_center(parent_value, String(slot["side"]))
	var marker: Control = Control.new()
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	network.add_child(marker)
	var rect: ColorRect = ColorRect.new()
	rect.color = Color(color.r, color.g, color.b, 0.35)
	rect.size = Vector2(64.0, 64.0)
	rect.position = pos - Vector2(32.0, 32.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_child(rect)
	var tween: Tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(marker.queue_free)


func penalty(seconds: float = GameManager.WRONG_ANSWER_PENALTY) -> void:
	GameManager.apply_penalty(seconds)
	_spawn_penalty_text(seconds)


func set_alert_mode(enabled: bool) -> void:
	_alert_mode = enabled
	if not enabled:
		background.color = Color(0.027, 0.047, 0.098, 1.0)


func _spawn_penalty_text(seconds: float) -> void:
	var label: Label = Label.new()
	label.text = "-%d s" % int(seconds)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = timer_label.position + Vector2(60.0, 44.0)
	hud.add_child(label)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 46.0, 0.9)
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
	clear_action_bar()
	network.clear_slots()
	end_title.text = "TEMPO SCADUTO"
	end_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	end_subtitle.text = "L'hacker ha avuto la meglio: la rete non è stata ripristinata in tempo.\nRipassa la regola del BST — minori a sinistra, maggiori a destra — e riprova."
	_show_end_screen()


func _show_victory() -> void:
	is_over = true
	GameManager.complete_level()
	Sfx.play("victory")
	clear_action_bar()
	set_alert_mode(false)
	end_title.text = "RETE RIPRISTINATA"
	end_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	end_subtitle.text = "Hai completato il Livello 1 con %s ancora sul cronometro.\n\nHai imparato sul campo: inserimento, ricerca riuscita e fallita, visite\n(Preorder, Inorder, Postorder, BFS), minimo, massimo, successore in-order\ne cancellazione di un nodo con due figli." % GameManager.formatted_time()
	restart_button.text = "Gioca di nuovo"
	_show_end_screen()


func _show_end_screen() -> void:
	end_screen.visible = true
	end_screen.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(end_screen, "modulate:a", 1.0, 0.5)


func _on_restart_pressed() -> void:
	GameManager.restart_game()


func _on_menu_pressed() -> void:
	GameManager.go_to_menu()


# ------------------------------------------------------------------ style ---

func _style_hud() -> void:
	phase_title.add_theme_font_size_override("font_size", 26)
	phase_title.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))

	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0))

	timer_label.add_theme_font_size_override("font_size", 40)
	timer_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))

	toast_label.add_theme_font_size_override("font_size", 20)
	toast_label.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.08))
	toast_label.add_theme_constant_override("outline_size", 8)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.add_theme_color_override("font_color", Color(0.55, 0.72, 0.9))

	banner_title.add_theme_font_size_override("font_size", 40)
	banner_title.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.08))
	banner_title.add_theme_constant_override("outline_size", 8)
	banner_sub.add_theme_font_size_override("font_size", 19)
	banner_sub.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0))
	banner.pivot_offset = Vector2(470.0, 96.0)

	end_title.add_theme_font_size_override("font_size", 56)
	end_subtitle.add_theme_font_size_override("font_size", 20)
	end_subtitle.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0))
	end_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_style_button(restart_button, Color(0.12, 0.42, 0.28))
	_style_button(menu_button, Color(0.16, 0.24, 0.44))
	restart_button.add_theme_font_size_override("font_size", 20)
	menu_button.add_theme_font_size_override("font_size", 20)

	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 1.0, 0.55)
	fill.corner_radius_top_left = 6
	fill.corner_radius_top_right = 6
	fill.corner_radius_bottom_left = 6
	fill.corner_radius_bottom_right = 6
	timer_bar.add_theme_stylebox_override("fill", fill)

	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.15, 0.25, 0.9)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	timer_bar.add_theme_stylebox_override("background", bg)


static func _style_button(button: Button, base: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = Color(base.r + 0.3, base.g + 0.45, base.b + 0.4, 0.9)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(10)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(base.r * 1.5 + 0.06, base.g * 1.5 + 0.06, base.b * 1.5 + 0.06)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(base.r * 0.7, base.g * 0.7, base.b * 0.7)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.14, 0.16, 0.2, 0.75)
	disabled.border_color = Color(0.3, 0.35, 0.4, 0.5)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.55, 0.62))
