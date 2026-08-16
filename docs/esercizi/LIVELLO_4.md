# Aggiungere esercizi al Livello 4 — Code Review (Java)

Gli esercizi di questo livello **non sono nel codice**: stanno in

```
res://data/esercizi_livello_4.json
```

Per aggiungerne uno si aggiunge una voce a quel file. Non serve toccare nessuno script.
`scripts/phases/lvl4/Lvl4Catalogo.gd` si limita a caricarlo, normalizzarlo e sorteggiare.

> **Dopo ogni modifica lancia i test.** Validano ogni singola voce e ti dicono subito se hai sbagliato qualcosa:
> ```
> godot --headless --script res://tests/run_lvl4_tests.gd
> ```

---

## Come viene corretto il codice, e perché conta

Il gioco **non compila il Java**: analizza la *struttura* del codice scritto — classi, campi, visibilità, metodi, lunghezze, nomi, annotazioni, duplicazioni. Quando scrivi un esercizio devi quindi esprimere la richiesta come un elenco di **controlli** verificabili sulla forma, non sul risultato dell'esecuzione.

Va bene: «il campo deve essere privato», «nessun metodo oltre 8 righe», «niente numeri magici».
Non è esprimibile: «il metodo deve restituire 42».

---

## La forma del file

```json
{
  "review":   [ ... ],
  "split":    [ ... ],
  "refactor": [ ... ],
  "write":    [ ... ]
}
```

Le quattro liste alimentano fasi diverse:

| Lista | Fase | Che cosa fa il giocatore |
|---|---|---|
| `review` | 1 e 2 | Clicca le righe difettose di uno spezzone |
| `split` | 2 | Assegna ogni metodo alla classe a cui appartiene |
| `refactor` | 3 | Riscrive nell'editor codice che ha dei difetti |
| `write` | 4 | Scrive codice nuovo (classe, JavaFX, persistenza) |

**Il codice Java si scrive come array di righe**, non come stringa unica:

```json
"code": [
  "public class Fattura {",
  "    private double t;",
  "}"
]
```

Due motivi: si legge in un file di dati, e negli esercizi a clic **l'indice della riga coincide con la posizione nell'array** (partendo da 0), quindi indicare le righe difettose diventa immediato.

---

## 1. Esercizi `review` — clicca le righe difettose

```json
{
  "topic": "clean",
  "name": "nomi e numeri magici",
  "question": "Clicca le righe con nomi che non spiegano nulla o con numeri senza nome.",
  "code": [
    "public class Fattura {",
    "    private double t;",
    "",
    "    public double c(double p) {",
    "        return p * 1.22;",
    "    }",
    "}"
  ],
  "bad": [1, 3, 4],
  "hint": "Un nome deve dire che cosa contiene. Un numero deve dire da dove viene.",
  "explain": "«t» e «c» non dicono niente, e 1.22 è l'IVA."
}
```

| Campo | Significato |
|---|---|
| `topic` | `"clean"` (Fase 1) oppure `"solid"` (Fase 2) — sono due pescate separate |
| `name` | Titolo mostrato sopra il codice |
| `question` | L'obiettivo in alto: dev'essere **inequivocabile su cosa cliccare** |
| `code` | Le righe del codice |
| `bad` | Indici delle righe da cliccare, **contati da 0** |
| `hint` | Suggerimento (compare solo se il giocatore è in difficoltà) |
| `explain` | Spiegazione mostrata quando indovina |

**Vincoli (li verificano i test):** almeno una riga in `bad`; ogni indice deve esistere e **non essere una riga vuota**; non possono essere difettose *tutte* le righe; servono `question`, `hint` e `explain`.

> ⚠️ **L'errore più frequente è sbagliare gli indici.** Conta le righe partendo da **0** e ricorda che le righe vuote contano. Nell'esempio la riga 2 è vuota, quindi il metodo comincia alla 3.

---

## 2. Esercizi `split` — separa le responsabilità

```json
{
  "name": "Ordine",
  "origin": "Ordine",
  "targets": ["Ordine  ·  dominio", "RepositoryOrdini  ·  persistenza"],
  "methods": [
    ["double calcolaTotale()", 0],
    ["void salvaSuDatabase()", 1]
  ],
  "hint": "Se cambia il database, quali metodi devo toccare?",
  "explain": "Le due classi cambiano per motivi diversi."
}
```

`methods` è una lista di coppie `[firma, indice della classe di destinazione]`.

**Vincoli:** esattamente **due** destinazioni; almeno tre metodi; **entrambe** le classi devono ricevere almeno un metodo, altrimenti non c'è niente da separare.

---

## 3. Esercizi `refactor` — riscrivi il codice

```json
{
  "prompt": "Dai un nome ai numeri di questo calcolo.",
  "code": ["public class Sconto {", "    ...", "}"],
  "checks": [
    {"kind": "no_magic_numbers"},
    {"kind": "contains", "text": "static final",
     "message": "I numeri devono diventare costanti: usa static final."}
  ],
  "solution": ["public class Sconto {", "    ...", "}"],
  "hint": "Tre numeri, tre costanti.",
  "explain": "Con i nomi al posto dei numeri la regola si legge nel codice."
}
```

| Campo | Significato |
|---|---|
| `prompt` | La richiesta. È anche l'**identità** dell'esercizio: dev'essere unica |
| `code` | Codice di partenza, precaricato nell'editor |
| `checks` | I controlli da superare (elenco sotto) |
| `solution` | Una soluzione di riferimento: la usa il bot di collaudo |
| `hint`, `explain` | Come sopra |

**Tre regole che i test verificano:**

1. **Il codice di partenza NON deve già superare i controlli**, altrimenti l'esercizio nasce risolto.
2. **La soluzione di riferimento deve superarli tutti.**
3. **Le richieste devono essere tutte diverse** fra loro.

---

## 4. Esercizi `write` — scrivi codice nuovo

Identici ai `refactor`, più il campo `topic`, e `code` può essere vuoto (`[]`) per far scrivere da zero:

```json
{
  "topic": "classe",
  "prompt": "Scrivi la classe Libro: titolo, autore e anno privati, costruttore, getter e toString().",
  "code": [],
  "checks": [
    {"kind": "class_named", "name": "Libro"},
    {"kind": "no_public_fields"},
    {"kind": "has_method", "method": "toString"}
  ],
  "solution": ["public class Libro {", "    ...", "}"],
  "hint": "...",
  "explain": "..."
}
```

`topic` vale `"classe"`, `"javafx"` o `"persistenza"`: la Fase 4 pesca **un esercizio per argomento**.

> ⚠️ **Ogni argomento deve avere almeno due esercizi**, altrimenti esce sempre lo stesso. C'è un test apposta, perché è esattamente l'errore che c'era prima.

---

## I controlli disponibili

| `kind` | Parametri | Verifica |
|---|---|---|
| `class_named` | `name` | La classe si chiama così |
| `kind_is` | `value` | È una `class`, `interface`, `enum`, `record` |
| `extends` | `name` | Estende quella classe |
| `implements` | `name` | Implementa quell'interfaccia |
| `has_field` | `field` | Il campo esiste |
| `field_private` | `field` | Quel campo è `private` |
| `no_public_fields` | — | Nessun campo accessibile da fuori (le costanti `static final` sono ammesse) |
| `has_method` | `method` | Il metodo esiste |
| `lacks_method` | `method` | Il metodo **non** deve esserci (utile per SRP) |
| `method_count_at_least` | `count` | Almeno N metodi (per le estrazioni) |
| `method_count_at_most` | `count` | Al massimo N metodi (per le classi che fanno troppo) |
| `max_method_lines` | `max` | Nessun metodo più lungo di N righe |
| `no_magic_numbers` | — | Niente numeri nel corpo dei metodi (0, 1, 2, −1 sono ammessi) |
| `meaningful_names` | `min_length` | Nomi di campi e metodi non più corti di N |
| `no_duplicated_lines` | — | Nessuna riga di codice ripetuta |
| `contains` | `text` | Il codice contiene quel testo (ignora spazi e maiuscole) |
| `lacks` | `text` | Il codice **non** contiene quel testo |
| `has_annotation` | `name` | La classe ha `@Nome` |
| `field_annotated` | `field`, `name` | Quel campo ha `@Nome` |
| `max_code_lines` | `max` | Il codice non supera N righe utili |

Ogni controllo accetta un `"message"` proprio: **usalo**. Il messaggio predefinito è generico, e questo livello insegna soprattutto attraverso il messaggio d'errore. Meglio *«il campo saldo è pubblico: chiunque può scriverci un valore negativo senza passare dai controlli della classe»* che *«il campo saldo non è private»*.

Per aggiungere un controllo nuovo servono tre cose: un ramo nel `match` di `JavaTask._run_check()`, l'interrogazione corrispondente in `JavaCode.gd` e i casi in `tests/test_lvl4.gd`.

---

## Verificare

```bash
GODOT="percorso/di/godot"

# 1. valida ogni voce del catalogo (254 test)
"$GODOT" --headless --script res://tests/run_lvl4_tests.gd

# 2. il bot gioca il livello usando le soluzioni di riferimento
"$GODOT" tests/autoplay_level4.tscn
```

Nel bot due costanti aiutano a guardare le fasi: `STOP_AT_PHASE` lo ferma all'inizio di una fase, `CONFIRM_DELAY` ritarda la conferma di una risposta.

---

## Due trappole già pagate

**Gli interi del JSON.** JSON non distingue interi e decimali: `1` torna come `1.0`, e in GDScript `[1.0].has(1)` è **falso**. Il caricatore riporta a intero gli indici di `bad` e le destinazioni di `methods`. Se aggiungi un campo numerico che serve da indice, **convertilo in `_normalise()`** e aggiungi il caso a `test_json_types()`.

**L'esportazione.** In export il `.json` non viene incluso automaticamente: `export_presets.cfg` contiene il filtro `*.json`, ma non è ancora stato verificato su un export reale (mancavano i template). Al primo export vero, controlla che gli esercizi ci siano: se il livello parte vuoto, il problema è quello, e il caricatore lo segnala con un messaggio esplicito.

---

## Idee di esercizi da aggiungere

**`review` · clean code** — un metodo con troppi parametri (segnale di una classe mancante) · variabili riusate per scopi diversi · un `catch` vuoto che ingoia l'eccezione · numeri booleani come parametri (`salva(true, false)`) · una costante duplicata in due punti.

**`review` · SOLID** — **LSP**: una sottoclasse che lancia `UnsupportedOperationException` su un metodo ereditato · **ISP**: un'interfaccia con otto metodi di cui l'implementazione ne usa due, lasciando gli altri vuoti · **OCP**: uno `switch` sul tipo che ritorna comportamenti diversi.

**`split`** — separare `Fattura` (calcolo) da `StampaFattura` (formattazione) · separare `Partita` (regole) da `SalvataggioPartita` (file) · separare validazione e invio in un modulo di registrazione.

**`refactor`** — sostituire una catena di `if` sul tipo con il polimorfismo (serve `lacks` su `else if`) · trasformare un metodo statico che lavora su una classe in un metodo di quella classe · estrarre una classe da un gruppo di campi che viaggiano sempre insieme (`via`, `civico`, `cap` → `Indirizzo`).

**`write` · classe** — una classe immutabile con campi `final` e nessun setter · una classe che implementa `Comparable` · una classe con `equals` e `hashCode`.

**`write` · JavaFX** — una `TableView` con le colonne · un layout `BorderPane` con menu in alto · una finestra di dialogo di conferma.

**`write` · persistenza** — una relazione `@ManyToOne` fra due entity · `@OneToMany` con `mappedBy` · una `@NamedQuery` · un file `persistence.xml` (servirebbe un controllo nuovo, perché non è Java).

---

Per la struttura del livello (fasi, viste, controller) vedi [CREARE_UN_LIVELLO.md](../CREARE_UN_LIVELLO.md), capitolo 5.
