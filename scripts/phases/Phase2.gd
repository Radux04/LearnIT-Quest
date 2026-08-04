extends PhaseBase

## FASE 2 — Instradamento dei pacchetti.
## 7 pacchetti: 5 verso router realmente presenti (ricerca con successo) e
## 2 verso metriche che NON esistono in rete. In quel caso il giocatore deve
## riconoscere il vicolo cieco e dichiarare "NON IN RETE": è la ricerca
## con esito negativo, che costa comunque solo O(altezza) confronti.

const PRESENT_PACKETS := 5
const ABSENT_PACKETS := 2

## Valori scelti apposta per cadere "in mezzo" ai router esistenti.
const ABSENT_CANDIDATES: Array[float] = [25.7, 50.4, 13.5, 70.9, 62.3, 99.1, 5.2]


func _start() -> void:
	level.set_phase_header("FASE 2 — INSTRADAMENTO DEI PACCHETTI", Color(0.35, 1.0, 0.7))

	var targets: Array[float] = _build_queue()
	for i in range(targets.size()):
		if _is_over():
			return
		var target: float = targets[i]
		var known: String = "" if level.model.contains(target) else "  (potrebbe non esistere!)"
		level.set_objective("Pacchetto %d/%d — destinazione %s%s" % [
			i + 1, targets.size(), fmt(target), known])
		await route_packet(target)
		if not _is_over():
			await _wait(0.3)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Traffico ripristinato! Hai eseguito ricerche con esito positivo e negativo.", COLOR_OK)
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
	# Il primo pacchetto è sempre "presente": introduce la meccanica con calma.
	for i in range(queue.size()):
		if level.model.contains(queue[i]):
			var first: float = queue[i]
			queue.remove_at(i)
			queue.push_front(first)
			break
	return queue
