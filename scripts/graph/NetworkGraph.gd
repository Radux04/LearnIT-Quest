class_name NetworkGraph
extends RefCounted

## Grafo pesato non orientato costruito sopra la rete di router.
## I cavi dell'albero diventano archi, più alcuni "cavi ridondanti" che
## creano percorsi alternativi: senza di essi il cammino fra due nodi
## sarebbe unico e Dijkstra non avrebbe nulla da decidere.
## Il peso di un arco è la latenza del cavo in millisecondi.

const INF := 1000000000.0

var adjacency: Dictionary = {}     # float -> Array[{ "to": float, "weight": int }]
var edges: Array = []              # [{ "a": float, "b": float, "weight": int, "extra": bool }]


func clear() -> void:
	adjacency.clear()
	edges.clear()


func add_node(value: float) -> void:
	if not adjacency.has(value):
		adjacency[value] = []


func has_edge(a: float, b: float) -> bool:
	if not adjacency.has(a):
		return false
	for link in adjacency[a]:
		if is_equal_approx(float(link["to"]), b):
			return true
	return false


func add_edge(a: float, b: float, weight: int, extra: bool = false) -> void:
	if is_equal_approx(a, b) or has_edge(a, b):
		return
	add_node(a)
	add_node(b)
	adjacency[a].append({"to": b, "weight": weight})
	adjacency[b].append({"to": a, "weight": weight})
	edges.append({"a": a, "b": b, "weight": weight, "extra": extra})


func neighbors(value: float) -> Array:
	return adjacency.get(value, [])


func nodes() -> Array[float]:
	var out: Array[float] = []
	for key in adjacency.keys():
		out.append(float(key))
	return out


func edge_weight(a: float, b: float) -> int:
	for link in adjacency.get(a, []):
		if is_equal_approx(float(link["to"]), b):
			return int(link["weight"])
	return -1


## Costruisce il grafo a partire dall'albero: ogni cavo padre-figlio
## diventa un arco con una latenza casuale.
static func from_tree(model: BSTModel, min_weight: int = 1, max_weight: int = 9) -> NetworkGraph:
	var graph: NetworkGraph = NetworkGraph.new()
	for value in model.values():
		graph.add_node(value)
	graph._add_tree_edges(model.root, min_weight, max_weight)
	return graph


func _add_tree_edges(node: BSTModel.BSTNodeData, min_weight: int, max_weight: int) -> void:
	if node == null:
		return
	if node.left != null:
		add_edge(node.value, node.left.value, randi_range(min_weight, max_weight), false)
		_add_tree_edges(node.left, min_weight, max_weight)
	if node.right != null:
		add_edge(node.value, node.right.value, randi_range(min_weight, max_weight), false)
		_add_tree_edges(node.right, min_weight, max_weight)


## Algoritmo di Dijkstra dalla sorgente.
## Ritorna { "dist": { valore -> float }, "prev": { valore -> float } }.
func dijkstra(source: float) -> Dictionary:
	var dist: Dictionary = {}
	var prev: Dictionary = {}
	var settled: Dictionary = {}
	for value in adjacency.keys():
		dist[value] = INF
	dist[source] = 0.0

	while true:
		var best: float = NAN
		var best_dist: float = INF
		for value in adjacency.keys():
			if settled.has(value):
				continue
			if float(dist[value]) < best_dist:
				best_dist = float(dist[value])
				best = float(value)
		if is_nan(best):
			break
		settled[best] = true
		for link in adjacency[best]:
			var to: float = float(link["to"])
			var candidate: float = best_dist + float(link["weight"])
			if candidate < float(dist[to]):
				dist[to] = candidate
				prev[to] = best

	return {"dist": dist, "prev": prev}


## Il cammino minimo come sequenza di valori, sorgente inclusa.
## Array vuoto se la destinazione non è raggiungibile.
func shortest_path(source: float, target: float) -> Array[float]:
	var result: Dictionary = dijkstra(source)
	return path_from(result["prev"], source, target)


static func path_from(prev: Dictionary, source: float, target: float) -> Array[float]:
	var path: Array[float] = [target]
	var current: float = target
	var guard: int = 0
	while not is_equal_approx(current, source):
		if not prev.has(current) or guard > 256:
			return []
		current = float(prev[current])
		path.push_front(current)
		guard += 1
	return path


## Numero di archi (salti) del cammino, utile per far notare che
## "meno salti" non vuol dire "meno costo".
static func path_cost(graph: NetworkGraph, path: Array[float]) -> int:
	var total: int = 0
	for i in range(path.size() - 1):
		total += graph.edge_weight(path[i], path[i + 1])
	return total
