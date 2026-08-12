class_name HintGate
extends RefCounted

## Decide QUANDO mostrare il suggerimento in basso.
##
## Il suggerimento spesso contiene mezza risposta: se è visibile subito, il
## giocatore non prova nemmeno a ragionare. Resta quindi nascosto finché non
## serve davvero, cioè quando il giocatore è in difficoltà:
##   - ha sbagliato almeno ERRORS_TO_UNLOCK volte NELLA FASE CORRENTE, oppure
##   - è trascorso TIME_RATIO_TO_UNLOCK del tempo totale del livello.
##
## Il conteggio degli errori riparte a ogni fase: chi è andato liscio nelle
## prime fasi non si ritrova il suggerimento già sbloccato nell'ultima.

const ERRORS_TO_UNLOCK := 5
const TIME_RATIO_TO_UNLOCK := 0.25

var errors: int = 0                    # errori commessi nella fase corrente
var text: String = ""                  # il suggerimento vero, quando si sblocca


func reset_phase() -> void:
	errors = 0


func register_error() -> void:
	errors += 1


func unlocked() -> bool:
	if errors >= ERRORS_TO_UNLOCK:
		return true
	return GameManager.elapsed_ratio() >= TIME_RATIO_TO_UNLOCK


## Che cosa scrivere nella riga in basso.
func display() -> String:
	if text.strip_edges().is_empty():
		return ""
	if unlocked():
		return text
	return "🔒  Suggerimento: si sblocca dopo %s, oppure %s." % [
		_errors_left_text(), _time_left_text()]


func _errors_left_text() -> String:
	var missing: int = ERRORS_TO_UNLOCK - errors
	if missing <= 1:
		return "un altro errore in questa fase"
	return "altri %d errori in questa fase" % missing


func _time_left_text() -> String:
	var seconds: float = GameManager.time_until_ratio(TIME_RATIO_TO_UNLOCK)
	if seconds <= 0.0:
		return "subito"
	var total: int = int(ceil(seconds))
	@warning_ignore("integer_division")
	return "fra %d:%02d" % [total / 60, total % 60]
