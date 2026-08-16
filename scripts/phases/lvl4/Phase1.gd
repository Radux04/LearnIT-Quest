extends Lvl4PhaseBase

## FASE 1 — Revisione del codice: clean code.
##
## Il gesto del revisore è indicare la riga che non va, e qui è esattamente
## quello: si clicca sulle righe difettose e si conferma. Non si risponde a
## domande sul clean code, lo si applica.

const ROUNDS := 2

var _view: CodeView = null
var _entry: Dictionary = {}
var _picking: bool = false


func _start() -> void:
	level.set_phase_header("FASE 1 — REVISIONE: CLEAN CODE", Color(0.4, 0.85, 1.0))

	_view = CodeView.new()
	_view.line_clicked.connect(_on_line_clicked)
	level.mount(_view)
	_view.offset_left = 120.0
	_view.offset_right = -120.0
	_view.offset_bottom = -110.0

	for entry in Lvl4Catalogo.pick_topic(Lvl4Catalogo.review_pool(), "clean", ROUNDS):
		if _is_over():
			return
		await _round(entry)

	if _is_over():
		return
	await complete("Il clean code non è questione di gusto: nomi, lunghezza e duplicazione si vedono e si misurano.")


func _round(entry: Dictionary) -> void:
	_entry = entry
	_view.setup(String(entry["code"]), "REVISIONE  ·  %s" % String(entry["name"]))
	_view.clickable = true
	_picking = true

	level.set_objective(String(entry["question"]))
	level.set_hint(String(entry["hint"]))

	var confirm: Button = level.make_action_button("CONFERMA LA REVISIONE",
		Vector2(level.size.x * 0.5, level.size.y - 96.0), Vector2(320.0, 52.0))
	confirm.pressed.connect(_on_confirm)

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


func _on_confirm() -> void:
	if not _picking or _is_over():
		return

	var chosen: Array[int] = _view.selected_lines()
	var expected: Array = _entry["bad"]

	var missing: Array[int] = []
	var extra: Array[int] = []
	for line in expected:
		if not chosen.has(int(line)):
			missing.append(int(line))
	for line in chosen:
		if not expected.has(line):
			extra.append(line)

	if missing.is_empty() and extra.is_empty():
		_picking = false
		Sfx.play("correct")
		_score()
		for line in expected:
			_view.mark(int(line), CodeView.Mark.CORRECT)
		level.toast(String(_entry["explain"]), COLOR_OK)
		helper_done.emit()
		return

	Sfx.play("error")
	level.penalty(PENALTY_REVIEW)
	if not extra.is_empty():
		_view.mark(extra[0], CodeView.Mark.WRONG)
		_view.shake_row(extra[0])
		level.toast("La riga %d non ha niente che non va: guarda meglio prima di segnalarla." % (extra[0] + 1), COLOR_BAD)
	else:
		level.toast("Manca ancora %d riga/e: rileggi il codice cercando lo stesso difetto altrove." % missing.size(), COLOR_BAD)
