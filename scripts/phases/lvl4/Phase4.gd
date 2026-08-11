extends Lvl4PhaseBase

## FASE 4 — Scrivere codice nuovo.
##
## Tre esercizi di scrittura: una classe ben incapsulata, una schermata JavaFX
## e la mappatura di un oggetto verso una forma persistente (JPA/Hibernate
## oppure XML con JAXB). Sempre correzione strutturale.

var _console: CodeConsole = null
var _task: JavaTask = null
var _solved: bool = false


func _start() -> void:
	level.set_phase_header("FASE 4 — SCRIVI IL CODICE", Color(0.75, 0.65, 1.0))

	_console = CodeConsole.new()
	_console.title_text = "EDITOR JAVA"
	_console.placeholder = "Scrivi qui il codice e premi Controlla (Ctrl+Invio)"
	_console.run_label = "▶  Controlla"
	_console.code_submitted.connect(_on_code_submitted)
	level.mount(_console)
	_console.offset_left = 40.0
	_console.offset_right = -40.0
	_console.offset_top = 16.0
	_console.offset_bottom = -20.0

	# Un esercizio per argomento: la classe, l'interfaccia grafica, la persistenza.
	var chosen: Array = []
	chosen.append_array(Lvl4Pools.pick_topic(Lvl4Pools.WRITE_POOL, "classe", 1))
	chosen.append_array(Lvl4Pools.pick_topic(Lvl4Pools.WRITE_POOL, "javafx", 1))
	chosen.append_array(Lvl4Pools.pick_topic(Lvl4Pools.WRITE_POOL, "persistenza", 1))

	for i in range(chosen.size()):
		if _is_over():
			return
		await _do_task(Lvl4Pools.build_task(chosen[i]), i + 1, chosen.size())

	if _is_over():
		return
	await complete("Incapsulamento, interfaccia grafica e persistenza: tre strati diversi, ognuno con le sue regole.")


func _do_task(task: JavaTask, index: int, total: int) -> void:
	_task = task
	_solved = false
	level.set_objective("Esercizio %d/%d — %s" % [index, total, task.prompt])
	level.set_hint(task.hint)
	_console.prefill(task.starting_code)
	_console.show_message("Scrivi il codice e premi Controlla.", CodeConsole.INFO_COLOR)
	_console.clear_result()
	_console.focus_editor()

	await helper_done
	if _is_over():
		return
	await _wait(1.0)


func _on_code_submitted(source: String) -> void:
	if _is_over() or _task == null or _solved:
		return

	var verdict: Dictionary = JavaTask.check(_task, source)
	var status: String = String(verdict["status"])
	_console.show_analysis(source)

	if status == "error":
		Sfx.play("error")
		level.penalty(PENALTY_SYNTAX)
		_console.show_message("✗  %s" % String(verdict["message"]), CodeConsole.ERR_COLOR)
		return

	if status == "wrong":
		Sfx.play("error")
		level.penalty(PENALTY_WRONG)
		_console.show_message("✗  %s" % String(verdict["message"]), CodeConsole.ERR_COLOR)
		return

	_solved = true
	Sfx.play("correct")
	_score()
	_console.show_message("✓  Tutti i controlli superati.", CodeConsole.OK_COLOR)
	level.toast(_task.explain, COLOR_OK)
	helper_done.emit()
