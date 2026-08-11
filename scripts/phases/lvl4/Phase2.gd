extends Lvl4PhaseBase

## FASE 2 — Principi SOLID.
##
## Due meccaniche diverse. Prima si indicano le righe che violano un principio
## (come nella revisione), poi si SEPARA una classe che fa troppe cose
## assegnando ogni metodo alla classe a cui appartiene: il principio di singola
## responsabilità applicato con un gesto invece che con una definizione.

var _view: CodeView = null
var _entry: Dictionary = {}
var _picking: bool = false

var _split: Dictionary = {}
var _assignment: Array[int] = []
var _buttons: Array[Button] = []


func _start() -> void:
	level.set_phase_header("FASE 2 — PRINCIPI SOLID", Color(0.4, 1.0, 0.7))

	# Primo giro: trovare la violazione in un codice dato.
	_view = CodeView.new()
	_view.line_clicked.connect(_on_line_clicked)
	level.mount(_view)
	_view.offset_left = 120.0
	_view.offset_right = -120.0
	_view.offset_bottom = -110.0

	for entry in Lvl4Pools.pick_topic(Lvl4Pools.REVIEW_POOL, "solid", 1):
		if _is_over():
			return
		await _violation_round(entry)

	if _is_over():
		return
	level.clear_stage()
	_view = null

	# Secondo giro: separare le responsabilità.
	await _split_round(Lvl4Pools.pick_one(Lvl4Pools.SPLIT_POOL))
	if _is_over():
		return

	await complete("I principi SOLID servono a una cosa sola: poter cambiare il codice senza avere paura.")


# ------------------------------------------------- giro 1: trova il difetto --

func _violation_round(entry: Dictionary) -> void:
	_entry = entry
	_view.setup(String(entry["code"]), "REVISIONE  ·  %s" % String(entry["name"]))
	_view.clickable = true
	_picking = true

	level.set_objective(String(entry["question"]))
	level.set_hint(String(entry["hint"]))

	var confirm: Button = level.make_action_button("CONFERMA",
		Vector2(level.size.x * 0.5, level.size.y - 96.0), Vector2(280.0, 52.0))
	confirm.pressed.connect(_on_confirm_violation)

	await helper_done
	_picking = false
	_view.clickable = false
	level.clear_action_bar()
	await _wait(1.2)


func _on_line_clicked(index: int) -> void:
	if not _picking or _is_over():
		return
	Sfx.play("click")
	_view.toggle(index)


func _on_confirm_violation() -> void:
	if not _picking or _is_over():
		return
	var chosen: Array[int] = _view.selected_lines()
	var expected: Array = _entry["bad"]

	var correct: bool = chosen.size() == expected.size()
	if correct:
		for line in expected:
			if not chosen.has(int(line)):
				correct = false

	if correct:
		_picking = false
		Sfx.play("correct")
		_score()
		for line in expected:
			_view.mark(int(line), CodeView.Mark.CORRECT)
		level.toast(String(_entry["explain"]), COLOR_OK)
		helper_done.emit()
		return

	Sfx.play("error")
	level.penalty(PENALTY_CHOICE)
	level.toast("Non è quella la riga che crea il problema. Chiediti che cosa ti costringerebbe a riaprire questa classe.", COLOR_BAD)


# ------------------------------------------- giro 2: separa le responsabilità --

func _split_round(entry: Dictionary) -> void:
	_split = entry
	_assignment.clear()
	_buttons.clear()

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	level.mount(box)
	box.offset_left = 220.0
	box.offset_right = -220.0
	box.offset_top = 40.0

	var caption: Label = Label.new()
	caption.text = "La classe %s fa troppe cose. Clicca ogni metodo per spostarlo nella classe giusta." % String(entry["origin"])
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_color", COLOR_INFO)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(caption)

	var methods: Array = entry["methods"]
	for i in range(methods.size()):
		_assignment.append(0)
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 52.0)
		button.add_theme_font_size_override("font_size", 16)
		button.focus_mode = Control.FOCUS_NONE
		var index: int = i
		button.pressed.connect(func() -> void: _cycle(index))
		box.add_child(button)
		_buttons.append(button)
		_refresh(i)

	level.set_objective("Assegna ogni metodo alla classe a cui appartiene, poi conferma.")
	level.set_hint(String(entry["hint"]))

	var confirm: Button = level.make_action_button("CONFERMA LA SEPARAZIONE",
		Vector2(level.size.x * 0.5, level.size.y - 96.0), Vector2(340.0, 52.0))
	confirm.pressed.connect(_on_confirm_split)

	await helper_done
	level.clear_action_bar()
	await _wait(1.2)


func _cycle(index: int) -> void:
	if _is_over():
		return
	Sfx.play("click")
	var targets: Array = _split["targets"]
	_assignment[index] = (_assignment[index] + 1) % targets.size()
	_refresh(index)


func _refresh(index: int) -> void:
	var methods: Array = _split["methods"]
	var targets: Array = _split["targets"]
	var target: int = _assignment[index]
	var button: Button = _buttons[index]
	button.text = "%s        →   %s" % [String(methods[index][0]), String(targets[target])]
	var base: Color = Color(0.10, 0.20, 0.34) if target == 0 else Color(0.22, 0.14, 0.30)
	var border: Color = Color(0.40, 0.70, 1.0) if target == 0 else Color(0.80, 0.60, 1.0)
	SqlConsole._style_button(button, base, border)


func _on_confirm_split() -> void:
	if _is_over():
		return
	var methods: Array = _split["methods"]
	var wrong_index: int = -1
	for i in range(methods.size()):
		if _assignment[i] != int(methods[i][1]):
			wrong_index = i
			break

	if wrong_index == -1:
		Sfx.play("correct")
		_score()
		for button in _buttons:
			button.disabled = true
		level.toast(String(_split["explain"]), COLOR_OK)
		helper_done.emit()
		return

	Sfx.play("error")
	level.penalty(PENALTY_CHOICE)
	var targets: Array = _split["targets"]
	level.toast("«%s» non sta bene in %s: chiediti per quale motivo quel metodo cambierebbe." % [
		String(methods[wrong_index][0]), String(targets[_assignment[wrong_index]])], COLOR_BAD)
