class_name WhileInterpreter
extends RefCounted

## Interprete del linguaggio WHILE: sintassi e semantica operazionale.
##
## Le variabili contengono numeri naturali. La sottrazione è "troncata"
## (monus): 3 - 5 vale 0, non -2. È la scelta classica del linguaggio WHILE,
## e serve a restare dentro i naturali.
##
## Il limite di passi non è un dettaglio implementativo: un programma WHILE
## può non terminare, e in quel caso calcola una funzione PARZIALE. L'interprete
## non può sapere in anticipo se si fermerà (è il problema dell'arresto), quindi
## dopo MAX_STEPS si arrende e lo dichiara "non terminato".

const MAX_STEPS := 20000

enum Type { NUMBER, NAME, KEYWORD, OP, EOF }

const KEYWORDS := ["while", "do", "end", "od", "if", "then", "else", "fi", "skip"]


# =========================================================== tokenizzatore ==

static func tokenize(source: String) -> Dictionary:
	var tokens: Array = []
	var i: int = 0
	var text: String = source
	while i < text.length():
		var c: String = text[i]

		if c == " " or c == "\t" or c == "\n" or c == "\r":
			i += 1
			continue

		# commenti: # fino a fine riga
		if c == "#":
			while i < text.length() and text[i] != "\n":
				i += 1
			continue

		if c.is_valid_int() or (c >= "0" and c <= "9"):
			var number: String = ""
			while i < text.length() and text[i] >= "0" and text[i] <= "9":
				number += text[i]
				i += 1
			tokens.append({"type": Type.NUMBER, "value": int(number), "text": number})
			continue

		if _is_name_start(c):
			var name: String = ""
			while i < text.length() and _is_name_char(text[i]):
				name += text[i]
				i += 1
			var lower: String = name.to_lower()
			if KEYWORDS.has(lower):
				tokens.append({"type": Type.KEYWORD, "value": lower, "text": name})
			else:
				tokens.append({"type": Type.NAME, "value": name, "text": name})
			continue

		# operatori a due caratteri
		var two: String = text.substr(i, 2)
		if two == ":=" or two == "!=" or two == "<=" or two == ">=" or two == "<>":
			var op: String = "!=" if two == "<>" else two
			tokens.append({"type": Type.OP, "value": op, "text": two})
			i += 2
			continue

		if c == "≠":
			tokens.append({"type": Type.OP, "value": "!=", "text": c})
			i += 1
			continue

		if "+-*;()=<>".contains(c):
			tokens.append({"type": Type.OP, "value": c, "text": c})
			i += 1
			continue

		if c == ":":
			return _fail_tokens("Ho trovato ':' da solo: per assegnare si scrive ':=' (per esempio x := 1).")

		return _fail_tokens("Carattere non riconosciuto: '%s'." % c)

	tokens.append({"type": Type.EOF, "value": "", "text": ""})
	return {"ok": true, "error": "", "tokens": tokens}


static func _fail_tokens(message: String) -> Dictionary:
	return {"ok": false, "error": message, "tokens": []}


static func _is_name_start(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"


static func _is_name_char(c: String) -> bool:
	return _is_name_start(c) or (c >= "0" and c <= "9")


# ================================================================= parser ===

class Parser extends RefCounted:
	var tokens: Array = []
	var pos: int = 0
	var error: String = ""

	func _init(token_list: Array) -> void:
		tokens = token_list

	func current() -> Dictionary:
		return tokens[pos] if pos < tokens.size() else {"type": Type.EOF, "value": "", "text": ""}

	func advance() -> Dictionary:
		var token: Dictionary = current()
		pos += 1
		return token

	func at_keyword(word: String) -> bool:
		var token: Dictionary = current()
		return int(token["type"]) == Type.KEYWORD and String(token["value"]) == word

	func at_op(symbol: String) -> bool:
		var token: Dictionary = current()
		return int(token["type"]) == Type.OP and String(token["value"]) == symbol

	func accept_keyword(word: String) -> bool:
		if at_keyword(word):
			pos += 1
			return true
		return false

	func accept_op(symbol: String) -> bool:
		if at_op(symbol):
			pos += 1
			return true
		return false

	func describe() -> String:
		var token: Dictionary = current()
		if int(token["type"]) == Type.EOF:
			return "la fine del programma"
		return "'%s'" % String(token["text"])

	## Un programma è una sequenza di comandi separati da ';'.
	func parse_program() -> Dictionary:
		var items: Array = []
		var first: Dictionary = parse_command()
		if error != "":
			return {}
		items.append(first)
		while accept_op(";"):
			# ';' finale tollerato
			if _at_block_end():
				break
			var next_command: Dictionary = parse_command()
			if error != "":
				return {}
			items.append(next_command)
		if items.size() == 1:
			return items[0]
		return {"kind": "seq", "items": items}

	func _at_block_end() -> bool:
		var token: Dictionary = current()
		if int(token["type"]) == Type.EOF:
			return true
		if int(token["type"]) == Type.KEYWORD:
			var word: String = String(token["value"])
			return word == "end" or word == "od" or word == "fi" or word == "else"
		return false

	func parse_command() -> Dictionary:
		if accept_keyword("skip"):
			return {"kind": "skip"}
		if at_keyword("while"):
			return parse_while()
		if at_keyword("if"):
			return parse_if()

		var token: Dictionary = current()
		if int(token["type"]) != Type.NAME:
			error = "Mi aspettavo un comando (un assegnamento, while, if o skip) ma ho trovato %s." % describe()
			return {}
		var name: String = String(advance()["value"])
		if not accept_op(":="):
			error = "Dopo la variabile '%s' serve ':=' per assegnarle un valore (per esempio %s := 0)." % [name, name]
			return {}
		var expr: Dictionary = parse_expression()
		if error != "":
			return {}
		return {"kind": "assign", "name": name, "expr": expr}

	func parse_while() -> Dictionary:
		advance()                                     # while
		var cond: Dictionary = parse_condition()
		if error != "":
			return {}
		if not accept_keyword("do"):
			error = "Dopo la condizione del while serve 'do'."
			return {}
		var body: Dictionary = parse_program()
		if error != "":
			return {}
		if not _accept_block_end():
			error = "Il ciclo while non è chiuso: serve 'end' (oppure 'od') alla fine del corpo."
			return {}
		return {"kind": "while", "cond": cond, "body": body}

	func parse_if() -> Dictionary:
		advance()                                     # if
		var cond: Dictionary = parse_condition()
		if error != "":
			return {}
		if not accept_keyword("then"):
			error = "Dopo la condizione dell'if serve 'then'."
			return {}
		var then_branch: Dictionary = parse_program()
		if error != "":
			return {}
		var else_branch: Dictionary = {"kind": "skip"}
		if accept_keyword("else"):
			else_branch = parse_program()
			if error != "":
				return {}
		if not _accept_block_end():
			error = "L'if non è chiuso: serve 'end' (oppure 'fi')."
			return {}
		return {"kind": "if", "cond": cond, "then": then_branch, "else": else_branch}

	func _accept_block_end() -> bool:
		return accept_keyword("end") or accept_keyword("od") or accept_keyword("fi")

	## Una condizione è un confronto; una espressione da sola significa "≠ 0".
	func parse_condition() -> Dictionary:
		var left: Dictionary = parse_expression()
		if error != "":
			return {}
		for op in ["=", "!=", "<=", ">=", "<", ">"]:
			if at_op(op):
				advance()
				var right: Dictionary = parse_expression()
				if error != "":
					return {}
				return {"type": "cmp", "op": op, "left": left, "right": right}
		return {"type": "nonzero", "expr": left}

	func parse_expression() -> Dictionary:
		var left: Dictionary = parse_term()
		if error != "":
			return {}
		while at_op("+") or at_op("-"):
			var op: String = String(advance()["value"])
			var right: Dictionary = parse_term()
			if error != "":
				return {}
			left = {"type": "bin", "op": op, "left": left, "right": right}
		return left

	func parse_term() -> Dictionary:
		var left: Dictionary = parse_factor()
		if error != "":
			return {}
		while at_op("*"):
			advance()
			var right: Dictionary = parse_factor()
			if error != "":
				return {}
			left = {"type": "bin", "op": "*", "left": left, "right": right}
		return left

	func parse_factor() -> Dictionary:
		var token: Dictionary = current()
		if int(token["type"]) == Type.NUMBER:
			advance()
			return {"type": "num", "value": int(token["value"])}
		if int(token["type"]) == Type.NAME:
			advance()
			return {"type": "var", "name": String(token["value"])}
		if accept_op("("):
			var inner: Dictionary = parse_expression()
			if error != "":
				return {}
			if not accept_op(")"):
				error = "Manca la parentesi chiusa ')'."
				return {}
			return inner
		error = "Mi aspettavo un numero, una variabile o '(' ma ho trovato %s." % describe()
		return {}


static func parse(source: String) -> Dictionary:
	if source.strip_edges().is_empty():
		return {"ok": false, "error": "Il programma è vuoto.", "ast": {}}
	var lexed: Dictionary = tokenize(source)
	if not bool(lexed["ok"]):
		return {"ok": false, "error": String(lexed["error"]), "ast": {}}
	var parser: Parser = Parser.new(lexed["tokens"])
	var ast: Dictionary = parser.parse_program()
	if parser.error != "":
		return {"ok": false, "error": parser.error, "ast": {}}
	if int(parser.current()["type"]) != Type.EOF:
		return {"ok": false,
			"error": "Non capisco cosa ci fa %s alla fine del programma: forse manca un ';'." % parser.describe(),
			"ast": {}}
	return {"ok": true, "error": "", "ast": ast}


# ============================================================= esecuzione ===

## Esegue il programma partendo da `initial_state` (nome variabile -> naturale).
## Ritorna { ok, error, state, steps, terminated }.
## `terminated == false` significa che il limite di passi è scattato: per quanto
## ne sappiamo il programma cicla, cioè la funzione è indefinita su quell'input.
static func run(source: String, initial_state: Dictionary = {}, max_steps: int = MAX_STEPS) -> Dictionary:
	var parsed: Dictionary = parse(source)
	if not bool(parsed["ok"]):
		return {"ok": false, "error": String(parsed["error"]), "state": {}, "steps": 0, "terminated": false}
	return run_ast(parsed["ast"], initial_state, max_steps)


static func run_ast(ast: Dictionary, initial_state: Dictionary = {}, max_steps: int = MAX_STEPS) -> Dictionary:
	var state: Dictionary = {}
	for name in initial_state.keys():
		state[String(name)] = int(initial_state[name])
	var budget: Array = [max_steps]                    # contenitore mutabile
	var terminated: bool = _exec(ast, state, budget)
	return {
		"ok": true,
		"error": "",
		"state": state,
		"steps": max_steps - int(budget[0]),
		"terminated": terminated,
	}


## Ritorna false se il budget di passi si è esaurito (programma presunto infinito).
static func _exec(node: Dictionary, state: Dictionary, budget: Array) -> bool:
	if int(budget[0]) <= 0:
		return false
	budget[0] = int(budget[0]) - 1

	match String(node.get("kind", "")):
		"skip":
			return true
		"seq":
			for item in node["items"]:
				if not _exec(item, state, budget):
					return false
			return true
		"assign":
			state[String(node["name"])] = _eval(node["expr"], state)
			return true
		"if":
			if _truth(node["cond"], state):
				return _exec(node["then"], state, budget)
			return _exec(node["else"], state, budget)
		"while":
			while _truth(node["cond"], state):
				if int(budget[0]) <= 0:
					return false
				budget[0] = int(budget[0]) - 1
				if not _exec(node["body"], state, budget):
					return false
			return true
	return true


static func _eval(expr: Dictionary, state: Dictionary) -> int:
	match String(expr.get("type", "")):
		"num":
			return int(expr["value"])
		"var":
			return int(state.get(String(expr["name"]), 0))
		"bin":
			var left: int = _eval(expr["left"], state)
			var right: int = _eval(expr["right"], state)
			match String(expr["op"]):
				"+":
					return left + right
				"-":
					return maxi(left - right, 0)          # monus: mai negativo
				"*":
					return left * right
	return 0


static func _truth(cond: Dictionary, state: Dictionary) -> bool:
	if String(cond.get("type", "")) == "nonzero":
		return _eval(cond["expr"], state) != 0
	var left: int = _eval(cond["left"], state)
	var right: int = _eval(cond["right"], state)
	match String(cond["op"]):
		"=":
			return left == right
		"!=":
			return left != right
		"<":
			return left < right
		"<=":
			return left <= right
		">":
			return left > right
		">=":
			return left >= right
	return false


## Variabili citate dal programma, in ordine alfabetico (serve alla vista).
static func variables_of(source: String) -> Array[String]:
	var out: Array[String] = []
	var lexed: Dictionary = tokenize(source)
	if not bool(lexed["ok"]):
		return out
	for token in lexed["tokens"]:
		if int(token["type"]) == Type.NAME:
			var name: String = String(token["value"])
			if not out.has(name):
				out.append(name)
	out.sort()
	return out
