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
## Testo dell'alternativa corretta nel giro di progettazione (lo legge il bot).
var _correct_option: String = ""


func _start() -> void:
	level.set_phase_header("FASE 3 — MACCHINE DI TURING", Color(1.0, 0.82, 0.35))

	_tape = TapeView.new()
	level.mount(_tape)

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
	_rules.offset_bottom = -12.0
	_layout_rules()

	await _execute_round()
	if _is_over():
		return
	await _design_round()
	if _is_over():
		return

	await complete("Una macchina di Turing è solo un nastro e una tabella: eppure calcola tutto ciò che è calcolabile.")


## La tabella cresce verso l'alto in base a quante regole ha la macchina, e il
## nastro si sposta per non finirci sotto.
func _layout_rules() -> void:
	var height: float = _rules.preferred_height()
	_rules.offset_top = -height - 12.0
	_tape.offset_bottom = -height - 46.0


## Giro 1: esegui una macchina pescata dal catalogo.
func _execute_round() -> void:
	var entry: Dictionary = Lvl3Pools.pick_one(Lvl3Pools.TM_POOL)
	var input: String = String(entry["input"])
	_machine = Lvl3Pools.build_machine(entry)

	_tape.setup(_machine)
	_rules.setup(_machine, _machine.rules.keys())
	_layout_rules()
	level.set_hint(String(entry["hint"]))

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
	level.toast("Macchina ferma in %s. Il nastro è passato da %s a %s: %s." % [
		_machine.state, input, _machine.tape_string(), String(entry["result"])], COLOR_OK)
	await _wait(1.8)


## Giro 2: progetta la regola mancante.
func _design_round() -> void:
	var entry: Dictionary = Lvl3Pools.pick_one(Lvl3Pools.DESIGN_POOL)
	_machine = Lvl3Pools.build_machine(entry)

	_tape.setup(_machine)
	_rules.setup(_machine, _machine.rules.keys())
	_layout_rules()
	level.set_objective(String(entry["goal"]))
	level.set_hint(String(entry["hint"]))

	# Le alternative vengono mescolate: la risposta giusta non è sempre la prima.
	var options: Array = entry["options"].duplicate()
	options.shuffle()
	for option in options:
		if bool(option["correct"]):
			_correct_option = String(option["text"])

	# Il palco può contenere ancora i pulsanti del giro precedente.
	level.clear_action_bar()

	# Le alternative vanno SOPRA la tabella delle regole, che resta visibile
	# perché serve a ragionare: la tabella ha altezza variabile, quindi la
	# posizione si calcola da lei e non da un numero fisso.
	# Attenzione: la tabella sta dentro Stage (che non parte dal bordo dello
	# schermo), mentre i pulsanti stanno in ActionBar, che è a schermo intero.
	# La posizione va quindi calcolata dal rettangolo di Stage, non da level.size.
	var spacing: float = 62.0
	var stage_bottom: float = level.stage.position.y + level.stage.size.y
	var table_top: float = stage_bottom - _rules.preferred_height() - 12.0
	var lowest: float = table_top - 40.0
	var chosen: Array = [false]
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var y: float = lowest - float(options.size() - 1 - i) * spacing
		var button: Button = level.make_action_button(String(option["text"]),
			Vector2(level.size.x * 0.5, y), Vector2(430.0, 52.0))
		button.pressed.connect(func() -> void: _on_option(option, chosen))

	await helper_done
	level.clear_action_bar()
	if _is_over():
		return

	# La macchina completata gira da sola: il giocatore vede il nastro cambiare.
	var missing: Array = entry["missing"]
	_machine.set_rule(String(missing[0]), String(missing[1]), String(missing[2]),
		int(missing[3]), String(missing[4]))
	_rules.setup(_machine, _machine.rules.keys())
	_layout_rules()
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
	var tape: String = _machine.tape_string()
	level.toast("Nastro finale: %s. La macchina fa quello che doveva." % (
		tape if tape != "" else "vuoto"), COLOR_OK)
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
