class_name WhileTask
extends RefCounted

## Un obiettivo di programmazione in WHILE.
##
## Come nel Livello 2, la correzione non guarda il TESTO del programma ma il suo
## EFFETTO: il programma del giocatore e quello di riferimento vengono eseguiti
## sugli stessi stati iniziali e si confrontano i valori delle variabili di
## uscita. Così qualsiasi algoritmo corretto viene accettato, anche se diverso
## da quello che avevamo in mente.

const STEP_LIMIT := 20000

var prompt: String = ""            # cosa deve calcolare il giocatore
var solution: String = ""          # un programma di riferimento
var hint: String = ""              # suggerimento mostrato in basso
var explain: String = ""           # spiegazione mostrata quando riesce
var cases: Array = []              # stati iniziali di prova (Dictionary)
var outputs: Array[String] = []    # variabili da confrontare


static func make(task_prompt: String, task_solution: String, test_cases: Array,
		output_vars: Array, task_hint: String = "", task_explain: String = "") -> WhileTask:
	var task: WhileTask = WhileTask.new()
	task.prompt = task_prompt
	task.solution = task_solution
	task.cases = test_cases
	for name in output_vars:
		task.outputs.append(String(name))
	task.hint = task_hint
	task.explain = task_explain
	return task


## Ritorna { "status": "ok"|"error"|"wrong", "message": String, "trace": Dictionary }
static func check(task: WhileTask, player_source: String) -> Dictionary:
	var parsed: Dictionary = WhileInterpreter.parse(player_source)
	if not bool(parsed["ok"]):
		return {"status": "error", "message": String(parsed["error"]), "trace": {}}

	for initial_state in task.cases:
		var mine: Dictionary = WhileInterpreter.run_ast(parsed["ast"], initial_state, STEP_LIMIT)

		if not bool(mine["terminated"]):
			return {"status": "wrong",
				"message": "Con %s il programma non si ferma. Un programma WHILE che cicla calcola una funzione PARZIALE: qui serve che termini sempre." % _describe(initial_state),
				"trace": mine}

		var expected: Dictionary = WhileInterpreter.run(task.solution, initial_state, STEP_LIMIT)
		if not bool(expected["ok"]) or not bool(expected["terminated"]):
			# Non deve mai capitare: vuol dire che la soluzione del livello è sbagliata.
			return {"status": "error",
				"message": "Soluzione di riferimento non valida: %s" % expected.get("error", "non termina"),
				"trace": mine}

		for var_name in task.outputs:
			var got: int = int(mine["state"].get(var_name, 0))
			var want: int = int(expected["state"].get(var_name, 0))
			if got != want:
				return {"status": "wrong",
					"message": "Con %s la variabile %s vale %d, ma doveva valere %d." % [
						_describe(initial_state), var_name, got, want],
					"trace": mine}

	return {"status": "ok", "message": "", "trace": {}}


## Esegue il programma per mostrarne il risultato in console, senza giudicarlo.
static func preview(source: String, initial_state: Dictionary) -> Dictionary:
	return WhileInterpreter.run(source, initial_state, STEP_LIMIT)


static func _describe(initial_state: Dictionary) -> String:
	if initial_state.is_empty():
		return "lo stato iniziale vuoto"
	var parts: PackedStringArray = PackedStringArray()
	var names: Array = initial_state.keys()
	names.sort()
	for name in names:
		parts.append("%s=%d" % [String(name), int(initial_state[name])])
	return ", ".join(parts)
