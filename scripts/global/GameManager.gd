class_name GameManager
extends Node

# Singleton per la gestione globale del gioco
var current_phase: int = 0
var game_active: bool = false
var time_remaining: float = 300.0  # 5 minuti
var max_time: float = 300.0

# Segnali
signal phase_changed(new_phase: int)
signal game_state_changed(is_active: bool)
signal time_updated(time_remaining: float)
signal time_expired

# BST structure
var bst_root: BSTNode = null
var bst_nodes: Array[BSTNode] = []

# Fase 1 - Valori per la ricostruzione
var phase1_values: Array[int] = [50, 30, 70, 20, 40, 60, 80]
var phase1_placed_count: int = 0

# Fase 2 - Packet routing
var phase2_packets_completed: int = 0
var phase2_total_packets: int = 5

# Fase 3 - Tree traversals
var phase3_traversals_completed: int = 0
var phase3_total_traversals: int = 4

func _ready() -> void:
	add_to_group("global")
	set_multiplayer_authority(1)

func _process(delta: float) -> void:
	if game_active:
		time_remaining -= delta
		time_updated.emit(time_remaining)
		
		if time_remaining <= 0:
			time_remaining = 0
			end_game_timeout()
			time_expired.emit()

func start_game() -> void:
	game_active = true
	time_remaining = max_time
	current_phase = 1
	phase_changed.emit(current_phase)
	game_state_changed.emit(true)

func end_game_timeout() -> void:
	game_active = false
	game_state_changed.emit(false)

func advance_phase() -> void:
	current_phase += 1
	if current_phase > 4:
		current_phase = 4
	phase_changed.emit(current_phase)

func initialize_bst() -> void:
	bst_root = null
	bst_nodes.clear()
	bst_root = BSTNode.new(phase1_values[0])
	bst_nodes.append(bst_root)
	
	# Prepara gli altri valori (non ancora inseriti)
	for i in range(1, phase1_values.size()):
		var node: BSTNode = BSTNode.new(phase1_values[i])
		bst_nodes.append(node)

func insert_node_in_bst(value: int, parent: BSTNode, direction: String) -> bool:
	if direction == "left":
		if parent.left == null:
			parent.left = BSTNode.new(value)
			return true
		else:
			if value < parent.left.value:
				return insert_node_in_bst(value, parent.left, direction)
			else:
				return false
	elif direction == "right":
		if parent.right == null:
			parent.right = BSTNode.new(value)
			return true
		else:
			if value > parent.right.value:
				return insert_node_in_bst(value, parent.right, direction)
			else:
				return false
	return false

func search_in_bst(value: int) -> Array[int]:
	# Ritorna il path da seguire come array: [left(0) o right(1)]
	var path: Array[int] = []
	var current: BSTNode = bst_root
	
	while current != null:
		if current.value == value:
			return path
		elif value < current.value:
			path.append(0)  # 0 = left
			current = current.left
		else:
			path.append(1)  # 1 = right
			current = current.right
	
	return []

func get_preorder() -> Array[int]:
	var result: Array[int] = []
	_preorder_traverse(bst_root, result)
	return result

func get_inorder() -> Array[int]:
	var result: Array[int] = []
	_inorder_traverse(bst_root, result)
	return result

func get_postorder() -> Array[int]:
	var result: Array[int] = []
	_postorder_traverse(bst_root, result)
	return result

func get_bfs() -> Array[int]:
	var result: Array[int] = []
	if bst_root == null:
		return result
	
	var queue: Array[BSTNode] = [bst_root]
	while queue.size() > 0:
		var node: BSTNode = queue.pop_front()
		result.append(node.value)
		if node.left != null:
			queue.append(node.left)
		if node.right != null:
			queue.append(node.right)
	
	return result

func _preorder_traverse(node: BSTNode, result: Array) -> void:
	if node == null:
		return
	result.append(node.value)
	_preorder_traverse(node.left, result)
	_preorder_traverse(node.right, result)

func _inorder_traverse(node: BSTNode, result: Array) -> void:
	if node == null:
		return
	_inorder_traverse(node.left, result)
	result.append(node.value)
	_inorder_traverse(node.right, result)

func _postorder_traverse(node: BSTNode, result: Array) -> void:
	if node == null:
		return
	_postorder_traverse(node.left, result)
	_postorder_traverse(node.right, result)
	result.append(node.value)

class BSTNode:
	var value: int
	var left: BSTNode = null
	var right: BSTNode = null
	
	func _init(val: int) -> void:
		value = val
