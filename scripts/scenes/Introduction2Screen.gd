extends Control

## Introduzione teorica del Livello 2: dai concetti di base del modello
## relazionale fino alle query nidificate. Il livello parte solo dopo
## l'ultima pagina.

const PAGES: Array = [
	{
		"title": "1 · Il modello relazionale",
		"body": """[b][color=#7fd8ff]Che cos'è un database relazionale?[/color][/b]
I dati sono organizzati in [b]tabelle[/b]. Ogni tabella ha delle [b]colonne[/b] (i campi, ognuno con un tipo) e delle [b]righe[/b] (i record, cioè i dati veri e propri).

[b][color=#7fd8ff]Lo schema di questo livello[/color][/b]
[code]clienti (id, nome, citta, eta)[/code]  ·  l'anagrafica dei clienti
[code]ordini (id, cliente_id, totale)[/code]  ·  gli acquisti
[code]temp_backup (id, nota)[/code]  ·  spazzatura lasciata dall'attacco

[b][color=#7fd8ff]Le relazioni[/color][/b]
La colonna [code]id[/code] di [b]clienti[/b] è la [b]chiave primaria[/b]: identifica una riga in modo univoco.
La colonna [code]cliente_id[/code] di [b]ordini[/b] è una [b]chiave esterna[/b]: punta all'id di un cliente.
È questo collegamento a rendere il database "relazionale" e a permetterti di rispondere a domande come «quali clienti hanno almeno un ordine?».

[b][color=#7fd8ff]Il linguaggio[/color][/b]
Al database si parla in [b]SQL[/b]. Ogni comando è una frase che finisce con [code];[/code] e non distingue maiuscole da minuscole: [code]SELECT[/code] e [code]select[/code] sono la stessa cosa.""",
	},
	{
		"title": "2 · Leggere i dati: SELECT",
		"body": """[b][color=#7fd8ff]La forma base[/color][/b]
[code]SELECT colonne FROM tabella WHERE condizione;[/code]
[code]SELECT * FROM clienti;[/code] → tutte le colonne di tutte le righe
[code]SELECT nome, citta FROM clienti;[/code] → solo le due colonne indicate

[b][color=#7fd8ff]Il filtro WHERE[/color][/b]
Decide [b]quali righe[/b] tenere. Il testo va fra apici singoli, i numeri no:
[code]WHERE citta = 'Roma'[/code]      [code]WHERE eta > 30[/code]
Operatori: [code]=[/code]  [code]!=[/code]  [code]<[/code]  [code]<=[/code]  [code]>[/code]  [code]>=[/code]   ·   combinazioni: [code]AND[/code]  [code]OR[/code]  [code]NOT[/code]  [code]( )[/code]

[b][color=#7fd8ff]Filtri comodi[/color][/b]
[code]citta IN ('Roma','Milano')[/code]  appartiene all'elenco
[code]eta BETWEEN 25 AND 40[/code]  compreso fra i due valori (inclusi)
[code]nome LIKE 'M%'[/code]  inizia per M   ·   [code]LIKE '%ss%'[/code]  contiene ss

[b][color=#7fd8ff]Ordinare, limitare, contare[/color][/b]
[code]ORDER BY eta[/code] crescente · [code]ORDER BY eta DESC[/code] decrescente · [code]LIMIT 3[/code] solo 3 righe
[code]COUNT(*)[/code] quante righe · [code]SUM[/code] · [code]AVG[/code] · [code]MIN[/code] · [code]MAX[/code]
[code]SELECT COUNT(*) FROM clienti WHERE citta = 'Milano';[/code]""",
	},
	{
		"title": "3 · Modificare i dati",
		"body": """[b][color=#7ffcc0]INSERT — aggiungere una riga[/color][/b]
[code]INSERT INTO clienti (id, nome, citta, eta) VALUES (6, 'Ivo', 'Torino', 51);[/code]
Puoi omettere l'elenco delle colonne, ma allora i valori devono rispettare
[b]esattamente l'ordine[/b] delle colonne della tabella:
[code]INSERT INTO clienti VALUES (6, 'Ivo', 'Torino', 51);[/code]

[b][color=#ffd166]UPDATE — modificare righe esistenti[/color][/b]
[code]UPDATE clienti SET citta = 'Bologna' WHERE id = 2;[/code]
Più colonne insieme, separate da virgola. Nel SET puoi partire dal valore
attuale della colonna:
[code]UPDATE clienti SET eta = eta + 1 WHERE citta = 'Roma';[/code]

[b][color=#ff9a9a]DELETE — eliminare righe[/color][/b]
[code]DELETE FROM ordini WHERE id = 2;[/code]

[b][color=#ff9a9a]La regola che salva la carriera[/color][/b]
Senza [b]WHERE[/b], UPDATE e DELETE agiscono su [b]TUTTE[/b] le righe della tabella.
[code]DELETE FROM clienti;[/code] cancella l'intera anagrafica, senza chiedere conferma.
Prima di eseguire una modifica, prova la stessa condizione con una SELECT.""",
	},
	{
		"title": "4 · Tabelle e tipi di dato",
		"body": """[b][color=#7fd8ff]CREATE TABLE — creare la struttura[/color][/b]
[code]CREATE TABLE prodotti (
    id INT,
    nome VARCHAR(40),
    prezzo INT
);[/code]
La tabella nasce [b]vuota[/b]: la struttura (le colonne) è una cosa, i dati
(le righe) un'altra. Dopo la CREATE servono le INSERT.

[b][color=#ff9a9a]DROP TABLE — eliminare la struttura[/color][/b]
[code]DROP TABLE prodotti;[/code]
Differenza fondamentale:
• [code]DELETE FROM prodotti;[/code] → svuota la tabella, che resta esistente
• [code]DROP TABLE prodotti;[/code] → la tabella [b]scompare[/b] con tutti i suoi dati

[b][color=#7fd8ff]I tipi principali[/color][/b]
[code]INT[/code] numeri interi   ·   [code]VARCHAR(n)[/code] testo fino a n caratteri
[code]DECIMAL(a,b)[/code] numeri con virgola   ·   [code]DATE[/code] date ('AAAA-MM-GG')
[code]BOOLEAN[/code] vero/falso
Il tipo serve al database per validare i dati e per occupare meno spazio.""",
	},
	{
		"title": "5 · Query nidificate (subquery)",
		"body": """Una [b]subquery[/b] è una SELECT scritta fra parentesi dentro un'altra query.
Il database la esegue [b]prima[/b] e poi usa il suo risultato. Serve quando il
valore che ti occorre [b]non lo conosci in anticipo[/b]: deve calcolarlo il database.

[b][color=#c0a8ff]Subquery scalare — restituisce UN valore[/color][/b]
[code]SELECT nome, eta FROM clienti
WHERE eta > (SELECT AVG(eta) FROM clienti);[/code]
Prima calcola l'età media, poi tiene chi la supera. Senza subquery dovresti
fare due query separate e copiare il numero a mano.

[b][color=#c0a8ff]Subquery con IN — restituisce un ELENCO[/color][/b]
[code]SELECT nome FROM clienti
WHERE id IN (SELECT cliente_id FROM ordini);[/code]
La subquery produce tutti i cliente_id presenti in ordini; [code]IN[/code] tiene i
clienti che compaiono in quell'elenco: sono quelli che hanno almeno un ordine.
Con [code]NOT IN[/code] ottieni l'opposto: i clienti senza nessun ordine.

[b][color=#ffd166]Regola pratica[/color][/b]
La subquery deve restituire [b]una sola colonna[/b]: un valore singolo per i
confronti ([code]=[/code], [code]>[/code], [code]<[/code]), una colonna intera per [code]IN[/code]. Può avere il suo WHERE.""",
	},
	{
		"title": "6 · La missione",
		"body": """[b][color=#ff8f8f]Database Recovery[/color][/b]
Il database della LearnIT Corp è stato attaccato. Hai [b]9 MINUTI[/b] per rimetterlo in sesto scrivendo query nella console. A cronometro scaduto la partita è persa.
Le tabelle sono sempre visibili in alto: guardale, ti dicono colonne, tipi e dati.

[b][color=#7fd8ff]FASE 1 · Interrogazione[/color][/b]  Leggere i dati: SELECT, WHERE, ORDER BY, COUNT.
[b][color=#7ffcc0]FASE 2 · Ricostruzione[/color][/b]  Ricreare la tabella perduta e reinserire i record: CREATE TABLE, INSERT.
[b][color=#ffd166]FASE 3 · Correzione[/color][/b]  Sistemare i dati sbagliati: UPDATE ... SET ... WHERE.
[b][color=#ff9a9a]FASE 4 · Bonifica[/color][/b]  Rimuovere record e tabelle spazzatura: DELETE, DROP TABLE.
[b][color=#c0a8ff]FASE 5 · Query nidificate[/color][/b]  Rispondere a domande che richiedono una subquery.

[b][color=#ffd166]IL MANUALE[/color][/b]
In alto c'è il pulsante [b]MANUALE[/b]: apre la sintassi completa in sovraimpressione,
ma [b]costa 10 secondi di cronometro ogni volta che lo apri[/b]. Usalo quando serve
davvero, non a ogni dubbio.

[b][color=#7fd8ff]Penalità[/color][/b]  Query con errore di sintassi [b]-8 s[/b]  ·  query valida ma che non risolve l'obiettivo [b]-12 s[/b].
[b][color=#7fd8ff]Comandi[/color][/b]  Scrivi nella console e premi [b]Esegui[/b] oppure [b]Ctrl+Invio[/b].""",
	},
]

@onready var body: RichTextLabel = $Body
@onready var title_label: Label = $PageTitle
@onready var next_button: Button = $NextButton
@onready var back_button: Button = $BackButton
@onready var page_label: Label = $PageLabel

var _page: int = 0


func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_show_page(0)
	next_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_next_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _show_page(index: int) -> void:
	_page = clampi(index, 0, PAGES.size() - 1)
	title_label.text = String(PAGES[_page]["title"])
	body.text = String(PAGES[_page]["body"])
	page_label.text = "%d / %d" % [_page + 1, PAGES.size()]
	back_button.visible = _page > 0
	var is_last: bool = _page == PAGES.size() - 1
	next_button.text = "Inizia la missione  ▶" if is_last else "Avanti  ▶"
	body.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(body, "modulate:a", 1.0, 0.25)


func _on_next_pressed() -> void:
	if _page < PAGES.size() - 1:
		Sfx.play("click")
		_show_page(_page + 1)
	else:
		Sfx.play("correct")
		GameManager.go_to_level_2()


func _on_back_pressed() -> void:
	if _page > 0:
		Sfx.play("click")
		_show_page(_page - 1)
