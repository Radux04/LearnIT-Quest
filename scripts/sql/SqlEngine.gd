class_name SqlEngine
extends RefCounted

## Esegue l'AST prodotto da SqlParser su un SqlDatabase.
## Il risultato è sempre un Dictionary:
##   ok        bool
##   error     String  (messaggio didattico, se ok == false)
##   kind      String  "select" | "insert" | "update" | "delete" | "create" | "drop"
##   columns   Array[String]
##   rows      Array[Array]     (solo per SELECT)
##   affected  int              (righe toccate da INSERT/UPDATE/DELETE)
##   message   String           (riepilogo per la console)

const AGGREGATES: Array[String] = ["COUNT", "SUM", "AVG", "MIN", "MAX"]


static func empty_result() -> Dictionary:
	return {
		"ok": true, "error": "", "kind": "", "columns": [], "rows": [],
		"affected": 0, "message": "",
	}


static func fail(message: String) -> Dictionary:
	var result: Dictionary = empty_result()
	result["ok"] = false
	result["error"] = message
	return result


static func execute(db: SqlDatabase, sql: String) -> Dictionary:
	var parser: SqlParser = SqlParser.new()
	var ast: Dictionary = parser.parse(sql)
	if parser.error != "":
		return fail(parser.error)
	return execute_ast(db, ast)


static func execute_ast(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	match String(ast.get("kind", "")):
		"select":
			return _run_select(db, ast)
		"insert":
			return _run_insert(db, ast)
		"update":
			return _run_update(db, ast)
		"delete":
			return _run_delete(db, ast)
		"create":
			return _run_create(db, ast)
		"drop":
			return _run_drop(db, ast)
	return fail("Comando non riconosciuto.")


# ------------------------------------------------------------- messaggi ---

static func _missing_table(db: SqlDatabase, name: String) -> String:
	var available: Array[String] = db.table_names()
	if available.is_empty():
		return "La tabella '%s' non esiste e al momento il database è vuoto." % name
	return "La tabella '%s' non esiste. Tabelle disponibili: %s." % [name, ", ".join(available)]


static func _missing_column(db: SqlDatabase, table: String, column: String) -> String:
	var available: Array[String] = db.column_names(table)
	return "La colonna '%s' non esiste in %s. Colonne disponibili: %s." % [
		column, table, ", ".join(available)]


# --------------------------------------------------------------- SELECT ---

static func _run_select(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	var table_name: String = String(ast["from"])
	if not db.has_table(table_name):
		return fail(_missing_table(db, table_name))
	var table: Dictionary = db.get_table(table_name)

	# 1. filtro WHERE
	var filtered: Array = []
	for row in table["rows"]:
		if ast["where"].is_empty():
			filtered.append(row)
			continue
		var keep: Variant = _eval_condition(db, ast["where"], row, table_name)
		if keep is String:
			return fail(keep)
		if bool(keep):
			filtered.append(row)

	var has_aggregate: bool = _select_has_aggregate(ast)
	var group_column: String = String(ast["group"])

	# 2. proiezione (con o senza raggruppamento)
	var output: Array = []          # [{ "values": Dictionary, "source": Dictionary }]
	var columns: Array[String] = []

	if group_column != "" or has_aggregate:
		var groups: Array = []
		if group_column != "":
			var real_column: String = db.resolve_column(table_name, group_column)
			if real_column == "":
				return fail(_missing_column(db, table_name, group_column))
			var buckets: Dictionary = {}
			var order: Array = []
			for row in filtered:
				var key: String = SqlDatabase.format_value(row.get(real_column))
				if not buckets.has(key):
					buckets[key] = []
					order.append(key)
				buckets[key].append(row)
			for key in order:
				groups.append(buckets[key])
		else:
			groups.append(filtered)

		for group_rows in groups:
			var values: Dictionary = {}
			var representative: Dictionary = group_rows[0] if group_rows.size() > 0 else {}
			for item in ast["columns"]:
				var name: String = _output_name(item)
				var value: Variant = _eval_group(db, item["expr"], group_rows, representative, table_name)
				if value is String and String(value).begins_with("\u0001"):
					return fail(String(value).substr(1))
				values[name] = value
			output.append({"values": values, "source": representative})
		columns = _output_columns(ast, db, table_name)
	else:
		if ast["star"]:
			columns = db.column_names(table_name)
			for row in filtered:
				var values: Dictionary = {}
				for name in columns:
					values[name] = row.get(name)
				output.append({"values": values, "source": row})
		else:
			columns = _output_columns(ast, db, table_name)
			for row in filtered:
				var values: Dictionary = {}
				for item in ast["columns"]:
					var name: String = _output_name(item)
					var value: Variant = _eval_expression(db, item["expr"], row, table_name)
					if value is String and String(value).begins_with("\u0001"):
						return fail(String(value).substr(1))
					values[name] = value
				output.append({"values": values, "source": row})

	# 3. DISTINCT
	if ast["distinct"]:
		var unique: Array = []
		for entry in output:
			var duplicate_found: bool = false
			for existing in unique:
				if SqlDatabase._same_row(existing["values"], entry["values"]):
					duplicate_found = true
					break
			if not duplicate_found:
				unique.append(entry)
		output = unique

	# 4. ORDER BY
	if not ast["order"].is_empty():
		var order_column: String = String(ast["order"]["column"])
		var descending: bool = bool(ast["order"]["desc"])
		var resolved: String = ""
		for name in columns:
			if name.to_lower() == order_column.to_lower():
				resolved = name
				break
		var source_column: String = db.resolve_column(table_name, order_column)
		if resolved == "" and source_column == "":
			return fail(_missing_column(db, table_name, order_column))
		output.sort_custom(func(a, b):
			var va: Variant = a["values"].get(resolved) if resolved != "" else a["source"].get(source_column)
			var vb: Variant = b["values"].get(resolved) if resolved != "" else b["source"].get(source_column)
			var comparison: int = _compare(va, vb)
			return comparison > 0 if descending else comparison < 0)

	# 5. LIMIT
	if int(ast["limit"]) >= 0:
		output = output.slice(0, int(ast["limit"]))

	var result: Dictionary = empty_result()
	result["kind"] = "select"
	result["columns"] = columns
	for entry in output:
		var line: Array = []
		for name in columns:
			line.append(entry["values"].get(name))
		result["rows"].append(line)
	result["affected"] = result["rows"].size()
	result["message"] = "%d riga/e trovate." % result["rows"].size()
	return result


static func _select_has_aggregate(ast: Dictionary) -> bool:
	for item in ast["columns"]:
		if _expression_has_aggregate(item["expr"]):
			return true
	return false


static func _expression_has_aggregate(expr: Dictionary) -> bool:
	match String(expr.get("type", "")):
		"agg":
			return true
		"binop":
			return _expression_has_aggregate(expr["left"]) or _expression_has_aggregate(expr["right"])
	return false


static func _output_name(item: Dictionary) -> String:
	if String(item.get("alias", "")) != "":
		return String(item["alias"])
	return _expression_label(item["expr"])


static func _expression_label(expr: Dictionary) -> String:
	match String(expr.get("type", "")):
		"col":
			return String(expr["name"])
		"lit":
			return SqlDatabase.format_value(expr["value"])
		"agg":
			return "%s(%s)" % [expr["func"], "*" if bool(expr["star"]) else _expression_label(expr["arg"])]
		"binop":
			return "%s %s %s" % [_expression_label(expr["left"]), expr["op"], _expression_label(expr["right"])]
		"subquery":
			return "(subquery)"
	return "?"


static func _output_columns(ast: Dictionary, db: SqlDatabase, table_name: String) -> Array[String]:
	var columns: Array[String] = []
	for item in ast["columns"]:
		var name: String = _output_name(item)
		# Per una colonna semplice usiamo il nome reale della tabella
		if String(item["expr"].get("type", "")) == "col" and String(item.get("alias", "")) == "":
			var real: String = db.resolve_column(table_name, name)
			if real != "":
				name = real
		columns.append(name)
	return columns


# --------------------------------------------------------------- INSERT ---

static func _run_insert(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	var table_name: String = String(ast["table"])
	if not db.has_table(table_name):
		return fail(_missing_table(db, table_name))

	var all_columns: Array[String] = db.column_names(table_name)
	var target: Array[String] = []
	if ast["columns"].is_empty():
		target = all_columns
	else:
		for name in ast["columns"]:
			var real: String = db.resolve_column(table_name, String(name))
			if real == "":
				return fail(_missing_column(db, table_name, String(name)))
			target.append(real)

	var inserted: int = 0
	for values in ast["rows"]:
		if values.size() != target.size():
			return fail("Hai indicato %d colonne ma %d valori: devono essere in numero uguale." % [
				target.size(), values.size()])
		var row: Dictionary = {}
		for name in all_columns:
			row[name] = null
		for i in range(target.size()):
			var value: Variant = _eval_expression(db, values[i], {}, table_name)
			if value is String and String(value).begins_with("\u0001"):
				return fail(String(value).substr(1))
			row[target[i]] = value
		db.insert_row(table_name, row)
		inserted += 1

	var result: Dictionary = empty_result()
	result["kind"] = "insert"
	result["affected"] = inserted
	result["message"] = "%d riga/e inserite in %s." % [inserted, table_name]
	return result


# --------------------------------------------------------------- UPDATE ---

static func _run_update(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	var table_name: String = String(ast["table"])
	if not db.has_table(table_name):
		return fail(_missing_table(db, table_name))
	var table: Dictionary = db.get_table(table_name)

	for assignment in ast["set"]:
		if db.resolve_column(table_name, String(assignment["column"])) == "":
			return fail(_missing_column(db, table_name, String(assignment["column"])))

	var changed: int = 0
	for row in table["rows"]:
		if not ast["where"].is_empty():
			var keep: Variant = _eval_condition(db, ast["where"], row, table_name)
			if keep is String:
				return fail(keep)
			if not bool(keep):
				continue
		for assignment in ast["set"]:
			var column: String = db.resolve_column(table_name, String(assignment["column"]))
			var value: Variant = _eval_expression(db, assignment["value"], row, table_name)
			if value is String and String(value).begins_with("\u0001"):
				return fail(String(value).substr(1))
			row[column] = value
		changed += 1

	var result: Dictionary = empty_result()
	result["kind"] = "update"
	result["affected"] = changed
	result["message"] = "%d riga/e aggiornate in %s." % [changed, table_name]
	return result


# --------------------------------------------------------------- DELETE ---

static func _run_delete(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	var table_name: String = String(ast["table"])
	if not db.has_table(table_name):
		return fail(_missing_table(db, table_name))
	var table: Dictionary = db.get_table(table_name)

	var kept: Array = []
	var removed: int = 0
	for row in table["rows"]:
		var should_delete: bool = true
		if not ast["where"].is_empty():
			var matched: Variant = _eval_condition(db, ast["where"], row, table_name)
			if matched is String:
				return fail(matched)
			should_delete = bool(matched)
		if should_delete:
			removed += 1
		else:
			kept.append(row)
	table["rows"] = kept

	var result: Dictionary = empty_result()
	result["kind"] = "delete"
	result["affected"] = removed
	result["message"] = "%d riga/e eliminate da %s." % [removed, table_name]
	return result


# ---------------------------------------------------------- CREATE/DROP ---

static func _run_create(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	var table_name: String = String(ast["table"])
	if db.has_table(table_name):
		return fail("La tabella '%s' esiste già." % table_name)
	db.create_table(table_name, ast["columns"])
	var result: Dictionary = empty_result()
	result["kind"] = "create"
	result["message"] = "Tabella %s creata con %d colonne." % [table_name, ast["columns"].size()]
	return result


static func _run_drop(db: SqlDatabase, ast: Dictionary) -> Dictionary:
	var table_name: String = String(ast["table"])
	if not db.has_table(table_name):
		return fail(_missing_table(db, table_name))
	db.drop_table(table_name)
	var result: Dictionary = empty_result()
	result["kind"] = "drop"
	result["message"] = "Tabella %s eliminata." % table_name
	return result


# ----------------------------------------------------------- espressioni ---
# Gli errori vengono restituiti come String che inizia con \u0001 per
# distinguerli da un normale valore testuale.

static func _error_value(message: String) -> String:
	return "\u0001" + message


static func _eval_expression(db: SqlDatabase, expr: Dictionary, row: Dictionary, table_name: String) -> Variant:
	match String(expr.get("type", "")):
		"lit":
			return expr["value"]
		"col":
			var name: String = String(expr["name"])
			for key in row.keys():
				if String(key).to_lower() == name.to_lower():
					return row[key]
			if table_name != "" and db.has_table(table_name):
				return _error_value(_missing_column(db, table_name, name))
			return _error_value("La colonna '%s' non esiste." % name)
		"binop":
			var left: Variant = _eval_expression(db, expr["left"], row, table_name)
			if left is String and String(left).begins_with("\u0001"):
				return left
			var right: Variant = _eval_expression(db, expr["right"], row, table_name)
			if right is String and String(right).begins_with("\u0001"):
				return right
			return _arithmetic(String(expr["op"]), left, right)
		"subquery":
			var result: Dictionary = _run_select(db, expr["select"])
			if not result["ok"]:
				return _error_value(String(result["error"]))
			if result["rows"].is_empty():
				return null
			return result["rows"][0][0]
		"agg":
			return _error_value("Le funzioni come %s si usano nell'elenco delle colonne di una SELECT, non qui." % expr["func"])
	return null


static func _arithmetic(op: String, a: Variant, b: Variant) -> Variant:
	if a == null or b == null:
		return null
	var x: float = _to_number(a)
	var y: float = _to_number(b)
	match op:
		"+":
			return _shrink(x + y)
		"-":
			return _shrink(x - y)
		"*":
			return _shrink(x * y)
		"/":
			if is_zero_approx(y):
				return null
			return _shrink(x / y)
		"%":
			if is_zero_approx(y):
				return null
			return _shrink(fmod(x, y))
	return null


static func _shrink(value: float) -> Variant:
	if is_equal_approx(value, roundf(value)):
		return int(roundf(value))
	return value


static func _to_number(value: Variant) -> float:
	if value is int or value is float:
		return float(value)
	if value is String and String(value).is_valid_float():
		return String(value).to_float()
	return 0.0


static func _eval_group(db: SqlDatabase, expr: Dictionary, rows: Array, representative: Dictionary, table_name: String) -> Variant:
	if String(expr.get("type", "")) == "agg":
		return _eval_aggregate(db, expr, rows, table_name)
	if String(expr.get("type", "")) == "binop":
		var left: Variant = _eval_group(db, expr["left"], rows, representative, table_name)
		if left is String and String(left).begins_with("\u0001"):
			return left
		var right: Variant = _eval_group(db, expr["right"], rows, representative, table_name)
		if right is String and String(right).begins_with("\u0001"):
			return right
		return _arithmetic(String(expr["op"]), left, right)
	return _eval_expression(db, expr, representative, table_name)


static func _eval_aggregate(db: SqlDatabase, expr: Dictionary, rows: Array, table_name: String) -> Variant:
	var function: String = String(expr["func"])
	if function == "COUNT" and bool(expr["star"]):
		return rows.size()

	var values: Array = []
	for row in rows:
		var value: Variant = _eval_expression(db, expr["arg"], row, table_name)
		if value is String and String(value).begins_with("\u0001"):
			return value
		if value != null:
			values.append(value)

	match function:
		"COUNT":
			return values.size()
		"SUM":
			var total: float = 0.0
			for value in values:
				total += _to_number(value)
			return _shrink(total)
		"AVG":
			if values.is_empty():
				return null
			var sum: float = 0.0
			for value in values:
				sum += _to_number(value)
			return _shrink(sum / float(values.size()))
		"MIN", "MAX":
			if values.is_empty():
				return null
			var best: Variant = values[0]
			for value in values:
				var comparison: int = _compare(value, best)
				if (function == "MIN" and comparison < 0) or (function == "MAX" and comparison > 0):
					best = value
			return best
	return null


# ------------------------------------------------------------ condizioni ---
# Ritorna bool, oppure String col messaggio d'errore.

static func _eval_condition(db: SqlDatabase, cond: Dictionary, row: Dictionary, table_name: String) -> Variant:
	match String(cond.get("type", "")):
		"and":
			var left: Variant = _eval_condition(db, cond["left"], row, table_name)
			if left is String:
				return left
			if not bool(left):
				return false
			return _eval_condition(db, cond["right"], row, table_name)
		"or":
			var left_or: Variant = _eval_condition(db, cond["left"], row, table_name)
			if left_or is String:
				return left_or
			if bool(left_or):
				return true
			return _eval_condition(db, cond["right"], row, table_name)
		"not":
			var inner: Variant = _eval_condition(db, cond["expr"], row, table_name)
			if inner is String:
				return inner
			return not bool(inner)
		"cmp":
			return _eval_comparison(db, cond, row, table_name)
		"in":
			return _eval_in(db, cond, row, table_name)
		"like":
			return _eval_like(db, cond, row, table_name)
		"between":
			return _eval_between(db, cond, row, table_name)
		"isnull":
			var value: Variant = _eval_expression(db, cond["expr"], row, table_name)
			if value is String and String(value).begins_with("\u0001"):
				return String(value).substr(1)
			var is_null: bool = value == null
			return not is_null if bool(cond["negate"]) else is_null
	return false


static func _eval_comparison(db: SqlDatabase, cond: Dictionary, row: Dictionary, table_name: String) -> Variant:
	var left: Variant = _eval_expression(db, cond["left"], row, table_name)
	if left is String and String(left).begins_with("\u0001"):
		return String(left).substr(1)
	var right: Variant = _eval_expression(db, cond["right"], row, table_name)
	if right is String and String(right).begins_with("\u0001"):
		return String(right).substr(1)
	if left == null or right == null:
		return false
	var comparison: int = _compare(left, right)
	match String(cond["op"]):
		"=":
			return comparison == 0
		"<":
			return comparison < 0
		">":
			return comparison > 0
		"<=":
			return comparison <= 0
		">=":
			return comparison >= 0
		"<>", "!=":
			return comparison != 0
	return false


static func _eval_in(db: SqlDatabase, cond: Dictionary, row: Dictionary, table_name: String) -> Variant:
	var value: Variant = _eval_expression(db, cond["expr"], row, table_name)
	if value is String and String(value).begins_with("\u0001"):
		return String(value).substr(1)

	var candidates: Array = []
	if not cond["subquery"].is_empty():
		var result: Dictionary = _run_select(db, cond["subquery"])
		if not result["ok"]:
			return String(result["error"])
		for line in result["rows"]:
			if line.size() > 0:
				candidates.append(line[0])
	else:
		for item in cond["list"]:
			var candidate: Variant = _eval_expression(db, item, row, table_name)
			if candidate is String and String(candidate).begins_with("\u0001"):
				return String(candidate).substr(1)
			candidates.append(candidate)

	var found: bool = false
	for candidate in candidates:
		if SqlDatabase.values_equal(value, candidate):
			found = true
			break
	return not found if bool(cond["negate"]) else found


static func _eval_like(db: SqlDatabase, cond: Dictionary, row: Dictionary, table_name: String) -> Variant:
	var value: Variant = _eval_expression(db, cond["expr"], row, table_name)
	if value is String and String(value).begins_with("\u0001"):
		return String(value).substr(1)
	var pattern: Variant = _eval_expression(db, cond["pattern"], row, table_name)
	if pattern is String and String(pattern).begins_with("\u0001"):
		return String(pattern).substr(1)
	if value == null or pattern == null:
		return false
	var matched: bool = _like_match(str(value), str(pattern))
	return not matched if bool(cond["negate"]) else matched


static func _like_match(text: String, pattern: String) -> bool:
	var regex_source: String = "^"
	for i in range(pattern.length()):
		var c: String = pattern[i]
		match c:
			"%":
				regex_source += ".*"
			"_":
				regex_source += "."
			".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|", "\\":
				regex_source += "\\" + c
			_:
				regex_source += c
	regex_source += "$"
	var regex: RegEx = RegEx.new()
	if regex.compile("(?i)" + regex_source) != OK:
		return false
	return regex.search(text) != null


static func _eval_between(db: SqlDatabase, cond: Dictionary, row: Dictionary, table_name: String) -> Variant:
	var value: Variant = _eval_expression(db, cond["expr"], row, table_name)
	if value is String and String(value).begins_with("\u0001"):
		return String(value).substr(1)
	var low: Variant = _eval_expression(db, cond["low"], row, table_name)
	if low is String and String(low).begins_with("\u0001"):
		return String(low).substr(1)
	var high: Variant = _eval_expression(db, cond["high"], row, table_name)
	if high is String and String(high).begins_with("\u0001"):
		return String(high).substr(1)
	if value == null or low == null or high == null:
		return false
	var inside: bool = _compare(value, low) >= 0 and _compare(value, high) <= 0
	return not inside if bool(cond["negate"]) else inside


## -1, 0 o 1. I numeri si confrontano numericamente, il resto come testo.
static func _compare(a: Variant, b: Variant) -> int:
	if a == null and b == null:
		return 0
	if a == null:
		return -1
	if b == null:
		return 1
	var a_numeric: bool = a is int or a is float
	var b_numeric: bool = b is int or b is float
	if a_numeric and b_numeric:
		var x: float = float(a)
		var y: float = float(b)
		if is_equal_approx(x, y):
			return 0
		return -1 if x < y else 1
	if a_numeric != b_numeric:
		# Numero contro testo: se il testo è un numero, confronto numerico
		var sa: String = str(a)
		var sb: String = str(b)
		if sa.is_valid_float() and sb.is_valid_float():
			var na: float = sa.to_float()
			var nb: float = sb.to_float()
			if is_equal_approx(na, nb):
				return 0
			return -1 if na < nb else 1
	var ta: String = str(a)
	var tb: String = str(b)
	if ta == tb:
		return 0
	return -1 if ta.naturalnocasecmp_to(tb) < 0 else 1
