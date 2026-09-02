class_name BSTModel
extends RefCounted

## Modello dati puro di un Binary Search Tree.
## Le chiavi sono numeri REALI (decimali come 25.5, 37.2): niente
## interi, così il giocatore è costretto a confrontare davvero i valori.
## Nessuna logica di rendering: la TreeView legge questo modello.

class BSTNodeData extends RefCounted:
	var value: float = 0.0
	var left: BSTNodeData = null
	var right: BSTNodeData = null

	func _init(v: float) -> void:
		value = v


var root: BSTNodeData = null


## Formattazione condivisa: "50" per gli interi, "25.5" per i decimali.
static func fmt(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return String.num(value, 1)


func clear() -> void:
	root = null


func is_empty() -> bool:
	return root == null


## Inserisce un valore rispettando la regola del BST. false sui duplicati.
func insert(value: float) -> bool:
	if root == null:
		root = BSTNodeData.new(value)
		return true
	var current: BSTNodeData = root
	while true:
		if is_equal_approx(value, current.value):
			return false
		if value < current.value:
			if current.left == null:
				current.left = BSTNodeData.new(value)
				return true
			current = current.left
		else:
			if current.right == null:
				current.right = BSTNodeData.new(value)
				return true
			current = current.right
	return false


func find(value: float) -> BSTNodeData:
	var current: BSTNodeData = root
	while current != null:
		if is_equal_approx(value, current.value):
			return current
		current = current.left if value < current.value else current.right
	return null


func contains(value: float) -> bool:
	return find(value) != null


## { "parent": float, "side": "left"/"right" }: l'unico slot libero legale per
## `value`. Dizionario vuoto se il valore esiste già o l'albero è vuoto.
func insertion_slot(value: float) -> Dictionary:
	if root == null:
		return {}
	var current: BSTNodeData = root
	while true:
		if is_equal_approx(value, current.value):
			return {}
		if value < current.value:
			if current.left == null:
				return {"parent": current.value, "side": "left"}
			current = current.left
		else:
			if current.right == null:
				return {"parent": current.value, "side": "right"}
			current = current.right
	return {}


## Tutte le posizioni figlio attualmente libere.
func empty_slots() -> Array:
	var slots: Array = []
	_collect_slots(root, slots)
	return slots


func _collect_slots(node: BSTNodeData, slots: Array) -> void:
	if node == null:
		return
	if node.left == null:
		slots.append({"parent": node.value, "side": "left"})
	else:
		_collect_slots(node.left, slots)
	if node.right == null:
		slots.append({"parent": node.value, "side": "right"})
	else:
		_collect_slots(node.right, slots)


## Cancellazione BST. Per un nodo con due figli il giocatore può scegliere
## il successore in-order oppure il predecessore in-order.
func erase(value: float, replacement_value: float = NAN) -> bool:
	if not contains(value):
		return false
	if not is_nan(replacement_value) and not valid_replacements(value).has(replacement_value):
		return false
	root = _erase_recursive(root, value, replacement_value)
	return true


## Valori che possono prendere legalmente il posto di un nodo con due figli.
func valid_replacements(value: float) -> Array[float]:
	var node: BSTNodeData = find(value)
	var out: Array[float] = []
	if node == null or node.left == null or node.right == null:
		return out
	var predecessor_node: BSTNodeData = node.left
	while predecessor_node.right != null:
		predecessor_node = predecessor_node.right
	var successor_node: BSTNodeData = node.right
	while successor_node.left != null:
		successor_node = successor_node.left
	out.append(predecessor_node.value)
	out.append(successor_node.value)
	return out


func _erase_recursive(node: BSTNodeData, value: float, replacement_value: float = NAN) -> BSTNodeData:
	if node == null:
		return null
	if value < node.value and not is_equal_approx(value, node.value):
		node.left = _erase_recursive(node.left, value)
	elif value > node.value and not is_equal_approx(value, node.value):
		node.right = _erase_recursive(node.right, value)
	else:
		if node.left == null:
			return node.right
		if node.right == null:
			return node.left
		var replacement: BSTNodeData
		if not is_nan(replacement_value) and replacement_value < node.value:
			replacement = node.left
			while replacement.right != null:
				replacement = replacement.right
			node.value = replacement.value
			node.left = _erase_recursive(node.left, replacement.value)
		else:
			replacement = node.right
			while replacement.left != null:
				replacement = replacement.left
			node.value = replacement.value
			node.right = _erase_recursive(node.right, replacement.value)
	return node


## Quanti confronti servono per cercare `value` (anche se assente).
func comparisons_for(value: float) -> int:
	var steps: int = 0
	var current: BSTNodeData = root
	while current != null:
		steps += 1
		if is_equal_approx(value, current.value):
			return steps
		current = current.left if value < current.value else current.right
	return steps


## "left" / "right" per un passo di ricerca; "" se siamo già sul valore.
func step_direction(from_value: float, target: float) -> String:
	if is_equal_approx(from_value, target):
		return ""
	return "left" if target < from_value else "right"


func minimum() -> float:
	if root == null:
		return NAN
	var current: BSTNodeData = root
	while current.left != null:
		current = current.left
	return current.value


func maximum() -> float:
	if root == null:
		return NAN
	var current: BSTNodeData = root
	while current.right != null:
		current = current.right
	return current.value


## Successore in-order: il valore immediatamente più grande di `value`.
## NAN se `value` è il massimo o non esiste.
func successor(value: float) -> float:
	var ordered: Array[float] = inorder()
	for i in range(ordered.size() - 1):
		if is_equal_approx(ordered[i], value):
			return ordered[i + 1]
	return NAN


## Predecessore in-order: il valore immediatamente più piccolo.
func predecessor(value: float) -> float:
	var ordered: Array[float] = inorder()
	for i in range(1, ordered.size()):
		if is_equal_approx(ordered[i], value):
			return ordered[i - 1]
	return NAN


## Nodi che hanno entrambi i figli (i casi "difficili" di cancellazione).
func nodes_with_two_children() -> Array[float]:
	var out: Array[float] = []
	_collect_two_children(root, out)
	return out


func _collect_two_children(node: BSTNodeData, out: Array[float]) -> void:
	if node == null:
		return
	if node.left != null and node.right != null:
		out.append(node.value)
	_collect_two_children(node.left, out)
	_collect_two_children(node.right, out)


func preorder() -> Array[float]:
	var out: Array[float] = []
	_preorder(root, out)
	return out


func inorder() -> Array[float]:
	var out: Array[float] = []
	_inorder(root, out)
	return out


func postorder() -> Array[float]:
	var out: Array[float] = []
	_postorder(root, out)
	return out


func bfs() -> Array[float]:
	var out: Array[float] = []
	if root == null:
		return out
	var queue: Array[BSTNodeData] = [root]
	while not queue.is_empty():
		var node: BSTNodeData = queue.pop_front()
		out.append(node.value)
		if node.left != null:
			queue.append(node.left)
		if node.right != null:
			queue.append(node.right)
	return out


func traversal(kind: String) -> Array[float]:
	match kind:
		"Preorder":
			return preorder()
		"Inorder":
			return inorder()
		"Postorder":
			return postorder()
		"BFS":
			return bfs()
	return []


func values() -> Array[float]:
	return bfs()


func size() -> int:
	return bfs().size()


func max_depth() -> int:
	return _depth(root)


func _depth(node: BSTNodeData) -> int:
	if node == null:
		return -1
	return 1 + maxi(_depth(node.left), _depth(node.right))


func _preorder(node: BSTNodeData, out: Array[float]) -> void:
	if node == null:
		return
	out.append(node.value)
	_preorder(node.left, out)
	_preorder(node.right, out)


func _inorder(node: BSTNodeData, out: Array[float]) -> void:
	if node == null:
		return
	_inorder(node.left, out)
	out.append(node.value)
	_inorder(node.right, out)


func _postorder(node: BSTNodeData, out: Array[float]) -> void:
	if node == null:
		return
	_postorder(node.left, out)
	_postorder(node.right, out)
	out.append(node.value)
