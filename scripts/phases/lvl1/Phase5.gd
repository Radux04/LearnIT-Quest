extends Lvl1PhaseBase

## FASE 5 — Cammino minimo (algoritmo di Dijkstra).
## L'albero viene trasformato in un grafo pesato: compaiono archi aggiuntivi
## e fra due nodi possono esistere più cammini. Dijkstra trova quello con
## costo totale minimo, che non coincide necessariamente con meno archi.

const EXTRA_LINKS := 4
const MIN_WEIGHT := 1
const MAX_WEIGHT := 9


func _start() -> void:
	level.set_phase_header("FASE 5 — DIJKSTRA: CAMMINO MINIMO", Color(0.7, 0.65, 1.0))

	var graph: WeightedGraph = WeightedGraph.from_tree(level.model, MIN_WEIGHT, MAX_WEIGHT)
	_add_redundant_links(graph)

	var source: float = level.model.root.value
	var target: float = _choose_destination(graph, source)
	if is_nan(target):
		finished.emit()
		return

	var optimal: Array[float] = graph.shortest_path(source, target)
	var cost: int = WeightedGraph.path_cost(graph, optimal)

	level.tree_view.set_graph(graph)
	await level.show_banner("GRAFO PESATO",
		"Ogni arco ha un costo: cerca il cammino minimo, non quello con meno passaggi.",
		Color(0.7, 0.65, 1.0))
	if _is_over():
		return

	level.set_objective("Dijkstra: trova il cammino di costo minimo da %s a %s." % [
		fmt(source), fmt(target)])
	level.set_hint("Fissa ogni volta il nodo non fissato con il costo provvisorio più basso. Parti dalla sorgente (costo 0).")

	await shortest_path_game(graph, source, target)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Cammino minimo trovato: %s è raggiungibile con costo %d." % [fmt(target), cost], COLOR_OK)
	await _wait(1.4)
	finished.emit()


## Aggiunge alcuni archi fra nodi vicini sullo schermo ma non collegati
## nell'albero: sono questi a creare cammini alternativi.
func _add_redundant_links(graph: WeightedGraph) -> void:
	var values: Array[float] = level.model.values()
	var candidates: Array = []
	for i in range(values.size()):
		for j in range(i + 1, values.size()):
			var a: float = values[i]
			var b: float = values[j]
			if graph.has_edge(a, b):
				continue
			var distance: float = level.tree_view.center_of(a).distance_to(level.tree_view.center_of(b))
			candidates.append({"a": a, "b": b, "d": distance})

	candidates.sort_custom(func(x, y): return float(x["d"]) < float(y["d"]))

	var added: int = 0
	for candidate in candidates:
		if added >= EXTRA_LINKS:
			break
		# Salta i archi troppo lunghi: attraverserebbero mezzo schermo.
		if float(candidate["d"]) > 420.0:
			continue
		graph.add_edge(float(candidate["a"]), float(candidate["b"]),
			randi_range(MIN_WEIGHT, MAX_WEIGHT), true)
		added += 1


## Una destinazione lontana dalla sorgente, così l'algoritmo deve davvero
## fissare più nodi prima di arrivarci.
func _choose_destination(graph: WeightedGraph, source: float) -> float:
	var result: Dictionary = graph.dijkstra(source)
	var distances: Dictionary = result["dist"]
	var best: float = NAN
	var best_hops: int = -1
	for value in graph.nodes():
		if is_equal_approx(value, source):
			continue
		var path: Array[float] = WeightedGraph.path_from(result["prev"], source, value)
		if path.size() > best_hops and float(distances[value]) < WeightedGraph.INF:
			best_hops = path.size()
			best = value
	return best
