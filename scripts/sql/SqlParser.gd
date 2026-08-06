class_name SqlParser
extends RefCounted

## Parser a discesa ricorsiva: dai token costruisce l'albero sintattico
## della query. Gli errori sono scritti per insegnare, non per il compilatore.

const AGGREGATES: Array[String] = ["COUNT", "SUM", "AVG", "MIN", "MAX"]

var error: String = ""

var _tokens: Array = []
var _pos: int = 0


## Ritorna l'AST come Dictionary, oppure {} in caso di errore (vedi `error`).
func parse(sql: String) -> Dictionary:
	error = ""
	var tokenizer: SqlTokenizer = SqlTokenizer.new()
	if not tokenizer.tokenize(sql):
		error = tokenizer.error
		return {}
	_tokens = tokenizer.tokens
	_pos = 0

	if _check_end():
		error = "La query è vuota: scrivi un comando come SELECT * FROM tabella."
		return {}

	var statement: Dictionary = _parse_statement()
	if error != "":
		return {}
	if not _check_end():
		error = "Non capisco cosa ci fa '%s' alla fine della query." % _current_text()
		return {}
	return statement


# ---------------------------------------------------------------- helper ---

func _current() -> Dictionary:
	return _tokens[_pos] if _pos < _tokens.size() else {"type": SqlTokenizer.Type.END, "text": "", "value": ""}


func _current_text() -> String:
	return String(_current().get("text", ""))


func _current_upper() -> String:
	return _current_text().to_upper()


func _check_end() -> bool:
	return int(_current().get("type", SqlTokenizer.Type.END)) == SqlTokenizer.Type.END


func _advance() -> Dictionary:
	var token: Dictionary = _current()
	_pos += 1
	return token


func _accept_keyword(word: String) -> bool:
	if int(_current().get("type")) == SqlTokenizer.Type.IDENT and _current_upper() == word:
		_pos += 1
		return true
	return false


func _accept_punct(symbol: String) -> bool:
	var type: int = int(_current().get("type"))
	if (type == SqlTokenizer.Type.PUNCT or type == SqlTokenizer.Type.OP) and _current_text() == symbol:
		_pos += 1
		return true
	return false


func _expect_keyword(word: String, message: String) -> bool:
	if _accept_keyword(word):
		return true
	error = message
	return false


func _expect_punct(symbol: String, message: String) -> bool:
	if _accept_punct(symbol):
		return true
	error = message
	return false


## Legge un nome (di tabella o colonna) rifiutando le parole riservate.
func _expect_name(what: String) -> String:
	if int(_current().get("type")) != SqlTokenizer.Type.IDENT:
		error = "Mi aspettavo %s, ho trovato '%s'." % [what, _current_text()]
		return ""
	var text: String = _current_text()
	if SqlTokenizer.is_keyword(text) and not AGGREGATES.has(text.to_upper()):
		error = "'%s' è una parola riservata di SQL e non può essere usata come %s." % [text, what]
		return ""
	_pos += 1
	return text


# ------------------------------------------------------------ statements ---

func _parse_statement() -> Dictionary:
	var word: String = _current_upper()
	match word:
		"SELECT":
			return _parse_select()
		"INSERT":
			return _parse_insert()
		"UPDATE":
			return _parse_update()
		"DELETE":
			return _parse_delete()
		"CREATE":
			return _parse_create()
		"DROP":
			return _parse_drop()
	error = "'%s' non è un comando che conosco. Usa SELECT, INSERT, UPDATE, DELETE, CREATE TABLE o DROP TABLE." % _current_text()
	return {}


func _parse_select() -> Dictionary:
	_advance()   # SELECT
	var node: Dictionary = {
		"kind": "select", "distinct": false, "columns": [], "star": false,
		"from": "", "where": {}, "group": "", "order": {}, "limit": -1,
	}
	node["distinct"] = _accept_keyword("DISTINCT")

	if _accept_punct("*"):
		node["star"] = true
	else:
		while true:
			var item: Dictionary = _parse_select_item()
			if error != "":
				return {}
			node["columns"].append(item)
			if not _accept_punct(","):
				break

	if not _expect_keyword("FROM", "Dopo l'elenco delle colonne serve FROM seguito dal nome della tabella."):
		return {}
	node["from"] = _expect_name("il nome di una tabella")
	if error != "":
		return {}

	if _accept_keyword("WHERE"):
		node["where"] = _parse_condition()
		if error != "":
			return {}

	if _accept_keyword("GROUP"):
		if not _expect_keyword("BY", "Dopo GROUP serve BY, cioè GROUP BY colonna."):
			return {}
		node["group"] = _expect_name("il nome di una colonna")
		if error != "":
			return {}

	if _accept_keyword("ORDER"):
		if not _expect_keyword("BY", "Dopo ORDER serve BY, cioè ORDER BY colonna."):
			return {}
		var order_col: String = _expect_name("il nome di una colonna")
		if error != "":
			return {}
		var descending: bool = false
		if _accept_keyword("DESC"):
			descending = true
		else:
			_accept_keyword("ASC")
		node["order"] = {"column": order_col, "desc": descending}

	if _accept_keyword("LIMIT"):
		if int(_current().get("type")) != SqlTokenizer.Type.NUMBER:
			error = "Dopo LIMIT serve un numero, per esempio LIMIT 5."
			return {}
		node["limit"] = int(_advance()["value"])

	return node


func _parse_select_item() -> Dictionary:
	var expression: Dictionary = _parse_expression()
	if error != "":
		return {}
	var alias: String = ""
	if _accept_keyword("AS"):
		alias = _expect_name("un alias")
		if error != "":
			return {}
	elif int(_current().get("type")) == SqlTokenizer.Type.IDENT and not SqlTokenizer.is_keyword(_current_text()):
		alias = _advance()["text"]
	return {"expr": expression, "alias": alias}


func _parse_insert() -> Dictionary:
	_advance()   # INSERT
	if not _expect_keyword("INTO", "La sintassi è INSERT INTO tabella (colonne) VALUES (valori)."):
		return {}
	var table: String = _expect_name("il nome di una tabella")
	if error != "":
		return {}

	var columns: Array[String] = []
	if _accept_punct("("):
		while true:
			var name: String = _expect_name("il nome di una colonna")
			if error != "":
				return {}
			columns.append(name)
			if not _accept_punct(","):
				break
		if not _expect_punct(")", "Manca la parentesi chiusa dopo l'elenco delle colonne."):
			return {}

	if not _expect_keyword("VALUES", "Dopo la tabella serve VALUES seguito dai valori fra parentesi."):
		return {}

	var rows: Array = []
	while true:
		if not _expect_punct("(", "I valori vanno fra parentesi: VALUES ('Mario', 30)."):
			return {}
		var values: Array = []
		while true:
			var expression: Dictionary = _parse_expression()
			if error != "":
				return {}
			values.append(expression)
			if not _accept_punct(","):
				break
		if not _expect_punct(")", "Manca la parentesi chiusa dopo i valori."):
			return {}
		rows.append(values)
		if not _accept_punct(","):
			break

	return {"kind": "insert", "table": table, "columns": columns, "rows": rows}


func _parse_update() -> Dictionary:
	_advance()   # UPDATE
	var table: String = _expect_name("il nome di una tabella")
	if error != "":
		return {}
	if not _expect_keyword("SET", "Dopo il nome della tabella serve SET colonna = valore."):
		return {}

	var assignments: Array = []
	while true:
		var column: String = _expect_name("il nome di una colonna")
		if error != "":
			return {}
		if not _expect_punct("=", "Fra la colonna e il nuovo valore serve il segno =."):
			return {}
		var expression: Dictionary = _parse_expression()
		if error != "":
			return {}
		assignments.append({"column": column, "value": expression})
		if not _accept_punct(","):
			break

	var where: Dictionary = {}
	if _accept_keyword("WHERE"):
		where = _parse_condition()
		if error != "":
			return {}

	return {"kind": "update", "table": table, "set": assignments, "where": where}


func _parse_delete() -> Dictionary:
	_advance()   # DELETE
	if not _expect_keyword("FROM", "La sintassi è DELETE FROM tabella WHERE condizione."):
		return {}
	var table: String = _expect_name("il nome di una tabella")
	if error != "":
		return {}
	var where: Dictionary = {}
	if _accept_keyword("WHERE"):
		where = _parse_condition()
		if error != "":
			return {}
	return {"kind": "delete", "table": table, "where": where}


func _parse_create() -> Dictionary:
	_advance()   # CREATE
	if not _expect_keyword("TABLE", "Per creare una tabella scrivi CREATE TABLE nome (colonna TIPO, ...)."):
		return {}
	var table: String = _expect_name("il nome della nuova tabella")
	if error != "":
		return {}
	if not _expect_punct("(", "Dopo il nome della tabella servono le colonne fra parentesi."):
		return {}

	var columns: Array = []
	while true:
		var name: String = _expect_name("il nome di una colonna")
		if error != "":
			return {}
		if int(_current().get("type")) != SqlTokenizer.Type.IDENT:
			error = "Alla colonna '%s' manca il tipo: per esempio INT o VARCHAR." % name
			return {}
		var type: String = _advance()["text"].to_upper()
		# VARCHAR(50): la lunghezza non ci serve, la saltiamo
		if _accept_punct("("):
			while not _check_end() and not _accept_punct(")"):
				_advance()
		# Vincoli tipo PRIMARY KEY / NOT NULL: li accettiamo e li ignoriamo
		while int(_current().get("type")) == SqlTokenizer.Type.IDENT and not _check_end():
			var word: String = _current_upper()
			if word == "PRIMARY" or word == "KEY" or word == "NOT" or word == "NULL" or word == "UNIQUE" or word == "AUTO_INCREMENT":
				_advance()
			else:
				break
		columns.append({"name": name, "type": type})
		if not _accept_punct(","):
			break

	if not _expect_punct(")", "Manca la parentesi chiusa alla fine delle colonne."):
		return {}
	return {"kind": "create", "table": table, "columns": columns}


func _parse_drop() -> Dictionary:
	_advance()   # DROP
	if not _expect_keyword("TABLE", "Per eliminare una tabella scrivi DROP TABLE nome."):
		return {}
	var table: String = _expect_name("il nome della tabella da eliminare")
	if error != "":
		return {}
	return {"kind": "drop", "table": table}


# ------------------------------------------------------------ condizioni ---

func _parse_condition() -> Dictionary:
	return _parse_or()


func _parse_or() -> Dictionary:
	var left: Dictionary = _parse_and()
	if error != "":
		return {}
	while _accept_keyword("OR"):
		var right: Dictionary = _parse_and()
		if error != "":
			return {}
		left = {"type": "or", "left": left, "right": right}
	return left


func _parse_and() -> Dictionary:
	var left: Dictionary = _parse_not()
	if error != "":
		return {}
	while _accept_keyword("AND"):
		var right: Dictionary = _parse_not()
		if error != "":
			return {}
		left = {"type": "and", "left": left, "right": right}
	return left


func _parse_not() -> Dictionary:
	if _accept_keyword("NOT"):
		var inner: Dictionary = _parse_not()
		if error != "":
			return {}
		return {"type": "not", "expr": inner}
	return _parse_predicate()


func _parse_predicate() -> Dictionary:
	# Una parentesi può racchiudere una condizione oppure un'espressione:
	# guardiamo avanti per capire quale delle due.
	if _current_text() == "(" and _paren_holds_condition():
		_advance()
		var inner: Dictionary = _parse_condition()
		if error != "":
			return {}
		if not _expect_punct(")", "Manca la parentesi chiusa nella condizione."):
			return {}
		return inner

	var left: Dictionary = _parse_expression()
	if error != "":
		return {}

	var negate: bool = _accept_keyword("NOT")

	if _accept_keyword("IN"):
		return _parse_in(left, negate)
	if _accept_keyword("LIKE"):
		var pattern: Dictionary = _parse_expression()
		if error != "":
			return {}
		return {"type": "like", "expr": left, "pattern": pattern, "negate": negate}
	if _accept_keyword("BETWEEN"):
		var low: Dictionary = _parse_expression()
		if error != "":
			return {}
		if not _expect_keyword("AND", "Dopo BETWEEN servono due valori separati da AND."):
			return {}
		var high: Dictionary = _parse_expression()
		if error != "":
			return {}
		return {"type": "between", "expr": left, "low": low, "high": high, "negate": negate}
	if _accept_keyword("IS"):
		var is_negate: bool = _accept_keyword("NOT")
		if not _expect_keyword("NULL", "Dopo IS serve NULL (oppure NOT NULL)."):
			return {}
		return {"type": "isnull", "expr": left, "negate": is_negate}

	if negate:
		error = "Dopo NOT mi aspettavo IN, LIKE o BETWEEN."
		return {}

	var operator: String = _current_text()
	if int(_current().get("type")) == SqlTokenizer.Type.OP and ["=", "<", ">", "<=", ">=", "<>", "!="].has(operator):
		_advance()
		var right: Dictionary = _parse_expression()
		if error != "":
			return {}
		return {"type": "cmp", "op": operator, "left": left, "right": right}

	error = "Nella condizione manca un confronto: per esempio eta > 30 oppure citta = 'Roma'."
	return {}


func _parse_in(left: Dictionary, negate: bool) -> Dictionary:
	if not _expect_punct("(", "Dopo IN servono le parentesi: IN (1, 2, 3) oppure IN (SELECT ...)."):
		return {}
	if _current_upper() == "SELECT":
		var subquery: Dictionary = _parse_select()
		if error != "":
			return {}
		if not _expect_punct(")", "Manca la parentesi chiusa dopo la sottoquery."):
			return {}
		return {"type": "in", "expr": left, "subquery": subquery, "list": [], "negate": negate}

	var values: Array = []
	while true:
		var expression: Dictionary = _parse_expression()
		if error != "":
			return {}
		values.append(expression)
		if not _accept_punct(","):
			break
	if not _expect_punct(")", "Manca la parentesi chiusa dopo l'elenco di IN."):
		return {}
	return {"type": "in", "expr": left, "subquery": {}, "list": values, "negate": negate}


## Guarda avanti fino alla parentesi corrispondente: se al livello esterno
## trova un operatore logico o di confronto, allora è una condizione.
func _paren_holds_condition() -> bool:
	var depth: int = 0
	var i: int = _pos
	while i < _tokens.size():
		var token: Dictionary = _tokens[i]
		var text: String = String(token.get("text", ""))
		var upper: String = text.to_upper()
		if text == "(":
			depth += 1
		elif text == ")":
			depth -= 1
			if depth == 0:
				return false
		elif depth == 1:
			if upper == "SELECT":
				return false
			if ["AND", "OR", "IN", "LIKE", "BETWEEN", "IS"].has(upper):
				return true
			if int(token.get("type")) == SqlTokenizer.Type.OP and ["=", "<", ">", "<=", ">=", "<>", "!="].has(text):
				return true
		i += 1
	return false


# ----------------------------------------------------------- espressioni ---

func _parse_expression() -> Dictionary:
	return _parse_additive()


func _parse_additive() -> Dictionary:
	var left: Dictionary = _parse_multiplicative()
	if error != "":
		return {}
	while int(_current().get("type")) == SqlTokenizer.Type.OP and (_current_text() == "+" or _current_text() == "-"):
		var operator: String = _advance()["text"]
		var right: Dictionary = _parse_multiplicative()
		if error != "":
			return {}
		left = {"type": "binop", "op": operator, "left": left, "right": right}
	return left


func _parse_multiplicative() -> Dictionary:
	var left: Dictionary = _parse_primary()
	if error != "":
		return {}
	while _current_text() == "*" or _current_text() == "/" or _current_text() == "%":
		var operator: String = _advance()["text"]
		var right: Dictionary = _parse_primary()
		if error != "":
			return {}
		left = {"type": "binop", "op": operator, "left": left, "right": right}
	return left


func _parse_primary() -> Dictionary:
	var token: Dictionary = _current()
	var type: int = int(token.get("type"))

	if type == SqlTokenizer.Type.NUMBER:
		_advance()
		return {"type": "lit", "value": token["value"]}

	if type == SqlTokenizer.Type.STRING:
		_advance()
		return {"type": "lit", "value": token["value"]}

	if _current_text() == "-":
		_advance()
		var inner: Dictionary = _parse_primary()
		if error != "":
			return {}
		return {"type": "binop", "op": "-", "left": {"type": "lit", "value": 0}, "right": inner}

	if _current_text() == "(":
		_advance()
		if _current_upper() == "SELECT":
			var subquery: Dictionary = _parse_select()
			if error != "":
				return {}
			if not _expect_punct(")", "Manca la parentesi chiusa dopo la sottoquery."):
				return {}
			return {"type": "subquery", "select": subquery}
		var expression: Dictionary = _parse_expression()
		if error != "":
			return {}
		if not _expect_punct(")", "Manca una parentesi chiusa."):
			return {}
		return expression

	if type == SqlTokenizer.Type.IDENT:
		var upper: String = _current_upper()
		if upper == "NULL":
			_advance()
			return {"type": "lit", "value": null}
		if upper == "TRUE" or upper == "FALSE":
			_advance()
			return {"type": "lit", "value": 1 if upper == "TRUE" else 0}
		if AGGREGATES.has(upper):
			return _parse_aggregate()
		var name: String = _advance()["text"]
		return {"type": "col", "name": name}

	error = "Mi aspettavo un valore o il nome di una colonna, ho trovato '%s'." % _current_text()
	return {}


func _parse_aggregate() -> Dictionary:
	var function: String = _advance()["text"].to_upper()
	if not _expect_punct("(", "Dopo %s servono le parentesi, per esempio %s(eta)." % [function, function]):
		return {}
	if _accept_punct("*"):
		if not _expect_punct(")", "Manca la parentesi chiusa di %s(*)." % function):
			return {}
		return {"type": "agg", "func": function, "star": true, "arg": {}}
	var argument: Dictionary = _parse_expression()
	if error != "":
		return {}
	if not _expect_punct(")", "Manca la parentesi chiusa di %s." % function):
		return {}
	return {"type": "agg", "func": function, "star": false, "arg": argument}
