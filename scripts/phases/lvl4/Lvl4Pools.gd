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
		"prompt": "Questo metodo fa tre cose. Spezzalo: il totale, le spese di spedizione e lo sconto devono stare in metodi separati.",
		"code": """public class Ordine {

    public double totale(List<Riga> righe, boolean urgente, int puntiFedelta) {
        double somma = 0;
        for (Riga riga : righe) {
            somma = somma + riga.getPrezzo() * riga.getQuantita();
        }
        double spedizione = 0;
        if (urgente) {
            spedizione = 15;
        } else {
            spedizione = 5;
        }
        double sconto = 0;
        if (puntiFedelta > 100) {
            sconto = somma * 0.1;
        }
        return somma + spedizione - sconto;
    }
}""",
		"checks": [
			{"kind": "method_count_at_least", "count": 4,
				"message": "Servono almeno quattro metodi: quello principale più uno per ciascuna delle tre responsabilità."},
			{"kind": "max_method_lines", "max": 10},
			{"kind": "no_magic_numbers"},
		],
		"solution": """public class Ordine {

	private static final double SPEDIZIONE_URGENTE = 15;
	private static final double SPEDIZIONE_STANDARD = 5;
	private static final int PUNTI_PER_SCONTO = 100;
	private static final double PERCENTUALE_SCONTO = 0.1;

	public double totale(List<Riga> righe, boolean urgente, int puntiFedelta) {
		double somma = sommaRighe(righe);
		return somma + spedizione(urgente) - sconto(somma, puntiFedelta);
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
		return SPEDIZIONE_STANDARD;
	}

	private double sconto(double somma, int puntiFedelta) {
		if (puntiFedelta > PUNTI_PER_SCONTO) {
			return somma * PERCENTUALE_SCONTO;
		}
		return 0;
	}
}""",
		"hint": "Estrai tre metodi privati e falli chiamare dal metodo principale, che diventa il riassunto leggibile dell'algoritmo.",
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
]


# ================================================================ sorteggio ==

static func pick(pool: Array, count: int) -> Array:
	var bag: Array = pool.duplicate()
	bag.shuffle()
	return bag.slice(0, mini(count, bag.size()))


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
