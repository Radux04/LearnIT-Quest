extends Control

## Introduzione teorica del Livello 4: metodologie di programmazione.
## Clean code, principi SOLID, manutenibilità, e i tre contesti su cui si
## eserciterà il giocatore (classi, JavaFX, persistenza).

const PAGES: Array = [
	{
		"title": "1 · Perché esiste il clean code",
		"body": """Il codice si scrive una volta e si [b]legge decine di volte[/b]: da chi lo corregge fra sei mesi, da chi lo eredita, da te stesso quando non ricordi più niente. Scrivere «pulito» non è eleganza, è [b]risparmiare il tempo di domani[/b].

[b][color=#7fd8ff]I nomi sono la prima documentazione[/color][/b]
[code]double t;[/code] non dice nulla. [code]double totaleImponibile;[/code] non ha bisogno di commenti.
Un nome deve dire [b]che cosa contiene[/b] o [b]che cosa fa[/b], non come è fatto dentro.

[b][color=#7fd8ff]Niente numeri magici[/color][/b]
[code]return prezzo * 1.22;[/code] → che cos'è 1.22? Fra un anno nessuno lo saprà.
[code]private static final double ALIQUOTA_IVA = 1.22;[/code] lo spiega da sola, e quando l'IVA cambia si modifica in [b]un punto solo[/b].

[b][color=#7fd8ff]Metodi corti, una cosa sola[/color][/b]
Se per capire un metodo devi scorrere, è troppo lungo. Se il nome contiene «e» — [code]calcolaTotaleEStampa[/code] — sta facendo due cose: sono due metodi.

[b][color=#ff9a9a]Il commento che non serve[/color][/b]
[code]// metodo che calcola il totale[/code] sopra [code]calcolaTotale()[/code] è rumore: ripete il nome e prima o poi mentirà, perché il codice cambia e il commento no. Commenta il [b]perché[/b], mai il [b]cosa[/b].

[b][color=#ff9a9a]La duplicazione[/color][/b]
La stessa riga in due punti è un bug che dovrai correggere due volte. Se la vedi due volte, estraila in un metodo.""",
	},
	{
		"title": "2 · I principi SOLID",
		"body": """Cinque regole per scrivere classi che si possano cambiare senza paura.

[b][color=#7ffcc0]S — Single Responsibility[/color][/b]
Una classe deve avere [b]una sola ragione per cambiare[/b]. Un [code]Ordine[/code] che calcola il totale, si salva sul database e si stampa in PDF cambia per tre motivi diversi: sono tre classi.

[b][color=#7ffcc0]O — Open/Closed[/color][/b]
[b]Aperta alle estensioni, chiusa alle modifiche.[/b] Se aggiungere un nuovo tipo di cliente ti obbliga a riaprire una catena di [code]if[/code], il codice è chiuso alle estensioni: con il polimorfismo basterebbe aggiungere una classe.

[b][color=#7ffcc0]L — Liskov Substitution[/color][/b]
Dove funziona la classe base deve funzionare la sottoclasse, [b]senza sorprese[/b]. Se [code]Quadrato[/code] estende [code]Rettangolo[/code] ma rompe chi imposta larghezza e altezza separatamente, l'ereditarietà è sbagliata.

[b][color=#7ffcc0]I — Interface Segregation[/color][/b]
Meglio [b]tante interfacce piccole[/b] che una grande. Nessuno deve essere costretto a implementare metodi che non gli servono, magari lasciandoli vuoti.

[b][color=#7ffcc0]D — Dependency Inversion[/color][/b]
Si dipende da [b]astrazioni[/b], non da dettagli concreti.
[code]private MySqlOrdineDao dao = new MySqlOrdineDao();[/code] incolla la classe a MySQL e la rende impossibile da provare.
[code]public ServizioOrdini(OrdineDao dao) { ... }[/code] la libera: chi la costruisce decide quale implementazione usare.""",
	},
	{
		"title": "3 · Codice che si può mantenere",
		"body": """[b][color=#ffd166]Incapsulamento[/color][/b]
I campi sono [code]private[/code], si espongono i metodi. Con [code]public double saldo;[/code] chiunque può scrivere un saldo negativo saltando ogni controllo. Con i campi privati la classe [b]difende le proprie regole[/b] e resta libera di cambiare come conserva i dati.

[b][color=#ffd166]Alta coesione, basso accoppiamento[/color][/b]
[b]Coesione[/b]: le cose che cambiano insieme stanno insieme.
[b]Accoppiamento[/b]: quante altre classi devi toccare se ne cambi una. Poche dipendenze, e verso interfacce.

[b][color=#ffd166]Tre strati che non si mescolano[/color][/b]
[b]Dominio[/b] — le regole (un ordine sa quanto costa)
[b]Interfaccia[/b] — quello che l'utente vede (JavaFX)
[b]Persistenza[/b] — come i dati sopravvivono (database o file)
Mescolarli è l'errore più costoso: mettere una query dentro un gestore di bottoni significa non poter cambiare né l'una né l'altro.

[b][color=#c0a8ff]JavaFX in tre parole[/color][/b]
[code]Stage[/code] è la finestra, [code]Scene[/code] è il contenuto, i nodi ([code]Button[/code], [code]VBox[/code]...) formano l'albero della grafica. Ai bottoni si collega un'azione con [code]setOnAction[/code], che deve [b]chiamare[/b] la logica, non contenerla.

[b][color=#c0a8ff]Persistenza[/color][/b]
Con [b]JPA/Hibernate[/b] le annotazioni sono la mappatura fra oggetti e tabelle: [code]@Entity[/code] sulla classe, [code]@Id[/code] sulla chiave, [code]@GeneratedValue[/code] per farla generare al database, [code]@Column[/code] sui campi.
Con [b]JAXB[/b] lo stesso oggetto va in XML: [code]@XmlRootElement[/code] sulla classe, [code]@XmlElement[/code] sui campi. Cambia la destinazione, non la classe.""",
	},
	{
		"title": "4 · La missione",
		"body": """[b][color=#7fd8ff]Code Review[/color][/b]
Sei il revisore di una base di codice Java che deve andare in produzione. Hai [b]16 MINUTI[/b]: a cronometro scaduto la revisione è respinta.

[b][color=#7fd8ff]FASE 1 · Clean code[/color][/b]  Il codice è a schermo con i numeri di riga: [b]clicca le righe difettose[/b] e conferma.
[b][color=#7ffcc0]FASE 2 · Principi SOLID[/color][/b]  Prima individua la violazione, poi [b]separa una classe che fa troppe cose[/b] assegnando ogni metodo alla classe giusta.
[b][color=#ffd166]FASE 3 · Riscrivi il codice[/color][/b]  Ricevi codice con dei difetti e lo riscrivi nell'editor.
[b][color=#c0a8ff]FASE 4 · Scrivi il codice[/color][/b]  Una classe incapsulata, una schermata JavaFX, una mappatura persistente.

[b][color=#ffd166]Come viene corretto[/color][/b]
Il gioco non compila il Java: [b]analizza la struttura[/b] del codice che scrivi — campi, visibilità, metodi, lunghezze, nomi, annotazioni, duplicazioni. È quello che conta per il clean code, ma vuol dire che la sintassi non viene verificata come farebbe un compilatore.
Il riquadro a destra ti mostra sempre [b]che cosa ha capito[/b] del tuo codice.

[b][color=#7fd8ff]Penalità[/color][/b]  Riga segnalata a torto [b]-8 s[/b]  ·  scelta sbagliata [b]-10 s[/b]  ·  codice che non sta in piedi [b]-8 s[/b]  ·  controlli non superati [b]-12 s[/b].

[b][color=#7fd8ff]Comandi[/color][/b]  Clic sulle righe e sui metodi. Nell'editor premi [b]Controlla[/b] oppure [b]Ctrl+Invio[/b]. [b]Esc[/b] mette in pausa.""",
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
	next_button.text = "Inizia la revisione  ▶" if is_last else "Avanti  ▶"
	body.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(body, "modulate:a", 1.0, 0.25)


func _on_next_pressed() -> void:
	if _page < PAGES.size() - 1:
		Sfx.play("click")
		_show_page(_page + 1)
	else:
		Sfx.play("correct")
		GameManager.go_to_level_4()


func _on_back_pressed() -> void:
	if _page > 0:
		Sfx.play("click")
		_show_page(_page - 1)
