class_name SqlTokenizer
extends RefCounted

## Analizzatore lessicale del sottoinsieme di SQL supportato dal gioco.
## Trasforma il testo della query in una lista di token.

enum Type { IDENT, NUMBER, STRING, OP, PUNCT, END }

const KEYWORDS: Array[String] = [
	"SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
	"DELETE", "CREATE", "TABLE", "DROP", "ORDER", "BY", "ASC", "DESC",
	"LIMIT", "GROUP", "HAVING", "AND", "OR", "NOT", "IN", "LIKE", "BETWEEN",
	"IS", "NULL", "AS", "DISTINCT", "COUNT", "SUM", "AVG", "MIN", "MAX",
	"INT", "INTEGER", "TEXT", "VARCHAR", "REAL", "DECIMAL", "TRUE", "FALSE",
]

## Un token: { "type": Type, "value": Variant, "text": String, "pos": int }
var tokens: Array = []
var error: String = ""

var _source: String = ""
var _index: int = 0


func tokenize(sql: String) -> bool:
	tokens.clear()
	error = ""
	_source = sql
	_index = 0

	while _index < _source.length():
		var c: String = _source[_index]

		if c == " " or c == "\t" or c == "\n" or c == "\r":
			_index += 1
			continue

		# Commenti -- fino a fine riga
		if c == "-" and _index + 1 < _source.length() and _source[_index + 1] == "-":
			while _index < _source.length() and _source[_index] != "\n":
				_index += 1
			continue

		if c == ";":
			_index += 1
			continue

		if _is_digit(c) or (c == "." and _is_digit(_peek(1))):
			if not _read_number():
				return false
			continue

		if c == "'" or c == "\"":
			if not _read_string(c):
				return false
			continue

		if _is_ident_start(c):
			_read_identifier()
			continue

		if c == "(" or c == ")" or c == "," or c == "*":
			# '*' è punteggiatura in SELECT * ma operatore in un'espressione:
			# lo classifichiamo come PUNCT e il parser decide in base al contesto.
			_push(Type.PUNCT, c, c)
			_index += 1
			continue

		if _read_operator():
			continue

		error = "Carattere non riconosciuto: '%s'" % c
		return false

	_push(Type.END, "", "")
	return true


func _peek(offset: int) -> String:
	var i: int = _index + offset
	return _source[i] if i < _source.length() else ""


func _push(type: int, value: Variant, text: String) -> void:
	tokens.append({"type": type, "value": value, "text": text, "pos": _index})


static func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"


static func _is_ident_start(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"


static func _is_ident_char(c: String) -> bool:
	return _is_ident_start(c) or _is_digit(c)


func _read_number() -> bool:
	var start: int = _index
	var seen_dot: bool = false
	while _index < _source.length():
		var c: String = _source[_index]
		if _is_digit(c):
			_index += 1
		elif c == "." and not seen_dot:
			seen_dot = true
			_index += 1
		else:
			break
	var text: String = _source.substr(start, _index - start)
	if seen_dot:
		_push(Type.NUMBER, text.to_float(), text)
	else:
		_push(Type.NUMBER, text.to_int(), text)
	return true


func _read_string(quote: String) -> bool:
	_index += 1
	var value: String = ""
	while _index < _source.length():
		var c: String = _source[_index]
		if c == quote:
			# '' dentro una stringa significa un apice letterale
			if _peek(1) == quote:
				value += quote
				_index += 2
				continue
			_index += 1
			_push(Type.STRING, value, value)
			return true
		value += c
		_index += 1
	error = "Stringa aperta con %s ma mai chiusa: ricordati l'apice finale." % quote
	return false


func _read_identifier() -> void:
	var start: int = _index
	while _index < _source.length() and _is_ident_char(_source[_index]):
		_index += 1
	# Backtick di MySQL attorno ai nomi: `tabella`
	var text: String = _source.substr(start, _index - start)
	_push(Type.IDENT, text, text)


func _read_operator() -> bool:
	var two: String = _source.substr(_index, 2)
	if two == "<=" or two == ">=" or two == "<>" or two == "!=":
		_push(Type.OP, two, two)
		_index += 2
		return true
	var one: String = _source[_index]
	if one == "=" or one == "<" or one == ">" or one == "+" or one == "-" or one == "/" or one == "%":
		_push(Type.OP, one, one)
		_index += 1
		return true
	if one == "`":
		# nome fra backtick
		_index += 1
		var start: int = _index
		while _index < _source.length() and _source[_index] != "`":
			_index += 1
		var text: String = _source.substr(start, _index - start)
		_index += 1
		_push(Type.IDENT, text, text)
		return true
	return false


static func is_keyword(word: String) -> bool:
	return KEYWORDS.has(word.to_upper())
