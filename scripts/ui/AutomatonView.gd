class_name AutomatonView
extends Control

## Disegna un automa: stati in fila e archi etichettati con i simboli.
##
## Gli archi stanno in un Control FIGLIO creato per primo, perché in Godot il
## genitore disegna prima dei figli: così le frecce restano sotto i cerchi.

signal state_clicked(state_name: String)

const CABLE := Color(0.30, 0.55, 0.85, 0.75)
const CABLE_ACTIVE := Color(1.00, 0.80, 0.30)
const CABLE_OK := Color(0.35, 1.00, 0.60)
const CABLE_BAD := Color(1.00, 0.40, 0.42)

var automaton: Automaton = null
var nodes: Dictionary = {}                 # nome stato -> StateNode

var _edges_layer: Control = null
var _edge_colors: Dictionary = {}          # "da|a" -> Color
var _row_y: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_edges_layer = Control.new()
	_edges_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_edges_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_edges_layer.draw.connect(_draw_edges)
	add_child(_edges_layer)


func setup(model: Automaton) -> void:
	automaton = model
	for node in nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	nodes.clear()
	_edge_colors.clear()

	for state in automaton.states:
		var node: StateNode = StateNode.new(state)
		node.is_start = (state == automaton.start_state)
		node.is_accepting = automaton.is_accepting(state)
		node.clicked.connect(_on_state_clicked)
		add_child(node)
		nodes[state] = node

	relayout()


## Stati in fila orizzontale: è la disposizione più leggibile per gli automi
## didattici, perché segue l'ordine in cui si attraversano.
func relayout() -> void:
	if automaton == null or nodes.is_empty():
		return
	var count: int = automaton.states.size()
	var spacing: float = minf(190.0, (size.x - 220.0) / maxf(float(count - 1), 1.0))
	var start_x: float = size.x * 0.5 - float(count - 1) * spacing * 0.5
	_row_y = size.y * 0.42
	for i in range(count):
		var node: StateNode = nodes[automaton.states[i]]
		node.move_center_to(Vector2(start_x + float(i) * spacing, _row_y))
	queue_redraw()
	if _edges_layer != null:
		_edges_layer.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		relayout()


func get_node_for(state: String) -> StateNode:
	return nodes.get(state, null)


func center_of(state: String) -> Vector2:
	var node: StateNode = get_node_for(state)
	return node.center() if node != null else Vector2.ZERO


func set_clickable(enabled: bool) -> void:
	for node in nodes.values():
		node.clickable = enabled


func set_all_modes(mode: StateNode.Mode) -> void:
	for node in nodes.values():
		node.set_mode(mode)
		node.set_pulsing(false)


func set_mode(state: String, mode: StateNode.Mode) -> void:
	var node: StateNode = get_node_for(state)
	if node != null:
		node.set_mode(mode)


## Evidenzia l'insieme degli stati attivi (serve alla simulazione dell'NFA).
func highlight_set(state_set: Array, mode: StateNode.Mode = StateNode.Mode.ACTIVE) -> void:
	for state in nodes.keys():
		var node: StateNode = nodes[state]
		if state_set.has(state):
			node.set_mode(mode)
			node.set_pulsing(true)
		else:
			node.set_mode(StateNode.Mode.DIM)
			node.set_pulsing(false)


func set_edge_color(from_state: String, to_state: String, color: Color) -> void:
	_edge_colors[from_state + "|" + to_state] = color
	_edges_layer.queue_redraw()


func reset_edges() -> void:
	_edge_colors.clear()
	_edges_layer.queue_redraw()


func _on_state_clicked(node: StateNode) -> void:
	state_clicked.emit(node.label_text)


# ----------------------------------------------------------- disegno archi --

func _draw_edges() -> void:
	if automaton == null:
		return
	# Raggruppa i simboli che collegano la stessa coppia di stati.
	var grouped: Dictionary = {}               # "da|a" -> Array[String]
	for key in automaton.transitions.keys():
		var parts: PackedStringArray = String(key).split("|")
		if parts.size() != 2:
			continue
		var from_state: String = parts[0]
		var symbol: String = parts[1]
		for to_state in automaton.transitions[key]:
			var pair: String = from_state + "|" + String(to_state)
			if not grouped.has(pair):
				grouped[pair] = []
			grouped[pair].append(symbol)

	for pair in grouped.keys():
		var ends: PackedStringArray = String(pair).split("|")
		var label: String = ", ".join(PackedStringArray(grouped[pair]))
		var color: Color = _edge_colors.get(pair, CABLE)
		if ends[0] == ends[1]:
			_draw_self_loop(center_of(ends[0]), label, color)
		else:
			_draw_arc_between(center_of(ends[0]), center_of(ends[1]), label, color)


func _draw_self_loop(middle: Vector2, label: String, color: Color) -> void:
	var top: Vector2 = middle - Vector2(0.0, 30.0)
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(25):
		var angle: float = PI * 0.15 + (TAU * 0.7) * float(i) / 24.0
		points.append(top + Vector2(cos(angle) * 26.0, -sin(angle) * 24.0 - 12.0))
	_edges_layer.draw_polyline(points, color, 2.5, true)
	_draw_arrow_head(points[points.size() - 1], points[points.size() - 2], color)
	_draw_label(top + Vector2(0.0, -50.0), label, color)


func _draw_arc_between(from_point: Vector2, to_point: Vector2, label: String, color: Color) -> void:
	if from_point == Vector2.ZERO or to_point == Vector2.ZERO:
		return
	var direction: Vector2 = (to_point - from_point).normalized()
	var start_point: Vector2 = from_point + direction * 30.0
	var end_point: Vector2 = to_point - direction * 34.0
	# Le due direzioni si curvano da parti opposte, così restano entrambe visibili.
	var bulge: float = -46.0 if to_point.x > from_point.x else 46.0
	var middle: Vector2 = (start_point + end_point) * 0.5 + Vector2(0.0, bulge)

	var points: PackedVector2Array = PackedVector2Array()
	for i in range(21):
		var t: float = float(i) / 20.0
		points.append(start_point.lerp(middle, t).lerp(middle.lerp(end_point, t), t))
	_edges_layer.draw_polyline(points, color, 2.5, true)
	_draw_arrow_head(points[points.size() - 1], points[points.size() - 2], color)
	_draw_label(middle + Vector2(0.0, -6.0 if bulge < 0.0 else 14.0), label, color)


func _draw_arrow_head(tip: Vector2, previous: Vector2, color: Color) -> void:
	var direction: Vector2 = (tip - previous).normalized()
	var side: Vector2 = Vector2(-direction.y, direction.x)
	_edges_layer.draw_colored_polygon(PackedVector2Array([
		tip,
		tip - direction * 12.0 + side * 5.5,
		tip - direction * 12.0 - side * 5.5,
	]), color)


func _draw_label(at: Vector2, text: String, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_edges_layer.draw_string(font, at - Vector2(width * 0.5, 0.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(color.r, color.g, color.b, 1.0))
