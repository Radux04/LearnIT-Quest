class_name Lvl4Catalogo
extends RefCounted

## Accesso agli esercizi del Livello 4.
##
## Gli esercizi NON stanno qui: stanno in res://data/esercizi_livello_4.json,
## così si possono aggiungere senza toccare il codice. Questo file li carica,
## li normalizza e li sorteggia.
##
## Nel JSON il codice Java è scritto come ARRAY DI RIGHE invece che come una
## stringa unica: si legge meglio, e negli esercizi a clic gli indici di "bad"
## coincidono con le posizioni nell'array. Qui le righe vengono riunite.

const DATA_PATH := "res://data/esercizi_livello_4.json"

static var _data: Dictionary = {}
static var _loaded: bool = false


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true

	var raw: Variant = null

	# In un gioco esportato il file potrebbe non esistere sul filesystem ma
	# essere disponibile come risorsa: si provano tutte e due le strade.
	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file != null:
		raw = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		var resource: Resource = load(DATA_PATH)
		if resource is JSON:
			raw = (resource as JSON).data

	if raw == null or not (raw is Dictionary):
		push_error("Livello 4: non riesco a leggere %s. Se il gioco e' esportato, aggiungi *.json ai filtri di esportazione dei file non-risorsa." % DATA_PATH)
		return

	var parsed: Dictionary = raw
	for key in ["review", "split", "refactor", "write"]:
		var entries: Array = []
		for entry in parsed.get(key, []):
			entries.append(_normalise(entry))
		_data[key] = entries


## Riunisce gli array di righe in stringhe: il resto passa invariato.
static func _normalise(entry: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in entry.keys():
		var name: String = String(key)
		var value: Variant = entry[key]
		if (name == "code" or name == "solution") and value is Array:
			var lines: PackedStringArray = PackedStringArray()
			for line in value:
				lines.append(String(line))
			out[name] = "\n".join(lines)

		elif name == "bad" and value is Array:
			# JSON non distingue interi e decimali: 1 torna come 1.0, e in
			# GDScript `[1.0].has(1)` è FALSO. Senza questa conversione il
			# confronto fra le righe scelte dal giocatore e quelle attese
			# fallirebbe sempre, anche con la risposta giusta.
			var indices: Array[int] = []
			for index in value:
				indices.append(int(index))
			out[name] = indices

		elif name == "methods" and value is Array:
			# [ "firma del metodo", indice della classe di destinazione ]
			var methods: Array = []
			for method in value:
				methods.append([String(method[0]), int(method[1])])
			out[name] = methods

		else:
			out[name] = value
	return out


static func _pool(key: String) -> Array:
	_ensure_loaded()
	return _data.get(key, [])


## Esercizi a clic sulle righe (Fasi 1 e 2).
static func review_pool() -> Array:
	return _pool("review")


## Separazione delle responsabilita' (Fase 2).
static func split_pool() -> Array:
	return _pool("split")


## Codice da riscrivere (Fase 3).
static func refactor_pool() -> Array:
	return _pool("refactor")


## Codice da scrivere (Fase 4).
static func write_pool() -> Array:
	return _pool("write")


# ================================================================ sorteggio ==

## Ricorda che cosa è uscito l'ultima volta, per ogni gruppo di esercizi.
## Vive quanto il processo: riavviando il livello dal menu o dalla schermata
## finale gli esercizi cambiano di sicuro.
static var _last_drawn: Dictionary = {}


static func pick(pool: Array, count: int) -> Array:
	var bag: Array = pool.duplicate()
	bag.shuffle()
	return bag.slice(0, mini(count, bag.size()))


## Pesca `count` voci evitando quelle uscite l'ultima volta con la stessa
## chiave. Se le voci rimaste non bastano riparte da tutte, così il gioco
## resta giocabile anche con cataloghi piccoli.
static func pick_fresh(entries: Array, count: int, memory_key: String) -> Array:
	var recent: Array = _last_drawn.get(memory_key, [])

	var fresh: Array = []
	for entry in entries:
		if not recent.has(identity(entry)):
			fresh.append(entry)
	if fresh.size() < count:
		fresh = entries.duplicate()

	fresh.shuffle()
	var chosen: Array = fresh.slice(0, mini(count, fresh.size()))

	var drawn: Array = []
	for entry in chosen:
		drawn.append(identity(entry))
	_last_drawn[memory_key] = drawn
	return chosen


## Voci di un solo argomento, nell'ordine del catalogo.
static func filter_topic(pool: Array, topic: String) -> Array:
	var out: Array = []
	for entry in pool:
		if String(entry.get("topic", "")) == topic:
			out.append(entry)
	return out


## Come si riconosce un esercizio: la richiesta è già unica.
static func identity(entry: Dictionary) -> String:
	return String(entry.get("prompt", entry.get("name", "")))


static func pick_one(pool: Array) -> Dictionary:
	return pool[randi() % pool.size()]


## Voci filtrate per argomento, poi mescolate.
static func pick_topic(pool: Array, topic: String, count: int) -> Array:
	var filtered: Array = []
	for entry in pool:
		if String(entry.get("topic", "")) == topic:
			filtered.append(entry)
	return pick(filtered, count)


static func build_task(entry: Dictionary) -> JavaTask:
	return JavaTask.make(
		String(entry["prompt"]), String(entry.get("code", "")), entry["checks"],
		String(entry.get("hint", "")), String(entry.get("explain", "")))
