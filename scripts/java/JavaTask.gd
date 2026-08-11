class_name JavaTask
extends RefCounted

## Un esercizio di scrittura o riscrittura di codice Java.
##
## La correzione è STRUTTURALE: non si esegue niente, si controlla com'è fatto
## il codice. Ogni controllo porta con sé il messaggio che spiega il perché,
## perché è quello che il giocatore deve imparare — non «sbagliato», ma
## «il campo saldo è pubblico: chiunque può scriverci un valore negativo».
##
## Ogni controllo è un Dictionary con una chiave "kind" e i suoi parametri:
##   {"kind": "field_private", "field": "saldo"}
##   {"kind": "max_method_lines", "max": 12}
## L'elenco completo è in _run_check().

var prompt: String = ""
var starting_code: String = ""     # codice da cui parte il giocatore
var checks: Array = []
var hint: String = ""
var explain: String = ""


static func make(task_prompt: String, code: String, task_checks: Array,
		task_hint: String = "", task_explain: String = "") -> JavaTask:
	var task: JavaTask = JavaTask.new()
	task.prompt = task_prompt
	task.starting_code = code
	task.checks = task_checks
	task.hint = task_hint
	task.explain = task_explain
	return task


## Ritorna { "status": "ok"|"error"|"wrong", "message": String }
static func check(task: JavaTask, source: String) -> Dictionary:
	if source.strip_edges().is_empty():
		return {"status": "error", "message": "Non hai scritto niente."}

	var code: JavaCode = JavaCode.parse(source)

	# Errori che rendono inutile ogni altra analisi.
	if not code.braces_balanced():
		return {"status": "error",
			"message": "Le parentesi graffe non tornano: ne manca o ne avanza una. Controlla l'indentazione, aiuta a vederlo."}
	if not code.has_type():
		return {"status": "error",
			"message": "Non trovo nessuna dichiarazione di classe o interfaccia."}

	for rule in task.checks:
		var verdict: Dictionary = _run_check(code, rule)
		if not bool(verdict["passed"]):
			return {"status": "wrong", "message": String(verdict["message"])}

	return {"status": "ok", "message": ""}


static func _run_check(code: JavaCode, rule: Dictionary) -> Dictionary:
	var kind: String = String(rule.get("kind", ""))
	var custom: String = String(rule.get("message", ""))

	match kind:
		"class_named":
			var wanted: String = String(rule["name"])
			if code.type_name == wanted:
				return _ok()
			return _fail(custom, "La classe deve chiamarsi %s, invece si chiama %s." % [
				wanted, code.type_name if code.type_name != "" else "(senza nome)"])

		"kind_is":
			var wanted_kind: String = String(rule["value"])
			if code.type_kind == wanted_kind:
				return _ok()
			return _fail(custom, "Serve un %s, non un %s." % [wanted_kind, code.type_kind])

		"implements":
			var wanted_interface: String = String(rule["name"])
			if code.implements_names.has(wanted_interface):
				return _ok()
			return _fail(custom, "La classe deve implementare %s." % wanted_interface)

		"extends":
			if code.extends_name == String(rule["name"]):
				return _ok()
			return _fail(custom, "La classe deve estendere %s." % String(rule["name"]))

		"has_field":
			var field_name: String = String(rule["field"])
			if not code.find_field(field_name).is_empty():
				return _ok()
			return _fail(custom, "Manca il campo %s." % field_name)

		"field_private":
			var private_name: String = String(rule["field"])
			var field: Dictionary = code.find_field(private_name)
			if field.is_empty():
				return _fail(custom, "Manca il campo %s." % private_name)
			if field["modifiers"].has("private"):
				return _ok()
			return _fail(custom,
				"Il campo %s non è private: chiunque potrebbe modificarlo dall'esterno senza passare dai controlli della classe." % private_name)

		"no_public_fields":
			var exposed: Array = code.public_fields()
			if exposed.is_empty():
				return _ok()
			return _fail(custom,
				"Il campo %s è accessibile dall'esterno. Incapsulamento: i dati sono private, si espongono i metodi." % String(exposed[0]["name"]))

		"has_method":
			var method_name: String = String(rule["method"])
			if code.declares_method(method_name):
				return _ok()
			return _fail(custom, "Manca il metodo %s()." % method_name)

		"lacks_method":
			var forbidden: String = String(rule["method"])
			if not code.declares_method(forbidden):
				return _ok()
			return _fail(custom, "Il metodo %s() non dovrebbe stare in questa classe." % forbidden)

		"method_count_at_least":
			var minimum: int = int(rule["count"])
			if code.methods.size() >= minimum:
				return _ok()
			return _fail(custom, "Servono almeno %d metodi, ne hai scritti %d." % [
				minimum, code.methods.size()])

		"method_count_at_most":
			var maximum: int = int(rule["count"])
			if code.methods.size() <= maximum:
				return _ok()
			return _fail(custom,
				"Questa classe ha %d metodi: sta facendo troppe cose. Una classe, una responsabilità." % code.methods.size())

		"max_method_lines":
			var limit: int = int(rule["max"])
			var too_long: Array = code.long_methods(limit)
			if too_long.is_empty():
				return _ok()
			return _fail(custom,
				"Il metodo %s() è lungo %d righe (il limite è %d). Un metodo deve stare sotto gli occhi tutto insieme: spezzalo." % [
					String(too_long[0]["name"]), int(too_long[0]["length"]), limit])

		"no_magic_numbers":
			var magic: Array = code.magic_numbers()
			if magic.is_empty():
				return _ok()
			return _fail(custom,
				"Il numero %s dentro %s() non dice niente a chi legge. Dagli un nome: una costante static final spiega che cos'è." % [
					String(magic[0]["value"]), String(magic[0]["method"])])

		"meaningful_names":
			var minimum_length: int = int(rule.get("min_length", 3))
			var poor: Array = code.poor_names(minimum_length)
			if poor.is_empty():
				return _ok()
			return _fail(custom,
				"Il %s «%s» ha un nome che non spiega nulla. Il nome è la prima documentazione del codice." % [
					String(poor[0]["kind"]), String(poor[0]["name"])])

		"no_duplicated_lines":
			var duplicates: Array = code.duplicated_lines()
			if duplicates.is_empty():
				return _ok()
			return _fail(custom,
				"La riga «%s» compare due volte. Codice duplicato significa correzioni da fare due volte: estraila." % String(duplicates[0]["text"]))

		"contains":
			if code.contains(String(rule["text"])):
				return _ok()
			return _fail(custom, "Nel codice manca: %s" % String(rule["text"]))

		"lacks":
			if not code.contains(String(rule["text"])):
				return _ok()
			return _fail(custom, "Nel codice non ci deve essere: %s" % String(rule["text"]))

		"has_annotation":
			var annotation: String = String(rule["name"])
			if code.has_annotation(annotation):
				return _ok()
			return _fail(custom, "Manca l'annotazione @%s." % annotation)

		"field_annotated":
			var target: String = String(rule["field"])
			var wanted_annotation: String = String(rule["name"])
			var annotated_field: Dictionary = code.find_field(target)
			if annotated_field.is_empty():
				return _fail(custom, "Manca il campo %s." % target)
			if annotated_field.get("annotations", []).has(wanted_annotation):
				return _ok()
			return _fail(custom, "Il campo %s deve essere annotato con @%s." % [target, wanted_annotation])

		"max_code_lines":
			var line_limit: int = int(rule["max"])
			if code.code_line_count() <= line_limit:
				return _ok()
			return _fail(custom, "Il codice è più lungo di %d righe utili: semplificalo." % line_limit)

	return _ok()


static func _ok() -> Dictionary:
	return {"passed": true, "message": ""}


static func _fail(custom: String, standard: String) -> Dictionary:
	return {"passed": false, "message": custom if custom != "" else standard}
