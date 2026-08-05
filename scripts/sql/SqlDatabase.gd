class_name SqlDatabase
extends RefCounted

## Database in memoria: un insieme di tabelle con colonne tipizzate e righe.
## I nomi di tabelle e colonne sono trattati senza distinzione fra
## maiuscole e minuscole, come fa MySQL con le colonne.

## nome_minuscolo -> { "name": String, "columns": Array[{name,type}], "rows": Array[Dictionary] }
var tables: Dictionary = {}


func clear() -> void:
	tables.clear()


func table_names() -> Array[String]:
	var names: Array[String] = []
	for key in tables.keys():
		names.append(String(tables[key]["name"]))
	names.sort()
	return names


func has_table(name: String) -> bool:
	return tables.has(name.to_lower())


func get_table(name: String) -> Dictionary:
	return tables.get(name.to_lower(), {})


func create_table(name: String, columns: Array) -> void:
	tables[name.to_lower()] = {"name": name, "columns": columns.duplicate(true), "rows": []}


func drop_table(name: String) -> void:
	tables.erase(name.to_lower())


func column_names(table_name: String) -> Array[String]:
	var names: Array[String] = []
	var table: Dictionary = get_table(table_name)
	if table.is_empty():
		return names
	for column in table["columns"]:
		names.append(String(column["name"]))
	return names


## Il nome reale della colonna (con le maiuscole originali) oppure "".
func resolve_column(table_name: String, column: String) -> String:
	for name in column_names(table_name):
		if name.to_lower() == column.to_lower():
			return name
	return ""


func insert_row(table_name: String, row: Dictionary) -> void:
	var table: Dictionary = get_table(table_name)
	if not table.is_empty():
		table["rows"].append(row)


func row_count(table_name: String) -> int:
	var table: Dictionary = get_table(table_name)
	return 0 if table.is_empty() else int(table["rows"].size())


# ------------------------------------------------------- popolamento ------

## Aggiunge una tabella completa in un colpo solo.
## columns: [["id", "INT"], ["nome", "VARCHAR"]]
## rows:    [[1, "Mario"], [2, "Anna"]]
func define(name: String, columns: Array, rows: Array) -> void:
	var column_defs: Array = []
	for column in columns:
		column_defs.append({"name": String(column[0]), "type": String(column[1]).to_upper()})
	create_table(name, column_defs)
	for row_values in rows:
		var row: Dictionary = {}
		for i in range(column_defs.size()):
			row[String(column_defs[i]["name"])] = row_values[i] if i < row_values.size() else null
		insert_row(name, row)


# -------------------------------------------------------- confronto -------

func snapshot() -> Dictionary:
	return tables.duplicate(true)


func restore(snap: Dictionary) -> void:
	tables = snap.duplicate(true)


## Confronto profondo fra lo stato attuale e uno snapshot, ignorando
## l'ordine delle righe (in SQL una tabella è un insieme).
func matches_snapshot(snap: Dictionary) -> bool:
	if tables.size() != snap.size():
		return false
	for key in snap.keys():
		if not tables.has(key):
			return false
		var expected: Dictionary = snap[key]
		var actual: Dictionary = tables[key]
		if not _same_columns(expected["columns"], actual["columns"]):
			return false
		if not same_rows(expected["rows"], actual["rows"]):
			return false
	return true


static func _same_columns(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if String(a[i]["name"]).to_lower() != String(b[i]["name"]).to_lower():
			return false
	return true


## Due insiemi di righe sono uguali se contengono le stesse righe,
## indipendentemente dall'ordine.
static func same_rows(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	var remaining: Array = b.duplicate(true)
	for row in a:
		var found: int = -1
		for i in range(remaining.size()):
			if _same_row(row, remaining[i]):
				found = i
				break
		if found == -1:
			return false
		remaining.remove_at(found)
	return true


static func _same_row(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key in a.keys():
		var other_key: String = ""
		for candidate in b.keys():
			if String(candidate).to_lower() == String(key).to_lower():
				other_key = String(candidate)
				break
		if other_key == "":
			return false
		if not values_equal(a[key], b[other_key]):
			return false
	return true


static func values_equal(a: Variant, b: Variant) -> bool:
	if a == null or b == null:
		return a == null and b == null
	if (a is int or a is float) and (b is int or b is float):
		return is_equal_approx(float(a), float(b))
	return String(a) == String(b)


## Rappresentazione leggibile di un valore per la UI.
static func format_value(value: Variant) -> String:
	if value == null:
		return "NULL"
	if value is float:
		if is_equal_approx(value, roundf(value)):
			return "%d" % int(roundf(value))
		return String.num(value, 2)
	return str(value)
