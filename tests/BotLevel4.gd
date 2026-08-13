extends Node

## Bot che gioca il Livello 4 da solo, sempre in modo corretto.
## Legge dalle fasi la risposta attesa (righe difettose, assegnazioni, soluzioni
## di riferimento), quindi continua a funzionare con qualunque esercizio venga
## aggiunto al catalogo.
##
## Eseguibile con:  godot tests/autoplay_level4.tscn

const TIME_SCALE := 3.0
const STEP := 0.10
## 0 = gioca tutto. N = si ferma all'inizio della fase N per poterla guardare.
const STOP_AT_PHASE := 0
## Secondi di attesa prima di confermare una risposta. A 0 il bot conferma
## subito; alzandolo si fa in tempo a guardare (e fotografare) la schermata.
const CONFIRM_DELAY := 0.0

var level: Node = null


func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	var scene: PackedScene = load("res://scenes/level4.tscn")
	level = scene.instantiate()
	add_child(level)
	print("[L4] livello istanziato")
	_play()


func _play() -> void:
	await get_tree().create_timer(1.0).timeout
	for phase_index in range(1, 5):
		if level.is_over:
			break
		var started: bool = await _await_phase(phase_index)
		if not started or level.is_over:
			break
		if STOP_AT_PHASE > 0 and phase_index == STOP_AT_PHASE:
			Engine.time_scale = 1.0
			print("[L4] fermo all'inizio della fase %d" % phase_index)
			return
		print("[L4] --> fase %d" % phase_index)
		match phase_index:
			1:
				await _play_review()
			2:
				await _play_solid()
			3, 4:
				await _play_editor(phase_index)
	await get_tree().create_timer(2.0).timeout
	_report()


func _phase() -> Node:
	return level.phase_node


func _await_phase(index: int) -> bool:
	var guard: int = 0
	while not level.is_over and guard < 600:
		if level.current_phase == index and level.phase_node != null:
			return true
		guard += 1
		await get_tree().create_timer(0.1).timeout
	if not level.is_over:
		print("[L4] ERRORE: la fase %d non e' mai partita (fermo alla fase %d)" % [
			index, level.current_phase])
	return false


func _wait() -> void:
	await get_tree().create_timer(STEP).timeout


# ------------------------------------------------ fase 1: revisione visiva --

func _play_review() -> void:
	var guard: int = 0
	while level.current_phase == 1 and not level.is_over and guard < 400:
		guard += 1
		await _wait()
		var phase: Node = _phase()
		if phase == null or not phase._picking:
			continue
		_select_bad_lines(phase)
		await _wait()
		_press_first_button()
	print("[L4] fase 1 completata")


func _select_bad_lines(phase: Node) -> void:
	var expected: Array = phase._entry["bad"]
	for line in expected:
		if phase._view.mark_of(int(line)) != CodeView.Mark.SELECTED:
			phase._on_line_clicked(int(line))
	# Toglie eventuali selezioni di troppo.
	for line in phase._view.selected_lines():
		if not expected.has(line):
			phase._on_line_clicked(line)


func _press_first_button() -> void:
	for child in level.action_bar.get_children():
		if child is Button:
			(child as Button).pressed.emit()
			return


# --------------------------------------------------------- fase 2: SOLID ----

func _play_solid() -> void:
	var guard: int = 0
	while level.current_phase == 2 and not level.is_over and guard < 400:
		guard += 1
		await _wait()
		var phase: Node = _phase()
		if phase == null:
			continue

		if phase._picking and phase._view != null:
			_select_bad_lines(phase)
			await _wait()
			_press_first_button()
			continue

		# Separazione delle responsabilità: porta ogni metodo alla classe giusta.
		if not phase._split.is_empty() and not phase._buttons.is_empty():
			var methods: Array = phase._split["methods"]
			var ready_to_confirm: bool = true
			for i in range(methods.size()):
				var wanted: int = int(methods[i][1])
				if phase._assignment[i] != wanted:
					phase._cycle(i)
					ready_to_confirm = false
			if ready_to_confirm:
				await _wait()
				if CONFIRM_DELAY > 0.0:
					await get_tree().create_timer(CONFIRM_DELAY).timeout
				_press_first_button()
	print("[L4] fase 2 completata")


# ----------------------------------------------- fasi 3 e 4: editor Java ----

func _play_editor(index: int) -> void:
	# Una prova di codice rotto e una di codice valido ma non conforme.
	await get_tree().create_timer(0.6).timeout
	var phase: Node = _phase()
	if phase != null and not level.is_over:
		print("[L4] suggerimento prima degli errori: %s" % level.hint_label.text)
		print("[L4] prova codice con graffe sbilanciate")
		phase._on_code_submitted("public class Rotta {")
		await _wait()
		# Cinque errori in tutto: e' la soglia che sblocca il suggerimento.
		for i in range(4):
			phase._on_code_submitted("public class Vuota {\n}")
			await _wait()
		print("[L4] errori commessi nella fase: %d  ·  secondi sulla fase: %.0f" % [
			level.hint_gate.errors, level.hint_gate.seconds_in_phase()])
		print("[L4] suggerimento dopo 5 errori: %s" % level.hint_label.text)
		print("[L4] sbloccato? %s" % str(level.hint_gate.unlocked()))

	var solved: int = 0
	var guard: int = 0
	while level.current_phase == index and not level.is_over and guard < 600:
		guard += 1
		await _wait()
		phase = _phase()
		if phase == null or phase._task == null or phase._solved:
			continue
		var solution: String = _solution_for(phase._task)
		if solution == "":
			print("[L4] ERRORE: nessuna soluzione per «%s»" % phase._task.prompt)
			break
		phase._on_code_submitted(solution)
		solved += 1
		print("[L4] fase %d — risolto l'esercizio %d" % [index, solved])
		await get_tree().create_timer(1.0).timeout
	print("[L4] fase %d completata" % index)


## Ritrova nel catalogo la soluzione di riferimento dell'esercizio corrente.
func _solution_for(task: JavaTask) -> String:
	for pool in [Lvl4Pools.REFACTOR_POOL, Lvl4Pools.WRITE_POOL]:
		for entry in pool:
			if String(entry["prompt"]) == task.prompt:
				return String(entry["solution"])
	return ""


func _report() -> void:
	print("[L4] FINE - %s" % level.end_title.text)
	print("[L4] prove superate: %d" % level.solved_count)
	print("[L4] tempo rimasto: %s" % GameManager.formatted_time())
	print("[L4] livello concluso: %s" % str(level.is_over))
	get_tree().quit()
