class_name TuringMachine
extends RefCounted

## Macchina di Turing a nastro singolo, infinito nei due sensi.
##
## Contiene SOLO dati e algoritmi. Il nastro è un Dictionary posizione -> simbolo
## così non serve decidere in anticipo quanto sarà lungo: le celle mai scritte
## valgono BLANK.

const BLANK := "□"
const LEFT := -1
const RIGHT := 1
const STAY := 0

var tape: Dictionary = {}                 # int -> String
var head: int = 0
var state: String = ""
var steps: int = 0

var start_state: String = "q0"
var halt_states: Array[String] = []       # stati senza uscita: la macchina si ferma
var accept_state: String = ""
var rules: Dictionary = {}                # "stato|letto" -> {write, move, next}


static func _key(from_state: String, read_symbol: String) -> String:
	return from_state + "|" + read_symbol


## move: LEFT (-1), RIGHT (+1) oppure STAY (0).
func set_rule(from_state: String, read_symbol: String, write_symbol: String,
		move_dir: int, next_state: String) -> void:
	rules[_key(from_state, read_symbol)] = {
		"from": from_state,
		"read": read_symbol,
		"write": write_symbol,
		"move": move_dir,
		"next": next_state,
	}


## Scrive la parola sul nastro a partire dalla posizione 0 e riporta la macchina
## nello stato iniziale.
func load_input(word: String) -> void:
	tape.clear()
	for i in range(word.length()):
		tape[i] = word[i]
	head = 0
	state = start_state
	steps = 0


func read_symbol() -> String:
	return String(tape.get(head, BLANK))


func write_symbol(symbol: String) -> void:
	if symbol == BLANK:
		tape.erase(head)
	else:
		tape[head] = symbol


## La regola applicabile nella configurazione corrente, {} se la macchina è ferma.
func current_rule() -> Dictionary:
	var key: String = _key(state, read_symbol())
	if rules.has(key):
		return rules[key]
	return {}


func is_halted() -> bool:
	return current_rule().is_empty()


func is_accepting() -> bool:
	return accept_state != "" and state == accept_state


## Esegue un passo. Ritorna la regola applicata, oppure {} se era già ferma.
func step() -> Dictionary:
	var rule: Dictionary = current_rule()
	if rule.is_empty():
		return {}
	write_symbol(String(rule["write"]))
	head += int(rule["move"])
	state = String(rule["next"])
	steps += 1
	return rule


## Esegue fino all'arresto o al limite di passi.
## Il limite non è un dettaglio tecnico: è il motivo per cui il problema
## dell'arresto non si può risolvere guardando la macchina "abbastanza a lungo".
func run(max_steps: int = 2000) -> Dictionary:
	while steps < max_steps and not is_halted():
		step()
	return {
		"halted": is_halted(),
		"steps": steps,
		"accepted": is_accepting(),
		"tape": tape_string(),
	}


# ------------------------------------------------------------------ nastro --

func cell(position: int) -> String:
	return String(tape.get(position, BLANK))


func bounds() -> Vector2i:
	if tape.is_empty():
		return Vector2i(head, head)
	var low: int = head
	var high: int = head
	for position in tape.keys():
		low = mini(low, int(position))
		high = maxi(high, int(position))
	return Vector2i(low, high)


## Contenuto del nastro senza i blank ai bordi.
func tape_string() -> String:
	var span: Vector2i = bounds()
	var out: String = ""
	for position in range(span.x, span.y + 1):
		out += cell(position)
	return out.strip_edges().lstrip(BLANK).rstrip(BLANK)


func configuration() -> String:
	return "%s  testina=%d  legge=%s" % [state, head, read_symbol()]
