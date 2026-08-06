class_name SqlPhaseBase
extends Node

## Base delle fasi del Livello 2. Una fase è una sequenza di obiettivi:
## per ognuno mostra la richiesta e aspetta che il giocatore scriva una query
## equivalente alla soluzione, poi passa al successivo.

@warning_ignore("unused_signal")
signal finished

const COLOR_OK := Color(0.35, 1.0, 0.6)
const COLOR_BAD := Color(1.0, 0.45, 0.45)
const COLOR_INFO := Color(0.6, 0.82, 1.0)

var level: Node = null                # Level2Controller


func run() -> void:
	@warning_ignore("redundant_await")
	await _start()
	_cleanup()


func _start() -> void:
	pass


func _cleanup() -> void:
	if level != null:
		level.active_task = null
		level.set_hint("")


func _is_over() -> bool:
	return level == null or level.is_over


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Propone gli obiettivi uno alla volta e ritorna quando sono tutti risolti.
func do_tasks(tasks: Array) -> void:
	for i in range(tasks.size()):
		if _is_over():
			return
		level.set_task(tasks[i], i + 1, tasks.size())
		await level.task_solved
		if _is_over():
			return
		await _wait(0.8)


## Chiude la fase con un messaggio riassuntivo.
func complete(message: String) -> void:
	if _is_over():
		return
	Sfx.play("victory")
	level.toast(message, COLOR_OK)
	await _wait(1.3)
	finished.emit()
