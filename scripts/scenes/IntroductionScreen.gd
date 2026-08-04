extends Control

## Schermata introduttiva del Livello 1, divisa in tre pagine:
##   1. che cos'è un BST e la regola d'oro
##   2. come si cerca (esito positivo e negativo) e le quattro visite
##   3. la missione, le fasi, i comandi e le penalità
## Il livello parte solo dopo l'ultima pagina.

const DIAGRAM_NODES: Dictionary = {
	50.0: Vector2(976.0, 232.0),
	25.5: Vector2(864.0, 332.0),
	74.5: Vector2(1088.0, 332.0),
	12.8: Vector2(808.0, 442.0),
	37.2: Vector2(920.0, 442.0),
	62.4: Vector2(1032.0, 442.0),
	88.6: Vector2(1144.0, 442.0),
}

const DIAGRAM_EDGES: Array = [
	[50.0, 25.5], [50.0, 74.5], [25.5, 12.8], [25.5, 37.2], [74.5, 62.4], [74.5, 88.6],
]

const NODE_RADIUS := 29.0

const CARD_RIGHT_NARROW := 700.0
const CARD_RIGHT_WIDE := 1236.0
const BODY_RIGHT_NARROW := 678.0
const BODY_RIGHT_WIDE := 1212.0

## Ogni pagina: titolo del diagramma, nota sotto il diagramma, corpo BBCode.
const PAGES: Array = [
	{
		"diagram": true,
		"diagram_title": "La rete di esempio",
		"diagram_note": "Ogni cerchio è un router. Il numero è la sua metrica.",
		"body": """[b][color=#7fd8ff]Che cos'è un Binary Search Tree?[/color][/b]
La rete è organizzata come un [b]albero[/b]. Ogni [b]router[/b] (nodo) contiene una metrica numerica e ha al massimo due cavi in uscita: uno verso sinistra e uno verso destra. In cima c'è la [b]radice[/b], il router principale.

[b][color=#7fd8ff]La regola d'oro[/color][/b]
Per [b]ogni[/b] router della rete, senza eccezioni:
• le metriche [b][color=#66c8ff]MINORI[/color][/b] finiscono nel sottoalbero [b][color=#66c8ff]SINISTRO[/color][/b];
• le metriche [b][color=#66ffb0]MAGGIORI[/color][/b] finiscono nel sottoalbero [b][color=#66ffb0]DESTRO[/color][/b].

[b][color=#7fd8ff]Non vale solo per la radice[/color][/b]
Guarda il diagramma: sotto 25.5 trovi 12.8 (minore di 25.5) e 37.2 (maggiore di 25.5). Ma entrambi restano anche [i]minori di 50[/i], perché stanno tutti nel sottoalbero sinistro della radice. La regola si applica a cascata, a ogni livello.

[b][color=#7fd8ff]Conseguenza importante[/color][/b]
Leggendo i router da sinistra a destra, le metriche escono già [b]ordinate[/b]:
[color=#8fe3ff]12.8  ·  25.5  ·  37.2  ·  50  ·  62.4  ·  74.5  ·  88.6[/color]""",
	},
	{
		"diagram": true,
		"diagram_title": "Cercare 37.2 sulla rete",
		"diagram_note": "Due confronti (50, poi 25.5) e sei arrivato: gli altri 4 router non li hai nemmeno guardati.",
		"body": """[b][color=#7fd8ff]Cercare è velocissimo[/color][/b]
Per trovare la metrica [b]37.2[/b] non serve controllare tutti i router: parti dalla radice e a ogni passo fai [b]un solo confronto[/b]. Se il valore cercato è [b]minore[/b] scendi a [b]SINISTRA[/b], se è [b]maggiore[/b] scendi a [b]DESTRA[/b].

Esempio: 37.2 < 50 → sinistra; 37.2 > 25.5 → destra. Trovato in [b]2 confronti[/b] invece di 7 router. Ogni confronto butta via metà rete: il costo dipende dall'[b]altezza[/b] dell'albero, non dal numero di nodi.

[b][color=#ffd166]E se il valore non esiste?[/color][/b]
Cerchiamo [b]26.0[/b]: sinistra (26 < 50), destra (26 > 25.5), sinistra (26 < 37.2)... ma da 37.2 [b]non parte nessun cavo a sinistra[/b]. È un [b]vicolo cieco[/b]: 26.0 non è in rete, scoperto in soli 3 confronti.

[b][color=#7fd8ff]Le quattro visite (scansioni)[/color][/b]
• [b]Preorder[/b]: nodo → sinistra → destra
• [b]Inorder[/b]: sinistra → nodo → destra [i](restituisce i valori ordinati)[/i]
• [b]Postorder[/b]: sinistra → destra → nodo
• [b]BFS[/b]: un livello alla volta, dall'alto in basso e da sinistra a destra""",
	},
	{
		"diagram": false,
		"diagram_title": "",
		"diagram_note": "",
		"body": """[b][color=#ff8f8f]La tua missione[/color][/b]
Un hacker ha smontato la rete di router. Hai [b]5 MINUTI[/b] per rimetterla in piedi: se il cronometro arriva a zero la partita è persa e potrai ricominciare o tornare al menu.

[b][color=#7fd8ff]FASE 1 · Ricostruzione[/color][/b]  All'inizio è online solo la radice: [b]trascina[/b] gli 8 router nelle postazioni libere (i cerchi tratteggiati). Posizione giusta → il cavo diventa verde e il router si fissa; posizione sbagliata → il router torna indietro e perdi [b]5 secondi[/b].

[b][color=#7fd8ff]FASE 2 · Instradamento[/color][/b]  7 pacchetti da consegnare: a ogni router scegli [b]SINISTRA[/b] o [b]DESTRA[/b]. Alcune destinazioni [b]non esistono[/b] in rete: quando riconosci il vicolo cieco premi [b]NON IN RETE[/b]. Errore: pacchetto perso e [b]-12 secondi[/b].

[b][color=#7fd8ff]FASE 3 · Scansione[/color][/b]  Visita estratta a caso (Preorder, Inorder, Postorder o BFS): [b]clicca i router nell'ordine giusto[/b]. Tre round, e dal secondo la regola non viene più mostrata. Errore: [b]-10 secondi[/b].

[b][color=#ff8f8f]FASE 4 · Attacco finale[/color][/b]  7 richieste rapide e casuali: [b]inserisci[/b] un router, [b]elimina[/b] quello compromesso, [b]instrada[/b] un pacchetto, trova il [b]minimo[/b], il [b]massimo[/b] o il [b]successore[/b]. Errore: [b]-15 secondi[/b].

[b][color=#7fd8ff]Comandi[/color][/b]  Mouse per trascinare e cliccare  ·  [b]←[/b] e [b]→[/b] per instradare  ·  [b]↓[/b] per dichiarare che il valore non è in rete.
[b][color=#ffd166]Occhio ai decimali![/color][/b]  [b]25.5[/b] e [b]25.9[/b] finiscono in due punti completamente diversi della rete.""",
	},
]

@onready var body: RichTextLabel = $Body
@onready var card: Panel = $Card
@onready var diagram: Control = $Diagram
@onready var diagram_title: Label = $DiagramTitle
@onready var diagram_note: Label = $DiagramNote
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton
@onready var page_label: Label = $PageLabel

var _time: float = 0.0
var _page: int = 0


func _ready() -> void:
	diagram.draw.connect(_on_diagram_draw)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_build_diagram_labels()
	_show_page(0)
	next_button.grab_focus()
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	if diagram.visible:
		diagram.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_next_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _show_page(index: int) -> void:
	_page = clampi(index, 0, PAGES.size() - 1)
	var page: Dictionary = PAGES[_page]

	body.text = String(page["body"])
	var show_diagram: bool = bool(page["diagram"])
	diagram.visible = show_diagram
	diagram_title.visible = show_diagram
	diagram_note.visible = show_diagram
	diagram_title.text = String(page["diagram_title"])
	diagram_note.text = String(page["diagram_note"])

	card.offset_right = CARD_RIGHT_NARROW if show_diagram else CARD_RIGHT_WIDE
	body.offset_right = BODY_RIGHT_NARROW if show_diagram else BODY_RIGHT_WIDE

	back_button.visible = _page > 0
	page_label.text = "%d / %d" % [_page + 1, PAGES.size()]
	var is_last: bool = _page == PAGES.size() - 1
	next_button.text = "Inizia la missione  ▶" if is_last else "Avanti  ▶"

	# Piccola dissolvenza a ogni cambio pagina.
	body.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(body, "modulate:a", 1.0, 0.25)


func _on_next_pressed() -> void:
	if _page < PAGES.size() - 1:
		Sfx.play("click")
		_show_page(_page + 1)
	else:
		Sfx.play("correct")
		GameManager.go_to_level()


func _on_back_pressed() -> void:
	if _page > 0:
		Sfx.play("click")
		_show_page(_page - 1)


func _build_diagram_labels() -> void:
	for value in DIAGRAM_NODES:
		var label: Label = Label.new()
		label.text = BSTModel.fmt(value)
		label.size = Vector2(60.0, 26.0)
		label.position = DIAGRAM_NODES[value] - Vector2(30.0, 13.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		diagram.add_child(label)

	_add_caption("minori  <  50", Vector2(724.0, 276.0), Color(0.4, 0.85, 1.0))
	_add_caption("maggiori  >  50", Vector2(1076.0, 276.0), Color(0.4, 1.0, 0.65))


func _add_caption(text: String, pos: Vector2, color: Color) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.03, 0.08))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diagram.add_child(label)


## Il percorso di ricerca evidenziato nella pagina 2 (50 → 25.5 → 37.2).
func _search_path_edges() -> Array:
	return [[50.0, 25.5], [25.5, 37.2]]


func _on_diagram_draw() -> void:
	var highlight: Array = _search_path_edges() if _page == 1 else []

	for edge in DIAGRAM_EDGES:
		var a: Vector2 = DIAGRAM_NODES[edge[0]]
		var b: Vector2 = DIAGRAM_NODES[edge[1]]
		var dir: Vector2 = (b - a).normalized()
		var start: Vector2 = a + dir * NODE_RADIUS
		var end: Vector2 = b - dir * NODE_RADIUS

		var on_path: bool = false
		for h in highlight:
			if is_equal_approx(h[0], edge[0]) and is_equal_approx(h[1], edge[1]):
				on_path = true
		var color: Color = Color(0.3, 0.7, 1.0) if b.x < a.x else Color(0.3, 1.0, 0.65)
		if _page == 1:
			color = Color(1.0, 0.85, 0.35) if on_path else Color(0.28, 0.45, 0.62)

		diagram.draw_line(start, end, Color(color.r, color.g, color.b, 0.25), 8.0, true)
		diagram.draw_line(start, end, color, 3.0 if on_path else 2.5, true)
		var t: float = fposmod(_time * 0.4 + float(edge[1]) * 0.013, 1.0)
		diagram.draw_circle(start.lerp(end, t), 4.0, Color(color.r, color.g, color.b, sin(t * PI)))

	for value in DIAGRAM_NODES:
		var pos: Vector2 = DIAGRAM_NODES[value]
		var color: Color = Color(0.35, 0.75, 1.0)
		if is_equal_approx(value, 50.0):
			color = Color(0.4, 1.0, 0.75)
		if _page == 1:
			var visited: bool = is_equal_approx(value, 50.0) or is_equal_approx(value, 25.5)
			var found: bool = is_equal_approx(value, 37.2)
			if found:
				color = Color(0.35, 1.0, 0.6)
			elif visited:
				color = Color(1.0, 0.85, 0.35)
			else:
				color = Color(0.3, 0.45, 0.6)
		var pulse: float = (sin(_time * 2.4 + value * 0.2) * 0.5 + 0.5)
		diagram.draw_circle(pos, NODE_RADIUS + 7.0, Color(color.r, color.g, color.b, 0.10 + pulse * 0.09))
		diagram.draw_circle(pos, NODE_RADIUS, Color(0.06, 0.12, 0.22, 0.97))
		diagram.draw_arc(pos, NODE_RADIUS, 0.0, TAU, 48, color, 2.5, true)
