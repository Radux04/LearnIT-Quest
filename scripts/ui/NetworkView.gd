class_name NetworkView
extends Control

## Renders the BST as a futuristic router network: glowing cables, routers and
## animated network packets. Purely presentational - phases drive it.

const MARGIN_X := 70.0
const TREE_TOP := 178.0
const LEVEL_HEIGHT_MAX := 98.0
const LEVEL_HEIGHT_MIN := 50.0
const BOTTOM_RESERVED := 196.0
const MIN_CHILD_OFFSET := 38.0
const SLOT_RADIUS := 30.0
const DROP_TOLERANCE := 78.0

const CABLE_IDLE := Color(0.25, 0.62, 1.0, 0.85)
const CABLE_OK := Color(0.25, 1.0, 0.6, 1.0)
const CABLE_BAD := Color(1.0, 0.28, 0.32, 1.0)
const CABLE_EXTRA := Color(0.65, 0.55, 1.0, 0.85)
const CABLE_PATH := Color(1.0, 0.82, 0.3, 1.0)
const EXTRA_BULGE := 34.0

var model: BSTModel = null

var _routers: Dictionary = {}          # float value -> RouterNode
var _positions: Dictionary = {}        # float value -> Vector2 (center)
var _depths: Dictionary = {}           # float value -> int
var _edges: Array = []                 # [{ "from": float, "to": float }]
var _edge_colors: Dictionary = {}      # "from>to" -> Color
var _slots: Array = []                 # [{ "parent": int, "side": String, "pos": Vector2 }]
var _flow: float = 0.0
var _slot_pulse: float = 0.0
var _flow_enabled: bool = true
var _level_height: float = LEVEL_HEIGHT_MAX
var graph: NetworkGraph = null         # attivo solo nella fase Dijkstra


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
	var center_x: float = size.x * 0.5
	_layout_recursive(model.root, center_x, 0)


func _child_offset(depth: int) -> float:
	return maxf(_tree_width() / pow(2.0, float(depth) + 2.0), MIN_CHILD_OFFSET)


func _layout_recursive(node: BSTModel.BSTNodeData, x: float, depth: int) -> void:
	_positions[node.value] = Vector2(x, TREE_TOP + float(depth) * _level_height)
	_depths[node.value] = depth
	var dx: float = _child_offset(depth)
	if node.left != null:
		_edges.append({"from": node.value, "to": node.left.value})
		_layout_recursive(node.left, x - dx, depth + 1)
	if node.right != null:
		_edges.append({"from": node.value, "to": node.right.value})
		_layout_recursive(node.right, x + dx, depth + 1)


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


func has_router(value: float) -> bool:
	return _routers.has(value)


func get_router(value: float) -> RouterNode:
	return _routers.get(value, null)


func all_routers() -> Array:
	return _routers.values()


# --------------------------------------------------------------- building ---

## Rebuilds routers from the model. Existing routers are re-used and tweened
## to their new position so the network never "jumps".
func rebuild(animate: bool = true) -> void:
	compute_layout()
	if model == null:
		return
	var live_values: Array[float] = model.values()

	# Remove routers that no longer exist in the model.
	for value in _routers.keys():
		if not live_values.has(value):
			var stale: RouterNode = _routers[value]
			_routers.erase(value)
			_dissolve(stale)

	for value in live_values:
		var target: Vector2 = _positions[value]
		if _routers.has(value):
			var router: RouterNode = _routers[value]
			if animate:
				router.move_to_center(target, 0.35)
			else:
				router.set_center(target)
		else:
			var new_router: RouterNode = _make_router(value)
			new_router.set_center(target)
			_routers[value] = new_router
	queue_redraw()


func adopt_router(router: RouterNode, value: float) -> void:
	## Takes an externally created router (e.g. dragged from the tray) into the network.
	_routers[value] = router
	if router.get_parent() != self:
		var global_pos: Vector2 = router.global_position
		if router.get_parent() != null:
			router.get_parent().remove_child(router)
		add_child(router)
		router.global_position = global_pos
	router.draggable = false
	router.z_index = 0


func _make_router(value: float) -> RouterNode:
	var router: RouterNode = RouterNode.new(value)
	add_child(router)
	router.set_value(value)
	return router


func _dissolve(router: RouterNode) -> void:
	router.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = router.create_tween()
	tween.set_parallel(true)
	tween.tween_property(router, "modulate:a", 0.0, 0.3)
	tween.tween_property(router, "scale", Vector2(1.6, 1.6), 0.3)
	tween.chain().tween_callback(router.queue_free)


func clear_all() -> void:
	for router in _routers.values():
		router.queue_free()
	_routers.clear()
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


## I cavi sono bidirezionali: cerca il colore in entrambi i versi.
func _edge_color_or(from_value: float, to_value: float, fallback: Color) -> Color:
	if _edge_colors.has(_edge_key(from_value, to_value)):
		return _edge_colors[_edge_key(from_value, to_value)]
	if _edge_colors.has(_edge_key(to_value, from_value)):
		return _edge_colors[_edge_key(to_value, from_value)]
	return fallback


# --------------------------------------------------------- grafo pesato ----

## Attiva la visualizzazione a grafo: cavi ridondanti curvi e costi sui cavi.
func set_graph(new_graph: NetworkGraph) -> void:
	graph = new_graph
	queue_redraw()


func clear_graph() -> void:
	graph = null
	queue_redraw()


## Evidenzia un cammino (sequenza di valori) come cavi dorati.
func highlight_path(path: Array[float], color: Color = CABLE_PATH) -> void:
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


# ---------------------------------------------------------------- packets ---

## Creates a packet visual at a given local position.
func spawn_packet(value: float, at_local: Vector2) -> Control:
	var packet: Control = Control.new()
	packet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	packet.size = Vector2(44.0, 44.0)
	packet.pivot_offset = Vector2(22.0, 22.0)
	packet.z_index = 150
	add_child(packet)

	var texture: TextureRect = TextureRect.new()
	texture.texture = load("res://assets/generated/data_packet_frame_0.png")
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.size = Vector2(44.0, 44.0)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	packet.add_child(texture)

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
	packet.add_child(label)

	packet.position = at_local - Vector2(22.0, 22.0)
	return packet


func move_packet(packet: Control, to_local: Vector2, duration: float = 0.5) -> void:
	if not is_instance_valid(packet):
		return
	var tween: Tween = packet.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(packet, "position", to_local - Vector2(22.0, 22.0), duration)
	await tween.finished


func destroy_packet(packet: Control, exploded: bool = false) -> void:
	if not is_instance_valid(packet):
		return
	var tween: Tween = packet.create_tween()
	tween.set_parallel(true)
	if exploded:
		tween.tween_property(packet, "modulate", Color(1.0, 0.2, 0.2, 0.0), 0.35)
		tween.tween_property(packet, "scale", Vector2(2.0, 2.0), 0.35)
		tween.tween_property(packet, "rotation", 1.2, 0.35)
	else:
		tween.tween_property(packet, "modulate:a", 0.0, 0.25)
		tween.tween_property(packet, "scale", Vector2(1.5, 1.5), 0.25)
	tween.chain().tween_callback(packet.queue_free)


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
	# Cables between routers.
	for i in range(_edges.size()):
		var edge: Dictionary = _edges[i]
		var from_value: float = float(edge["from"])
		var to_value: float = float(edge["to"])
		if not _positions.has(from_value) or not _positions.has(to_value):
			continue
		var a: Vector2 = _positions[from_value]
		var b: Vector2 = _positions[to_value]
		var color: Color = _edge_color_or(from_value, to_value, CABLE_IDLE)
		_draw_cable(a, b, color, float(i) * 0.31)

	# Modalità grafo: cavi ridondanti (curvi) e latenza scritta su ogni cavo.
	if graph != null:
		for link in graph.edges:
			var a_value: float = float(link["a"])
			var b_value: float = float(link["b"])
			if not _positions.has(a_value) or not _positions.has(b_value):
				continue
			var pa: Vector2 = _positions[a_value]
			var pb: Vector2 = _positions[b_value]
			var is_extra: bool = bool(link["extra"])
			var link_color: Color = _edge_color_or(a_value, b_value,
				CABLE_EXTRA if is_extra else CABLE_IDLE)
			var label_pos: Vector2 = (pa + pb) * 0.5
			if is_extra:
				label_pos = _draw_curved_cable(pa, pb, link_color)
			_draw_weight(label_pos, int(link["weight"]), link_color)

	# Ghost slots where a router can be dropped.
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


## Cavo ridondante: una curva, per distinguerlo dai cavi dell'albero e per
## non farlo passare sopra i router che stanno in mezzo.
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


## Etichetta con il costo del cavo, su una pastiglia scura per la leggibilità.
func _draw_weight(at: Vector2, weight: int, color: Color) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var text: String = str(weight)
	var font_size: int = 15
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size)
	var pad: Vector2 = Vector2(7.0, 3.0)
	var rect: Rect2 = Rect2(at - text_size * 0.5 - pad, text_size + pad * 2.0)
	draw_rect(rect, Color(0.03, 0.06, 0.12, 0.92), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.7), false, 1.5)
	draw_string(font, at + Vector2(-text_size.x * 0.5, text_size.y * 0.36), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.92, 0.97, 1.0))


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
