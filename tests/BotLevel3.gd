extends Node

## Bot che gioca il Livello 3 da solo, sempre in modo corretto.
## Legge lo stato della fase e calcola la mossa giusta dal model: se arriva
## alla schermata di vittoria senza errori, l'intera catena funziona.
##
## Eseguibile con:  godot tests/autoplay_level3.tscn

const TIME_SCALE := 3.0
const STEP := 0.10
## 0 = gioca tutto il livello. N = si ferma all'inizio della fase N e resta lì,
## a velocità normale: serve per guardare (e fotografare) quella fase.
const STOP_AT_PHASE := 0
## Secondi di attesa prima di rispondere a una scelta multipla. A 0 il bot
## risponde subito; alzandolo si fa in tempo a guardare (e fotografare) le
## alternative mostrate a schermo.
const CHOICE_DELAY := 0.0

var level: Node = null


func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	var scene: PackedScene = load("res://scenes/level3.tscn")
	level = scene.instantiate()
	add_child(level)
	print("[L3] livello istanziato")
	_play()


func _play() -> void:
	await get_tree().create_timer(2.4).timeout
	# Quattro fasi: la fase sul problema dell'arresto è fuori rotazione.
	for phase_index in range(1, 5):
		if level.is_over:
			break
		var started: bool = await _await_phase(phase_index)
		if not started or level.is_over:
			break
		if STOP_AT_PHASE > 0 and phase_index == STOP_AT_PHASE:
			Engine.time_scale = 1.0
			print("[L3] fermo all'inizio della fase %d" % phase_index)
			return
		print("[L3] --> fase %d" % phase_index)
		match phase_index:
			1:
				await _play_phase1()
			2:
				await _play_phase2()
			3:
				await _play_phase3()
			4:
				await _play_while()
	await get_tree().create_timer(2.0).timeout
	_report()


func _phase() -> Node:
	return level.phase_node


## Aspetta che la fase richiesta sia davvero in esecuzione.
## Se scade lo dice: altrimenti le fasi successive fingerebbero di riuscire.
func _await_phase(index: int) -> bool:
	var guard: int = 0
	while not level.is_over and guard < 600:
		if level.current_phase == index and level.phase_node != null:
			return true
		guard += 1
		await get_tree().create_timer(0.1).timeout
	if not level.is_over:
		print("[L3] ERRORE: la fase %d non e' mai partita (fermo alla fase %d)" % [
			index, level.current_phase])
	return false


func _wait() -> void:
	await get_tree().create_timer(STEP).timeout


# ------------------------------------------------------------------ fase 1 --

func _play_phase1() -> void:
	# Esegue il DFA cliccando lo stato giusto, poi risponde accetta/rifiuta.
	var guard: int = 0
	while level.current_phase == 1 and not level.is_over and guard < 400:
		guard += 1
		await _wait()
		var phase: Node = _phase()
		if phase == null:
			continue
		if phase._waiting_state:
			var node: StateNode = phase._view.get_node_for(phase._expected)
			if node != null:
				phase._on_state_clicked(phase._expected)
			continue
		# In attesa della decisione: cerca il pulsante giusto.
		_press_decision(phase)
	print("[L3] fase 1 completata")


func _press_decision(phase: Node) -> void:
	for child in level.action_bar.get_children():
		if not (child is Button):
			continue
		var button: Button = child
		if button.text != "ACCETTATA" and button.text != "RIFIUTATA":
			continue
		# Il verdetto giusto si ricava dal model: lo stato attivo è finale?
		var current: String = ""
		for state in phase._view.nodes.keys():
			var node: StateNode = phase._view.nodes[state]
			if node.get_mode() == StateNode.Mode.ACTIVE or node.get_mode() == StateNode.Mode.SUCCESS:
				current = state
		if current == "":
			return
		var accepted: bool = phase._automaton.is_accepting(current)
		# Premi SOLO il pulsante giusto: non uscire al primo esaminato.
		if (button.text == "ACCETTATA") == accepted:
			button.pressed.emit()
			return


# ------------------------------------------------------------------ fase 2 --

func _play_phase2() -> void:
	var guard: int = 0
	while level.current_phase == 2 and not level.is_over and guard < 300:
		guard += 1
		await _wait()
		var phase: Node = _phase()
		if phase == null or not phase._picking:
			continue
		# Ricava la richiesta corrente dal testo dell'obiettivo? No: si usa il
		# model, ricalcolando la mossa attesa dalla selezione richiesta.
		var expected: Array[String] = _expected_set(phase)
		if expected.is_empty() and phase._selected.is_empty():
			continue
		for state in expected:
			if not phase._selected.has(state):
				phase._on_state_clicked(state)
		for state in phase._selected.duplicate():
			if not expected.has(state):
				phase._on_state_clicked(state)
		await _wait()
		for child in level.action_bar.get_children():
			if child is Button:
				(child as Button).pressed.emit()
				break
	print("[L3] fase 2 completata")


## Rilegge dall'obiettivo l'insieme di partenza e il simbolo, poi chiede al model.
func _expected_set(phase: Node) -> Array[String]:
	var text: String = level.objective_label.text
	var open_brace: int = text.find("{")
	var close_brace: int = text.find("}")
	var quote: int = text.find("'")
	if open_brace < 0 or close_brace < 0 or quote < 0:
		return [] as Array[String]
	var inside: String = text.substr(open_brace + 1, close_brace - open_brace - 1)
	var symbol: String = text.substr(quote + 1, 1)
	var source: Array[String] = []
	for piece in inside.split(","):
		source.append(String(piece).strip_edges())
	return phase._automaton.move(source, symbol)


# ------------------------------------------------------------------ fase 3 --

func _play_phase3() -> void:
	var guard: int = 0
	while level.current_phase == 3 and not level.is_over and guard < 400:
		guard += 1
		await _wait()
		var phase: Node = _phase()
		if phase == null:
			continue
		if phase._waiting:
			phase._on_rule_clicked(phase._expected_key)
			continue
		# Scelta della regola mancante: la fase espone il testo dell'alternativa
		# corretta, così il bot funziona con qualunque esercizio del catalogo.
		if String(phase._correct_option) == "":
			continue
		if CHOICE_DELAY > 0.0:
			await get_tree().create_timer(CHOICE_DELAY).timeout
		for child in level.action_bar.get_children():
			if child is Button and (child as Button).text == String(phase._correct_option):
				(child as Button).pressed.emit()
				break
	print("[L3] fase 3 completata")


# --------------------------------------------- fase diagonale (disattivata) --
#
# Serve solo se si rimette Phase4.gd in PHASE_SCRIPTS di Level3.gd: in quel caso
# va richiamata con il numero di fase che le spetta.

func _play_diagonal(index: int) -> void:
	var guard: int = 0
	while level.current_phase == index and not level.is_over and guard < 300:
		guard += 1
		await _wait()
		var phase: Node = _phase()
		if phase == null:
			continue
		if phase._filling:
			for i in range(phase.SIZE):
				var wanted: bool = not phase._diagonal[i]
				if phase._built[i] != wanted:
					phase._on_cell_clicked(phase.SIZE, i)
			await _wait()
			phase._on_confirm_row()
			continue
		if phase._picking_row:
			phase._on_cell_clicked(phase._row_target, phase._row_target)
			continue
	print("[L3] fase diagonale completata")


# -------------------------------------------------- fase 4: linguaggio WHILE --

func _play_while() -> void:
	# Prima una prova di errore di sintassi e una di programma sbagliato.
	await get_tree().create_timer(0.6).timeout
	var phase: Node = _phase()
	if phase != null and not level.is_over:
		print("[L3] prova programma che non compila")
		phase._on_code_submitted("m := ")
		await _wait()
		print("[L3] prova programma valido ma sbagliato")
		phase._on_code_submitted("zzz := 0")
		await _wait()

	# Gli esercizi sono pescati a caso, quindi il bot non può avere soluzioni
	# fisse: usa la soluzione di riferimento dell'obiettivo corrente.
	var solved: int = 0  # quanti programmi risolti
	var guard: int = 0
	while level.current_phase == 4 and not level.is_over and guard < 600:
		guard += 1
		await _wait()
		phase = _phase()
		if phase == null or phase._task == null or phase._solved:
			continue
		var solution: String = String(phase._task.solution)
		phase._on_code_submitted(solution)
		solved += 1
		print("[L3] fase 4 — risolto il programma %d (%d righe)" % [solved, solution.split("\n").size()])
		await get_tree().create_timer(1.2).timeout
	print("[L3] fase 4 completata")


func _report() -> void:
	print("[L3] FINE — %s" % level.end_title.text)
	print("[L3] prove superate: %d" % level.solved_count)
	print("[L3] tempo rimasto: %s" % GameManager.formatted_time())
	print("[L3] livello finito: %s" % str(level.is_over))
	get_tree().quit()
