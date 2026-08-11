extends Control

## Introduzione teorica del Livello 3: dai riconoscitori più semplici (automi)
## fino ai limiti del calcolo (indecidibilità) e ai modelli equivalenti
## (funzioni ricorsive, linguaggio WHILE).

const PAGES: Array = [
	{
		"title": "1 · Automi di riconoscimento",
		"body": """Un [b]automa a stati finiti[/b] è la macchina più semplice che sappia dire [b]sì[/b] o [b]no[/b] a una parola. Ha una memoria minima: sa solo in quale [b]stato[/b] si trova.

[b][color=#7fd8ff]Come è fatto[/color][/b]
Un insieme di [b]stati[/b], un [b]alfabeto[/b] di simboli, uno [b]stato iniziale[/b] (freccia entrante), uno o più [b]stati finali[/b] (doppio cerchio) e una [b]funzione di transizione[/b] δ che dice dove si va.

[b][color=#7fd8ff]Come si esegue[/color][/b]
Si parte dallo stato iniziale e si legge la parola [b]un simbolo alla volta[/b], seguendo ogni volta la freccia etichettata con quel simbolo. La parola è [b]accettata[/b] se lo stato in cui si finisce è finale, [b]rifiutata[/b] altrimenti.

[b][color=#7fd8ff]Deterministico (DFA)[/color][/b]
Da ogni stato, per ogni simbolo, parte [b]esattamente una[/b] freccia. Non c'è mai scelta: l'esecuzione è un cammino unico. Per questo un DFA si può eseguire con un dito sul disegno.

[b][color=#ffd166]Che cosa riconosce[/color][/b]
L'insieme delle parole accettate è il [b]linguaggio[/b] dell'automa. Sono i [b]linguaggi regolari[/b]: «numero pari di 1», «contiene ab», «finisce per 01». Con la sola memoria degli stati non si può contare senza limite: [code]aⁿbⁿ[/code] NON è regolare.""",
	},
	{
		"title": "2 · Non determinismo e trasformazioni",
		"body": """In un automa [b]non deterministico[/b] (NFA) da uno stato, con lo stesso simbolo, possono partire [b]più frecce[/b] — o nessuna. Esistono anche le [b]ε-transizioni[/b]: si cambia stato [b]senza leggere[/b] nulla.

[b][color=#7ffcc0]Che cosa significa "accettare"[/color][/b]
La parola è accettata se [b]esiste almeno un cammino[/b] che finisce in uno stato finale. Non serve che vadano bene tutti: ne basta uno.

[b][color=#7ffcc0]Il trucco per eseguirlo[/color][/b]
Invece di provare i cammini a uno a uno, si tengono attivi [b]tutti insieme[/b]: si lavora con un [b]insieme di stati[/b] invece che con uno solo. Leggendo un simbolo, il nuovo insieme è l'unione di tutto ciò che si raggiunge da ciascuno stato dell'insieme.

[b][color=#7ffcc0]La ε-chiusura[/color][/b]
Dopo ogni mossa bisogna aggiungere tutti gli stati raggiungibili con frecce ε, e ripetere finché non se ne aggiungono altri.

[b][color=#c0a8ff]Costruzione per sottoinsiemi (NFA → DFA)[/color][/b]
Ogni [b]insieme[/b] di stati dell'NFA diventa [b]uno stato[/b] del DFA. Si parte dalla ε-chiusura dello stato iniziale e si calcolano le mosse finché non escono insiemi nuovi. Sono finali gli insiemi che contengono almeno uno stato finale.
[b]Conseguenza:[/b] NFA e DFA riconoscono esattamente gli stessi linguaggi. Il non determinismo è più [b]comodo[/b], non più [b]potente[/b].""",
	},
	{
		"title": "3 · Macchine di Turing",
		"body": """Agli automi manca la memoria. Aggiungiamo un [b]nastro infinito[/b] su cui si può anche [b]scrivere[/b]: nasce la [b]macchina di Turing[/b], il modello di calcolo più generale che conosciamo.

[b][color=#ffd166]Come è fatta[/color][/b]
Un nastro diviso in celle, una [b]testina[/b] che legge e scrive una cella alla volta, uno stato interno e una tabella di [b]quintuple[/b]:
[code]δ(stato, simbolo letto) = (simbolo scritto, direzione, nuovo stato)[/code]
La direzione è ← oppure →. Se per la coppia (stato, simbolo) non c'è nessuna regola, la macchina [b]si ferma[/b].

[b][color=#ffd166]Funzioni calcolabili e linguaggi decidibili[/color][/b]
Una funzione è [b]calcolabile secondo Turing[/b] se esiste una macchina che, partendo dall'input sul nastro, [b]si ferma[/b] lasciando il risultato scritto.
Un linguaggio è [b]decidibile[/b] se una macchina si ferma sempre rispondendo sì o no; è [b]semidecidibile[/b] se si ferma solo sui "sì" e sugli altri può girare per sempre.

[b][color=#ffd166]La tesi di Church-Turing[/color][/b]
Non è un teorema ma una [b]tesi[/b]: tutto ciò che è calcolabile con un procedimento meccanico è calcolabile da una macchina di Turing. Ogni modello proposto finora (funzioni ricorsive, λ-calcolo, WHILE, il tuo PC) si è rivelato [b]equivalente[/b].

[b][color=#ffd166]Non determinismo, di nuovo[/color][/b]
Anche le macchine di Turing possono essere non deterministiche, e anche qui non guadagnano potenza: una NTM si simula con una TM deterministica. Cambia il [b]tempo[/b], non ciò che si può calcolare.""",
	},
	{
		"title": "4 · Problemi senza soluzione",
		"body": """[b][color=#7fd8ff]La macchina universale[/color][/b]
Una macchina di Turing si può [b]codificare come una stringa[/b]. Esiste allora la [b]macchina universale[/b] U che riceve ⟨M, w⟩ ed [b]esegue M su w[/b]: è l'antenato teorico del computer, dove il programma è un dato come gli altri.

[b][color=#ff9a9a]Il problema dell'arresto[/color][/b]
«Dato ⟨M, w⟩, M si ferma su w?» Supponiamo esista H che risponde sempre. Costruiamo D che, su input ⟨M⟩, chiede a H se M si ferma su sé stessa e poi fa [b]il contrario[/b]: se M si ferma, D cicla; se M cicla, D si ferma.
Ora chiediamoci: [b]D si ferma su D?[/b] Se sì, allora per costruzione cicla. Se cicla, allora si ferma. Contraddizione: [b]H non può esistere[/b]. È l'[b]argomento diagonale[/b], lo stesso di Cantor.

[b][color=#ff9a9a]Il teorema di Rice[/color][/b]
Non è un caso isolato: [b]ogni[/b] proprietà non banale del [b]comportamento[/b] di un programma è indecidibile. «Calcola la funzione zero?», «termina sempre?», «è equivalente a quest'altro?»: tutte indecidibili. Sono invece decidibili le proprietà del [b]testo[/b] («contiene un while?»).

[b][color=#c0a8ff]Kleene e il decimo problema di Hilbert[/color][/b]
Il [b]teorema di ricorsione[/b] di Kleene garantisce che un programma può ottenere il proprio codice e usarlo: l'autoriferimento è legittimo, non un trucco.
Il [b]decimo problema di Hilbert[/b] chiedeva un algoritmo per decidere se un'equazione diofantea ha soluzioni intere: Matiyasevich ha dimostrato nel 1970 che non esiste. L'indecidibilità non è una stranezza dell'informatica: abita anche la matematica classica.""",
	},
	{
		"title": "5 · Funzioni ricorsive",
		"body": """Prima di Turing, [b]Church[/b] e [b]Kleene[/b] definirono la calcolabilità in modo puramente [b]matematico[/b], senza nessuna macchina: partendo da funzioni elementari e da regole per comporne di nuove.

[b][color=#7ffcc0]Le funzioni di base[/color][/b]
[code]zero(x) = 0[/code]   ·   [code]succ(x) = x + 1[/code]   ·   [code]proiezione[/code]: sceglie uno degli argomenti

[b][color=#7ffcc0]Le regole di costruzione[/color][/b]
[b]Composizione[/b]: usare il risultato di funzioni già costruite come argomento di un'altra.
[b]Ricorsione primitiva[/b]: definire f su n+1 a partire dal valore su n. È esattamente un ciclo di cui si conosce in anticipo il [b]numero di giri[/b].
Ciò che si ottiene sono le [b]funzioni primitive ricorsive[/b]: somma, prodotto, potenza, fattoriale... Tutte [b]totali[/b] (danno sempre un risultato) e tutte terminano.

[b][color=#c0a8ff]Il salto: la minimalizzazione μ[/color][/b]
[code]μy [f(x, y) = 0][/code] significa «il più piccolo y che azzera f». Per trovarlo si prova y = 0, 1, 2, ... [b]ma quel y potrebbe non esistere[/b]: la ricerca non finisce mai.
Con μ nascono le [b]funzioni parziali ricorsive[/b]: definite solo su alcuni input, indefinite (= calcolo infinito) sugli altri.

[b][color=#ffd166]Il punto[/color][/b]
Le funzioni parziali ricorsive sono [b]esattamente[/b] le funzioni calcolabili da una macchina di Turing. Due definizioni nate da mondi diversi — una matematica, una meccanica — descrivono la stessa cosa. È la prova più forte a favore della tesi di Church.""",
	},
	{
		"title": "6 · Il linguaggio WHILE",
		"body": """Terzo modello, ancora equivalente agli altri due, ma stavolta è un vero [b]linguaggio di programmazione[/b]. Bastano [b]tre costrutti[/b].

[b][color=#c0a8ff]Sintassi[/color][/b]
[code]x := espressione[/code]  assegnamento   ·   [code]P1 ; P2[/code]  sequenza
[code]while condizione do P end[/code]  ciclo   ·   [code]if c then P else Q end[/code]

Le variabili contengono [b]numeri naturali[/b] e valgono [b]0[/b] se non le hai mai assegnate. Operatori [code]+[/code] [code]-[/code] [code]*[/code], confronti [code]=[/code] [code]!=[/code] [code]<[/code] [code]<=[/code] [code]>[/code] [code]>=[/code]. La sottrazione è [b]troncata[/b]: [code]3 - 5[/code] fa [b]0[/b], non -2, perché si resta nei naturali.

[b][color=#7ffcc0]Va bene anche la notazione del corso[/color][/b]
L'interprete accetta [b]entrambe[/b] le scritture, puoi usare quella che preferisci:
[code]begin INPUT(X); while X > 0 do begin Z := s(Z); X := pd(X) end end[/code]
[code]begin[/code]…[code]end[/code] raggruppa comandi · [code]INPUT[/code]/[code]OUTPUT[/code] dichiarano ingressi e uscite · [code]s(x)[/code] è il successore, [code]pd(x)[/code] il predecessore. Dopo un [code]end[/code] il [code];[/code] può mancare.

[b][color=#c0a8ff]Semantica[/color][/b]
Un programma trasforma uno [b]stato[/b] (i valori delle variabili) in un altro stato. [code]while[/code] ripete il corpo finché la condizione è vera; se non diventa mai falsa il programma [b]non termina[/b] e la funzione calcolata è [b]parziale[/b] su quell'input.

[b][color=#ffd166]Perché è importante[/color][/b]
Il solo [code]while[/code] fa la parte della [b]minimalizzazione μ[/b]: è il costrutto che introduce la possibile non terminazione, ed è ciò che rende il linguaggio [b]Turing-completo[/b]. Un linguaggio con soli cicli limitati calcolerebbe solo funzioni primitive ricorsive.""",
	},
	{
		"title": "7 · La missione",
		"body": """[b][color=#c0a8ff]Laboratorio di Calcolabilità[/color][/b]
Devi collaudare quattro macchine. Hai [b]12 MINUTI[/b]: a cronometro scaduto la prova è fallita. Non ti si chiede di ripetere definizioni, ma di [b]far girare[/b] le macchine.

[b][color=#7fd8ff]FASE 1 · Automi deterministici[/color][/b]  Esegui il DFA: leggi un simbolo, clicca lo stato di arrivo, poi dichiara se la parola è accettata.
[b][color=#7ffcc0]FASE 2 · Determinizzazione[/color][/b]  Costruzione per sottoinsiemi: seleziona tutti gli stati raggiungibili, ε-chiusura compresa.
[b][color=#ffd166]FASE 3 · Macchine di Turing[/color][/b]  Applica la quintupla giusta a ogni passo, poi progetta la regola mancante.
[b][color=#c0a8ff]FASE 4 · Linguaggio WHILE[/color][/b]  Scrivi programmi veri, nella notazione del corso: li esegue un interprete, non un correttore di testo.

Gli esercizi sono [b]sorteggiati a ogni partita[/b] da un catalogo: due volte di fila non trovi gli stessi.

[b][color=#7fd8ff]Penalità[/color][/b]  Passo di esecuzione sbagliato [b]-6 s[/b]  ·  scelta sbagliata [b]-10 s[/b]  ·  programma che non compila [b]-8 s[/b]  ·  programma che non risolve [b]-12 s[/b].

[b][color=#7fd8ff]Comandi[/color][/b]  Clic per stati e regole. Nella Fase 4 scrivi nella console e premi [b]Esegui[/b] oppure [b]Ctrl+Invio[/b]. [b]Esc[/b] mette in pausa.""",
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
	next_button.text = "Entra in laboratorio  ▶" if is_last else "Avanti  ▶"
	body.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(body, "modulate:a", 1.0, 0.25)


func _on_next_pressed() -> void:
	if _page < PAGES.size() - 1:
		Sfx.play("click")
		_show_page(_page + 1)
	else:
		Sfx.play("correct")
		GameManager.go_to_level_3()


func _on_back_pressed() -> void:
	if _page > 0:
		Sfx.play("click")
		_show_page(_page - 1)
