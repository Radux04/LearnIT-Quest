class_name HintGate
extends RefCounted

## Decide QUANDO mostrare il suggerimento in basso.
##
## Il suggerimento spesso contiene mezza risposta: se è visibile subito, il
## giocatore non prova nemmeno a ragionare. Resta quindi nascosto finché non
## serve davvero, cioè quando il giocatore è in difficoltà:
##   - ha sbagliato almeno ERRORS_TO_UNLOCK volte nella fase corrente, oppure
##   - è fermo sulla fase corrente da TIME_RATIO_TO_UNLOCK del tempo totale.
##
## ENTRAMBE le condizioni ripartono da zero a ogni fase: all'inizio di una fase
## il suggerimento torna sempre bloccato. Se il tempo si misurasse dall'inizio
## del livello, superata la soglia una volta il suggerimento resterebbe visibile
## per tutte le fasi successive — esattamente ciò che non vogliamo.

const ERRORS_TO_UNLOCK := 5
const TIME_RATIO_TO_UNLOCK := 0.10

var errors: int = 0                    # errori commessi nella fase corrente
var text: String = ""                  # il suggerimento vero, quando si sblocca
var phase_start: float = 0.0           # GameManager.elapsed_time a inizio fase


func reset_phase() -> void:
	errors = 0
	phase_start = GameManager.elapsed_time


## Da quanti secondi si è fermi sulla fase corrente. Non conta il tempo passato
## in pausa né quello tolto dalle penalità: conta solo il tempo per pensare.
func seconds_in_phase() -> float:
	return maxf(GameManager.elapsed_time - phase_start, 0.0)


## Quanti secondi sulla stessa fase sbloccano il suggerimento.
func seconds_to_unlock() -> float:
	return TIME_RATIO_TO_UNLOCK * GameManager.level_duration


func register_error() -> void:
	errors += 1


func unlocked() -> bool:
	if errors >= ERRORS_TO_UNLOCK:
		return true
	return seconds_in_phase() >= seconds_to_unlock()


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
	var seconds: float = seconds_to_unlock() - seconds_in_phase()
	if seconds <= 0.0:
		return "subito"
	var total: int = int(ceil(seconds))
	@warning_ignore("integer_division")
	return "fra %d:%02d" % [total / 60, total % 60]
