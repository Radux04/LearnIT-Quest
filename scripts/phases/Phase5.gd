extends PhaseBase

## FASE 5 — Instradamento ottimale (algoritmo di Dijkstra).
##
## Finora la rete era un albero: fra due router esisteva un solo percorso.
## L'hacker, ritirandosi, ha riattivato i vecchi cavi ridondanti: ora ci sono
## più strade possibili e ogni cavo ha una latenza. Il percorso migliore non
## è quello con meno salti, ma quello con il costo totale più basso.
##
## È esattamente ciò che fanno i router reali con OSPF, che usa Dijkstra
## per calcolare la Shortest Path First.

const EXTRA_LINKS := 4
const MIN_WEIGHT := 1
const MAX_WEIGHT := 9


func _start() -> void:
	level.set_phase_header("FASE 5 — INSTRADAMENTO OTTIMALE", Color(0.7, 0.65, 1.0))
	level.set_alert_mode(false)

	var graph: NetworkGraph = NetworkGraph.from_tree(level.model, MIN_WEIGHT, MAX_WEIGHT)
	_add_redundant_links(graph)

	var source: float = level.model.root.value
	var target: float = _choose_destination(graph, source)
	if is_nan(target):
		finished.emit()
		return

	var optimal: Array[float] = graph.shortest_path(source, target)
	var cost: int = NetworkGraph.path_cost(graph, optimal)

	level.network.set_graph(graph)
	await level.show_banner("CAVI RIDONDANTI ATTIVI",
		"Ogni cavo ora ha una latenza in ms: serve il percorso a costo minimo, non quello con meno salti.",
		Color(0.7, 0.65, 1.0))
	if _is_over():
		return

	level.set_objective("OSPF: trova il percorso a latenza minima da %s a %s." % [
		fmt(source), fmt(target)])
	level.set_hint("Dijkstra: fissa ogni volta il router non ancora fissato con il costo provvisorio più basso. Parti dalla sorgente (costo 0).")

	await shortest_path_game(graph, source, target)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Tabella di routing ricalcolata: %s raggiungibile in %d ms." % [fmt(target), cost], COLOR_OK)
	await _wait(1.4)
	finished.emit()


## Riattiva alcuni cavi fra router vicini sullo schermo ma non collegati
## nell'albero: sono questi a creare percorsi alternativi.
func _add_redundant_links(graph: NetworkGraph) -> void:
	var values: Array[float] = level.model.values()
	var candidates: Array = []
	for i in range(values.size()):
		for j in range(i + 1, values.size()):
			var a: float = values[i]
			var b: float = values[j]
			if graph.has_edge(a, b):
				continue
			var distance: float = level.network.center_of(a).distance_to(level.network.center_of(b))
			candidates.append({"a": a, "b": b, "d": distance})

	candidates.sort_custom(func(x, y): return float(x["d"]) < float(y["d"]))

	var added: int = 0
	for candidate in candidates:
		if added >= EXTRA_LINKS:
			break
		# Salta i cavi troppo lunghi: attraverserebbero mezzo schermo.
		if float(candidate["d"]) > 420.0:
			continue
		graph.add_edge(float(candidate["a"]), float(candidate["b"]),
			randi_range(MIN_WEIGHT, MAX_WEIGHT), true)
		added += 1


## Una destinazione lontana dalla sorgente, così l'algoritmo deve davvero
## fissare più router prima di arrivarci.
func _choose_destination(graph: NetworkGraph, source: float) -> float:
	var result: Dictionary = graph.dijkstra(source)
	var distances: Dictionary = result["dist"]
	var best: float = NAN
	var best_hops: int = -1
	for value in graph.nodes():
		if is_equal_approx(value, source):
			continue
		var path: Array[float] = NetworkGraph.path_from(result["prev"], source, value)
		if path.size() > best_hops and float(distances[value]) < NetworkGraph.INF:
			best_hops = path.size()
			best = value
	return best
