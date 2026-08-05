extends Node

## Batteria di test del motore SQL. Non fa parte del gioco.
## Eseguibile con lo strumento run_tests oppure aprendo la scena.

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	run_all()


func run_all() -> void:
	_passed = 0
	_failed = 0
	test_select_base()
	test_where_and_or()
	test_like_between_in()
	test_aggregates()
	test_order_limit()
	test_subquery_scalar()
	test_subquery_in()
	test_insert()
	test_update()
	test_delete()
	test_create_drop()
	test_errors()
	print("\n[SQL-TEST] %d passati, %d falliti" % [_passed, _failed])


# ------------------------------------------------------------- helpers -----

func _db() -> SqlDatabase:
	var db: SqlDatabase = SqlDatabase.new()
	db.define("utenti",
		[["id", "INT"], ["nome", "VARCHAR"], ["citta", "VARCHAR"], ["eta", "INT"]],
		[
			[1, "Mario", "Roma", 34],
			[2, "Anna", "Milano", 28],
			[3, "Luca", "Roma", 45],
			[4, "Sara", "Napoli", 22],
			[5, "Elena", "Milano", 39],
		])
	db.define("ordini",
		[["id", "INT"], ["utente_id", "INT"], ["totale", "INT"]],
		[
			[1, 1, 120],
			[2, 1, 40],
			[3, 3, 300],
			[4, 5, 90],
		])
	return db


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		_passed += 1
		print("  OK   %s" % label)
	else:
		_failed += 1
		print("  FAIL %s   %s" % [label, detail])


## Esegue una query e verifica la colonna richiesta contro i valori attesi.
func _expect_column(label: String, sql: String, column: String, expected: Array) -> void:
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db, sql)
	if not bool(result["ok"]):
		_check(label, false, "errore: %s" % result["error"])
		return
	var index: int = -1
	var columns: Array = result["columns"]
	for i in range(columns.size()):
		if String(columns[i]).to_lower() == column.to_lower():
			index = i
	if index == -1:
		_check(label, false, "colonna %s assente in %s" % [column, str(columns)])
		return
	var got: Array = []
	for row in result["rows"]:
		got.append(row[index])
	_check(label, str(got) == str(expected), "atteso %s, ottenuto %s" % [str(expected), str(got)])


# ---------------------------------------------------------------- test -----

func test_select_base() -> void:
	print("\n[SELECT base]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db, "SELECT * FROM utenti")
	_check("SELECT * righe", bool(result["ok"]) and result["rows"].size() == 5)
	_check("SELECT * colonne", result["columns"].size() == 4, str(result["columns"]))
	_expect_column("SELECT nome", "SELECT nome FROM utenti", "nome",
		["Mario", "Anna", "Luca", "Sara", "Elena"])
	_expect_column("case insensitive", "select NOME from UTENTI where ETA = 22", "nome", ["Sara"])
	_expect_column("punto e virgola finale", "SELECT nome FROM utenti WHERE eta = 22;", "nome", ["Sara"])


func test_where_and_or() -> void:
	print("\n[WHERE]")
	_expect_column("maggiore", "SELECT nome FROM utenti WHERE eta > 30", "nome",
		["Mario", "Luca", "Elena"])
	_expect_column("AND", "SELECT nome FROM utenti WHERE eta > 30 AND citta = 'Roma'", "nome",
		["Mario", "Luca"])
	_expect_column("OR", "SELECT nome FROM utenti WHERE citta = 'Napoli' OR eta = 28", "nome",
		["Anna", "Sara"])
	_expect_column("NOT", "SELECT nome FROM utenti WHERE NOT citta = 'Roma'", "nome",
		["Anna", "Sara", "Elena"])
	_expect_column("diverso", "SELECT nome FROM utenti WHERE citta != 'Roma'", "nome",
		["Anna", "Sara", "Elena"])
	_expect_column("parentesi", "SELECT nome FROM utenti WHERE (citta = 'Roma' OR citta = 'Milano') AND eta < 35", "nome",
		["Mario", "Anna"])


func test_like_between_in() -> void:
	print("\n[LIKE / BETWEEN / IN]")
	_expect_column("LIKE prefisso", "SELECT nome FROM utenti WHERE nome LIKE 'M%'", "nome", ["Mario"])
	_expect_column("LIKE contiene", "SELECT nome FROM utenti WHERE nome LIKE '%na%'", "nome", ["Anna", "Elena"])
	_expect_column("BETWEEN", "SELECT nome FROM utenti WHERE eta BETWEEN 28 AND 39", "nome",
		["Mario", "Anna", "Elena"])
	_expect_column("IN lista", "SELECT nome FROM utenti WHERE citta IN ('Roma', 'Napoli')", "nome",
		["Mario", "Luca", "Sara"])
	_expect_column("NOT IN", "SELECT nome FROM utenti WHERE citta NOT IN ('Roma', 'Napoli')", "nome",
		["Anna", "Elena"])


func test_aggregates() -> void:
	print("\n[Aggregati]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db, "SELECT COUNT(*) FROM utenti")
	_check("COUNT(*)", bool(result["ok"]) and int(result["rows"][0][0]) == 5,
		str(result.get("rows", [])) + str(result.get("error", "")))
	result = SqlEngine.execute(db, "SELECT MAX(eta) FROM utenti")
	_check("MAX", bool(result["ok"]) and int(result["rows"][0][0]) == 45, str(result))
	result = SqlEngine.execute(db, "SELECT MIN(eta) FROM utenti")
	_check("MIN", bool(result["ok"]) and int(result["rows"][0][0]) == 22, str(result))
	result = SqlEngine.execute(db, "SELECT SUM(totale) FROM ordini")
	_check("SUM", bool(result["ok"]) and int(result["rows"][0][0]) == 550, str(result))
	result = SqlEngine.execute(db, "SELECT COUNT(*) FROM utenti WHERE citta = 'Milano'")
	_check("COUNT con WHERE", bool(result["ok"]) and int(result["rows"][0][0]) == 2, str(result))


func test_order_limit() -> void:
	print("\n[ORDER BY / LIMIT]")
	_expect_column("ORDER BY ASC", "SELECT nome FROM utenti ORDER BY eta", "nome",
		["Sara", "Anna", "Mario", "Elena", "Luca"])
	_expect_column("ORDER BY DESC", "SELECT nome FROM utenti ORDER BY eta DESC", "nome",
		["Luca", "Elena", "Mario", "Anna", "Sara"])
	_expect_column("LIMIT", "SELECT nome FROM utenti ORDER BY eta DESC LIMIT 2", "nome",
		["Luca", "Elena"])


func test_subquery_scalar() -> void:
	print("\n[Subquery scalare]")
	# media = (34+28+45+22+39)/5 = 33.6
	_expect_column("> AVG", "SELECT nome FROM utenti WHERE eta > (SELECT AVG(eta) FROM utenti)", "nome",
		["Mario", "Luca", "Elena"])
	_expect_column("= MAX", "SELECT nome FROM utenti WHERE eta = (SELECT MAX(eta) FROM utenti)", "nome",
		["Luca"])


func test_subquery_in() -> void:
	print("\n[Subquery IN]")
	_expect_column("IN subquery", "SELECT nome FROM utenti WHERE id IN (SELECT utente_id FROM ordini)", "nome",
		["Mario", "Luca", "Elena"])
	_expect_column("NOT IN subquery", "SELECT nome FROM utenti WHERE id NOT IN (SELECT utente_id FROM ordini)", "nome",
		["Anna", "Sara"])
	_expect_column("IN subquery con WHERE",
		"SELECT nome FROM utenti WHERE id IN (SELECT utente_id FROM ordini WHERE totale > 100)", "nome",
		["Mario", "Luca"])


func test_insert() -> void:
	print("\n[INSERT]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db,
		"INSERT INTO utenti (id, nome, citta, eta) VALUES (6, 'Ivo', 'Torino', 51)")
	_check("INSERT ok", bool(result["ok"]), String(result.get("error", "")))
	_check("INSERT righe", db.row_count("utenti") == 6)
	var check: Dictionary = SqlEngine.execute(db, "SELECT nome FROM utenti WHERE id = 6")
	_check("INSERT valore", bool(check["ok"]) and String(check["rows"][0][0]) == "Ivo", str(check))

	result = SqlEngine.execute(db, "INSERT INTO utenti VALUES (7, 'Nina', 'Bari', 30)")
	_check("INSERT senza lista colonne", bool(result["ok"]), String(result.get("error", "")))
	_check("INSERT righe 7", db.row_count("utenti") == 7)


func test_update() -> void:
	print("\n[UPDATE]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db, "UPDATE utenti SET citta = 'Bologna' WHERE id = 2")
	_check("UPDATE ok", bool(result["ok"]), String(result.get("error", "")))
	_check("UPDATE affected", int(result["affected"]) == 1, str(result))
	var check: Dictionary = SqlEngine.execute(db, "SELECT citta FROM utenti WHERE id = 2")
	_check("UPDATE valore", String(check["rows"][0][0]) == "Bologna", str(check))

	result = SqlEngine.execute(db, "UPDATE utenti SET eta = eta + 1 WHERE citta = 'Roma'")
	_check("UPDATE espressione", bool(result["ok"]) and int(result["affected"]) == 2, str(result))
	check = SqlEngine.execute(db, "SELECT eta FROM utenti WHERE id = 1")
	_check("UPDATE aritmetica", int(check["rows"][0][0]) == 35, str(check))


func test_delete() -> void:
	print("\n[DELETE]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db, "DELETE FROM utenti WHERE citta = 'Roma'")
	_check("DELETE ok", bool(result["ok"]) and int(result["affected"]) == 2, str(result))
	_check("DELETE righe", db.row_count("utenti") == 3)
	result = SqlEngine.execute(db, "DELETE FROM ordini")
	_check("DELETE tutto", bool(result["ok"]) and db.row_count("ordini") == 0, str(result))


func test_create_drop() -> void:
	print("\n[CREATE / DROP]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db,
		"CREATE TABLE prodotti (id INT, nome VARCHAR(50), prezzo INT)")
	_check("CREATE ok", bool(result["ok"]), String(result.get("error", "")))
	_check("CREATE tabella", db.has_table("prodotti"))
	_check("CREATE colonne", db.column_names("prodotti").size() == 3, str(db.column_names("prodotti")))
	result = SqlEngine.execute(db, "INSERT INTO prodotti VALUES (1, 'Mouse', 20)")
	_check("INSERT nella nuova tabella", bool(result["ok"]) and db.row_count("prodotti") == 1,
		String(result.get("error", "")))
	result = SqlEngine.execute(db, "DROP TABLE prodotti")
	_check("DROP ok", bool(result["ok"]) and not db.has_table("prodotti"), String(result.get("error", "")))


func test_errors() -> void:
	print("\n[Errori]")
	var db: SqlDatabase = _db()
	var result: Dictionary = SqlEngine.execute(db, "SELECT * FROM clienti")
	_check("tabella inesistente", not bool(result["ok"]) and String(result["error"]) != "",
		String(result.get("error", "")))
	result = SqlEngine.execute(db, "SELECT cognome FROM utenti")
	_check("colonna inesistente", not bool(result["ok"]), String(result.get("error", "")))
	result = SqlEngine.execute(db, "SELECT FROM utenti")
	_check("sintassi", not bool(result["ok"]), String(result.get("error", "")))
	result = SqlEngine.execute(db, "")
	_check("query vuota", not bool(result["ok"]), String(result.get("error", "")))
	result = SqlEngine.execute(db, "UPDATE utenti SET eta = 1 WHERE")
	_check("WHERE incompleto", not bool(result["ok"]), String(result.get("error", "")))
