extends Node

## Batteria di test dell'analizzatore Java e del correttore strutturale.
## Non fa parte del gioco.

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	run_all()


func run_all() -> void:
	_passed = 0
	_failed = 0
	test_parse_class()
	test_parse_fields()
	test_parse_methods()
	test_comments_and_strings()
	test_annotations()
	test_braces()
	test_magic_numbers()
	test_long_methods()
	test_public_fields()
	test_poor_names()
	test_duplicated_lines()
	test_interface_and_inheritance()
	test_task_ok()
	test_task_errors()
	test_task_encapsulation()
	test_task_refactoring()
	print("\n[LVL4-TEST] %d passati, %d falliti" % [_passed, _failed])


# ------------------------------------------------------------- helpers -----

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: %s" % label)


func _equal(got: Variant, want: Variant, label: String) -> void:
	if str(got) == str(want):
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: %s  (ottenuto %s, atteso %s)" % [label, str(got), str(want)])


const CONTO := """public class ContoCorrente {

    private static final double TASSO = 0.02;
    private String intestatario;
    private double saldo;

    public ContoCorrente(String intestatario, double saldo) {
        this.intestatario = intestatario;
        this.saldo = saldo;
    }

    public double getSaldo() {
        return saldo;
    }

    public void versa(double importo) {
        if (importo <= 0) {
            throw new IllegalArgumentException("importo non valido");
        }
        saldo = saldo + importo;
    }
}"""


# ------------------------------------------------------------ struttura ----

func test_parse_class() -> void:
	var code: JavaCode = JavaCode.parse(CONTO)
	_check(code.has_type(), "riconosce la dichiarazione di classe")
	_equal(code.type_name, "ContoCorrente", "nome della classe")
	_equal(code.type_kind, "class", "tipo: class")
	_check(code.braces_balanced(), "le graffe sono bilanciate")


func test_parse_fields() -> void:
	var code: JavaCode = JavaCode.parse(CONTO)
	_equal(code.fields.size(), 3, "trova tre campi")
	var saldo: Dictionary = code.find_field("saldo")
	_check(not saldo.is_empty(), "trova il campo saldo")
	_check(saldo["modifiers"].has("private"), "saldo è private")
	_equal(String(saldo["type"]), "double", "il tipo di saldo è double")
	var tasso: Dictionary = code.find_field("TASSO")
	_check(tasso["modifiers"].has("static") and tasso["modifiers"].has("final"),
		"TASSO è static final")


func test_parse_methods() -> void:
	var code: JavaCode = JavaCode.parse(CONTO)
	_equal(code.methods.size(), 3, "trova costruttore e due metodi")
	_check(code.declares_method("getSaldo"), "trova getSaldo")
	_check(code.declares_method("versa"), "trova versa")
	_check(not code.declares_method("preleva"), "non inventa metodi inesistenti")
	var versa: Dictionary = code.find_method("versa")
	_equal(String(versa["params"]), "double importo", "legge i parametri")
	_check(versa["modifiers"].has("public"), "versa è public")
	var costruttore: Dictionary = code.find_method("ContoCorrente")
	_check(bool(costruttore["is_constructor"]), "riconosce il costruttore")


## Il punto critico: parentesi e parole chiave dentro commenti e stringhe non
## devono confondere l'analisi.
func test_comments_and_strings() -> void:
	var tricky: String = """public class Trappola {
    // questo commento contiene una graffa { e la parola class
    private String messaggio = "if (x) { return; }";
    /* commento
       su piu' righe con }} graffe */
    public void stampa() {
        System.out.println(messaggio);
    }
}"""
	var code: JavaCode = JavaCode.parse(tricky)
	_equal(code.type_name, "Trappola", "il commento non confonde il nome della classe")
	_check(code.braces_balanced(), "le graffe nei commenti e nelle stringhe sono ignorate")
	_equal(code.methods.size(), 1, "un solo metodo, il resto è testo")
	_check(code.declares_method("stampa"), "trova stampa()")
	_check(code.comment_lines.size() >= 2, "segna le righe di commento")


func test_annotations() -> void:
	var entity: String = """@Entity
@Table(name = "clienti")
public class Cliente {
    @Id
    @GeneratedValue
    private Long id;

    @Column(name = "nome")
    private String nome;
}"""
	var code: JavaCode = JavaCode.parse(entity)
	_check(code.has_annotation("Entity"), "trova @Entity")
	_check(code.has_annotation("Table"), "trova @Table anche con i parametri")
	_check(code.has_annotation("Id"), "trova @Id")
	_check(not code.has_annotation("Transient"), "non inventa annotazioni")
	_equal(code.type_name, "Cliente", "le annotazioni non nascondono la classe")
	var id_field: Dictionary = code.find_field("id")
	_check(id_field.get("annotations", []).has("Id"), "@Id è associata al campo id")


func test_braces() -> void:
	var broken: JavaCode = JavaCode.parse("public class Rotta { public void a() { } ")
	_check(not broken.braces_balanced(), "graffa mancante rilevata")
	var extra: JavaCode = JavaCode.parse("public class Rotta { } }")
	_check(not extra.braces_balanced(), "graffa di troppo rilevata")


func test_magic_numbers() -> void:
	var code: JavaCode = JavaCode.parse("""public class Prezzi {
    public double conIva(double prezzo) {
        return prezzo * 1.22;
    }
}""")
	var magic: Array = code.magic_numbers()
	_check(magic.size() >= 1, "trova il numero magico 1.22")
	_equal(String(magic[0]["method"]), "conIva", "sa in quale metodo si trova")

	var clean: JavaCode = JavaCode.parse("""public class Prezzi {
    private static final double IVA = 1.22;
    public double conIva(double prezzo) {
        return prezzo * IVA;
    }
}""")
	_check(clean.magic_numbers().is_empty(), "una costante con un nome non è un numero magico")

	var harmless: JavaCode = JavaCode.parse("""public class Contatore {
    public int successivo(int n) {
        return n + 1;
    }
}""")
	_check(harmless.magic_numbers().is_empty(), "0 e 1 non contano come numeri magici")

	# Un numero dentro un identificatore non è un letterale.
	var identifier: JavaCode = JavaCode.parse("""public class Prova {
    public void x() {
        int valore2 = 0;
    }
}""")
	_check(identifier.magic_numbers().is_empty(), "il 2 di 'valore2' non è un numero magico")


func test_long_methods() -> void:
	var body: String = ""
	for i in range(20):
		body += "        System.out.println(\"riga\");\n"
	var code: JavaCode = JavaCode.parse("public class Lungo {\n    public void fai() {\n" + body + "    }\n}")
	_check(code.long_methods(10).size() == 1, "trova il metodo troppo lungo")
	_check(code.long_methods(30).is_empty(), "con un limite alto nessun metodo è lungo")


func test_public_fields() -> void:
	var code: JavaCode = JavaCode.parse("""public class Esposta {
    public String nome;
    private int eta;
    public static final int MAX = 100;
}""")
	var exposed: Array = code.public_fields()
	_equal(exposed.size(), 1, "solo il campo public non costante è un problema")
	_equal(String(exposed[0]["name"]), "nome", "il campo esposto è nome")


func test_poor_names() -> void:
	var code: JavaCode = JavaCode.parse("""public class Dati {
    private int x;
    private String descrizione;
    public void f() {
    }
}""")
	var poor: Array = code.poor_names(3)
	_equal(poor.size(), 2, "trova il campo x e il metodo f")


func test_duplicated_lines() -> void:
	var code: JavaCode = JavaCode.parse("""public class Doppio {
    public void a() {
        System.out.println("stessa riga ripetuta");
    }
    public void b() {
        System.out.println("stessa riga ripetuta");
    }
}""")
	_check(code.duplicated_lines().size() >= 1, "trova la riga duplicata")

	var unique: JavaCode = JavaCode.parse(CONTO)
	_check(unique.duplicated_lines().is_empty(), "un codice sano non ha duplicati")


func test_interface_and_inheritance() -> void:
	var code: JavaCode = JavaCode.parse("""public interface Ordinabile {
	int confronta(Object altro);
}""")
	_equal(code.type_kind, "interface", "riconosce un'interfaccia")
	_check(code.declares_method("confronta"), "trova il metodo astratto")

	var child: JavaCode = JavaCode.parse(
		"public class Cerchio extends Figura implements Disegnabile, Serializable { }")
	_equal(child.extends_name, "Figura", "legge extends")
	_check(child.implements_names.has("Disegnabile"), "legge il primo implements")
	_check(child.implements_names.has("Serializable"), "legge il secondo implements")


# ------------------------------------------------------------ correttore ----

func test_task_ok() -> void:
	var task: JavaTask = JavaTask.make("Scrivi la classe.", "", [
		{"kind": "class_named", "name": "ContoCorrente"},
		{"kind": "no_public_fields"},
		{"kind": "has_method", "method": "getSaldo"},
		{"kind": "no_magic_numbers"},
	])
	var verdict: Dictionary = JavaTask.check(task, CONTO)
	_equal(String(verdict["status"]), "ok", "il codice corretto passa tutti i controlli")


func test_task_errors() -> void:
	var task: JavaTask = JavaTask.make("Qualsiasi.", "", [])

	var empty: Dictionary = JavaTask.check(task, "   ")
	_equal(String(empty["status"]), "error", "codice vuoto rifiutato")

	var unbalanced: Dictionary = JavaTask.check(task, "public class A { void x() { }")
	_equal(String(unbalanced["status"]), "error", "graffe sbilanciate rifiutate")
	_check(String(unbalanced["message"]).contains("graffe"), "il messaggio parla delle graffe")

	var no_class: Dictionary = JavaTask.check(task, "int x = 3;")
	_equal(String(no_class["status"]), "error", "senza classe è un errore")


func test_task_encapsulation() -> void:
	var task: JavaTask = JavaTask.make("Incapsula.", "", [
		{"kind": "field_private", "field": "saldo"},
		{"kind": "has_method", "method": "getSaldo"},
	])

	var exposed: String = """public class Conto {
    public double saldo;
}"""
	var wrong: Dictionary = JavaTask.check(task, exposed)
	_equal(String(wrong["status"]), "wrong", "campo pubblico non passa")
	_check(String(wrong["message"]).contains("private"), "il messaggio spiega il perché")

	var missing_getter: String = """public class Conto {
    private double saldo;
}"""
	var no_getter: Dictionary = JavaTask.check(task, missing_getter)
	_equal(String(no_getter["status"]), "wrong", "senza getter non passa")
	_check(String(no_getter["message"]).contains("getSaldo"), "il messaggio nomina il metodo mancante")


func test_task_refactoring() -> void:
	var task: JavaTask = JavaTask.make("Ripulisci.", "", [
		{"kind": "no_magic_numbers"},
		{"kind": "meaningful_names", "min_length": 3},
		{"kind": "max_method_lines", "max": 12},
	])

	var smelly: String = """public class Ordine {
    public double t(double p) {
        return p * 1.22;
    }
}"""
	var verdict: Dictionary = JavaTask.check(task, smelly)
	_equal(String(verdict["status"]), "wrong", "il codice con difetti non passa")

	var clean: String = """public class Ordine {
    private static final double ALIQUOTA_IVA = 1.22;

    public double totaleConIva(double imponibile) {
        return imponibile * ALIQUOTA_IVA;
    }
}"""
	var good: Dictionary = JavaTask.check(task, clean)
	_equal(String(good["status"]), "ok", "il codice ripulito passa")
