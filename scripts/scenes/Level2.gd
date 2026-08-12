class_name Level2Controller
extends Control

## Livello 2 — Database Recovery (MySQL).
## Il giocatore vede le tabelle e agisce solo scrivendo query nella console.
## Il manuale è consultabile in qualsiasi momento, ma costa 10 secondi.

signal task_solved

const PENALTY_SYNTAX := 8.0
const PENALTY_WRONG := 12.0

const PHASE_SCRIPTS: Array[String] = [
	"res://scripts/phases/lvl2/Phase1.gd",
	"res://scripts/phases/lvl2/Phase2.gd",
	"res://scripts/phases/lvl2/Phase3.gd",
	"res://scripts/phases/lvl2/Phase4.gd",
	"res://scripts/phases/lvl2/Phase5.gd",
]

const PHASE_BANNERS: Array = [
	["FASE 1 — INTERROGAZIONE", "Impara a leggere i dati con SELECT e WHERE.", Color(0.4, 0.85, 1.0)],
	["FASE 2 — RICOSTRUZIONE", "Ricrea le tabelle perdute e reinserisci i record.", Color(0.4, 1.0, 0.7)],
	["FASE 3 — CORREZIONE", "I dati sono sbagliati: sistemali con UPDATE.", Color(1.0, 0.82, 0.35)],
	["FASE 4 — BONIFICA", "Elimina i record corrotti con DELETE. Attento al WHERE!", Color(1.0, 0.5, 0.45)],
	["FASE 5 — QUERY NIDIFICATE", "Una query dentro un'altra: subquery scalari e con IN.", Color(0.75, 0.65, 1.0)],
]

const HINT_COLOR_OPEN := Color(0.72, 0.85, 1.0)
const HINT_COLOR_LOCKED := Color(0.48, 0.54, 0.68)

## Decide quando il suggerimento in basso diventa visibile.
var hint_gate: HintGate = HintGate.new()

@onready var tables_box: HBoxContainer = $TablesScroll/TablesBox
@onready var console: SqlConsole = $Console
@onready var manual: SqlManual = $Overlays/Manual
@onready var manual_button: Button = $HUD/ManualButton
@onready var phase_title: Label = $HUD/PhaseTitle
@onready var objective_label: Label = $HUD/Objective
@onready var timer_label: Label = $HUD/TimerLabel
@onready var timer_bar: ProgressBar = $HUD/TimerBar
@onready var toast_label: Label = $HUD/Toast
@onready var hint_label: Label = $HUD/Hint
@onready var hud: Control = $HUD
@onready var banner: Panel = $Overlays/Banner
@onready var banner_title: Label = $Overlays/Banner/BannerTitle
@onready var banner_sub: Label = $Overlays/Banner/BannerSub
@onready var end_screen: Control = $Overlays/EndScreen
@onready var end_title: Label = $Overlays/EndScreen/Title
@onready var end_subtitle: Label = $Overlays/EndScreen/Subtitle
@onready var restart_button: Button = $Overlays/EndScreen/RestartButton
@onready var menu_button: Button = $Overlays/EndScreen/MenuButton

var db: SqlDatabase = SqlDatabase.new()
var is_over: bool = false
var current_phase: int = 0
var active_task: SqlTask = null
var manual_openings: int = 0
var pause_menu: PauseMenu = null

var _table_views: Dictionary = {}      # nome minuscolo -> SqlTableView
var _toast_tween: Tween = null
var _solved_count: int = 0


func _ready() -> void:
	_style_hud()
	end_screen.visible = false
	restart_button.pressed.connect(func(): GameManager.go_to_intro_2())
	menu_button.pressed.connect(func(): GameManager.go_to_menu())
	manual_button.pressed.connect(_on_manual_pressed)
	console.query_submitted.connect(_on_query_submitted)

	GameManager.time_updated.connect(_on_time_updated)
	GameManager.time_expired.connect(_on_time_expired)

	pause_menu = PauseMenu.new()
	pause_menu.restart_requested.connect(func(): GameManager.go_to_intro_2())
	pause_menu.resumed.connect(func(): console.focus_editor())
	$Overlays.add_child(pause_menu)

	_seed_database()
	refresh_tables(false)

	GameManager.start_level(GameManager.LEVEL2_DURATION)
	console.focus_editor()
	_run_level()


## ESC apre il menu di pausa (o chiude prima il manuale, se è aperto):
## da lì si può sempre tornare al menu principale e cambiare livello.
func _unhandled_input(event: InputEvent) -> void:
	if is_over or pause_menu == null:
		return
	if event.is_action_pressed("ui_cancel"):
		if manual.is_open():
			manual.close()
		else:
			pause_menu.toggle()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------- database ----

func _seed_database() -> void:
	db.clear()
	db.define("clienti",
		[["id", "INT"], ["nome", "VARCHAR(40)"], ["citta", "VARCHAR(40)"], ["eta", "INT"]],
		[
			[1, "Mario Rossi", "Roma", 34],
			[2, "Anna Bianchi", "Milano", 28],
			[3, "Luca Verdi", "Roma", 45],
			[4, "Sara Neri", "Napoli", 22],
			[5, "Elena Gallo", "Milano", 39],
		])
	db.define("ordini",
		[["id", "INT"], ["cliente_id", "INT"], ["totale", "INT"]],
		[
			[1, 1, 120],
			[2, 1, 40],
			[3, 3, 300],
			[4, 5, 90],
		])
	# Tabella spazzatura lasciata dall'attacco: verrà eliminata nella fase 4.
	db.define("temp_backup",
		[["id", "INT"], ["nota", "VARCHAR(60)"]],
		[
			[1, "dump parziale 03:14"],
			[2, "dump parziale 03:47"],
		])


## Ricostruisce le viste delle tabelle presenti nel database.
func refresh_tables(animate: bool = true) -> void:
	var live: Array[String] = db.table_names()

	for key in _table_views.keys():
		if not db.has_table(String(key)):
			var stale: SqlTableView = _table_views[key]
			_table_views.erase(key)
			if is_instance_valid(stale):
				stale.queue_free()

	for table in live:
		var key: String = table.to_lower()
		if not _table_views.has(key):
			var view: SqlTableView = SqlTableView.new(table)
			view.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			tables_box.add_child(view)
			_table_views[key] = view
		_table_views[key].refresh(db, animate)


# ---------------------------------------------------------- flusso fasi ----

func _run_level() -> void:
	for i in range(PHASE_SCRIPTS.size()):
		if is_over:
			return
		current_phase = i + 1
		hint_gate.reset_phase()
		var data: Array = PHASE_BANNERS[i]
		await show_banner(String(data[0]), String(data[1]), data[2])
		if is_over:
			return
		var script: GDScript = load(PHASE_SCRIPTS[i])
		var phase: SqlPhaseBase = script.new()
		phase.name = "Phase%d" % current_phase
		phase.level = self
		add_child(phase)
		await phase.run()
		if is_instance_valid(phase):
			phase.queue_free()
	if not is_over:
		_show_victory()


# ------------------------------------------------------------- obiettivi ---

func set_task(task: SqlTask, index: int, total: int) -> void:
	active_task = task
	set_objective("Obiettivo %d/%d — %s" % [index, total, task.prompt])
	set_hint(task.hint)
	console.show_message("In attesa della tua query...", SqlConsole.INFO_COLOR)


func _on_query_submitted(sql: String) -> void:
	if is_over:
		return
	if active_task == null:
		var preview: Dictionary = SqlEngine.execute(SqlTask._clone(db), sql)
		if bool(preview["ok"]) and String(preview["kind"]) == "select":
			console.show_result(preview)
			console.show_message(String(preview["message"]), SqlConsole.INFO_COLOR)
		else:
			console.show_message("Nessun obiettivo attivo in questo momento.", SqlConsole.INFO_COLOR)
		return

	var verdict: Dictionary = SqlTask.check(db, sql, active_task)
	var status: String = String(verdict["status"])
	var result: Dictionary = verdict["result"]

	if status == "error":
		Sfx.play("error")
		console.show_message("✗  %s" % verdict["message"], SqlConsole.ERR_COLOR)
		console.clear_result()
		toast("Query rifiutata dal database. Tempo -%d s" % int(PENALTY_SYNTAX), Color(1.0, 0.45, 0.45))
		penalty(PENALTY_SYNTAX)
		return

	if status == "wrong":
		Sfx.play("error")
		if String(result["kind"]) == "select":
			console.show_result(result)
		console.show_message("✗  %s" % verdict["message"], SqlConsole.ERR_COLOR)
		toast("La query è valida ma non risolve l'obiettivo. Tempo -%d s" % int(PENALTY_WRONG),
			Color(1.0, 0.45, 0.45))
		penalty(PENALTY_WRONG)
		return

	# Corretta: viene eseguita per davvero sul database del livello.
	var applied: Dictionary = SqlEngine.execute(db, sql)
	Sfx.play("correct")
	if String(applied["kind"]) == "select":
		console.show_result(applied)
	else:
		console.clear_result()
		refresh_tables(true)
	console.show_message("✓  %s" % applied["message"], SqlConsole.OK_COLOR)
	_solved_count += 1
	var task: SqlTask = active_task
	active_task = null
	toast("✓ " + (task.explain if task.explain != "" else "Obiettivo completato!"), Color(0.35, 1.0, 0.6))
	set_hint("")
	task_solved.emit()


# --------------------------------------------------------------- manuale ---

func _on_manual_pressed() -> void:
	if is_over or manual.is_open():
		return
	manual_openings += 1
	penalty(SqlManual.COST_SECONDS, false)
	Sfx.play("click")
	toast("Manuale aperto: -%d secondi." % int(SqlManual.COST_SECONDS), Color(1.0, 0.85, 0.45))
	manual.open_at(_suggested_manual_page())
	_update_manual_button()


## Apre il manuale sulla pagina utile alla fase in corso.
func _suggested_manual_page() -> int:
	match current_phase:
		1:
			return 0
		2:
			return 1 if db.has_table("prodotti") else 2
		3:
			return 1
		4:
			return 1
		5:
			return 3
	return 0


func _update_manual_button() -> void:
	manual_button.text = "MANUALE  -%ds   (aperto %d volte)" % [
		int(SqlManual.COST_SECONDS), manual_openings]


# ------------------------------------------------------------ HUD tools ----

func set_phase_header(title: String, color: Color) -> void:
	phase_title.text = title
	phase_title.add_theme_color_override("font_color", color)


func set_objective(text: String) -> void:
	objective_label.text = text


func set_hint(text: String) -> void:
	hint_gate.text = text
	_refresh_hint()
## Il suggerimento resta nascosto finché il giocatore non è davvero in
## difficoltà: la regola sta tutta in HintGate.
func _refresh_hint() -> void:
	hint_label.text = hint_gate.display()
	hint_label.add_theme_color_override("font_color",
		HINT_COLOR_OPEN if hint_gate.unlocked() else HINT_COLOR_LOCKED)


func toast(text: String, color: Color = Color.WHITE) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(3.0)
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


## `is_error` distingue lo sbaglio del giocatore da un costo scelto
## volontariamente (per esempio aprire il manuale): solo il primo
## avvicina lo sblocco del suggerimento.
func penalty(seconds: float, is_error: bool = true) -> void:
	GameManager.apply_penalty(seconds)
	if is_error:
		hint_gate.register_error()
		_refresh_hint()
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


# ------------------------------------------------------------------ timer --

func _on_time_updated(_time_left: float, ratio: float) -> void:
	timer_label.text = GameManager.formatted_time()
	_refresh_hint()
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
	manual.close()
	console.set_enabled(false)
	end_title.text = "TEMPO SCADUTO"
	end_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	end_subtitle.text = "Il database non è stato ripristinato in tempo.\nObiettivi completati: %d. Manuale consultato %d volte (-%d secondi in totale)." % [
		_solved_count, manual_openings, int(manual_openings * SqlManual.COST_SECONDS)]
	_show_end_screen()


func _show_victory() -> void:
	is_over = true
	GameManager.complete_level()
	Sfx.play("victory")
	console.set_enabled(false)
	end_title.text = "DATABASE RIPRISTINATO"
	end_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	end_subtitle.text = "Hai completato il Livello 2 con %s sul cronometro.\n\nHai usato sul campo: SELECT con WHERE, ORDER BY e aggregati,\nCREATE TABLE, INSERT, UPDATE, DELETE e query nidificate.\n\nManuale consultato %d volte." % [
		GameManager.formatted_time(), manual_openings]
	restart_button.text = "Gioca di nuovo"
	_show_end_screen()


func _show_end_screen() -> void:
	end_screen.visible = true
	end_screen.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(end_screen, "modulate:a", 1.0, 0.5)


# ------------------------------------------------------------------ style --

func _style_hud() -> void:
	phase_title.add_theme_font_size_override("font_size", 24)
	phase_title.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	objective_label.add_theme_font_size_override("font_size", 17)
	objective_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	timer_label.add_theme_font_size_override("font_size", 38)
	timer_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	toast_label.add_theme_font_size_override("font_size", 18)
	toast_label.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.08))
	toast_label.add_theme_constant_override("outline_size", 8)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 15)
	hint_label.add_theme_color_override("font_color", Color(0.6, 0.75, 0.92))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_title.add_theme_font_size_override("font_size", 38)
	banner_title.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.08))
	banner_title.add_theme_constant_override("outline_size", 8)
	banner_sub.add_theme_font_size_override("font_size", 18)
	banner_sub.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0))
	banner.pivot_offset = Vector2(470.0, 96.0)
	end_title.add_theme_font_size_override("font_size", 52)
	end_subtitle.add_theme_font_size_override("font_size", 19)
	end_subtitle.add_theme_color_override("font_color", Color(0.8, 0.88, 1.0))
	end_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	manual_button.add_theme_font_size_override("font_size", 16)
	manual_button.focus_mode = Control.FOCUS_NONE
	SqlConsole._style_button(manual_button, Color(0.3, 0.22, 0.05), Color(1.0, 0.82, 0.35))
	_update_manual_button()

	SqlConsole._style_button(restart_button, Color(0.12, 0.42, 0.28), Color(0.35, 1.0, 0.7))
	SqlConsole._style_button(menu_button, Color(0.16, 0.24, 0.44), Color(0.45, 0.7, 1.0))
	restart_button.add_theme_font_size_override("font_size", 19)
	menu_button.add_theme_font_size_override("font_size", 19)

	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 1.0, 0.55)
	fill.set_corner_radius_all(6)
	timer_bar.add_theme_stylebox_override("fill", fill)
	var bar_bg: StyleBoxFlat = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.15, 0.25, 0.9)
	bar_bg.set_corner_radius_all(6)
	timer_bar.add_theme_stylebox_override("background", bar_bg)
