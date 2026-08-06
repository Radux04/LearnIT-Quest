extends Lvl3PhaseBase

## FASE 5 — Calcolabilità e linguaggi di programmazione: il linguaggio WHILE.
##
## Qui non si clicca: si programma. Con tre soli costrutti (assegnamento,
## sequenza, ciclo while) si calcola tutto ciò che calcola una macchina di
## Turing. La correzione è per equivalenza: qualunque algoritmo corretto passa.

var _console: CodeConsole = null
var _task: WhileTask = null
var _solved: bool = false


func _start() -> void:
	level.set_phase_header("FASE 5 — IL LINGUAGGIO WHILE", Color(0.75, 0.65, 1.0))

	_console = CodeConsole.new()
	_console.code_submitted.connect(_on_code_submitted)
	level.mount(_console)
	_console.offset_left = 40.0
	_console.offset_right = -40.0
	_console.offset_top = 20.0
	_console.offset_bottom = -20.0
	_console.focus_editor()

	var tasks: Array = [
		WhileTask.make(
			"Metti in m il più grande fra x e y.",
			"if x < y then m := y else m := x end",
			[{"x": 3, "y": 8}, {"x": 9, "y": 2}, {"x": 5, "y": 5}, {"x": 0, "y": 0}],
			["m"],
			"if <condizione> then ... else ... end   ·   i confronti sono =, !=, <, <=, >, >=",
			"Il costrutto if sceglie fra due strade: nessun ciclo, quindi termina sempre."),
		WhileTask.make(
			"Metti in s la somma di tutti i numeri da 1 a n (con n = 0 la somma è 0).",
			"s := 0; i := n; while i != 0 do s := s + i; i := i - 1 end",
			[{"n": 0}, {"n": 1}, {"n": 5}, {"n": 10}],
			["s"],
			"Serve un ciclo: while <condizione> do ... end. Usa una variabile che scende fino a 0.",
			"Il ciclo termina perché il contatore cala di 1 a ogni giro: è una funzione TOTALE."),
		WhileTask.make(
			"Metti in q il quoziente intero di x diviso y, e in r il resto. Puoi assumere y > 0.",
			"q := 0; r := x; while r >= y do r := r - y; q := q + 1 end",
			[{"x": 0, "y": 3}, {"x": 7, "y": 2}, {"x": 12, "y": 4}, {"x": 5, "y": 9}],
			["q", "r"],
			"La divisione non esiste nel linguaggio: sottrai y finché puoi e conta quante volte.",
			"Hai costruito un operatore che il linguaggio non ha: è così che si estende la calcolabilità."),
		WhileTask.make(
			"Metti in f il fattoriale di n (0! vale 1).",
			"f := 1; i := n; while i != 0 do f := f * i; i := i - 1 end",
			[{"n": 0}, {"n": 1}, {"n": 4}, {"n": 6}],
			["f"],
			"Parti da f := 1 e moltiplica per i valori che scendono da n a 1.",
			"Con assegnamento, sequenza e while si calcola tutto il calcolabile: è la tesi di Church-Turing."),
	]

	for i in range(tasks.size()):
		if _is_over():
			return
		await _do_task(tasks[i], i + 1, tasks.size())

	if _is_over():
		return
	await complete("Hai programmato in WHILE: tre costrutti, la stessa potenza di una macchina di Turing.")


func _do_task(task: WhileTask, index: int, total: int) -> void:
	_task = task
	_solved = false
	level.set_objective("Programma %d/%d — %s" % [index, total, task.prompt])
	level.set_hint(task.hint)
	_console.show_message("In attesa del tuo programma...", CodeConsole.INFO_COLOR)
	_console.clear_result()

	await helper_done
	if _is_over():
		return
	await _wait(0.9)


func _on_code_submitted(source: String) -> void:
	if _is_over() or _task == null or _solved:
		return

	var verdict: Dictionary = WhileTask.check(_task, source)
	var status: String = String(verdict["status"])

	# Mostra comunque l'effetto sul primo caso di prova: vedere lo stato
	# cambiare è metà dell'apprendimento.
	if not _task.cases.is_empty():
		var demo: Dictionary = WhileTask.preview(source, _task.cases[0])
		if bool(demo.get("ok", false)):
			_console.show_state(_task.cases[0], demo)

	if status == "error":
		Sfx.play("error")
		level.penalty(PENALTY_SYNTAX)
		_console.show_message("✗  %s" % String(verdict["message"]), CodeConsole.ERR_COLOR)
		level.toast("Il programma non compila: -%d s." % int(PENALTY_SYNTAX), COLOR_BAD)
		return

	if status == "wrong":
		Sfx.play("error")
		level.penalty(PENALTY_WRONG)
		_console.show_message("✗  %s" % String(verdict["message"]), CodeConsole.ERR_COLOR)
		level.toast("Il programma gira ma non calcola quello che serve: -%d s." % int(PENALTY_WRONG), COLOR_BAD)
		return

	_solved = true
	Sfx.play("correct")
	_score()
	_console.show_message("✓  Corretto su tutti i casi di prova.", CodeConsole.OK_COLOR)
	level.toast(_task.explain, COLOR_OK)
	helper_done.emit()
