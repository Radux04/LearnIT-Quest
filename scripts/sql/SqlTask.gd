class_name SqlTask
extends RefCounted

## Un obiettivo del Livello 2.
##
## La correzione non confronta il TESTO della query, ma il suo EFFETTO:
## la query del giocatore e la soluzione di riferimento vengono eseguite su
## due copie identiche del database e si confrontano i risultati. Così ogni
## formulazione corretta viene accettata (WHERE in ordine diverso, IN al posto
## di OR, apici, maiuscole, spazi...).

const KIND_SELECT := "select"
const KIND_MUTATE := "mutate"

var prompt: String = ""          # cosa deve ottenere il giocatore
var solution: String = ""        # una soluzione di riferimento
var kind: String = KIND_SELECT
var hint: String = ""            # suggerimento mostrato in basso
var explain: String = ""         # spiegazione mostrata quando riesce


static func make(task_prompt: String, task_solution: String, task_kind: String,
		task_hint: String = "", task_explain: String = "") -> SqlTask:
	var task: SqlTask = SqlTask.new()
	task.prompt = task_prompt
	task.solution = task_solution
	task.kind = task_kind
	task.hint = task_hint
	task.explain = task_explain
	return task


## Verifica la query del giocatore contro la soluzione di riferimento.
## Ritorna { "status": "ok"|"error"|"wrong", "message": String, "result": Dictionary }
static func check(db: SqlDatabase, player_sql: String, task: SqlTask) -> Dictionary:
	var sandbox: SqlDatabase = _clone(db)
	var player_result: Dictionary = SqlEngine.execute(sandbox, player_sql)
	if not bool(player_result["ok"]):
		return {"status": "error", "message": String(player_result["error"]), "result": player_result}

	var expected_db: SqlDatabase = _clone(db)
	var reference_result: Dictionary = SqlEngine.execute(expected_db, task.solution)
	if not bool(reference_result["ok"]):
		# Non deve mai capitare: significa che la soluzione del livello è sbagliata.
		return {"status": "error",
			"message": "Soluzione di riferimento non valida: %s" % reference_result["error"],
			"result": player_result}

	if task.kind == KIND_SELECT:
		if String(player_result["kind"]) != "select":
			return {"status": "wrong",
				"message": "Questo obiettivo chiede di LEGGERE dei dati: serve una SELECT.",
				"result": player_result}
		var ordered: bool = task.solution.to_upper().contains("ORDER BY")
		# Con una sola colonna non si controlla il nome: così un alias come
		# "SELECT COUNT(*) AS quanti" resta una risposta valida.
		if reference_result["columns"].size() != 1 \
				and not _same_columns(player_result["columns"], reference_result["columns"]):
			return {"status": "wrong",
				"message": "Le colonne non sono quelle richieste: attese %s, ottenute %s." % [
					_join(reference_result["columns"]), _join(player_result["columns"])],
				"result": player_result}
		if not _same_rows(player_result, reference_result, ordered):
			var detail: String = "Attese %d riga/e, ottenute %d." % [
				reference_result["rows"].size(), player_result["rows"].size()]
			if reference_result["rows"].size() == player_result["rows"].size():
				detail = "Il numero di righe è giusto ma i valori no: controlla la condizione."
			if ordered:
				detail += " L'ordine conta: serve ORDER BY."
			return {"status": "wrong", "message": "Il risultato non è quello richiesto. " + detail,
				"result": player_result}
		return {"status": "ok", "message": "", "result": player_result}

	# Obiettivo di modifica: conta lo stato finale del database.
	if String(player_result["kind"]) == "select":
		return {"status": "wrong",
			"message": "Questo obiettivo chiede di MODIFICARE il database: serve INSERT, UPDATE, DELETE, CREATE o DROP.",
			"result": player_result}
	if not sandbox.matches_snapshot(expected_db.snapshot()):
		return {"status": "wrong",
			"message": "Il database non è nello stato richiesto. Verifica tabella, valori e condizione WHERE.",
			"result": player_result}
	return {"status": "ok", "message": "", "result": player_result}


static func _clone(db: SqlDatabase) -> SqlDatabase:
	var copy: SqlDatabase = SqlDatabase.new()
	copy.restore(db.snapshot())
	return copy


static func _join(columns: Array) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for column in columns:
		parts.append(String(column))
	return ", ".join(parts)


## Stessi nomi di colonna, senza badare a maiuscole e ordine.
static func _same_columns(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	var left: Array[String] = []
	var right: Array[String] = []
	for column in a:
		left.append(String(column).to_lower())
	for column in b:
		right.append(String(column).to_lower())
	left.sort()
	right.sort()
	return left == right


static func _same_rows(player: Dictionary, expected: Dictionary, ordered: bool) -> bool:
	var player_rows: Array = _as_dictionaries(player)
	var reference_rows: Array = _as_dictionaries(expected)
	if player_rows.size() != reference_rows.size():
		return false
	# Con una sola colonna i nomi possono differire (alias): si confrontano
	# direttamente i valori, in ordine se la soluzione usa ORDER BY.
	if expected.get("columns", []).size() == 1:
		for i in range(player_rows.size()):
			var mine: Array = player["rows"][i]
			var theirs: Array = expected["rows"][i]
			if ordered:
				if not SqlDatabase.values_equal(mine[0], theirs[0]):
					return false
			elif not _multiset_contains(expected["rows"], mine[0]):
				return false
		return true
	if ordered:
		for i in range(player_rows.size()):
			if not SqlDatabase._same_row(player_rows[i], reference_rows[i]):
				return false
		return true
	return SqlDatabase.same_rows(player_rows, reference_rows)


static func _multiset_contains(rows: Array, value: Variant) -> bool:
	for row in rows:
		if SqlDatabase.values_equal(row[0], value):
			return true
	return false


## Converte righe posizionali in dizionari con chiave minuscola, così il
## confronto non dipende dall'ordine in cui sono state elencate le colonne.
static func _as_dictionaries(result: Dictionary) -> Array:
	var out: Array = []
	var columns: Array = result.get("columns", [])
	for row in result.get("rows", []):
		var entry: Dictionary = {}
		for i in range(columns.size()):
			entry[String(columns[i]).to_lower()] = row[i] if i < row.size() else null
		out.append(entry)
	return out
