extends Lvl3PhaseBase

## FASE 2 — Non determinismo e trasformazione NFA → DFA.
##
## Il giocatore esegue a mano la costruzione per sottoinsiemi: dato l'insieme
## di stati attivo e un simbolo, seleziona TUTTI gli stati raggiungibili.
## È il passaggio che dimostra che il non determinismo non aggiunge potenza.

var _view: AutomatonView = null
var _automaton: Automaton = null
var _selected: Array[String] = []
var _picking: bool = false


func _start() -> void:
	level.set_phase_header("FASE 2 — DETERMINIZZAZIONE", Color(0.4, 1.0, 0.7))

	_view = AutomatonView.new()
	_view.state_clicked.connect(_on_state_clicked)
	level.mount(_view)

	# NFA che accetta le parole che FINISCONO per "ab".
	# Da q0 leggendo 'a' si può restare in q0 oppure andare in q1: è la scelta
	# non deterministica che il giocatore deve imparare a considerare tutta insieme.
	var nfa: Automaton = Automaton.make(["q0", "q1", "q2"], ["a", "b"], "q0", ["q2"])
	nfa.add_transition("q0", "a", "q0")
	nfa.add_transition("q0", "b", "q0")
	nfa.add_transition("q0", "a", "q1")
	nfa.add_transition("q1", "b", "q2")

	await _build(nfa,
		[["q0"], "a"],
		"Da q0 con 'a' l'automa può fare DUE cose: restare o avanzare. Selezionale entrambe.")
	if _is_over():
		return
	await _build(nfa, [["q0", "q1"], "b"],
		"Considera ogni stato dell'insieme, uno per uno, e unisci i risultati.")
	if _is_over():
		return
	await _build(nfa, [["q0", "q2"], "a"],
		"q2 non ha frecce uscenti con 'a': non contribuisce nulla.")
	if _is_over():
		return

	# Secondo automa, con transizioni ε: la ε-chiusura entra nel gioco.
	var eps: Automaton = Automaton.make(["p0", "p1", "p2"], ["a", "b"], "p0", ["p2"])
	eps.add_transition("p0", Automaton.EPSILON, "p1")
	eps.add_transition("p0", "a", "p0")
	eps.add_transition("p1", "b", "p2")
	eps.add_transition("p2", "a", "p2")

	await _build(eps, [["p0", "p1"], "a"],
		"Dopo la mossa aggiungi sempre la ε-chiusura: da p0 si scivola in p1 senza leggere nulla.")
	if _is_over():
		return

	await complete("Ogni automa non deterministico ha un equivalente deterministico: cambia la comodità, non la potenza.")


## Un passo della costruzione: dato (insieme, simbolo), il giocatore seleziona
## l'insieme di arrivo e conferma.
func _build(automaton: Automaton, request: Array, hint: String) -> void:
	_automaton = automaton
	_view.setup(automaton)
	level.set_hint(hint)

	var source_set: Array = request[0]
	var symbol: String = String(request[1])
	var expected: Array[String] = automaton.move(source_set, symbol)

	_selected.clear()
	_view.highlight_set(source_set, StateNode.Mode.ACTIVE)
	_view.set_clickable(true)
	_picking = true

	level.set_objective("Insieme corrente %s, leggi '%s': clicca TUTTI gli stati raggiungibili, poi conferma." % [
		Automaton.set_label(source_set), symbol])

	var confirm: Button = level.make_action_button("CONFERMA L'INSIEME",
		Vector2(level.size.x * 0.5, level.size.y - 168.0), Vector2(280.0, 54.0))
	confirm.pressed.connect(func() -> void: _on_confirm(expected, source_set, symbol))

	await helper_done
	_picking = false
	_view.set_clickable(false)
	level.clear_action_bar()


func _on_state_clicked(state_name: String) -> void:
	if not _picking or _is_over():
		return
	Sfx.play("click")
	var node: StateNode = _view.get_node_for(state_name)
	if _selected.has(state_name):
		_selected.erase(state_name)
		if node != null:
			node.set_mode(StateNode.Mode.DIM)
	else:
		_selected.append(state_name)
		if node != null:
			node.set_mode(StateNode.Mode.SELECTED)
			node.pop()


func _on_confirm(expected: Array[String], source_set: Array, symbol: String) -> void:
	if not _picking or _is_over():
		return
	var chosen: Array[String] = _automaton.sort_states(_selected)

	if chosen == expected:
		_picking = false
		Sfx.play("correct")
		_score()
		for state in chosen:
			var node: StateNode = _view.get_node_for(state)
			if node != null:
				node.set_mode(StateNode.Mode.SUCCESS)
				node.pop()
		var closing: String = ""
		if _automaton.has_epsilon():
			closing = "  (ε-chiusura compresa)"
		level.toast("%s con '%s' → %s%s" % [
			Automaton.set_label(source_set), symbol, Automaton.set_label(chosen), closing], COLOR_OK)
		helper_done.emit()
		return

	Sfx.play("error")
	level.penalty(PENALTY_CHOICE)
	var missing: Array[String] = []
	var extra: Array[String] = []
	for state in expected:
		if not chosen.has(state):
			missing.append(state)
	for state in chosen:
		if not expected.has(state):
			extra.append(state)

	var reason: String = ""
	if not missing.is_empty():
		reason = "manca %s: guarda le frecce '%s' che escono da %s." % [
			Automaton.set_label(missing), symbol, Automaton.set_label(source_set)]
	else:
		reason = "%s non è raggiungibile leggendo '%s' da %s." % [
			Automaton.set_label(extra), symbol, Automaton.set_label(source_set)]
	level.toast("Insieme incompleto — " + reason, COLOR_BAD)
	for state in _selected:
		var node: StateNode = _view.get_node_for(state)
		if node != null:
			node.shake()
