class_name Lvl4Pools
extends RefCounted

## CATALOGO DEGLI ESERCIZI DEL LIVELLO 4.
##
## Come per il Livello 3 gli esercizi sono DATI: per aggiungerne uno si
## aggiunge una voce qui, senza toccare il codice delle fasi. I test in
## tests/test_lvl4.gd controllano che ogni voce sia coerente (le righe indicate
## come difettose esistono davvero, le soluzioni di riferimento superano i
## propri controlli, ecc.).


# ============================================ FASE 1 e 2: revisione visiva ===
#
# Il giocatore clicca le righe che violano la regola indicata.
# "bad" contiene gli indici delle righe (partendo da 0) che vanno selezionate.

const REVIEW_POOL: Array = [
	{
		"topic": "clean",
		"name": "nomi e numeri magici",
		"question": "Clicca le righe con nomi che non spiegano nulla o con numeri senza nome.",
		"code": """public class Fattura {
    private double t;

    public double c(double p) {
        return p * 1.22;
    }
}""",
		"bad": [1, 3, 4],
		"hint": "Un nome deve dire che cosa contiene. Un numero scritto nel codice deve dire da dove viene.",
		"explain": "«t» e «c» non dicono niente, e 1.22 è l'IVA: una costante ALIQUOTA_IVA lo spiegherebbe da sola.",
	},
	{
		"topic": "clean",
		"name": "commento inutile e duplicazione",
		"question": "Clicca il commento che non aggiunge nulla e le due righe identiche fra loro.",
		"code": """public class Carrello {
    private List<Riga> righe;

    // metodo che calcola il totale
    public double totale() {
        double somma = 0;
        for (Riga r : righe) {
            somma = somma + r.getPrezzo() * r.getQuantita();
        }
        return somma;
    }

    public double totaleScontato(double sconto) {
        double somma = 0;
        for (Riga r : righe) {
            somma = somma + r.getPrezzo() * r.getQuantita();
        }
        return somma - sconto;
    }
}""",
		"bad": [3, 7, 15],
		"hint": "Un commento che ripete il nome del metodo è rumore. Una riga identica in due punti è un bug futuro.",
		"explain": "Il commento ripete il nome del metodo. La riga duplicata andrà corretta due volte: estraila in un metodo.",
	},
	{
		"topic": "clean",
		"name": "metodo che fa troppe cose",
		"question": "Clicca le righe che fanno un lavoro DIVERSO dal calcolo del totale.",
		"code": """public class Ordine {
    public double calcolaTotale() {
        double somma = 0;
        for (Riga r : righe) {
            somma = somma + r.getPrezzo();
        }
        System.out.println("Totale: " + somma);
        salvaLog("totale calcolato");
        return somma;
    }
}""",
		"bad": [6, 7],
		"hint": "Il nome del metodo è una promessa: deve fare quello e basta.",
		"explain": "Stampare a video e scrivere un log non sono «calcolare il totale»: sono altre due responsabilità.",
	},
	{
		"topic": "solid",
		"name": "SRP — la classe fa troppe cose",
		"question": "Questa classe viola il principio di singola responsabilità. Clicca le righe dove iniziano i metodi che NON riguardano l'ordine in sé.",
		"code": """public class Ordine {
    private List<Riga> righe;

    public double calcolaTotale() {
        return 0;
    }

    public void salvaSuDatabase() {
    }

    public void stampaPdf() {
    }
}""",
		"bad": [7, 10],
		"hint": "Un ordine sa quanto costa. Non sa come si parla a un database né come si impagina un PDF.",
		"explain": "Salvataggio e stampa sono altre due responsabilità: cambiano per motivi diversi, quindi vanno in classi diverse.",
	},
	{
		"topic": "solid",
		"name": "DIP — dipendenza da un dettaglio",
		"question": "Clicca la riga che lega questa classe a una tecnologia concreta invece che a un'astrazione.",
		"code": """public class ServizioOrdini {
    private MySqlOrdineDao dao = new MySqlOrdineDao();

    public void salva(Ordine ordine) {
        dao.inserisci(ordine);
    }
}""",
		"bad": [1],
		"hint": "Chi decide quale database si usa? Dovrebbe deciderlo chi costruisce l'oggetto, non l'oggetto stesso.",
		"explain": "Dipendere da MySqlOrdineDao impedisce di provare la classe senza un database. Si dipende da un'interfaccia OrdineDao, iniettata dal costruttore.",
	},
	{
		"topic": "solid",
		"name": "OCP — aperto alle estensioni",
		"question": "Clicca le righe che dovresti modificare ogni volta che si aggiunge un nuovo tipo di cliente.",
		"code": """public class CalcolatoreSconto {
    public double sconto(Cliente cliente) {
        if (cliente.getTipo().equals("BASE")) {
            return 0;
        } else if (cliente.getTipo().equals("PREMIUM")) {
            return 10;
        } else if (cliente.getTipo().equals("VIP")) {
            return 20;
        }
        return 0;
    }
}""",
		"bad": [2, 4, 6],
		"hint": "Aperto alle estensioni, chiuso alle modifiche: aggiungere un caso non dovrebbe voler dire riaprire questo metodo.",
		"explain": "Ogni nuovo tipo obbliga a modificare la catena di if. Con il polimorfismo basterebbe aggiungere una classe.",
	},
]


# ================================================ FASE 2: separa le classi ===
#
# Il giocatore assegna ogni metodo alla classe a cui appartiene: è il principio
# di singola responsabilità applicato con un gesto invece che con una domanda.

const SPLIT_POOL: Array = [
	{
		"name": "Ordine",
		"origin": "Ordine",
		"targets": ["Ordine  ·  dominio", "RepositoryOrdini  ·  persistenza"],
		"methods": [
			["double calcolaTotale()", 0],
			["void aggiungiRiga(Riga riga)", 0],
			["void salvaSuDatabase()", 1],
			["Ordine caricaPerId(int id)", 1],
		],
		"hint": "Chiediti: se cambia il database, quali metodi devo toccare? Quelli vanno insieme.",
		"explain": "Le due classi cambiano per motivi diversi: il dominio cambia se cambiano le regole di business, il repository se cambia il database.",
	},
	{
		"name": "Utente",
		"origin": "Utente",
		"targets": ["Utente  ·  dati", "ServizioEmail  ·  notifiche"],
		"methods": [
			["String getNome()", 0],
			["boolean passwordValida(String password)", 0],
			["void inviaEmailBenvenuto()", 1],
			["void inviaEmailRecuperoPassword()", 1],
		],
		"hint": "Un utente sa chi è. Non sa come funziona un server di posta.",
		"explain": "Separare le notifiche permette di provare l'utente senza spedire email, e di cambiare fornitore di posta senza toccare l'utente.",
	},
	{
		"name": "Figura",
		"origin": "Figura",
		"targets": ["Figura  ·  geometria", "DisegnatoreFigure  ·  grafica"],
		"methods": [
			["double area()", 0],
			["double perimetro()", 0],
			["void disegna(Canvas canvas)", 1],
			["void esportaPng(File file)", 1],
		],
		"hint": "La geometria di un cerchio non cambia se passi da JavaFX a Swing.",
		"explain": "Tenere separata la grafica permette di riusare le figure in un programma senza interfaccia, per esempio in un test.",
	},
]


# ============================================== FASE 3: riscrivere il codice =

const REFACTOR_POOL: Array = [
	{
		"prompt": "Riscrivi questa classe: dai nomi che spieghino e togli il numero magico.",
		"code": """public class Fattura {

    public double c(double p) {
        return p * 1.22;
    }
}""",
		"checks": [
			{"kind": "no_magic_numbers"},
			{"kind": "meaningful_names", "min_length": 5},
			{"kind": "contains", "text": "static final",
				"message": "Il numero deve diventare una costante: usa static final e dagli un nome che spieghi che cos'è."},
		],
		"solution": """public class Fattura {

	private static final double ALIQUOTA_IVA = 1.22;

	public double totaleConIva(double imponibile) {
		return imponibile * ALIQUOTA_IVA;
	}
}""",
		"hint": "Una costante si dichiara così:  private static final double ALIQUOTA_IVA = 1.22;",
		"explain": "Ora il codice si legge da solo: nessuno deve più chiedersi che cosa sia 1.22.",
	},
	{
		"prompt": "Questo metodo fa due cose: somma le righe e aggiunge la spedizione. Spezzalo in metodi separati e dai un nome al numero.",
		"code": """public class Ordine {

	public double totale(List<Riga> righe, boolean urgente) {
		double somma = 0;
		for (Riga riga : righe) {
			somma = somma + riga.getPrezzo() * riga.getQuantita();
		}
		if (urgente) {
			somma = somma + 15;
		}
		return somma;
	}
}""",
		"checks": [
			{"kind": "method_count_at_least", "count": 3,
				"message": "Servono almeno tre metodi: quello principale più uno per ciascuna delle due responsabilità."},
			{"kind": "max_method_lines", "max": 8},
			{"kind": "no_magic_numbers"},
		],
		"solution": """public class Ordine {

	private static final double SPEDIZIONE_URGENTE = 15;

	public double totale(List<Riga> righe, boolean urgente) {
		return sommaRighe(righe) + spedizione(urgente);
	}

	private double sommaRighe(List<Riga> righe) {
		double somma = 0;
		for (Riga riga : righe) {
			somma = somma + riga.getPrezzo() * riga.getQuantita();
		}
		return somma;
	}

	private double spedizione(boolean urgente) {
		if (urgente) {
			return SPEDIZIONE_URGENTE;
		}
		return 0;
	}
}""",
		"hint": "Estrai due metodi privati e falli chiamare dal metodo principale, che diventa il riassunto leggibile dell'algoritmo.",
		"explain": "Un metodo che fa una cosa sola si prova, si legge e si cambia senza paura.",
	},
	{
		"prompt": "Incapsula questa classe: i dati non devono essere accessibili dall'esterno, ma il saldo deve restare leggibile.",
		"code": """public class ContoCorrente {
    public String intestatario;
    public double saldo;
}""",
		"checks": [
			{"kind": "no_public_fields"},
			{"kind": "has_method", "method": "getSaldo"},
			{"kind": "class_named", "name": "ContoCorrente"},
		],
		"solution": """public class ContoCorrente {

	private String intestatario;
	private double saldo;

	public ContoCorrente(String intestatario, double saldo) {
		this.intestatario = intestatario;
		this.saldo = saldo;
	}

	public double getSaldo() {
		return saldo;
	}
}""",
		"hint": "Campi private, e un metodo pubblico per leggere il saldo. Chi vuole modificarlo deve passare da metodi che controllano.",
		"explain": "Con i campi pubblici chiunque può scrivere un saldo negativo. Con l'incapsulamento la classe difende le proprie regole.",
	},
	{
		"prompt": "Questi due metodi hanno lo stesso corpo. Togli la duplicazione estraendo la parte comune.",
		"code": """public class Report {

	public double totaleOrdini(List<Riga> righe) {
		double somma = 0;
		for (Riga riga : righe) {
			somma = somma + riga.getPrezzo() * riga.getQuantita();
		}
		return somma;
	}

	public double totaleConSconto(List<Riga> righe, double sconto) {
		double somma = 0;
		for (Riga riga : righe) {
			somma = somma + riga.getPrezzo() * riga.getQuantita();
		}
		return somma - sconto;
	}
}""",
		"checks": [
			{"kind": "no_duplicated_lines"},
			{"kind": "method_count_at_least", "count": 3,
				"message": "La parte comune va estratta in un terzo metodo, chiamato da entrambi."},
		],
		"solution": """public class Report {

	public double totaleOrdini(List<Riga> righe) {
		return sommaRighe(righe);
	}

	public double totaleConSconto(List<Riga> righe, double sconto) {
		return sommaRighe(righe) - sconto;
	}

	private double sommaRighe(List<Riga> righe) {
		double somma = 0;
		for (Riga riga : righe) {
			somma = somma + riga.getPrezzo() * riga.getQuantita();
		}
		return somma;
	}
}""",
		"hint": "Sposta il ciclo in un metodo privato e fallo chiamare da tutti e due.",
		"explain": "Codice duplicato significa correzioni da fare due volte, e prima o poi te ne dimentichi una.",
	},
	{
		"prompt": "Questo metodo è un labirinto di if annidati. Riscrivilo con uscite anticipate, in meno di 13 righe.",
		"code": """public class Accesso {

	public String stato(Utente utente) {
		String risultato = "";
		if (utente != null) {
			if (utente.isAttivo()) {
				if (utente.getRuolo().equals("ADMIN")) {
					risultato = "amministratore";
				} else {
					risultato = "utente";
				}
			} else {
				risultato = "disattivato";
			}
		} else {
			risultato = "sconosciuto";
		}
		return risultato;
	}
}""",
		"checks": [
			{"kind": "max_method_lines", "max": 13},
		],
		"solution": """public class Accesso {

	public String stato(Utente utente) {
		if (utente == null) {
			return "sconosciuto";
		}
		if (!utente.isAttivo()) {
			return "disattivato";
		}
		if (utente.getRuolo().equals("ADMIN")) {
			return "amministratore";
		}
		return "utente";
	}
}""",
		"hint": "Tratta subito i casi limite e esci con return: quello che resta è il caso normale, senza annidamenti.",
		"explain": "Le uscite anticipate tolgono un livello di indentazione per ogni caso trattato: il caso normale resta in fondo, in chiaro.",
	},
	{
		"prompt": "Dai un nome ai numeri di questo calcolo: chi legge non può indovinare che cosa significano.",
		"code": """public class Sconto {

	public double prezzoFinale(double prezzo, int punti) {
		if (punti > 500) {
			return prezzo * 0.8;
		}
		return prezzo * 0.95;
	}
}""",
		"checks": [
			{"kind": "no_magic_numbers"},
			{"kind": "contains", "text": "static final",
				"message": "I numeri devono diventare costanti: usa static final e dai a ciascuna un nome che spieghi che cos'è."},
		],
		"solution": """public class Sconto {

	private static final int PUNTI_CLIENTE_FEDELE = 500;
	private static final double SCONTO_FEDELE = 0.8;
	private static final double SCONTO_BASE = 0.95;

	public double prezzoFinale(double prezzo, int punti) {
		if (punti > PUNTI_CLIENTE_FEDELE) {
			return prezzo * SCONTO_FEDELE;
		}
		return prezzo * SCONTO_BASE;
	}
}""",
		"hint": "Tre numeri, tre costanti: la soglia dei punti e i due moltiplicatori.",
		"explain": "Con i nomi al posto dei numeri la regola commerciale si legge nel codice, e cambiarla è un'unica modifica.",
	},
]


# ============================================ FASE 4: scrivere codice nuovo ==

const WRITE_POOL: Array = [
	{
		"topic": "classe",
		"prompt": "Scrivi la classe Libro: titolo, autore e anno privati, un costruttore che li riceve, i tre getter e toString().",
		"code": "",
		"checks": [
			{"kind": "class_named", "name": "Libro"},
			{"kind": "no_public_fields"},
			{"kind": "field_private", "field": "titolo"},
			{"kind": "field_private", "field": "autore"},
			{"kind": "field_private", "field": "anno"},
			{"kind": "has_method", "method": "getTitolo"},
			{"kind": "has_method", "method": "getAutore"},
			{"kind": "has_method", "method": "getAnno"},
			{"kind": "has_method", "method": "toString"},
		],
		"solution": """public class Libro {

	private String titolo;
	private String autore;
	private int anno;

	public Libro(String titolo, String autore, int anno) {
		this.titolo = titolo;
		this.autore = autore;
		this.anno = anno;
	}

	public String getTitolo() {
		return titolo;
	}

	public String getAutore() {
		return autore;
	}

	public int getAnno() {
		return anno;
	}

	@Override
	public String toString() {
		return titolo + " di " + autore;
	}
}""",
		"hint": "public class Libro { private String titolo; ... public Libro(String titolo, ...) { this.titolo = titolo; } ... }",
		"explain": "Campi privati più getter: la classe controlla i propri dati e resta libera di cambiare come li conserva.",
	},
	{
		"topic": "classe",
		"prompt": "Scrivi la classe Rettangolo: base e altezza privati, un costruttore che li riceve, e i metodi area(), perimetro() e toString().",
		"code": "",
		"checks": [
			{"kind": "class_named", "name": "Rettangolo"},
			{"kind": "no_public_fields"},
			{"kind": "field_private", "field": "base"},
			{"kind": "field_private", "field": "altezza"},
			{"kind": "has_method", "method": "area"},
			{"kind": "has_method", "method": "perimetro"},
			{"kind": "has_method", "method": "toString"},
		],
		"solution": """public class Rettangolo {

	private double base;
	private double altezza;

	public Rettangolo(double base, double altezza) {
		this.base = base;
		this.altezza = altezza;
	}

	public double area() {
		return base * altezza;
	}

	public double perimetro() {
		return (base + altezza) * 2;
	}

	@Override
	public String toString() {
		return "Rettangolo " + base + "x" + altezza;
	}
}""",
		"hint": "I dati restano privati; area e perimetro sono servizi che la classe offre a chi la usa.",
		"explain": "Chi usa la classe non deve rifare i conti: li fa la classe, che è l'unica a conoscere i propri dati.",
	},
	{
		"topic": "classe",
		"prompt": "Scrivi la classe Studente: matricola, nome e media privati, un costruttore, i getter e un metodo promosso() che dice se la media è almeno 18.",
		"code": "",
		"checks": [
			{"kind": "class_named", "name": "Studente"},
			{"kind": "no_public_fields"},
			{"kind": "field_private", "field": "matricola"},
			{"kind": "field_private", "field": "nome"},
			{"kind": "field_private", "field": "media"},
			{"kind": "has_method", "method": "getNome"},
			{"kind": "has_method", "method": "promosso"},
			{"kind": "no_magic_numbers",
				"message": "Il 18 è la soglia di promozione: dagli un nome con una costante static final invece di scriverlo nel metodo."},
		],
		"solution": """public class Studente {

	private static final double VOTO_MINIMO = 18;

	private String matricola;
	private String nome;
	private double media;

	public Studente(String matricola, String nome, double media) {
		this.matricola = matricola;
		this.nome = nome;
		this.media = media;
	}

	public String getMatricola() {
		return matricola;
	}

	public String getNome() {
		return nome;
	}

	public boolean promosso() {
		return media >= VOTO_MINIMO;
	}
}""",
		"hint": "La soglia 18 non va scritta dentro il metodo: private static final double VOTO_MINIMO = 18;",
		"explain": "La regola («si passa da 18») vive in un punto solo, con un nome che la spiega: cambiarla è una riga.",
	},
	{
		"topic": "javafx",
		"prompt": "Scrivi una classe JavaFX che estende Application: nel metodo start crea un Button, collegagli un'azione, mettilo in una Scene e mostra la finestra.",
		"code": """public class MiaApp extends Application {

    @Override
    public void start(Stage stage) {
        // scrivi qui
    }
}""",
		"checks": [
			{"kind": "extends", "name": "Application"},
			{"kind": "has_method", "method": "start"},
			{"kind": "contains", "text": "new Button",
				"message": "Manca il Button: crealo con  Button bottone = new Button(\"testo\");"},
			{"kind": "contains", "text": "setOnAction",
				"message": "Il bottone non fa niente: collega l'azione con  bottone.setOnAction(e -> ...);"},
			{"kind": "contains", "text": "new Scene",
				"message": "Manca la Scene: in JavaFX i nodi vivono dentro una Scene, che sta dentro lo Stage."},
			{"kind": "contains", "text": "stage.show",
				"message": "Manca stage.show(): senza, la finestra non compare."},
		],
		"solution": """public class MiaApp extends Application {

	@Override
	public void start(Stage stage) {
		Button bottone = new Button("Premi");
		bottone.setOnAction(evento -> System.out.println("premuto"));
		VBox radice = new VBox(bottone);
		Scene scena = new Scene(radice);
		stage.setScene(scena);
		stage.show();
	}
}""",
		"hint": "Ordine delle scatole: Button → contenitore → Scene → Stage. Poi stage.show().",
		"explain": "Stage è la finestra, Scene il contenuto, i nodi sono l'albero della grafica: è la gerarchia di JavaFX.",
	},
	{
		"topic": "javafx",
		"prompt": "Scrivi una classe JavaFX: un TextField, una Label e un Button che, quando viene premuto, copia nella Label il testo scritto nel campo. Metti tutto in un VBox.",
		"code": """public class SalutoApp extends Application {

	@Override
	public void start(Stage stage) {
		// scrivi qui
	}
}""",
		"checks": [
			{"kind": "extends", "name": "Application"},
			{"kind": "has_method", "method": "start"},
			{"kind": "contains", "text": "new TextField",
				"message": "Manca il campo di testo: TextField campo = new TextField();"},
			{"kind": "contains", "text": "new Label",
				"message": "Manca la Label dove scrivere il risultato."},
			{"kind": "contains", "text": "new VBox",
				"message": "I tre nodi vanno raccolti in un contenitore: new VBox(...)."},
			{"kind": "contains", "text": "setOnAction",
				"message": "Il bottone non fa niente: collega l'azione con setOnAction."},
			{"kind": "contains", "text": "new Scene"},
			{"kind": "contains", "text": "stage.show"},
		],
		"solution": """public class SalutoApp extends Application {

	@Override
	public void start(Stage stage) {
		TextField campo = new TextField();
		Label etichetta = new Label();
		Button bottone = new Button("Saluta");
		bottone.setOnAction(evento -> etichetta.setText(campo.getText()));
		VBox radice = new VBox(campo, bottone, etichetta);
		Scene scena = new Scene(radice);
		stage.setScene(scena);
		stage.show();
	}
}""",
		"hint": "L'azione del bottone legge campo.getText() e la passa a etichetta.setText(...).",
		"explain": "Il gestore del bottone collega due nodi fra loro: la logica sta fuori, lui si limita a chiamarla.",
	},
	{
		"topic": "javafx",
		"prompt": "Scrivi una classe JavaFX con due Button dentro un VBox, un titolo alla finestra e la Scene mostrata.",
		"code": """public class MenuApp extends Application {

	@Override
	public void start(Stage stage) {
		// scrivi qui
	}
}""",
		"checks": [
			{"kind": "extends", "name": "Application"},
			{"kind": "has_method", "method": "start"},
			{"kind": "contains", "text": "new Button"},
			{"kind": "contains", "text": "new VBox"},
			{"kind": "contains", "text": "setTitle",
				"message": "Manca il titolo della finestra: stage.setTitle(\"...\")."},
			{"kind": "contains", "text": "setOnAction"},
			{"kind": "contains", "text": "new Scene"},
			{"kind": "contains", "text": "stage.show"},
		],
		"solution": """public class MenuApp extends Application {

	@Override
	public void start(Stage stage) {
		Button avvia = new Button("Avvia");
		Button esci = new Button("Esci");
		avvia.setOnAction(evento -> System.out.println("avvio"));
		esci.setOnAction(evento -> stage.close());
		VBox radice = new VBox(avvia, esci);
		Scene scena = new Scene(radice);
		stage.setTitle("Menu");
		stage.setScene(scena);
		stage.show();
	}
}""",
		"hint": "Il titolo si mette sullo Stage, non sulla Scene: stage.setTitle(\"Menu\");",
		"explain": "Stage è la finestra del sistema operativo — titolo, dimensioni, chiusura. La Scene è solo il contenuto.",
	},
	{
		"topic": "persistenza",
		"prompt": "Trasforma questa classe in una entity JPA/Hibernate: annota la classe, la chiave primaria con generazione automatica e mappa il campo titolo su una colonna.",
		"code": """public class Libro {
    private Long id;
    private String titolo;
}""",
		"checks": [
			{"kind": "has_annotation", "name": "Entity"},
			{"kind": "field_annotated", "field": "id", "name": "Id",
				"message": "La chiave primaria va annotata con @Id sul campo id."},
			{"kind": "field_annotated", "field": "id", "name": "GeneratedValue",
				"message": "Senza @GeneratedValue l'id non viene generato dal database: dovresti assegnarlo a mano."},
			{"kind": "field_annotated", "field": "titolo", "name": "Column",
				"message": "Mappa il campo titolo su una colonna con @Column(name = \"...\")."},
		],
		"solution": """@Entity
public class Libro {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(name = "titolo")
	private String titolo;
}""",
		"hint": "@Entity sulla classe; @Id e @GeneratedValue(strategy = GenerationType.IDENTITY) sul campo id; @Column sul titolo.",
		"explain": "Le annotazioni sono la mappatura fra oggetti e tabelle: Hibernate le legge per generare le query al posto tuo.",
	},
	{
		"topic": "persistenza",
		"prompt": "Prepara questa classe per essere salvata in XML con JAXB: annota la classe come radice del documento e i due campi come elementi.",
		"code": """public class Configurazione {
    private String host;
    private int porta;
}""",
		"checks": [
			{"kind": "has_annotation", "name": "XmlRootElement"},
			{"kind": "field_annotated", "field": "host", "name": "XmlElement",
				"message": "Il campo host deve diventare un elemento del documento: annotalo con @XmlElement."},
			{"kind": "field_annotated", "field": "porta", "name": "XmlElement",
				"message": "Anche porta deve essere un elemento: annotalo con @XmlElement."},
		],
		"solution": """@XmlRootElement
public class Configurazione {

	@XmlElement
	private String host;

	@XmlElement
	private int porta;
}""",
		"hint": "@XmlRootElement sulla classe, @XmlElement su ciascun campo da scrivere nel file.",
		"explain": "XML e database sono due destinazioni diverse per lo stesso oggetto: la classe non cambia, cambiano le annotazioni.",
	},
	{
		"topic": "persistenza",
		"prompt": "Mappa Cliente su una tabella: annota la classe come entity, indica che la tabella si chiama «clienti», segna la chiave primaria e mappa email sulla colonna «indirizzo_email».",
		"code": """public class Cliente {
	private Long id;
	private String email;
}""",
		"checks": [
			{"kind": "has_annotation", "name": "Entity"},
			{"kind": "has_annotation", "name": "Table",
				"message": "Il nome della tabella si indica con @Table(name = \"clienti\") sulla classe."},
			{"kind": "field_annotated", "field": "id", "name": "Id"},
			{"kind": "field_annotated", "field": "email", "name": "Column",
				"message": "Quando il nome della colonna è diverso da quello del campo serve @Column(name = \"indirizzo_email\")."},
		],
		"solution": """@Entity
@Table(name = "clienti")
public class Cliente {

	@Id
	private Long id;

	@Column(name = "indirizzo_email")
	private String email;
}""",
		"hint": "@Entity e @Table vanno sulla classe, @Id e @Column sui campi.",
		"explain": "Senza @Column Hibernate cercherebbe una colonna chiamata «email»: l'annotazione fa da ponte fra due nomi diversi.",
	},
	{
		"topic": "persistenza",
		"prompt": "Prepara Prodotto per JAXB: la classe è la radice del documento, il codice deve diventare un ATTRIBUTO e il nome un elemento.",
		"code": """public class Prodotto {
	private String codice;
	private String nome;
}""",
		"checks": [
			{"kind": "has_annotation", "name": "XmlRootElement"},
			{"kind": "field_annotated", "field": "codice", "name": "XmlAttribute",
				"message": "Il codice deve essere un attributo del tag, non un elemento: @XmlAttribute."},
			{"kind": "field_annotated", "field": "nome", "name": "XmlElement"},
		],
		"solution": """@XmlRootElement
public class Prodotto {

	@XmlAttribute
	private String codice;

	@XmlElement
	private String nome;
}""",
		"hint": "@XmlAttribute produce <prodotto codice=\"...\">, @XmlElement produce <nome>...</nome>.",
		"explain": "Attributo o elemento non è un dettaglio: gli attributi sono valori semplici del tag, gli elementi possono contenere altra struttura.",
	},
]


# ================================================================ sorteggio ==

## Ricorda che cosa è uscito l'ultima volta, per ogni gruppo di esercizi.
## Vive quanto il processo: riavviando il livello dal menu o dalla schermata
## finale gli esercizi cambiano di sicuro.
static var _last_drawn: Dictionary = {}


static func pick(pool: Array, count: int) -> Array:
	var bag: Array = pool.duplicate()
	bag.shuffle()
	return bag.slice(0, mini(count, bag.size()))


## Pesca `count` voci evitando quelle uscite l'ultima volta con la stessa
## chiave. Se le voci rimaste non bastano riparte da tutte, così il gioco
## resta giocabile anche con cataloghi piccoli.
static func pick_fresh(entries: Array, count: int, memory_key: String) -> Array:
	var recent: Array = _last_drawn.get(memory_key, [])

	var fresh: Array = []
	for entry in entries:
		if not recent.has(identity(entry)):
			fresh.append(entry)
	if fresh.size() < count:
		fresh = entries.duplicate()

	fresh.shuffle()
	var chosen: Array = fresh.slice(0, mini(count, fresh.size()))

	var drawn: Array = []
	for entry in chosen:
		drawn.append(identity(entry))
	_last_drawn[memory_key] = drawn
	return chosen


## Voci di un solo argomento, nell'ordine del catalogo.
static func filter_topic(pool: Array, topic: String) -> Array:
	var out: Array = []
	for entry in pool:
		if String(entry.get("topic", "")) == topic:
			out.append(entry)
	return out


## Come si riconosce un esercizio: la richiesta è già unica.
static func identity(entry: Dictionary) -> String:
	return String(entry.get("prompt", entry.get("name", "")))


static func pick_one(pool: Array) -> Dictionary:
	return pool[randi() % pool.size()]


## Voci filtrate per argomento, poi mescolate.
static func pick_topic(pool: Array, topic: String, count: int) -> Array:
	var filtered: Array = []
	for entry in pool:
		if String(entry.get("topic", "")) == topic:
			filtered.append(entry)
	return pick(filtered, count)


static func build_task(entry: Dictionary) -> JavaTask:
	return JavaTask.make(
		String(entry["prompt"]), String(entry.get("code", "")), entry["checks"],
		String(entry.get("hint", "")), String(entry.get("explain", "")))
