extends Lvl3PhaseBase

## FASE 1 — Automi di riconoscimento deterministici.
##
## Il giocatore NON risponde a domande sull'automa: lo esegue. Legge un simbolo
## alla volta e clicca lo stato in cui la macchina finisce, poi decide se la
## parola è accettata. È la definizione di "riconoscimento" trasformata in gesto.

## Quanti automi e quante parole per automa. Gli automi sono pescati a caso da
## Lvl3Pools.DFA_POOL, quindi ogni partita è diversa.
const AUTOMATA_PER_GAME := 2
const WORDS_PER_AUTOMATON := 2

var _view: AutomatonView = null
var _automaton: Automaton = null
var _expected: String = ""
var _waiting_state: bool = false


func _start() -> void:
	level.set_phase_header("FASE 1 — AUTOMI DETERMINISTICI", Color(0.4, 0.85, 1.0))

	_view = AutomatonView.new()
	_view.state_clicked.connect(_on_state_clicked)
	level.mount(_view)

	for entry in Lvl3Pools.pick(Lvl3Pools.DFA_POOL, AUTOMATA_PER_GAME):
		var automaton: Automaton = Lvl3Pools.build_automaton(entry)
		for word in Lvl3Pools.pick(entry["words"], WORDS_PER_AUTOMATON):
			if _is_over():
				return
			await _round(automaton, String(word), String(entry["hint"]))

	if _is_over():
		return
	await complete("Hai eseguito un automa deterministico: da ogni stato, per ogni simbolo, una sola strada.")


## Un giro: si legge la parola simbolo per simbolo, poi si decide.
func _round(automaton: Automaton, word: String, hint: String) -> void:
	_automaton = automaton
	_view.setup(automaton)
	level.set_hint(hint)

	var current: String = automaton.start_state
	var symbols: Array[String] = Automaton.symbols_of(word)

	_view.set_all_modes(StateNode.Mode.IDLE)
	_view.set_mode(current, StateNode.Mode.ACTIVE)

	for i in range(symbols.size()):
		if _is_over():
			return
		var symbol: String = symbols[i]
		_expected = automaton.step_dfa(current, symbol)
		level.set_objective("Parola \"%s\" — simbolo %d/%d: leggi '%s' da %s. Clicca lo stato di arrivo." % [
			word, i + 1, symbols.size(), symbol, current])

		_view.set_clickable(true)
		_waiting_state = true
		await helper_done
		if _is_over():
			return

		_view.set_edge_color(current, _expected, AutomatonView.CABLE_OK)
		current = _expected
		await _wait(0.25)
		_view.reset_edges()
		_view.set_all_modes(StateNode.Mode.IDLE)
		_view.set_mode(current, StateNode.Mode.ACTIVE)

	_view.set_clickable(false)
	await _decide(word, current, automaton)


## La domanda finale: lo stato in cui siamo finiti è finale?
func _decide(word: String, final_state: String, automaton: Automaton) -> void:
	if _is_over():
		return
	var accepted: bool = automaton.is_accepting(final_state)
	level.set_objective("La parola \"%s\" finisce in %s. È accettata?" % [word, final_state])
	level.set_hint("Una parola è accettata se lo stato raggiunto alla fine è uno stato finale (doppio cerchio).")

	var middle: Vector2 = Vector2(level.size.x * 0.5, level.size.y - 168.0)
	var yes: Button = level.make_action_button("ACCETTATA", middle - Vector2(130.0, 0.0))
	var no: Button = level.make_action_button("RIFIUTATA", middle + Vector2(130.0, 0.0))

	var answered: Array = [false]
	yes.pressed.connect(func() -> void: _on_decision(true, accepted, final_state, answered))
	no.pressed.connect(func() -> void: _on_decision(false, accepted, final_state, answered))

	await helper_done
	level.clear_action_bar()


func _on_decision(said_accepted: bool, truth: bool, final_state: String, answered: Array) -> void:
	if bool(answered[0]) or _is_over():
		return
	if said_accepted == truth:
		answered[0] = true
		Sfx.play("correct")
		_score()
		var reason: String = "%s è uno stato finale" % final_state if truth else "%s non è uno stato finale" % final_state
		level.toast("Esatto: %s, quindi la parola è %s." % [
			reason, "accettata" if truth else "rifiutata"], COLOR_OK)
		_view.set_mode(final_state, StateNode.Mode.SUCCESS if truth else StateNode.Mode.ERROR)
		helper_done.emit()
	else:
		Sfx.play("error")
		level.penalty(PENALTY_CHOICE)
		level.toast("No: guarda %s. Ha il doppio cerchio? %s" % [
			final_state, "Sì, allora è accettata." if truth else "No, allora è rifiutata."], COLOR_BAD)


func _on_state_clicked(state_name: String) -> void:
	if not _waiting_state or _is_over():
		return
	if state_name == _expected:
		_waiting_state = false
		_view.set_clickable(false)
		Sfx.play("correct")
		_score()
		var node: StateNode = _view.get_node_for(state_name)
		if node != null:
			node.set_mode(StateNode.Mode.SUCCESS)
			node.pop()
		helper_done.emit()
	else:
		Sfx.play("error")
		level.penalty(PENALTY_STEP)
		var node: StateNode = _view.get_node_for(state_name)
		if node != null:
			node.shake()
		level.toast("Da lì non si arriva in %s: segui la freccia etichettata con il simbolo che stai leggendo." % state_name, COLOR_BAD)
