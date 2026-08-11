class_name JavaCode
extends RefCounted

## Analizzatore strutturale di codice Java.
##
## NON è un compilatore: non esegue nulla e non verifica i tipi. Estrae la
## STRUTTURA del codice — classi, campi, metodi, modificatori, annotazioni,
## lunghezze, nomi — perché è su quella che si giudicano il clean code e i
## principi SOLID. Un metodo lungo 40 righe è un difetto anche se compila
## benissimo, ed è esattamente ciò che questo livello insegna a vedere.
##
## Contiene solo dati e algoritmi: nessun riferimento a nodi Godot.

const MODIFIERS := ["public", "private", "protected", "static", "final",
	"abstract", "synchronized", "native", "transient", "volatile", "default"]

## Numeri che non contano come "magici": sono idiomatici e leggibili ovunque.
const HARMLESS_NUMBERS := ["0", "1", "2", "-1"]

var source: String = ""                    # sorgente originale, com'è stato scritto
var lines: PackedStringArray = PackedStringArray()
var clean_lines: PackedStringArray = PackedStringArray()   # senza commenti e stringhe

var type_name: String = ""                 # nome della classe/interfaccia/enum
var type_kind: String = ""                 # "class", "interface", "enum", "record"
var extends_name: String = ""
var implements_names: Array[String] = []

var fields: Array = []                     # {name, type, modifiers, line}
var methods: Array = []                    # {name, return_type, params, modifiers,
                                           #  line, end_line, length, body}
var annotations: Array = []                # {name, line}
var imports: Array[String] = []
var comment_lines: Array[int] = []


static func parse(src: String) -> JavaCode:
	var code: JavaCode = JavaCode.new()
	code.source = src
	code.lines = src.split("\n")
	code._build_clean_lines()
	code._scan()
	return code


# ------------------------------------------------------- pulizia del testo --

## Sostituisce commenti e contenuto delle stringhe con spazi, mantenendo il
## numero di righe: così le analisi non inciampano su parentesi dentro un
## commento o su una parola chiave dentro una stringa.
func _build_clean_lines() -> void:
	clean_lines = PackedStringArray()
	comment_lines.clear()
	var in_block_comment: bool = false

	for index in range(lines.size()):
		var raw: String = lines[index]
		var out: String = ""
		var i: int = 0
		var in_string: bool = false
		var in_char: bool = false
		var had_comment: bool = false

		while i < raw.length():
			var c: String = raw[i]
			var next_c: String = raw[i + 1] if i + 1 < raw.length() else ""

			if in_block_comment:
				had_comment = true
				if c == "*" and next_c == "/":
					in_block_comment = false
					out += "  "
					i += 2
					continue
				out += " "
				i += 1
				continue

			if in_string:
				out += " "
				if c == "\\":
					i += 2
					continue
				if c == "\"":
					in_string = false
					out = out.substr(0, out.length() - 1) + "\""
				i += 1
				continue

			if in_char:
				out += " "
				if c == "\\":
					i += 2
					continue
				if c == "'":
					in_char = false
				i += 1
				continue

			if c == "/" and next_c == "/":
				had_comment = true
				break                                  # resto della riga: commento
			if c == "/" and next_c == "*":
				in_block_comment = true
				had_comment = true
				out += "  "
				i += 2
				continue
			if c == "\"":
				in_string = true
				out += "\""
				i += 1
				continue
			if c == "'":
				in_char = true
				out += "'"
				i += 1
				continue

			out += c
			i += 1

		if had_comment:
			comment_lines.append(index)
		clean_lines.append(out)


# ------------------------------------------------------------- estrazione ---

func _scan() -> void:
	var depth: int = 0
	var pending_annotations: Array = []
	var class_depth: int = -1

	var index: int = 0
	while index < clean_lines.size():
		var line: String = clean_lines[index]
		var trimmed: String = line.strip_edges()

		if trimmed.begins_with("import "):
			imports.append(trimmed.trim_prefix("import ").trim_suffix(";").strip_edges())

		if trimmed.begins_with("@"):
			var annotation: String = trimmed.substr(1)
			var paren: int = annotation.find("(")
			if paren >= 0:
				annotation = annotation.substr(0, paren)
			annotation = annotation.strip_edges()
			annotations.append({"name": annotation, "line": index})
			pending_annotations.append(annotation)
			index += 1
			continue

		# Dichiarazione del tipo (prendiamo solo la prima, quella esterna).
		if type_name == "":
			var declared: Dictionary = _match_type_declaration(trimmed)
			if not declared.is_empty():
				type_name = String(declared["name"])
				type_kind = String(declared["kind"])
				extends_name = String(declared["extends"])
				for name in declared["implements"]:
					implements_names.append(String(name))
				class_depth = depth

		# Metodo: ha le parentesi tonde e apre un blocco (oppure è astratto).
		# Solo al primo livello dentro la classe: più in profondità siamo
		# dentro il corpo di un altro metodo.
		var method: Dictionary = _match_method(trimmed, index)
		if not method.is_empty() and class_depth >= 0 and depth == class_depth + 1:
			method["annotations"] = pending_annotations.duplicate()
			var span: Dictionary = _method_span(index)
			method["end_line"] = int(span["end"])
			method["length"] = int(span["length"])
			method["body"] = String(span["body"])
			methods.append(method)
			pending_annotations.clear()
			# Si salta al termine del metodo. La profondità NON va toccata: le
			# graffe del metodo si aprono e si chiudono, quindi il saldo è zero
			# e restiamo dentro la classe.
			index = int(span["end"]) + 1
			continue

		# Campo: dentro la classe, fuori dai metodi, finisce con ';'.
		if class_depth >= 0 and depth == class_depth + 1 and trimmed.ends_with(";"):
			var field: Dictionary = _match_field(trimmed, index)
			if not field.is_empty():
				field["annotations"] = pending_annotations.duplicate()
				fields.append(field)
				pending_annotations.clear()

		depth += _brace_delta(line)
		if not trimmed.begins_with("@") and trimmed != "":
			pending_annotations.clear()
		index += 1


func _brace_delta(line: String) -> int:
	var delta: int = 0
	for i in range(line.length()):
		if line[i] == "{":
			delta += 1
		elif line[i] == "}":
			delta -= 1
	return delta


func _match_type_declaration(trimmed: String) -> Dictionary:
	for kind in ["class", "interface", "enum", "record"]:
		var marker: String = kind + " "
		var at: int = trimmed.find(marker)
		if at < 0:
			continue
		# Deve essere preceduto solo da modificatori.
		var before: String = trimmed.substr(0, at).strip_edges()
		if not _only_modifiers(before):
			continue
		var rest: String = trimmed.substr(at + marker.length()).strip_edges()
		var name: String = _first_identifier(rest)
		if name == "":
			continue
		var parent: String = ""
		var interfaces: Array[String] = []
		var extends_at: int = rest.find(" extends ")
		if extends_at >= 0:
			parent = _first_identifier(rest.substr(extends_at + 9).strip_edges())
		var implements_at: int = rest.find(" implements ")
		if implements_at >= 0:
			var tail: String = rest.substr(implements_at + 12)
			tail = tail.replace("{", " ")
			for piece in tail.split(","):
				var candidate: String = _first_identifier(String(piece).strip_edges())
				if candidate != "":
					interfaces.append(candidate)
		return {"kind": kind, "name": name, "extends": parent, "implements": interfaces}
	return {}


func _only_modifiers(text: String) -> bool:
	if text == "":
		return true
	for word in text.split(" ", false):
		if not MODIFIERS.has(String(word)):
			return false
	return true


func _match_method(trimmed: String, line_index: int) -> Dictionary:
	var open: int = trimmed.find("(")
	var close: int = trimmed.rfind(")")
	if open < 0 or close < open:
		return {}
	# Deve aprire un blocco o essere una firma astratta.
	var tail: String = trimmed.substr(close + 1).strip_edges()
	if not (tail.begins_with("{") or tail.begins_with(";") or tail.begins_with("throws")):
		return {}
	var head: String = trimmed.substr(0, open).strip_edges()
	var words: PackedStringArray = head.split(" ", false)
	if words.size() == 0:
		return {}
	var name: String = String(words[words.size() - 1])
	if name == "" or not _is_identifier(name):
		return {}
	# Esclude if/for/while/switch/catch, che hanno anch'essi le parentesi.
	if ["if", "for", "while", "switch", "catch", "return", "new"].has(name):
		return {}
	var modifiers: Array[String] = []
	var return_type: String = ""
	for i in range(words.size() - 1):
		var word: String = String(words[i])
		if MODIFIERS.has(word):
			modifiers.append(word)
		else:
			return_type = word
	var params: String = trimmed.substr(open + 1, close - open - 1).strip_edges()
	return {
		"name": name,
		"return_type": return_type,
		"params": params,
		"modifiers": modifiers,
		"line": line_index,
		"is_constructor": return_type == "" and name == type_name,
	}


## Trova dove finisce il metodo che comincia alla riga `start`.
func _method_span(start: int) -> Dictionary:
	var depth: int = 0
	var started: bool = false
	var body: String = ""
	var index: int = start
	while index < clean_lines.size():
		var line: String = clean_lines[index]
		if index > start:
			body += lines[index] + "\n"
		for i in range(line.length()):
			if line[i] == "{":
				depth += 1
				started = true
			elif line[i] == "}":
				depth -= 1
		if started and depth <= 0:
			return {"end": index, "length": index - start + 1, "body": body, "depth": 0}
		if not started and clean_lines[index].strip_edges().ends_with(";"):
			return {"end": index, "length": 1, "body": "", "depth": 0}   # metodo astratto
		index += 1
	return {"end": clean_lines.size() - 1, "length": clean_lines.size() - start,
		"body": body, "depth": depth}


func _match_field(trimmed: String, line_index: int) -> Dictionary:
	var statement: String = trimmed.trim_suffix(";").strip_edges()
	var assign: int = statement.find("=")
	if assign >= 0:
		statement = statement.substr(0, assign).strip_edges()
	var words: PackedStringArray = statement.split(" ", false)
	if words.size() < 2:
		return {}
	var name: String = String(words[words.size() - 1])
	if not _is_identifier(name):
		return {}
	var modifiers: Array[String] = []
	var type_text: String = ""
	for i in range(words.size() - 1):
		var word: String = String(words[i])
		if MODIFIERS.has(word):
			modifiers.append(word)
		else:
			type_text = word
	if type_text == "":
		return {}
	return {"name": name, "type": type_text, "modifiers": modifiers, "line": line_index}


static func _is_identifier(text: String) -> bool:
	if text == "":
		return false
	var first: String = text[0]
	if not ((first >= "a" and first <= "z") or (first >= "A" and first <= "Z") or first == "_"):
		return false
	for i in range(text.length()):
		var c: String = text[i]
		var ok: bool = (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
			or (c >= "0" and c <= "9") or c == "_"
		if not ok:
			return false
	return true


static func _first_identifier(text: String) -> String:
	var out: String = ""
	for i in range(text.length()):
		var c: String = text[i]
		var ok: bool = (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
			or (c >= "0" and c <= "9") or c == "_"
		if ok:
			out += c
		elif out != "":
			break
	return out


# --------------------------------------------------------------- interroga --

func has_type() -> bool:
	return type_name != ""


func find_method(name: String) -> Dictionary:
	for method in methods:
		if String(method["name"]) == name:
			return method
	return {}


## Nota: non si può chiamare has_method(), perché Object ne ha già uno suo.
func declares_method(name: String) -> bool:
	return not find_method(name).is_empty()


func find_field(name: String) -> Dictionary:
	for field in fields:
		if String(field["name"]) == name:
			return field
	return {}


func has_annotation(name: String) -> bool:
	for annotation in annotations:
		if String(annotation["name"]) == name:
			return true
	return false


## Campi visibili dall'esterno: la violazione più comune dell'incapsulamento.
func public_fields() -> Array:
	var out: Array = []
	for field in fields:
		var modifiers: Array = field["modifiers"]
		if modifiers.has("private"):
			continue
		if modifiers.has("static") and modifiers.has("final"):
			continue                                   # una costante va bene
		out.append(field)
	return out


## Metodi più lunghi del limite: [{name, length, line}, ...]
func long_methods(max_lines: int) -> Array:
	var out: Array = []
	for method in methods:
		if int(method["length"]) > max_lines:
			out.append(method)
	return out


## Numeri "magici": letterali numerici nel corpo dei metodi che non siano
## banali. Una costante dichiarata `static final` non conta.
func magic_numbers() -> Array:
	var out: Array = []
	for method in methods:
		var body: String = String(method["body"])
		for token in _numeric_literals(body):
			if not HARMLESS_NUMBERS.has(token):
				out.append({"value": token, "method": String(method["name"])})
	return out


static func _numeric_literals(text: String) -> Array[String]:
	var out: Array[String] = []
	var current: String = ""
	var previous: String = ""
	for i in range(text.length()):
		var c: String = text[i]
		var is_digit: bool = c >= "0" and c <= "9"
		if is_digit or (c == "." and current != ""):
			# Un numero attaccato a una lettera fa parte di un identificatore.
			if current == "" and _is_word_char(previous):
				previous = c
				continue
			current += c
		else:
			if current != "":
				out.append(current)
				current = ""
			previous = c
			continue
		previous = c
	if current != "":
		out.append(current)
	return out


static func _is_word_char(c: String) -> bool:
	if c == "":
		return false
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") \
		or (c >= "0" and c <= "9") or c == "_"


## Nomi troppo corti per dire qualcosa. I contatori di ciclo sono tollerati.
func poor_names(min_length: int = 3) -> Array:
	var out: Array = []
	for field in fields:
		if String(field["name"]).length() < min_length:
			out.append({"kind": "campo", "name": String(field["name"]), "line": int(field["line"])})
	for method in methods:
		var name: String = String(method["name"])
		if name.length() < min_length and not bool(method.get("is_constructor", false)):
			out.append({"kind": "metodo", "name": name, "line": int(method["line"])})
	return out


## Righe di codice identiche ripetute: il segnale più semplice di duplicazione.
func duplicated_lines(min_length: int = 12) -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	for index in range(clean_lines.size()):
		var text: String = clean_lines[index].strip_edges()
		if text.length() < min_length or text == "}" or text == "{":
			continue
		if seen.has(text):
			out.append({"text": text, "first": int(seen[text]), "again": index})
		else:
			seen[text] = index
	return out


## Parentesi graffe bilanciate: se non lo sono, il codice è sicuramente rotto.
func braces_balanced() -> bool:
	var depth: int = 0
	for line in clean_lines:
		depth += _brace_delta(line)
		if depth < 0:
			return false
	return depth == 0


## Cerca un testo nel codice ignorando spazi e maiuscole: serve per controllare
## la presenza di costrutti («implements Comparable», «@Entity»...).
func contains(needle: String) -> bool:
	return _squash(source).contains(_squash(needle))


static func _squash(text: String) -> String:
	var out: String = ""
	for i in range(text.length()):
		var c: String = text[i]
		if c == " " or c == "\t" or c == "\n" or c == "\r":
			continue
		out += c
	return out.to_lower()


## Quante righe di codice vero (senza righe vuote e senza commenti).
func code_line_count() -> int:
	var count: int = 0
	for index in range(clean_lines.size()):
		if clean_lines[index].strip_edges() != "":
			count += 1
	return count
