class_name Lvl4PhaseBase
extends Node

## Base delle fasi del Livello 4.

@warning_ignore("unused_signal")
signal finished
@warning_ignore("unused_signal")
signal helper_done

const COLOR_OK := Color(0.35, 1.0, 0.6)
const COLOR_BAD := Color(1.0, 0.45, 0.45)
const COLOR_INFO := Color(0.62, 0.82, 1.0)
const COLOR_WARN := Color(1.0, 0.82, 0.35)

## Individuare male un difetto costa poco: si sta imparando a vedere.
const PENALTY_REVIEW := 8.0
## Sbagliare la separazione delle responsabilità costa di più: è una scelta.
const PENALTY_CHOICE := 10.0
## Codice che non sta in piedi (graffe, nessuna classe): è una svista.
const PENALTY_SYNTAX := 8.0
## Codice valido ma che non rispetta le regole richieste.
const PENALTY_WRONG := 12.0

var level: Node = null


func run() -> void:
	@warning_ignore("redundant_await")
	await _start()
	_cleanup()


func _start() -> void:
	pass


func _cleanup() -> void:
	if level == null:
		return
	level.clear_action_bar()
	level.clear_stage()
	level.set_hint("")


func _is_over() -> bool:
	return level == null or level.is_over


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _score() -> void:
	if level != null:
		level.solved_count += 1


func complete(message: String) -> void:
	if _is_over():
		return
	Sfx.play("victory")
	level.toast(message, COLOR_OK)
	await _wait(1.4)
	finished.emit()
