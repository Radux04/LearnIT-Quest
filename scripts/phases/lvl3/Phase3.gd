extends Lvl3PhaseBase

## FASE 3 — Macchine di Turing.
##
## Prima il giocatore ESEGUE la macchina applicando la quintupla giusta a ogni
## passo: capisce che δ è una funzione, non un suggerimento. Poi COMPLETA una
## macchina a cui manca una regola, cioè la progetta.

var _tape: TapeView = null
var _rules: RuleTableView = null
var _machine: TuringMachine = null
var _expected_key: String = ""
var _waiting: bool = false


func _start() -> void:
	level.set_phase_header("FASE 3 — MACCHINE DI TURING", Color(1.0, 0.82, 0.35))

	_tape = TapeView.new()
	level.mount(_tape)
	_tape.offset_bottom = -190.0

	_rules = RuleTableView.new()
	_rules.rule_clicked.connect(_on_rule_clicked)
	level.mount(_rules)
	# Ancorata al centro-basso: gli offset sono relativi al centro, non ai bordi.
	_rules.anchor_left = 0.5
	_rules.anchor_right = 0.5
	_rules.anchor_top = 1.0
	_rules.anchor_bottom = 1.0
	_rules.offset_left = -200.0
	_rules.offset_right = 200.0
	_rules.offset_top = -200.0
	_rules.offset_bottom = -12.0

	await _execute_round()
	if _is_over():
		return
	await _design_round()
	if _is_over():
		return

	await complete("Una macchina di Turing è solo un nastro e una tabella: eppure calcola tutto ciò che è calcolabile.")


## Giro 1: esegui la macchina che inverte i bit.
func _execute_round() -> void:
	_machine = TuringMachine.new()
	_machine.start_state = "q0"
	_machine.accept_state = "qf"
	_machine.set_rule("q0", "0", "1", TuringMachine.RIGHT, "q0")
	_machine.set_rule("q0", "1", "0", TuringMachine.RIGHT, "q0")
	_machine.set_rule("q0", TuringMachine.BLANK, TuringMachine.BLANK, TuringMachine.STAY, "qf")
	_machine.load_input("101")

	_tape.setup(_machine)
	_rules.setup(_machine, ["q0|0", "q0|1", "q0|" + TuringMachine.BLANK])
	level.set_hint("La regola da applicare dipende SOLO da due cose: lo stato corrente e il simbolo sotto la testina.")

	var step: int = 0
	while not _machine.is_halted() and not _is_over():
		step += 1
		_expected_key = _machine.state + "|" + _machine.read_symbol()
		level.set_objective("Passo %d — stato %s, la testina legge '%s'. Clicca la quintupla che si applica." % [
			step, _machine.state, _machine.read_symbol()])
		_rules.set_enabled(true)
		_waiting = true
		await helper_done
		if _is_over():
			return

	if _is_over():
		return
	_rules.set_enabled(false)
	Sfx.play("correct")
	level.toast("Macchina ferma in %s. Il nastro è passato da 101 a %s: ogni bit invertito." % [
		_machine.state, _machine.tape_string()], COLOR_OK)
	await _wait(1.8)


## Giro 2: progetta la regola mancante.
func _design_round() -> void:
	# Successore in unario: scorre a destra finché trova celle piene, poi
	# scrive un altro 1. Manca proprio la regola che scrive.
	_machine = TuringMachine.new()
	_machine.start_state = "q0"
	_machine.accept_state = "qf"
	_machine.set_rule("q0", "1", "1", TuringMachine.RIGHT, "q0")
	_machine.load_input("111")

	_tape.setup(_machine)
	_rules.setup(_machine, ["q0|1"])
	level.set_objective("Questa macchina deve calcolare il SUCCESSORE in unario: 111 → 1111. Manca una regola.")
	level.set_hint("Quando la testina esce dal numero legge un blank □. Che cosa deve fare in quel momento?")

	var options: Array = [
		{"text": "δ(q0, □) = (1, •, qf)", "correct": true,
			"why": "scrive il simbolo mancante e si ferma: 111 diventa 1111."},
		{"text": "δ(q0, □) = (□, →, q0)", "correct": false,
			"why": "non scrive nulla e continua a destra: la macchina non si fermerebbe mai."},
		{"text": "δ(q0, □) = (1, ←, q0)", "correct": false,
			"why": "scrive l'1 ma poi torna indietro e rilegge un 1, ripartendo a destra: ciclo infinito."},
	]

	var chosen: Array = [false]
	var middle_y: float = level.size.y - 150.0
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var button: Button = level.make_action_button(String(option["text"]),
			Vector2(level.size.x * 0.5, middle_y - float(2 - i) * 62.0), Vector2(420.0, 52.0))
		button.pressed.connect(func() -> void: _on_option(option, chosen))

	await helper_done
	level.clear_action_bar()
	if _is_over():
		return

	# La macchina completata gira da sola: il giocatore vede il nastro crescere.
	_machine.set_rule("q0", TuringMachine.BLANK, "1", TuringMachine.STAY, "qf")
	_rules.setup(_machine, ["q0|1", "q0|" + TuringMachine.BLANK])
	_rules.set_enabled(false)
	level.set_objective("Regola inserita. La macchina gira da sola...")
	while not _machine.is_halted() and not _is_over():
		var rule: Dictionary = _machine.step()
		_tape.slide(int(rule["move"]))
		_tape.refresh()
		await _wait(0.32)
	if _is_over():
		return
	_tape.flash(Color(0.35, 1.0, 0.6))
	Sfx.play("correct")
	level.toast("Nastro finale: %s. La macchina calcola il successore." % _machine.tape_string(), COLOR_OK)
	await _wait(1.8)


func _on_option(option: Dictionary, chosen: Array) -> void:
	if bool(chosen[0]) or _is_over():
		return
	if bool(option["correct"]):
		chosen[0] = true
		Sfx.play("correct")
		_score()
		level.toast("Giusto: %s" % String(option["why"]), COLOR_OK)
		helper_done.emit()
	else:
		Sfx.play("error")
		level.penalty(PENALTY_CHOICE)
		level.toast("No: %s" % String(option["why"]), COLOR_BAD)


func _on_rule_clicked(key: String) -> void:
	if not _waiting or _is_over():
		return
	if key == _expected_key:
		_waiting = false
		_rules.set_enabled(false)
		Sfx.play("correct")
		_score()
		var rule: Dictionary = _machine.step()
		_tape.slide(int(rule["move"]))
		_tape.refresh()
		helper_done.emit()
	else:
		Sfx.play("error")
		level.penalty(PENALTY_STEP)
		_tape.flash(Color(1.0, 0.4, 0.42))
		var parts: PackedStringArray = key.split("|")
		level.toast("Quella regola vale per lo stato %s con il simbolo '%s': ora sei in %s e leggi '%s'." % [
			parts[0], parts[1], _machine.state, _machine.read_symbol()], COLOR_BAD)
