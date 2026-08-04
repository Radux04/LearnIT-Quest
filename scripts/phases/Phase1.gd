extends PhaseBase

## FASE 1 — Ricostruzione della rete.
## Solo il router radice è online. Il giocatore trascina gli altri 8 router
## nella posizione corretta. Le metriche sono decimali e volutamente vicine
## fra loro (25.5 / 25.9, 62.4 / 62.1): non basta guardare la parte intera.

const ROUTERS_TO_PLACE: Array[float] = [
	25.5, 74.5,        # livello 1
	12.8, 37.2, 62.4, 88.6,
	25.9, 62.1,        # coppie "trappola": vicinissime ai valori sopra
]


func _start() -> void:
	level.set_phase_header("FASE 1 — RICOSTRUZIONE DELLA RETE", Color(0.35, 0.85, 1.0))
	level.set_objective("Trascina ogni router nella postazione giusta: metriche MINORI a sinistra, MAGGIORI a destra.")
	level.set_hint("Attenzione ai decimali: 25.9 e 25.5 finiscono in due punti diversi della rete. Errore = -%d s." % int(PENALTY_PLACE))

	var values: Array[float] = ROUTERS_TO_PLACE.duplicate()
	values.shuffle()
	await place_routers(values, PENALTY_PLACE)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Rete ricostruita: %d router online, profondità %d." % [
		level.model.size(), level.model.max_depth()], COLOR_OK)
	await _wait(1.2)
	finished.emit()
