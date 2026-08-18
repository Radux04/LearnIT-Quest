extends Lvl1PhaseBase

## FASE 1 — Costruzione del BST.
## La radice è già presente. Il giocatore trascina gli altri valori nello slot
## corretto applicando la proprietà di ordinamento a ogni livello.

const ROUTERS_TO_PLACE: Array[float] = [
	25.5, 74.5,        # livello 1
	12.8, 37.2, 62.4, 88.6,
	25.9, 62.1,        # coppie "trappola": vicinissime ai valori sopra
]


func _start() -> void:
	level.set_phase_header("FASE 1 — COSTRUISCI IL BST", Color(0.35, 0.85, 1.0))
	level.set_objective("Trascina ogni valore nello slot corretto: MINORI a sinistra, MAGGIORI a destra.")
	level.set_hint("Confronta a ogni nodo, non solo con la radice. Attenzione ai decimali: errore = -%d s." % int(PENALTY_PLACE))

	var values: Array[float] = ROUTERS_TO_PLACE.duplicate()
	values.shuffle()
	await place_routers(values, PENALTY_PLACE)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("BST costruito: %d nodi, profondità %d." % [
		level.model.size(), level.model.max_depth()], COLOR_OK)
	await _wait(1.2)
	finished.emit()
