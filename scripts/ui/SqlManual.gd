class_name SqlManual
extends Control

## Manuale consultabile in sovraimpressione, alla maniera di
## "Keep Talking and Nobody Explodes": aprirlo costa tempo, quindi il
## giocatore deve decidere se vale la pena.
## Il costo viene addebitato una sola volta per apertura.

signal opened
signal closed

const COST_SECONDS := 10.0

var _pages: Array = []
var _page: int = 0

var _title: Label
var _body: RichTextLabel
var _page_label: Label
var _prev: Button
var _next: Button
var _close: Button

const MANUAL_PAGES: Array = [
	{
		"title": "MANUALE  ·  1. Leggere i dati (SELECT)",
		"body": """[b][color=#7fd8ff]Struttura di base[/color][/b]
[code]SELECT colonne FROM tabella WHERE condizione;[/code]
• [b]SELECT *[/b] → tutte le colonne.   • [b]SELECT nome, citta[/b] → solo quelle elencate.
• Le stringhe vanno fra apici singoli: [code]'Roma'[/code].  I numeri no: [code]30[/code].

[b][color=#7fd8ff]Confronti nel WHERE[/color][/b]
[code]=[/code] uguale   [code]!=[/code] diverso   [code]<[/code] [code]<=[/code] [code]>[/code] [code]>=[/code] confronti
[code]AND[/code] entrambe vere   [code]OR[/code] almeno una vera   [code]NOT[/code] nega   [code]( )[/code] raggruppa

[b][color=#7fd8ff]Filtri comodi[/color][/b]
[code]citta IN ('Roma', 'Milano')[/code]    appartiene all'elenco
[code]eta BETWEEN 25 AND 40[/code]          compreso fra due valori (estremi inclusi)
[code]nome LIKE 'M%'[/code]                 inizia per M   ([code]%[/code] = qualsiasi testo)
[code]nome LIKE '%ss%'[/code]               contiene ss

[b][color=#7fd8ff]Ordinare e limitare[/color][/b]
[code]ORDER BY eta[/code] crescente · [code]ORDER BY eta DESC[/code] decrescente · [code]LIMIT 3[/code] prime 3 righe

[b][color=#ffd166]Esempio completo[/color][/b]
[code]SELECT nome, eta FROM utenti WHERE citta = 'Roma' AND eta > 30 ORDER BY eta DESC;[/code]""",
	},
	{
		"title": "MANUALE  ·  2. Modificare i dati",
		"body": """[b][color=#7ffcc0]INSERT — aggiungere una riga[/color][/b]
[code]INSERT INTO tabella (col1, col2) VALUES (val1, val2);[/code]
Si può omettere l'elenco delle colonne, ma allora i valori devono seguire
l'ordine esatto della tabella:
[code]INSERT INTO utenti VALUES (6, 'Ivo', 'Torino', 51);[/code]

[b][color=#ffd166]UPDATE — modificare righe esistenti[/color][/b]
[code]UPDATE tabella SET colonna = valore WHERE condizione;[/code]
Più colonne insieme, separate da virgola:
[code]UPDATE utenti SET citta = 'Bari', eta = 30 WHERE id = 2;[/code]
Si possono usare espressioni che leggono il valore attuale:
[code]UPDATE utenti SET eta = eta + 1 WHERE citta = 'Roma';[/code]

[b][color=#ff9a9a]DELETE — eliminare righe[/color][/b]
[code]DELETE FROM tabella WHERE condizione;[/code]

[b][color=#ff9a9a]ATTENZIONE[/color][/b]
Senza [b]WHERE[/b], UPDATE e DELETE agiscono su [b]TUTTE[/b] le righe della
tabella. È l'errore più costoso che si possa fare su un database reale.""",
	},
	{
		"title": "MANUALE  ·  3. Tabelle e tipi",
		"body": """[b][color=#7fd8ff]CREATE TABLE — creare una tabella[/color][/b]
[code]CREATE TABLE nome (
    colonna1 TIPO,
    colonna2 TIPO
);[/code]
Esempio:
[code]CREATE TABLE prodotti (id INT, nome VARCHAR(50), prezzo INT);[/code]

[b][color=#ff9a9a]DROP TABLE — eliminare una tabella[/color][/b]
[code]DROP TABLE prodotti;[/code]
Elimina la struttura [i]e[/i] tutti i dati che conteneva.

[b][color=#7fd8ff]Tipi principali[/color][/b]
[code]INT[/code]           numeri interi
[code]VARCHAR(n)[/code]    testo di lunghezza variabile, massimo n caratteri
[code]DECIMAL(a,b)[/code]  numeri con virgola
[code]DATE[/code]          data nel formato 'AAAA-MM-GG'
[code]BOOLEAN[/code]       vero / falso

[b][color=#7fd8ff]Funzioni di aggregazione[/color][/b]
[code]COUNT(*)[/code] quante righe · [code]SUM(col)[/code] somma · [code]AVG(col)[/code] media
[code]MIN(col)[/code] minimo · [code]MAX(col)[/code] massimo
[code]SELECT COUNT(*) FROM utenti WHERE citta = 'Roma';[/code]""",
	},
	{
		"title": "MANUALE  ·  4. Query nidificate (subquery)",
		"body": """Una [b]subquery[/b] è una query scritta fra parentesi dentro un'altra query:
il database la esegue prima e ne usa il risultato.

[b][color=#c0a8ff]Subquery scalare (restituisce UN valore)[/color][/b]
Si usa dove servirebbe un numero, tipicamente in un confronto:
[code]SELECT nome FROM utenti
WHERE eta > (SELECT AVG(eta) FROM utenti);[/code]
Prima calcola la media, poi filtra chi la supera. Senza subquery non
potresti farlo in una sola query: il valore medio non è noto in anticipo.

[b][color=#c0a8ff]Subquery con IN (restituisce un ELENCO)[/color][/b]
[code]SELECT nome FROM utenti
WHERE id IN (SELECT utente_id FROM ordini);[/code]
Legge tutti gli utente_id presenti in ordini e tiene gli utenti che vi
compaiono: sono gli utenti che hanno almeno un ordine.

Con [b]NOT IN[/b] ottieni l'opposto, cioè chi non compare nell'elenco:
[code]SELECT nome FROM utenti
WHERE id NOT IN (SELECT utente_id FROM ordini);[/code]

[b][color=#ffd166]Regola pratica[/color][/b]
La subquery interna deve restituire [b]una sola colonna[/b]. Un valore solo
per i confronti ([code]=[/code], [code]>[/code], [code]<[/code]), una colonna intera per [code]IN[/code].""",
	},
]


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_pages = MANUAL_PAGES
	_build()


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.05, 0.93)
	add_child(dim)

	var frame: PanelContainer = PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 90.0
	frame.offset_top = 44.0
	frame.offset_right = -90.0
	frame.offset_bottom = -44.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.045, 0.03, 0.99)
	style.border_color = Color(0.85, 0.7, 0.35, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	frame.add_theme_stylebox_override("panel", style)
	add_child(frame)

	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	frame.add_child(box)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	box.add_child(_title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 16)
	_body.add_theme_font_size_override("bold_font_size", 16)
	_body.add_theme_font_size_override("italics_font_size", 16)
	_body.add_theme_font_size_override("mono_font_size", 16)
	_body.add_theme_color_override("default_color", Color(0.92, 0.9, 0.84))
	scroll.add_child(_body)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)

	_prev = Button.new()
	_prev.text = "◀  Indietro"
	_prev.custom_minimum_size = Vector2(150.0, 46.0)
	_prev.focus_mode = Control.FOCUS_NONE
	SqlConsole._style_button(_prev, Color(0.24, 0.18, 0.06), Color(0.85, 0.7, 0.35))
	_prev.pressed.connect(func(): _show_page(_page - 1))
	footer.add_child(_prev)

	_next = Button.new()
	_next.text = "Avanti  ▶"
	_next.custom_minimum_size = Vector2(150.0, 46.0)
	_next.focus_mode = Control.FOCUS_NONE
	SqlConsole._style_button(_next, Color(0.24, 0.18, 0.06), Color(0.85, 0.7, 0.35))
	_next.pressed.connect(func(): _show_page(_page + 1))
	footer.add_child(_next)

	_page_label = Label.new()
	_page_label.add_theme_font_size_override("font_size", 17)
	_page_label.add_theme_color_override("font_color", Color(0.8, 0.72, 0.55))
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(_page_label)

	_close = Button.new()
	_close.text = "Chiudi  (Esc)"
	_close.custom_minimum_size = Vector2(190.0, 46.0)
	_close.focus_mode = Control.FOCUS_NONE
	SqlConsole._style_button(_close, Color(0.1, 0.4, 0.3), Color(0.35, 1.0, 0.7))
	_close.pressed.connect(close)
	footer.add_child(_close)


func open_at(page: int = 0) -> void:
	visible = true
	_show_page(page)
	opened.emit()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _show_page(index: int) -> void:
	_page = clampi(index, 0, _pages.size() - 1)
	_title.text = String(_pages[_page]["title"])
	_body.text = String(_pages[_page]["body"])
	_page_label.text = "pagina %d di %d" % [_page + 1, _pages.size()]
	_prev.disabled = _page == 0
	_next.disabled = _page == _pages.size() - 1


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			_show_page(_page + 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT:
			_show_page(_page - 1)
			get_viewport().set_input_as_handled()
