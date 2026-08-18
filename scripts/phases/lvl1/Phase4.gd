extends Lvl1PhaseBase

## FASE 4 — Operazioni sul BST.
## Il giocatore applica inserimento, cancellazione, ricerca, minimo, massimo
## e successore in-order su un albero già costruito.

const CHALLENGE_COUNT := 5


func _start() -> void:
	level.set_phase_header("FASE 4 — OPERAZIONI SUL BST", Color(1.0, 0.68, 0.35))

	var plan: Array[String] = _build_plan()
	var done: int = 0
	while done < plan.size() and not _is_over():
		var kind: String = plan[done]
		if kind == "delete" and level.model.size() < 5:
			kind = "route"
		match kind:
			"insert":
				await _challenge_insert()
			"delete":
				await _challenge_delete()
			"min":
				await _challenge_extreme(true)
			"max":
				await _challenge_extreme(false)
			"successor":
				await _challenge_successor()
			_:
				await _challenge_route()
		done += 1
		if not _is_over():
			level.set_objective("Operazione completata %d/%d..." % [done, plan.size()])
			await _wait(0.45)
	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Operazioni completate: sai modificare e interrogare il BST.", COLOR_OK)
	await _wait(1.3)
	finished.emit()


## Mix garantito: ogni tipo di operazione compare almeno una volta,
## l'ordine è casuale e l'albero non viene mai svuotato.
func _build_plan() -> Array[String]:
	var plan: Array[String] = ["insert", "route", "delete", "min", "max", "successor", "route"]
	while plan.size() > CHALLENGE_COUNT:
		plan.remove_at(plan.size() - 1)
	plan.shuffle()
	return plan


func _challenge_insert() -> void:
	var value: float = _free_value()
	if is_nan(value):
		await _challenge_route()
		return
	level.set_objective("Inserisci %s nella posizione corretta dell'albero." % fmt(value))
	level.set_hint("Scendi dalla radice confrontando le metriche: minore → sinistra, maggiore → destra.")
	var values: Array[float] = [value]
	await place_routers(values, PENALTY_ATTACK)


func _challenge_delete() -> void:
	var target: float = _delete_target()
	if is_nan(target):
		await _challenge_route()
		return
	level.set_objective("Elimina il nodo %s cliccandoci sopra." % fmt(target))
	level.set_hint("Se ha due figli, dopo averlo selezionato sceglierai tu tra predecessore e successore in-order.")
	await delete_router(target)


func _challenge_extreme(want_min: bool) -> void:
	var target: float = level.model.minimum() if want_min else level.model.maximum()
	if is_nan(target):
		await _challenge_route()
		return
	if want_min:
		level.set_objective("Clicca il nodo con il valore PIÙ BASSO dell'albero.")
		level.set_hint("Il minimo di un BST si trova scendendo sempre a sinistra dalla radice.")
	else:
		level.set_objective("Clicca il nodo con il valore PIÙ ALTO dell'albero.")
		level.set_hint("Il massimo di un BST si trova scendendo sempre a destra dalla radice.")
	await pick_router(target, false, "Esatto: %s è l'estremo dell'albero." % fmt(target), PENALTY_ATTACK)


func _challenge_successor() -> void:
	var ordered: Array[float] = level.model.inorder()
	if ordered.size() < 2:
		await _challenge_route()
		return
	var index: int = randi() % (ordered.size() - 1)
	var reference: float = ordered[index]
	var target: float = ordered[index + 1]
	level.set_objective("Clicca il SUCCESSORE di %s (il valore subito più grande)." % fmt(reference))
	level.set_hint("Il successore in-order è il nodo che segue %s nella visita Inorder." % fmt(reference))
	await pick_router(target, false, "Corretto: dopo %s viene %s." % [fmt(reference), fmt(target)], PENALTY_ATTACK)


func _challenge_route() -> void:
	var candidates: Array[float] = level.model.values()
	if candidates.size() > 1:
		candidates.remove_at(0)
	var target: float = candidates[randi() % candidates.size()]
	level.set_objective("Esegui una RICERCA del valore %s." % fmt(target))
	level.set_hint("← e → per scegliere il ramo, ↓ se il valore non è nell'albero.")
	await route_packet(target)


## Preferisce un nodo con due figli: è il caso di cancellazione più istruttivo.
func _delete_target() -> float:
	var hard: Array[float] = level.model.nodes_with_two_children()
	hard.erase(level.model.root.value)      # la radice resta in piedi
	if not hard.is_empty():
		return hard[randi() % hard.size()]
	var candidates: Array[float] = level.model.values()
	if candidates.size() <= 1:
		return NAN
	candidates.remove_at(0)
	return candidates[randi() % candidates.size()]


## Una metrica decimale non ancora presente e che resta dentro lo schermo.
func _free_value() -> float:
	var existing: Array[float] = level.model.values()
	for attempt in range(80):
		var candidate: float = snappedf(randf_range(4.0, 96.0), 0.1)
		if is_equal_approx(candidate, roundf(candidate)):
			continue                     # niente interi: restiamo sulle metriche decimali
		if existing.has(candidate) or level.model.contains(candidate):
			continue
		var slot: Dictionary = level.model.insertion_slot(candidate)
		if slot.is_empty():
			continue
		if level.network.slot_center(float(slot["parent"]), String(slot["side"])).y > level.size.y - 210.0:
			continue
		return candidate
	return NAN
