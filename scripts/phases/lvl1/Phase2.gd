extends Lvl1PhaseBase

## FASE 2 — Ricerca nel BST.
## Il giocatore cerca valori presenti e assenti. Per quelli assenti deve
## riconoscere lo slot vuoto: anche una ricerca negativa costa O(altezza).

const PRESENT_PACKETS := 4
const ABSENT_PACKETS := 2

## Valori scelti apposta per cadere "in mezzo" ai router esistenti.
const ABSENT_CANDIDATES: Array[float] = [25.7, 50.4, 13.5, 70.9, 62.3, 99.1, 5.2]


func _start() -> void:
	level.set_phase_header("FASE 2 — RICERCA NEL BST", Color(0.35, 1.0, 0.7))

	var targets: Array[float] = _build_queue()
	for i in range(targets.size()):
		if _is_over():
			return
		var target: float = targets[i]
		var known: String = "" if level.model.contains(target) else "  (potrebbe non essere nell'albero!)"
		level.set_objective("Ricerca %d/%d — trova %s%s" % [
			i + 1, targets.size(), fmt(target), known])
		await route_packet(target)
		if not _is_over():
			await _wait(0.3)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Ricerche completate: sai riconoscere esiti positivi e negativi.", COLOR_OK)
	await _wait(1.3)
	finished.emit()


func _build_queue() -> Array[float]:
	var present: Array[float] = level.model.values()
	if not present.is_empty():
		present.remove_at(0)            # la radice sarebbe banale
	present.shuffle()

	var queue: Array[float] = []
	for value in present:
		if queue.size() >= PRESENT_PACKETS:
			break
		queue.append(value)

	var absent: Array[float] = []
	for value in ABSENT_CANDIDATES:
		if not level.model.contains(value):
			absent.append(value)
	absent.shuffle()
	for i in range(mini(ABSENT_PACKETS, absent.size())):
		queue.append(absent[i])

	queue.shuffle()
	# La prima ricerca è sempre presente: introduce la meccanica con calma.
	for i in range(queue.size()):
		if level.model.contains(queue[i]):
			var first: float = queue[i]
			queue.remove_at(i)
			queue.push_front(first)
			break
	return queue
