class_name TreeView
extends Control

## Renders the BST as a futuristic tree: glowing edges, nodes and
## animated search tokens. Purely presentational - phases drive it.

const MARGIN_X := 70.0
const TREE_TOP := 178.0
const LEVEL_HEIGHT_MAX := 98.0
const LEVEL_HEIGHT_MIN := 50.0
const BOTTOM_RESERVED := 196.0
## Distanza minima fra due colonne: un nodo è largo 58 px, quindi sotto i
## 74 px due nodi vicini si toccherebbero.
const MIN_COLUMN_STEP := 74.0
const MAX_COLUMN_STEP := 150.0
const SIDE_MARGIN := 90.0
const SLOT_RADIUS := 30.0
const DROP_TOLERANCE := 78.0

const EDGE_IDLE := Color(0.25, 0.62, 1.0, 0.85)
const EDGE_OK := Color(0.25, 1.0, 0.6, 1.0)
const EDGE_BAD := Color(1.0, 0.28, 0.32, 1.0)
const EDGE_EXTRA := Color(0.65, 0.55, 1.0, 0.85)
const EDGE_PATH := Color(1.0, 0.82, 0.3, 1.0)
const EXTRA_BULGE := 44.0
## Di quanto l'etichetta del costo si scosta dal arco, perpendicolarmente.
const WEIGHT_OFFSET := 15.0

var model: BSTModel = null

var _node_views: Dictionary = {}          # float value -> TreeNodeView
var _positions: Dictionary = {}        # float value -> Vector2 (center)
var _depths: Dictionary = {}           # float value -> int
var _edges: Array = []                 # [{ "from": float, "to": float }]
var _edge_colors: Dictionary = {}      # "from>to" -> Color
var _slots: Array = []                 # [{ "parent": int, "side": String, "pos": Vector2 }]
var _flow: float = 0.0
var _slot_pulse: float = 0.0
var _flow_enabled: bool = true
var _level_height: float = LEVEL_HEIGHT_MAX
## Distanza orizzontale fra due colonne vicine, ricalcolata a ogni layout.
var _column_step: float = MAX_COLUMN_STEP
var graph: WeightedGraph = null         # attivo solo nella fase Dijkstra
## Nodo sotto il mouse nella fase Dijkstra: i suoi archi vengono evidenziati.
var _hovered_value: float = NAN


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	resized.connect(_on_resized)


func setup(bst: BSTModel) -> void:
	model = bst
	rebuild()


# ---------------------------------------------------------------- layout ----

func _tree_width() -> float:
	return maxf(size.x - MARGIN_X * 2.0, 400.0)


func compute_layout() -> void:
	_positions.clear()
	_depths.clear()
	_edges.clear()
	if model == null or model.root == null:
		return
	# Il passo verticale si adatta alla profondità così che anche un albero
	# molto sbilanciato resti dentro lo schermo (con una riga libera in più
	# per lo slot di inserimento successivo).
	var levels: float = maxf(float(model.max_depth()) + 1.0, 1.0)
	var available: float = maxf(size.y - BOTTOM_RESERVED - TREE_TOP, 200.0)
	_level_height = clampf(available / levels, LEVEL_HEIGHT_MIN, LEVEL_HEIGHT_MAX)

	# Disposizione IN-ORDER: ogni nodo riceve una colonna tutta sua, nell'ordine
	# della visita simmetrica. Così due nodi non possono MAI sovrapporsi,
	# nemmeno quando l'albero degenera in una catena — con il vecchio schema
	# «dimezza l'offset a ogni livello» i nodi profondi finivano a 38 px l'uno
	# dall'altro, cioè meno della loro larghezza, e archi ed etichette si
	# accavallavano diventando illeggibili.
	var ordered: Array[float] = model.inorder()
	_column_step = _compute_column_step(ordered.size())
	var span: float = float(maxi(ordered.size() - 1, 0)) * _column_step
	var start_x: float = size.x * 0.5 - span * 0.5

	var columns: Dictionary = {}
	for i in range(ordered.size()):
		columns[ordered[i]] = start_x + float(i) * _column_step

	_layout_recursive(model.root, columns, 0)


## Distanza fra due colonne vicine: mai meno della larghezza di un nodo più
## un margine, mai tanto da disperdere l'albero su tutto lo schermo.
func _compute_column_step(count: int) -> float:
	if count <= 1:
		return MAX_COLUMN_STEP
	var usable: float = maxf(size.x - SIDE_MARGIN * 2.0, 240.0)
	return clampf(usable / float(count - 1), MIN_COLUMN_STEP, MAX_COLUMN_STEP)


## Dove finirebbe un figlio che ancora non esiste: mezza colonna di lato,
## perché la colonna intera accanto al genitore è occupata dal suo vicino
## nella visita simmetrica.
func _child_offset(_depth: int) -> float:
	return _column_step * 0.5


func _layout_recursive(node: BSTModel.BSTNodeData, columns: Dictionary, depth: int) -> void:
	var x: float = float(columns.get(node.value, size.x * 0.5))
	_positions[node.value] = Vector2(x, TREE_TOP + float(depth) * _level_height)
	_depths[node.value] = depth
	if node.left != null:
		_edges.append({"from": node.value, "to": node.left.value})
		_layout_recursive(node.left, columns, depth + 1)
	if node.right != null:
		_edges.append({"from": node.value, "to": node.right.value})
		_layout_recursive(node.right, columns, depth + 1)


## Where a hypothetical child of `parent_value` on `side` would be drawn.
func slot_center(parent_value: float, side: String) -> Vector2:
	if not _positions.has(parent_value):
		return Vector2.ZERO
	var parent_pos: Vector2 = _positions[parent_value]
	var depth: int = _depths.get(parent_value, 0)
	var dx: float = _child_offset(depth)
	var offset: float = -dx if side == "left" else dx
	return parent_pos + Vector2(offset, _level_height)


func center_of(value: float) -> Vector2:
	return _positions.get(value, Vector2.ZERO)


func has_node_view(value: float) -> bool:
	return _node_views.has(value)


func get_node_view(value: float) -> TreeNodeView:
	return _node_views.get(value, null)


func all_node_views() -> Array:
	return _node_views.values()


# --------------------------------------------------------------- building ---

## Rebuilds node views from the model. Existing ones are re-used and tweened
## to their new position so the tree never "jumps".
func rebuild(animate: bool = true) -> void:
	compute_layout()
	if model == null:
		return
	var live_values: Array[float] = model.values()

	# Remove node views that no longer exist in the model.
	for value in _node_views.keys():
		if not live_values.has(value):
			var stale: TreeNodeView = _node_views[value]
			_node_views.erase(value)
			_dissolve(stale)

	for value in live_values:
		var target: Vector2 = _positions[value]
		if _node_views.has(value):
			var node_view: TreeNodeView = _node_views[value]
			if animate:
				node_view.move_to_center(target, 0.35)
			else:
				node_view.set_center(target)
		else:
			var new_node_view: TreeNodeView = _make_node_view(value)
			new_node_view.set_center(target)
			_node_views[value] = new_node_view
	queue_redraw()


func adopt_node_view(node_view: TreeNodeView, value: float) -> void:
	## Takes an externally created node view (e.g. dragged from the tray) into the tree.
	_node_views[value] = node_view
	if node_view.get_parent() != self:
		var global_pos: Vector2 = node_view.global_position
		if node_view.get_parent() != null:
			node_view.get_parent().remove_child(node_view)
		add_child(node_view)
		node_view.global_position = global_pos
	node_view.draggable = false
	node_view.z_index = 0


func _make_node_view(value: float) -> TreeNodeView:
	var node_view: TreeNodeView = TreeNodeView.new(value)
	add_child(node_view)
	node_view.set_value(value)
	node_view.hovered.connect(_on_node_hovered)
	return node_view


## Passando il mouse su un nodo si accendono i SUOI collegamenti e si
## spengono gli altri: con molti archi sovrapposti è l'unico modo per capire a
## colpo d'occhio quali archi partono da lì e quanto costano.
func _on_node_hovered(node_view: TreeNodeView, inside: bool) -> void:
	if graph == null:
		return
	_hovered_value = node_view.value if inside else NAN
	queue_redraw()


func _dissolve(node_view: TreeNodeView) -> void:
	node_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = node_view.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node_view, "modulate:a", 0.0, 0.3)
	tween.tween_property(node_view, "scale", Vector2(1.6, 1.6), 0.3)
	tween.chain().tween_callback(node_view.queue_free)


func clear_all() -> void:
	for node_view in _node_views.values():
		node_view.queue_free()
	_node_views.clear()
	_slots.clear()
	_edge_colors.clear()
	queue_redraw()


# ------------------------------------------------------------------ slots ---

func show_slots(slots: Array) -> void:
	_slots.clear()
	for slot in slots:
		var parent_value: float = float(slot["parent"])
		var side: String = String(slot["side"])
		_slots.append({
			"parent": parent_value,
			"side": side,
			"pos": slot_center(parent_value, side),
		})
	queue_redraw()


func show_all_free_slots() -> void:
	if model != null:
		show_slots(model.empty_slots())


func clear_slots() -> void:
	_slots.clear()
	queue_redraw()


## Closest free slot to a global point, or {} when nothing is close enough.
func nearest_slot(global_pos: Vector2) -> Dictionary:
	var local: Vector2 = global_pos - global_position
	var best: Dictionary = {}
	var best_dist: float = DROP_TOLERANCE
	for slot in _slots:
		var d: float = (slot["pos"] as Vector2).distance_to(local)
		if d < best_dist:
			best_dist = d
			best = slot
	return best


# ------------------------------------------------------------------ edges ---

func set_edge_color(from_value: float, to_value: float, color: Color) -> void:
	_edge_colors[_edge_key(from_value, to_value)] = color
	queue_redraw()


static func _edge_key(from_value: float, to_value: float) -> String:
	return "%s>%s" % [BSTModel.fmt(from_value), BSTModel.fmt(to_value)]


## I archi sono bidirezionali: cerca il colore in entrambi i versi.
func _edge_color_or(from_value: float, to_value: float, fallback: Color) -> Color:
	if _edge_colors.has(_edge_key(from_value, to_value)):
		return _edge_colors[_edge_key(from_value, to_value)]
	if _edge_colors.has(_edge_key(to_value, from_value)):
		return _edge_colors[_edge_key(to_value, from_value)]
	return fallback


# --------------------------------------------------------- grafo pesato ----

## Attiva la visualizzazione a grafo: archi ridondanti curvi e costi sui archi.
func set_graph(new_graph: WeightedGraph) -> void:
	graph = new_graph
	queue_redraw()


func clear_graph() -> void:
	graph = null
	queue_redraw()


## Evidenzia un cammino (sequenza di valori) come archi dorati.
func highlight_path(path: Array[float], color: Color = EDGE_PATH) -> void:
	for i in range(path.size() - 1):
		set_edge_color(path[i], path[i + 1], color)


func reset_edges() -> void:
	_edge_colors.clear()
	queue_redraw()


func flash_edge(from_value: float, to_value: float, color: Color, duration: float = 0.6) -> void:
	set_edge_color(from_value, to_value, color)
	await get_tree().create_timer(duration).timeout
	_edge_colors.erase(_edge_key(from_value, to_value))
	queue_redraw()


# ----------------------------------------------------------------- token ---

## Creates a token visual at a given local position.
func spawn_token(value: float, at_local: Vector2) -> Control:
	var token: Control = Control.new()
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.size = Vector2(44.0, 44.0)
	token.pivot_offset = Vector2(22.0, 22.0)
	token.z_index = 150
	add_child(token)

	var texture: TextureRect = TextureRect.new()
	texture.texture = load("res://assets/generated/search_token_frame_0.png")
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.size = Vector2(44.0, 44.0)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_child(texture)

	var label: Label = Label.new()
	label.text = BSTModel.fmt(value)
	label.size = Vector2(44.0, 18.0)
	label.position = Vector2(0.0, 40.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.1))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_child(label)

	token.position = at_local - Vector2(22.0, 22.0)
	return token


func move_token(token: Control, to_local: Vector2, duration: float = 0.5) -> void:
	if not is_instance_valid(token):
		return
	var tween: Tween = token.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(token, "position", to_local - Vector2(22.0, 22.0), duration)
	await tween.finished


func destroy_token(token: Control, exploded: bool = false) -> void:
	if not is_instance_valid(token):
		return
	var tween: Tween = token.create_tween()
	tween.set_parallel(true)
	if exploded:
		tween.tween_property(token, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.35)
		tween.tween_property(token, "scale", Vector2(2.0, 2.0), 0.35)
		tween.tween_property(token, "rotation", 1.2, 0.35)
	else:
		tween.tween_property(token, "modulate:a", 0.0, 0.25)
		tween.tween_property(token, "scale", Vector2(1.5, 1.5), 0.25)
	tween.chain().tween_callback(token.queue_free)


# ---------------------------------------------------------------- drawing ---

func set_flow_enabled(enabled: bool) -> void:
	_flow_enabled = enabled


func _process(delta: float) -> void:
	_flow += delta * 0.45
	_slot_pulse += delta
	queue_redraw()


func _on_resized() -> void:
	rebuild(false)


func _draw() -> void:
	# Edges between nodes.
	for i in range(_edges.size()):
		var edge: Dictionary = _edges[i]
		var from_value: float = float(edge["from"])
		var to_value: float = float(edge["to"])
		if not _positions.has(from_value) or not _positions.has(to_value):
			continue
		var a: Vector2 = _positions[from_value]
		var b: Vector2 = _positions[to_value]
		var color: Color = _edge_color_or(from_value, to_value, EDGE_IDLE)
		_draw_cable(a, b, color, float(i) * 0.31)

	# Modalità grafo: archi ridondanti (curvi) e costo scritto su ogni arco.
	if graph != null:
		var hovering: bool = not is_nan(_hovered_value)
		# Prima i archi non evidenziati, poi quelli del nodo sotto il mouse:
		# così restano sopra e leggibili.
		for pass_index in range(2):
			for link in graph.edges:
				var a_value: float = float(link["a"])
				var b_value: float = float(link["b"])
				if not _positions.has(a_value) or not _positions.has(b_value):
					continue
				var touches: bool = hovering and (
					is_equal_approx(a_value, _hovered_value) or is_equal_approx(b_value, _hovered_value))
				if (pass_index == 1) != touches:
					continue

				var pa: Vector2 = _positions[a_value]
				var pb: Vector2 = _positions[b_value]
				var is_extra: bool = bool(link["extra"])
				var link_color: Color = _edge_color_or(a_value, b_value,
					EDGE_EXTRA if is_extra else EDGE_IDLE)
				# Chi non è collegato al nodo sotto il mouse si spegne.
				if hovering and not touches:
					link_color = Color(link_color.r, link_color.g, link_color.b, 0.18)

				var label_pos: Vector2 = (pa + pb) * 0.5
				if is_extra:
					label_pos = _draw_curved_cable(pa, pb, link_color)
				elif touches:
					_draw_cable(pa, pb, link_color, 0.0)      # ridisegnato più acceso
				_draw_weight(label_pos, int(link["weight"]), link_color, pa, pb, touches)

	# Ghost slots where a node can be dropped.
	for slot in _slots:
		var pos: Vector2 = slot["pos"]
		var parent_value: float = float(slot["parent"])
		if _positions.has(parent_value):
			_draw_dashed_line(_positions[parent_value], pos, Color(0.45, 0.7, 1.0, 0.3), 2.0)
		var pulse: float = (sin(_slot_pulse * 3.0) * 0.5 + 0.5)
		draw_arc(pos, SLOT_RADIUS, 0.0, TAU, 36, Color(0.4, 0.85, 1.0, 0.35 + pulse * 0.4), 2.5, true)
		draw_circle(pos, SLOT_RADIUS - 4.0, Color(0.3, 0.7, 1.0, 0.08 + pulse * 0.06))


func _draw_cable(a: Vector2, b: Vector2, color: Color, phase_offset: float) -> void:
	var dir: Vector2 = (b - a).normalized()
	var trim: float = minf(30.0, a.distance_to(b) * 0.34)
	var start: Vector2 = a + dir * trim
	var end: Vector2 = b - dir * trim
	# Outer glow
	draw_line(start, end, Color(color.r, color.g, color.b, 0.16), 10.0, true)
	draw_line(start, end, Color(color.r, color.g, color.b, 0.28), 6.0, true)
	draw_line(start, end, color, 2.6, true)
	if not _flow_enabled:
		return
	# Animated data pulses travelling along the cable.
	for k in range(2):
		var t: float = fposmod(_flow + phase_offset + float(k) * 0.5, 1.0)
		var p: Vector2 = start.lerp(end, t)
		var fade: float = sin(t * PI)
		draw_circle(p, 4.0, Color(color.r, color.g, color.b, 0.85 * fade))
		draw_circle(p, 7.5, Color(color.r, color.g, color.b, 0.22 * fade))


## Arco ridondante: una curva, per distinguerlo dai archi dell'albero e per
## non farlo passare sopra i nodi che stanno in mezzo.
## Ritorna il punto centrale della curva (dove va scritto il costo).
func _draw_curved_cable(a: Vector2, b: Vector2, color: Color) -> Vector2:
	var dir: Vector2 = (b - a).normalized()
	var trim: float = minf(30.0, a.distance_to(b) * 0.34)
	var start: Vector2 = a + dir * trim
	var end: Vector2 = b - dir * trim
	var normal: Vector2 = Vector2(-dir.y, dir.x)
	if normal.y > 0.0:
		normal = -normal              # curva sempre verso l'alto
	var control: Vector2 = (start + end) * 0.5 + normal * EXTRA_BULGE

	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = 16
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = start.lerp(control, t).lerp(control.lerp(end, t), t)
		points.append(p)

	draw_polyline(points, Color(color.r, color.g, color.b, 0.16), 9.0, true)
	draw_polyline(points, color, 2.2, true)

	if _flow_enabled:
		var t_flow: float = fposmod(_flow * 0.8, 1.0)
		var index: int = clampi(int(t_flow * float(steps)), 0, steps)
		var fade: float = sin(t_flow * PI)
		draw_circle(points[index], 3.5, Color(color.r, color.g, color.b, 0.85 * fade))

	@warning_ignore("integer_division")
	var mid: int = steps / 2
	return points[mid]


## Etichetta con il costo del arco, su una pastiglia scura per la leggibilità.
##
## Viene spostata di lato rispetto al arco (perpendicolarmente): al centro
## esatto finirebbe sopra i badge delle distanze dei nodi vicini, ed è
## esattamente il motivo per cui prima non si capiva quale costo appartenesse
## a quale collegamento.
func _draw_weight(at: Vector2, weight: int, color: Color,
		from_point: Vector2 = Vector2.ZERO, to_point: Vector2 = Vector2.ZERO,
		emphasised: bool = false) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return

	var anchor: Vector2 = at
	if from_point != to_point:
		var direction: Vector2 = (to_point - from_point).normalized()
		var normal: Vector2 = Vector2(-direction.y, direction.x)
		if normal.y > 0.0:
			normal = -normal                  # sempre verso l'alto: area più libera
		anchor += normal * WEIGHT_OFFSET

	var text: String = str(weight)
	var font_size: int = 17 if emphasised else 15
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var pad: Vector2 = Vector2(8.0, 4.0)
	var rect: Rect2 = Rect2(anchor - text_size * 0.5 - pad, text_size + pad * 2.0)

	var fill: Color = Color(0.03, 0.06, 0.12, 0.92)
	var border: Color = Color(color.r, color.g, color.b, 0.7)
	var ink: Color = Color(0.92, 0.97, 1.0)
	if emphasised:
		fill = Color(0.10, 0.16, 0.30, 0.98)
		border = Color(color.r, color.g, color.b, 1.0)
	elif color.a < 0.5:
		# Arco spento: anche il costo si attenua, così non distrae.
		fill = Color(0.03, 0.06, 0.12, 0.45)
		ink = Color(0.92, 0.97, 1.0, 0.35)

	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0 if emphasised else 1.5)
	draw_string(font, anchor + Vector2(-text_size.x * 0.5, text_size.y * 0.36), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, ink)


func _draw_dashed_line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	var dir: Vector2 = (b - a).normalized()
	var trim: float = minf(30.0, a.distance_to(b) * 0.34)
	var start: Vector2 = a + dir * trim
	var total: float = maxf(start.distance_to(b) - trim, 0.0)
	var dash: float = 10.0
	var travelled: float = 0.0
	while travelled < total:
		var seg_end: float = minf(travelled + dash, total)
		draw_line(start + dir * travelled, start + dir * seg_end, color, width, true)
		travelled += dash * 2.0
