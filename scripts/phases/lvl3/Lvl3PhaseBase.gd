class_name Lvl3PhaseBase
extends Node

## Base delle fasi del Livello 3.
##
## Ogni fase porta in scena il proprio strumento, quindi qui non ci sono
## mini-giochi condivisi come nel Livello 1: ci sono i servizi comuni
## (attesa, penalità, pulizia del palco) e le costanti di bilanciamento.

@warning_ignore("unused_signal")
signal finished
@warning_ignore("unused_signal")
signal helper_done

const COLOR_OK := Color(0.35, 1.0, 0.6)
const COLOR_BAD := Color(1.0, 0.45, 0.45)
const COLOR_INFO := Color(0.62, 0.82, 1.0)
const COLOR_WARN := Color(1.0, 0.82, 0.35)

## L'errore di esecuzione costa poco: si sta imparando a seguire una regola.
const PENALTY_STEP := 6.0
## Sbagliare una scelta ragionata costa di più.
const PENALTY_CHOICE := 10.0
## Programma che non compila: è una svista.
const PENALTY_SYNTAX := 8.0
## Programma valido ma che non risolve: è un errore di ragionamento.
const PENALTY_WRONG := 12.0

var level: Node = null                    # Level3 (controller)


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


## Registra una prova superata (finisce nel riepilogo finale).
func _score() -> void:
	if level != null:
		level.solved_count += 1


## Chiude la fase con un messaggio riassuntivo.
func complete(message: String) -> void:
	if _is_over():
		return
	Sfx.play("victory")
	level.toast(message, COLOR_OK)
	await _wait(1.4)
	finished.emit()
