class_name Automaton
extends RefCounted

## Automa a stati finiti, deterministico o non deterministico.
##
## Contiene SOLO dati e algoritmi: nessun riferimento a nodi Godot.
## Le stesse strutture servono al gioco per tre cose diverse:
##   - eseguire un DFA passo per passo (Fase 1);
##   - calcolare le mosse di un NFA e la ε-chiusura (Fase 2);
##   - costruire il DFA equivalente con la costruzione per sottoinsiemi.

const EPSILON := "ε"

var states: Array[String] = []
var alphabet: Array[String] = []
var start_state: String = ""
var accepting: Array[String] = []
var transitions: Dictionary = {}          # "stato|simbolo" -> Array di stati


static func make(state_list: Array, symbols: Array, start: String, final_states: Array) -> Automaton:
	var automaton: Automaton = Automaton.new()
	for state in state_list:
		automaton.states.append(String(state))
	for symbol in symbols:
		automaton.alphabet.append(String(symbol))
	automaton.start_state = start
	for state in final_states:
		automaton.accepting.append(String(state))
	return automaton


static func _key(state: String, symbol: String) -> String:
	return state + "|" + symbol


func add_transition(from_state: String, symbol: String, to_state: String) -> void:
	var k: String = _key(from_state, symbol)
	if not transitions.has(k):
		transitions[k] = []
	var list: Array = transitions[k]
	if not list.has(to_state):
		list.append(to_state)


## Tutti gli stati raggiungibili da `state` leggendo `symbol` (senza ε-chiusura).
func targets(state: String, symbol: String) -> Array[String]:
	var out: Array[String] = []
	var k: String = _key(state, symbol)
	if transitions.has(k):
		for target in transitions[k]:
			out.append(String(target))
	return out


func is_accepting(state: String) -> bool:
	return accepting.has(state)


func has_epsilon() -> bool:
	for k in transitions.keys():
		if String(k).ends_with("|" + EPSILON):
			return true
	return false


## Deterministico: niente ε e al massimo una destinazione per ogni coppia.
func is_deterministic() -> bool:
	if has_epsilon():
		return false
	for k in transitions.keys():
		if transitions[k].size() > 1:
			return false
	return true


# ------------------------------------------------------------ esecuzione ---

## Unico stato successivo di un DFA, "" se la transizione non esiste.
func step_dfa(state: String, symbol: String) -> String:
	var list: Array[String] = targets(state, symbol)
	return list[0] if not list.is_empty() else ""


## Traccia degli stati attraversati leggendo la parola. Si ferma se si blocca.
func run_dfa(word: String) -> Array[String]:
	var trace: Array[String] = [start_state]
	var current: String = start_state
	for symbol in symbols_of(word):
		current = step_dfa(current, symbol)
		trace.append(current)
		if current == "":
			break
	return trace


## Vale sia per DFA sia per NFA: simula l'insieme degli stati attivi.
func accepts(word: String) -> bool:
	var active: Array[String] = epsilon_closure([start_state])
	for symbol in symbols_of(word):
		active = move(active, symbol)
		if active.is_empty():
			return false
	for state in active:
		if is_accepting(state):
			return true
	return false


# ---------------------------------------------- non determinismo e insiemi --

## Chiusura rispetto alle sole transizioni ε.
func epsilon_closure(state_set: Array) -> Array[String]:
	var result: Array[String] = []
	var stack: Array[String] = []
	for state in state_set:
		var name: String = String(state)
		if not result.has(name):
			result.append(name)
			stack.append(name)
	while not stack.is_empty():
		var current: String = stack.pop_back()
		for target in targets(current, EPSILON):
			if not result.has(target):
				result.append(target)
				stack.append(target)
	return sort_states(result)


## Insieme raggiunto da `state_set` leggendo `symbol`, ε-chiusura compresa.
## È esattamente la mossa che il giocatore deve ricostruire nella Fase 2.
func move(state_set: Array, symbol: String) -> Array[String]:
	var reached: Array[String] = []
	for state in state_set:
		for target in targets(String(state), symbol):
			if not reached.has(target):
				reached.append(target)
	return epsilon_closure(reached)


## Ordina secondo l'ordine di dichiarazione, così le etichette sono stabili.
func sort_states(state_set: Array) -> Array[String]:
	var out: Array[String] = []
	for state in states:
		if state_set.has(state):
			out.append(state)
	for state in state_set:            # eventuali stati non dichiarati
		var name: String = String(state)
		if not out.has(name):
			out.append(name)
	return out


func set_contains_accepting(state_set: Array) -> bool:
	for state in state_set:
		if is_accepting(String(state)):
			return true
	return false


static func set_label(state_set: Array) -> String:
	if state_set.is_empty():
		return "∅"
	var parts: PackedStringArray = PackedStringArray()
	for state in state_set:
		parts.append(String(state))
	return "{" + ",".join(parts) + "}"


## Costruzione per sottoinsiemi: da NFA a DFA equivalente.
## Ritorna { "sets": Array[Array], "labels": Array[String],
##           "transitions": Dictionary "etichetta|simbolo" -> etichetta,
##           "start": Array, "accepting": Array[String] }
func subset_construction() -> Dictionary:
	var start_set: Array[String] = epsilon_closure([start_state])
	var sets: Array = [start_set]
	var labels: Array[String] = [set_label(start_set)]
	var table: Dictionary = {}
	var final_labels: Array[String] = []
	if set_contains_accepting(start_set):
		final_labels.append(labels[0])

	var index: int = 0
	while index < sets.size():
		var current: Array = sets[index]
		var current_label: String = set_label(current)
		for symbol in alphabet:
			if symbol == EPSILON:
				continue
			var next_set: Array[String] = move(current, symbol)
			var next_label: String = set_label(next_set)
			table[current_label + "|" + symbol] = next_label
			if not next_set.is_empty() and not labels.has(next_label):
				sets.append(next_set)
				labels.append(next_label)
				if set_contains_accepting(next_set):
					final_labels.append(next_label)
		index += 1

	return {
		"sets": sets,
		"labels": labels,
		"transitions": table,
		"start": start_set,
		"accepting": final_labels,
	}


# ---------------------------------------------------------------- utility --

## Spezza la parola nei suoi simboli. L'alfabeto del gioco è di singoli caratteri.
static func symbols_of(word: String) -> Array[String]:
	var out: Array[String] = []
	for i in range(word.length()):
		out.append(word[i])
	return out
