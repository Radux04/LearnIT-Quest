class_name Lvl1PhaseBase
extends Node

## Classe base delle fasi del BST. Contiene mini-giochi riutilizzabili:
## inserimento drag & drop, ricerca positiva e negativa, visite, selezione,
## cancellazione e Dijkstra.

@warning_ignore("unused_signal")
signal finished
signal helper_done
signal direction_chosen(direction: String)
signal replacement_chosen(value: float)

const COLOR_OK := Color(0.3, 1.0, 0.6)
const COLOR_BAD := Color(1.0, 0.35, 0.4)
const COLOR_INFO := Color(0.55, 0.85, 1.0)
const COLOR_WARN := Color(1.0, 0.82, 0.35)

const PENALTY_PLACE := 5.0
const PENALTY_ROUTE := 12.0
const PENALTY_SCAN := 10.0
const PENALTY_ATTACK := 15.0

var level: Node = null                       # LevelController

var _tray_nodes: Dictionary = {}           # float value -> TreeNodeView
var _pending_values: Array[float] = []
var _drop_penalty: float = 0.0
var _accepting_direction: bool = false
var _direction_buttons: Array[Button] = []
var _replacement_buttons: Array[Button] = []

var _expected: Array[float] = []
var _scan_index: int = 0
var _scan_active: bool = false

var _pick_target: float = NAN
var _pick_active: bool = false
var _pick_penalty: float = PENALTY_ATTACK
var _pick_success_message: String = ""

# Stato della fase Dijkstra.
var _dij_graph: WeightedGraph = null
var _dij_dist: Dictionary = {}
var _dij_prev: Dictionary = {}
var _dij_settled: Array[float] = []
var _dij_source: float = NAN
var _dij_target: float = NAN
var _dij_active: bool = false

# Stato osservabile (usato dall'HUD, dai messaggi e dai test automatici).
var current_target: float = NAN
var current_node: float = NAN
var current_target_exists: bool = true


func run() -> void:
	@warning_ignore("redundant_await")
	await _start()
	_cleanup()


func _start() -> void:
	pass


func _cleanup() -> void:
	_clear_tray()
	_clear_direction_buttons()
	_clear_replacement_buttons()
	_disconnect_node_clicks()
	level.set_hint("")


func _is_over() -> bool:
	return level == null or level.is_over


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


## Registra una prova superata: finisce nei progressi salvati del giocatore.
func _score() -> void:
	if level != null:
		level.solved_count += 1


static func fmt(value: float) -> String:
	return BSTModel.fmt(value)


# ==== INSERT GAME ====
# Trascina i nodi dal vassoio nello slot libero corretto dell'albero.

func place_nodes(values: Array[float], penalty: float = 0.0) -> void:
	if _is_over():
		return
	_drop_penalty = penalty
	_pending_values = values.duplicate()
	_tray_nodes.clear()

	for value in _pending_values:
		var node_view: TreeNodeView = TreeNodeView.new(value)
		node_view.draggable = true
		level.tray.add_child(node_view)
		node_view.set_value(value)
		node_view.dropped.connect(_on_node_dropped)
		node_view.drag_started.connect(_on_node_drag_started)
		_tray_nodes[value] = node_view

	_relayout_tray()
	level.tree_view.show_all_free_slots()
	await helper_done
	level.tree_view.clear_slots()


func _relayout_tray() -> void:
	var keys: Array = _tray_nodes.keys()
	keys.sort()
	var count: int = keys.size()
	if count == 0:
		return
	var spacing: float = minf(92.0, (level.size.x - 140.0) / float(count))
	var start_x: float = level.size.x * 0.5 - (float(count) - 1.0) * spacing * 0.5
	var y: float = level.size.y - 104.0
	for i in range(count):
		var node_view: TreeNodeView = _tray_nodes[keys[i]]
		var target: Vector2 = Vector2(start_x + float(i) * spacing, y)
		node_view.home_position = target - TreeNodeView.NODE_SIZE * 0.5
		if not node_view.is_dragging():
			var tween: Tween = node_view.create_tween()
			tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(node_view, "position", node_view.home_position, 0.2)


func _on_node_drag_started(_node_view: TreeNodeView) -> void:
	Sfx.play("click")


func _on_node_dropped(node_view: TreeNodeView, global_pos: Vector2) -> void:
	if _is_over():
		node_view.return_home()
		return

	var slot: Dictionary = level.tree_view.nearest_slot(global_pos)
	if slot.is_empty():
		level.toast("Rilascia il valore su uno slot libero dell'albero.", COLOR_INFO)
		node_view.return_home()
		return

	var correct: Dictionary = level.model.insertion_slot(node_view.value)
	var is_correct: bool = (not correct.is_empty()
		and is_equal_approx(float(correct["parent"]), float(slot["parent"]))
		and String(correct["side"]) == String(slot["side"]))

	if is_correct:
		_accept_node(node_view, float(slot["parent"]))
	else:
		_reject_node(node_view, slot)


func _accept_node(node_view: TreeNodeView, parent_value: float) -> void:
	var value: float = node_view.value
	_tray_nodes.erase(value)
	_pending_values.erase(value)
	node_view.draggable = false
	node_view.dropped.disconnect(_on_node_dropped)
	node_view.drag_started.disconnect(_on_node_drag_started)

	level.model.insert(value)
	level.tree_view.adopt_node_view(node_view, value)
	level.tree_view.rebuild(true)
	level.tree_view.set_edge_color(parent_value, value, TreeView.EDGE_OK)
	node_view.set_state(TreeNodeView.State.SUCCESS)
	node_view.pop()
	Sfx.play("place")
	level.toast("Collegamento stabilito: %s %s di %s." % [
		fmt(value), "a sinistra" if value < parent_value else "a destra", fmt(parent_value)], COLOR_OK)

	_relayout_tray()
	level.tree_view.show_all_free_slots()

	await _wait(0.5)
	if is_instance_valid(node_view):
		node_view.set_state(TreeNodeView.State.IDLE)
	level.tree_view.reset_edges()

	if _pending_values.is_empty():
		helper_done.emit()


func _reject_node(node_view: TreeNodeView, slot: Dictionary) -> void:
	var parent_value: float = float(slot["parent"])
	var side: String = String(slot["side"])
	var reason: String = ""
	if level.model.contains(node_view.value):
		reason = "il valore %s è già nell'albero: in un BST non esistono duplicati." % fmt(node_view.value)
	elif side == "left":
		reason = "%s NON è minore di %s: non può stare a sinistra." % [fmt(node_view.value), fmt(parent_value)]
	else:
		reason = "%s NON è maggiore di %s: non può stare a destra." % [fmt(node_view.value), fmt(parent_value)]

	level.toast("Collegamento rifiutato — " + reason, COLOR_BAD)
	node_view.set_state(TreeNodeView.State.ERROR)
	node_view.shake()
	Sfx.play("error")
	level.flash_slot(slot, TreeView.EDGE_BAD)
	if _drop_penalty > 0.0:
		level.penalty(_drop_penalty)
	await _wait(0.45)
	if is_instance_valid(node_view):
		node_view.set_state(TreeNodeView.State.IDLE)
		node_view.return_home()


func _clear_tray() -> void:
	for node_view in _tray_nodes.values():
		if is_instance_valid(node_view):
			node_view.queue_free()
	_tray_nodes.clear()
	_pending_values.clear()


# ============================================================= SEARCH GAME ==
# Cerca un valore a partire dalla radice.
# Se il valore non è nell'albero il giocatore riconosce lo slot vuoto e
# dichiara "NON NELL'ALBERO": è la ricerca con esito negativo.

func search_key(target: float) -> void:
	if _is_over() or level.model.root == null:
		return
	var net: TreeView = level.tree_view
	var exists: bool = level.model.contains(target)
	var current: float = level.model.root.value
	current_target = target
	current_target_exists = exists
	var token: Control = _spawn_token_at(target, current)
	var comparisons: int = 0
	_make_direction_buttons()

	while not _is_over():
		current_node = current
		var node_view: TreeNodeView = net.get_node_view(current)
		if node_view != null:
			node_view.set_state(TreeNodeView.State.ACTIVE)
			node_view.set_pulsing(true)

		# Lato verso cui la ricerca deve proseguire, e figlio che ci si trova.
		var node: BSTModel.BSTNodeData = level.model.find(current)
		var side: String = level.model.step_direction(current, target)
		var child: BSTModel.BSTNodeData = null
		if node != null and side != "":
			child = node.left if side == "left" else node.right
		# Se da quel lato non c'è alcun figlio, la risposta giusta è "assente".
		var expected: String = "absent" if child == null else side

		level.set_hint("Nodo %s — cerchi %s.  %s è %s di %s." % [
			fmt(current), fmt(target), fmt(target),
			"MINORE" if target < current else "MAGGIORE", fmt(current)])
		_set_direction_enabled(true)

		var direction: String = await direction_chosen
		_set_direction_enabled(false)
		if _is_over():
			break
		if node_view != null:
			node_view.set_pulsing(false)
			node_view.set_state(TreeNodeView.State.IDLE)
		comparisons += 1

		if direction == expected:
			if expected == "absent":
				await _search_failed_correctly(token, current, target, comparisons)
				break
			net.set_edge_color(current, child.value, TreeView.EDGE_OK)
			Sfx.play("token")
			await net.move_token(token, _token_anchor(child.value), 0.42)
			current = child.value
			if is_equal_approx(current, target):
				await _key_found(token, current, comparisons)
				break
			continue

		# Risposta sbagliata: spiega esattamente perché.
		var explanation: String = ""
		if expected == "absent":
			explanation = "Il nodo %s non ha un figlio a %s: %s NON è nell'albero." % [
				fmt(current), "sinistra" if side == "left" else "destra", fmt(target)]
		elif direction == "absent":
			explanation = "Il nodo %s ha ancora un figlio a %s: la ricerca non era finita!" % [
				fmt(current), "sinistra" if side == "left" else "destra"]
		else:
			explanation = "%s è %s di %s: dovevi andare a %s!" % [
				fmt(target), "minore" if target < current else "maggiore", fmt(current),
				"SINISTRA" if side == "left" else "DESTRA"]

		var wrong_child: BSTModel.BSTNodeData = null
		if node != null and direction != "absent":
			wrong_child = node.left if direction == "left" else node.right
		_search_error(token, current, wrong_child, explanation)
		await _wait(1.2)
		net.reset_edges()
		if _is_over():
			break
		current = level.model.root.value
		comparisons = 0
		token = _spawn_token_at(target, current)

	_clear_direction_buttons()
	current_target = NAN
	current_node = NAN
	level.set_hint("")


## Risposta corretta per il passo attuale: "left", "right" o "absent".
func expected_direction() -> String:
	if is_nan(current_node) or is_nan(current_target):
		return ""
	var node: BSTModel.BSTNodeData = level.model.find(current_node)
	if node == null:
		return ""
	var side: String = level.model.step_direction(current_node, current_target)
	if side == "":
		return ""
	# Se dal lato corretto non c'è figlio, il valore non è nell'albero.
	var child: BSTModel.BSTNodeData = node.left if side == "left" else node.right
	return side if child != null else "absent"


func _search_error(token: Control, from_value: float, wrong_child: BSTModel.BSTNodeData, explanation: String) -> void:
	if wrong_child != null:
		level.tree_view.set_edge_color(from_value, wrong_child.value, TreeView.EDGE_BAD)
	Sfx.play("error")
	level.toast("Ricerca da ripetere. " + explanation, COLOR_BAD)
	level.tree_view.destroy_token(token, true)
	level.penalty(PENALTY_ROUTE)


func _search_failed_correctly(token: Control, at_value: float, target: float, comparisons: int) -> void:
	var node_view: TreeNodeView = level.tree_view.get_node_view(at_value)
	if node_view != null:
		node_view.flash(COLOR_WARN)
		node_view.pop()
	Sfx.play("scan")
	level.toast("Esatto: %s NON è nell'albero. Bastati %d confronti per esserne certi." % [
		fmt(target), comparisons], COLOR_WARN)
	level.tree_view.destroy_token(token, false)
	await _wait(1.1)
	level.tree_view.reset_edges()


func _token_anchor(value: float) -> Vector2:
	return level.tree_view.center_of(value) + Vector2(0.0, -46.0)


func _spawn_token_at(target: float, node_value: float) -> Control:
	var net: TreeView = level.tree_view
	var token: Control = net.spawn_token(target, _token_anchor(node_value) + Vector2(0.0, -60.0))
	net.move_token(token, _token_anchor(node_value), 0.3)
	return token


func _key_found(token: Control, value: float, comparisons: int) -> void:
	var net: TreeView = level.tree_view
	var node_view: TreeNodeView = net.get_node_view(value)
	if node_view != null:
		node_view.set_state(TreeNodeView.State.SUCCESS)
		node_view.pop()
	Sfx.play("correct")
	level.toast("Trovato %s in %d confronti invece di controllare %d nodi!" % [
		fmt(value), comparisons, level.model.size()], COLOR_OK)
	net.destroy_token(token, false)
	await _wait(1.0)
	net.reset_edges()
	if node_view != null and is_instance_valid(node_view):
		node_view.set_state(TreeNodeView.State.IDLE)


func _make_direction_buttons() -> void:
	_clear_direction_buttons()
	var y: float = level.size.y - 104.0
	var left_button: Button = level.make_action_button("◀  SINISTRA",
		Vector2(level.size.x * 0.5 - 280.0, y), Vector2(250.0, 58.0))
	left_button.pressed.connect(_on_direction_pressed.bind("left"))
	var absent_button: Button = level.make_action_button("✖  NON NELL'ALBERO",
		Vector2(level.size.x * 0.5, y), Vector2(250.0, 58.0))
	absent_button.pressed.connect(_on_direction_pressed.bind("absent"))
	var right_button: Button = level.make_action_button("DESTRA  ▶",
		Vector2(level.size.x * 0.5 + 280.0, y), Vector2(250.0, 58.0))
	right_button.pressed.connect(_on_direction_pressed.bind("right"))
	_direction_buttons = [left_button, absent_button, right_button]
	_set_direction_enabled(false)


func _set_direction_enabled(enabled: bool) -> void:
	_accepting_direction = enabled
	for button in _direction_buttons:
		if is_instance_valid(button):
			button.disabled = not enabled


func _clear_direction_buttons() -> void:
	for button in _direction_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_direction_buttons.clear()
	_accepting_direction = false


func _on_direction_pressed(direction: String) -> void:
	if not _accepting_direction:
		return
	_accepting_direction = false
	Sfx.play("click")
	direction_chosen.emit(direction)


func _unhandled_input(event: InputEvent) -> void:
	if not _accepting_direction or not (event is InputEventKey) or not event.pressed:
		return
	if event.is_action("ui_left"):
		_on_direction_pressed("left")
	elif event.is_action("ui_right"):
		_on_direction_pressed("right")
	elif event.is_action("ui_down"):
		_on_direction_pressed("absent")


# =============================================================== SCAN GAME ==
# Clicca i nodi seguendo un ordine di visita.

func traverse_tree(kind: String, show_rule: bool) -> void:
	if _is_over():
		return
	_expected = level.model.traversal(kind)
	_scan_index = 0
	_scan_active = true

	level.set_objective("Visita l'albero in ordine %s (%d nodi)." % [
		kind.to_upper(), _expected.size()])
	level.set_hint(traversal_rule(kind) if show_rule else "Nessun aiuto: ricorda la definizione della visita.")
	for node_view in level.tree_view.all_node_views():
		node_view.set_state(TreeNodeView.State.IDLE)
		node_view.hide_badge()
	_connect_node_clicks(_on_traverse_click)

	await helper_done

	_scan_active = false
	_disconnect_node_clicks()
	await _wait(0.6)
	for node_view in level.tree_view.all_node_views():
		node_view.set_state(TreeNodeView.State.IDLE)
		node_view.hide_badge()


static func traversal_rule(kind: String) -> String:
	match kind:
		"Preorder":
			return "PREORDER  =  nodo  →  sottoalbero sinistro  →  sottoalbero destro"
		"Inorder":
			return "INORDER  =  sottoalbero sinistro  →  nodo  →  sottoalbero destro   (dà i valori ordinati!)"
		"Postorder":
			return "POSTORDER  =  sottoalbero sinistro  →  sottoalbero destro  →  nodo"
		"BFS":
			return "BFS  =  un livello alla volta, dall'alto verso il basso e da sinistra a destra"
	return ""


func _on_traverse_click(node_view: TreeNodeView) -> void:
	if not _scan_active or _is_over():
		return
	if _scan_index >= _expected.size():
		return

	if is_equal_approx(node_view.value, _expected[_scan_index]):
		_scan_index += 1
		node_view.set_state(TreeNodeView.State.SCANNED)
		node_view.show_badge(str(_scan_index))
		node_view.pop()
		Sfx.play("scan")
		level.toast("Nodo %s selezionato (%d/%d)" % [
			fmt(node_view.value), _scan_index, _expected.size()], COLOR_OK)
		if _scan_index >= _expected.size():
			Sfx.play("correct")
			level.toast("Visita completata! Ordine corretto.", COLOR_OK)
			_scan_active = false
			helper_done.emit()
	else:
		Sfx.play("error")
		node_view.set_state(TreeNodeView.State.ERROR)
		node_view.shake()
		level.toast("Nodo sbagliato! Non tocca a %s. Tempo -%d s" % [
			fmt(node_view.value), int(PENALTY_SCAN)], COLOR_BAD)
		level.penalty(PENALTY_SCAN)
		await _wait(0.5)
		if is_instance_valid(node_view) and node_view.state == TreeNodeView.State.ERROR:
			node_view.set_state(TreeNodeView.State.IDLE)


# =============================================================== PICK GAME ==
# "Clicca il nodo giusto": usato per minimo, massimo, successore
# e per l'eliminazione di un nodo.

func pick_node(target: float, highlight: bool, success_message: String, penalty: float = PENALTY_ATTACK) -> void:
	if _is_over() or is_nan(target) or not level.model.contains(target):
		return
	_pick_target = target
	_pick_active = true
	_pick_penalty = penalty
	_pick_success_message = success_message

	if highlight:
		var marked: TreeNodeView = level.tree_view.get_node_view(target)
		if marked != null:
			marked.set_state(TreeNodeView.State.ACTIVE)
			marked.set_pulsing(true)
		Sfx.play("click")
	_connect_node_clicks(_on_pick_click)

	await helper_done

	_pick_active = false
	_disconnect_node_clicks()


func _on_pick_click(node_view: TreeNodeView) -> void:
	if not _pick_active or _is_over():
		return
	if is_equal_approx(node_view.value, _pick_target):
		_pick_active = false
		node_view.set_pulsing(false)
		node_view.set_state(TreeNodeView.State.SUCCESS)
		node_view.pop()
		Sfx.play("correct")
		level.toast(_pick_success_message, COLOR_OK)
		helper_done.emit()
	else:
		Sfx.play("error")
		node_view.shake()
		node_view.flash(COLOR_BAD)
		level.toast("Non è quello: %s non va bene. Tempo -%d s" % [
			fmt(node_view.value), int(_pick_penalty)], COLOR_BAD)
		level.penalty(_pick_penalty)


## Elimina un nodo. Se possiede due figli, il giocatore sceglie quale nodo
## sostitutivo usare: predecessore oppure successore in-order.
func delete_node(target: float) -> void:
	if _is_over() or not level.model.contains(target):
		return
	var node: BSTModel.BSTNodeData = level.model.find(target)
	var two_children: bool = node != null and node.left != null and node.right != null
	var replacement_value: float = NAN

	await pick_node(target, true, "Nodo %s selezionato per l'eliminazione." % fmt(target))
	if _is_over():
		return

	if two_children:
		replacement_value = await _choose_replacement(target)
		if _is_over() or is_nan(replacement_value):
			return

	if not level.model.erase(target, replacement_value):
		level.toast("Scelta di sostituzione non valida.", COLOR_BAD)
		return
	await _wait(0.25)
	level.tree_view.rebuild(true)
	if two_children:
		level.toast("Scelta applicata: %s prende il posto di %s." % [
			fmt(replacement_value), fmt(target)], COLOR_INFO)
	else:
		level.toast("Albero riorganizzato: la proprietà del BST è intatta.", COLOR_INFO)
	await _wait(1.1)


func _choose_replacement(target: float) -> float:
	var choices: Array[float] = level.model.valid_replacements(target)
	if choices.size() != 2:
		return NAN

	level.set_objective("Scegli il nodo che prenderà il posto di %s." % fmt(target))
	level.set_hint("Con due figli puoi scegliere il predecessore (max del ramo sinistro) oppure il successore (min del ramo destro).")
	var labels: Array[String] = [
		"Predecessore: %s" % fmt(choices[0]),
		"Successore: %s" % fmt(choices[1])]
	var button_width: float = minf(280.0, maxf(180.0, (level.size.x - 180.0) * 0.42))
	var button_gap: float = 24.0
	var button_step: float = button_width + button_gap
	for i in range(choices.size()):
		var button_center: Vector2 = Vector2(
			level.size.x * 0.5 + (float(i) - 0.5) * button_step,
			level.size.y - 96.0)
		var button: Button = level.make_action_button(labels[i], button_center,
			Vector2(button_width, 54.0), Color(0.12, 0.35, 0.6))
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_on_replacement_pressed.bind(choices[i]))
		_replacement_buttons.append(button)

	var selected: float = await replacement_chosen
	_clear_replacement_buttons()
	return selected


func _on_replacement_pressed(value: float) -> void:
	if _replacement_buttons.is_empty():
		return
	Sfx.play("click")
	replacement_chosen.emit(value)


func _clear_replacement_buttons() -> void:
	for button in _replacement_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_replacement_buttons.clear()


# ========================================================== DIJKSTRA GAME ==
# Il giocatore esegue a mano il ciclo principale di Dijkstra: a ogni turno
# deve cliccare il nodo NON ancora fissato con la distanza provvisoria
# più bassa. Il gioco si occupa del rilassamento dei vicini e mostra le
# distanze aggiornate sui badge, così l'algoritmo si vede lavorare.

const DIJ_INF := WeightedGraph.INF
const BADGE_UNREACHED := Color(0.35, 0.42, 0.55)
const BADGE_TENTATIVE := Color(1.0, 0.82, 0.35)
const BADGE_SETTLED := Color(0.3, 1.0, 0.6)


func shortest_path_game(graph: WeightedGraph, source: float, target: float) -> void:
	if _is_over() or graph == null:
		return
	_dij_graph = graph
	_dij_source = source
	_dij_target = target
	_dij_settled.clear()
	_dij_dist.clear()
	_dij_prev.clear()
	for value in graph.nodes():
		_dij_dist[value] = DIJ_INF
	_dij_dist[source] = 0.0

	_dij_active = true
	level.tree_view.set_graph(graph)
	level.tree_view.reset_edges()
	for node_view in level.tree_view.all_node_views():
		node_view.set_state(TreeNodeView.State.IDLE)
	_refresh_dijkstra_badges()
	_connect_node_clicks(_on_dijkstra_click)

	await helper_done

	_dij_active = false
	_disconnect_node_clicks()


func _refresh_dijkstra_badges() -> void:
	for node_view in level.tree_view.all_node_views():
		var d: float = float(_dij_dist.get(node_view.value, DIJ_INF))
		if d >= DIJ_INF:
			node_view.show_badge("∞", BADGE_UNREACHED)
		elif _dij_settled.has(node_view.value):
			node_view.show_badge(str(int(d)), BADGE_SETTLED)
		else:
			node_view.show_badge(str(int(d)), BADGE_TENTATIVE)


## La distanza provvisoria più bassa fra i nodi non ancora fissati.
func _dijkstra_min_distance() -> float:
	var best: float = DIJ_INF
	for value in _dij_dist.keys():
		if _dij_settled.has(float(value)):
			continue
		best = minf(best, float(_dij_dist[value]))
	return best


func _on_dijkstra_click(node_view: TreeNodeView) -> void:
	if not _dij_active or _is_over():
		return
	var value: float = node_view.value

	if _dij_settled.has(value):
		level.toast("Il nodo %s è già fissato: la sua distanza non cambierà più." % fmt(value), COLOR_INFO)
		return

	var d: float = float(_dij_dist.get(value, DIJ_INF))
	var best: float = _dijkstra_min_distance()

	if d >= DIJ_INF:
		Sfx.play("error")
		node_view.shake()
		level.toast("%s è ancora a distanza ∞: non è raggiungibile dai nodi già fissati. Tempo -%d s" % [
			fmt(value), int(PENALTY_ROUTE)], COLOR_BAD)
		level.penalty(PENALTY_ROUTE)
		return

	if d > best + 0.0001:
		Sfx.play("error")
		node_view.shake()
		level.toast("Troppo presto: %s costa %d, ma c'è ancora un nodo non fissato a %d. Dijkstra prende sempre il minimo! Tempo -%d s" % [
			fmt(value), int(d), int(best), int(PENALTY_ROUTE)], COLOR_BAD)
		level.penalty(PENALTY_ROUTE)
		return

	_settle_dijkstra_node(node_view, value, d)


func _settle_dijkstra_node(node_view: TreeNodeView, value: float, distance: float) -> void:
	_dij_settled.append(value)
	node_view.set_state(TreeNodeView.State.SUCCESS)
	node_view.pop()
	Sfx.play("scan")

	# Rilassamento dei vicini.
	var improved: Array[String] = []
	for link in _dij_graph.neighbors(value):
		var to: float = float(link["to"])
		if _dij_settled.has(to):
			continue
		var candidate: float = distance + float(link["weight"])
		if candidate < float(_dij_dist.get(to, DIJ_INF)):
			_dij_dist[to] = candidate
			_dij_prev[to] = value
			improved.append("%s→%d" % [fmt(to), int(candidate)])
			level.tree_view.set_edge_color(value, to, TreeView.EDGE_OK)

	_refresh_dijkstra_badges()

	if is_equal_approx(value, _dij_target):
		await _dijkstra_finished(distance)
		return

	if improved.is_empty():
		level.toast("Fissato %s a costo %d. Nessun vicino migliora." % [fmt(value), int(distance)], COLOR_OK)
	else:
		level.toast("Fissato %s a costo %d. Aggiornati: %s" % [
			fmt(value), int(distance), ", ".join(improved)], COLOR_OK)
	level.set_hint("Ora clicca il nodo non fissato con il costo più basso.")


func _dijkstra_finished(distance: float) -> void:
	_dij_active = false
	var path: Array[float] = WeightedGraph.path_from(_dij_prev, _dij_source, _dij_target)
	level.tree_view.reset_edges()
	level.tree_view.highlight_path(path)
	for value in path:
		var node_view: TreeNodeView = level.tree_view.get_node_view(value)
		if node_view != null:
			node_view.set_state(TreeNodeView.State.SUCCESS)
			node_view.pop()
	Sfx.play("correct")

	var readable: PackedStringArray = PackedStringArray()
	for value in path:
		readable.append(fmt(value))
	level.toast("Percorso ottimo trovato: %s  —  costo totale %d in %d archi." % [
		" → ".join(readable), int(distance), maxi(path.size() - 1, 0)], COLOR_OK)
	level.set_hint("")
	await _wait(2.6)
	helper_done.emit()


# ======================================================== gestione dei click ==

func _connect_node_clicks(callback: Callable) -> void:
	for node_view in level.tree_view.all_node_views():
		node_view.clickable = true
		if not node_view.clicked.is_connected(callback):
			node_view.clicked.connect(callback)


func _disconnect_node_clicks() -> void:
	if level == null or level.tree_view == null:
		return
	for node_view in level.tree_view.all_node_views():
		if not is_instance_valid(node_view):
			continue
		node_view.clickable = false
		node_view.set_pulsing(false)
		for connection in node_view.clicked.get_connections():
			node_view.clicked.disconnect(connection["callable"])
