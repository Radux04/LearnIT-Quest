# LearnIT Quest

**Edugame 2D in Godot 4.5 che insegna le strutture dati e gli algoritmi facendoli usare, non spiegandoli.**

Ogni livello è una "missione informatica" da completare in **5 minuti**: niente quiz a risposta multipla, ma meccaniche di gioco in cui l'algoritmo *è* il gameplay. Se il tempo scade la partita è persa e si può ricominciare o tornare al menu.

| | |
|---|---|
| **Engine** | Godot 4.5 (Forward+) |
| **Risoluzione** | 1280×720, stretch `canvas_items` / `expand` |
| **Lingua** | Italiano |
| **Livelli disponibili** | 1 — Binary Search Tree Network · 2 — Database Recovery (MySQL) |

---

## Livello 1 · Binary Search Tree Network

La rete informatica è rappresentata come un albero di **router futuristici** collegati da **cavi luminosi** percorsi da **pacchetti animati**. Ogni router è un nodo del BST e la sua "metrica" è la chiave. Nell'ultima fase la rete si apre in un **grafo pesato** e si passa al cammino minimo con **Dijkstra**.

Le metriche sono **numeri decimali** scelti a coppie ravvicinate (`25.5` / `25.9`, `62.1` / `62.4`): non basta guardare la parte intera, bisogna confrontare davvero.

### Introduzione teorica (3 pagine)

Prima del gameplay c'è una spiegazione navigabile con diagramma animato:

1. **Che cos'è un BST** — nodi, cavi, radice, la regola d'oro (minori a sinistra, maggiori a destra) e il fatto che vale a *ogni* livello, non solo alla radice.
2. **La ricerca** — perché costa quanto l'*altezza* dell'albero e non il numero di nodi, cosa succede quando il valore **non esiste** (vicolo cieco), e le quattro visite. Il diagramma evidenzia il percorso di ricerca reale.
3. **Dijkstra** — cosa cambia quando i percorsi diventano più di uno: cavi con latenze diverse, il ciclo *fissa il minimo / rilassa i vicini*, e il fatto che il percorso con meno salti spesso **non** è il più veloce. Il diagramma mostra un grafo pesato con il cammino ottimo in oro.
4. **La missione** — le 5 fasi, il timer, i comandi e le penalità.

Il livello parte solo premendo *"Inizia la missione"*.

### Le quattro fasi

Le fasi si susseguono **senza caricamenti**: la rete disegnata a schermo è sempre la stessa e viene riorganizzata dal vivo, fino a trasformarsi in un grafo pesato nell'ultima fase.

| Fase | Cosa fa il giocatore | Concetto di algoritmi | Penalità |
|---|---|---|---|
| **1 · Ricostruzione** | Trascina 8 router nelle postazioni libere della rete | **Inserimento** in un BST | −5 s |
| **2 · Instradamento** | Guida 6 pacchetti dalla radice alla destinazione scegliendo SINISTRA/DESTRA — e riconosce i **vicoli ciechi** | **Ricerca** con esito positivo *e negativo* | −12 s |
| **3 · Scansione** | Clicca i router nell'ordine di una visita estratta a caso | **Preorder, Inorder, Postorder, BFS** | −10 s |
| **4 · Attacco finale** | Risponde a 5 richieste rapide e casuali | **Inserimento, cancellazione (con successore in-order), ricerca, minimo, massimo, successore** | −15 s |
| **5 · Instradamento ottimale** | Esegue a mano il ciclo di **Dijkstra** sulla rete diventata un grafo pesato | **Cammino minimo**, rilassamento, differenza fra "meno salti" e "costo minore" | −12 s |

Dettagli che rendono l'esperienza didattica e non un quiz:

- **Fase 1** — se sbagli, il messaggio spiega *esattamente perché*: «25.9 NON è minore di 25.5: non può stare a sinistra». Le postazioni libere sono cerchi tratteggiati pulsanti, quindi il giocatore vede subito dove *si potrebbe* inserire.
- **Fase 2** — 2 pacchetti su 7 hanno una destinazione che **non esiste** in rete. Il giocatore deve accorgersi che dal lato in cui dovrebbe scendere non parte alcun cavo e premere **`✖ NON IN RETE`**. A consegna riuscita il gioco mostra il costo reale: *«Consegnato a 74.5 in 2 confronti invece di 9 router controllati!»*.
- **Fase 3** — la regola della visita è mostrata solo nel **primo** dei tre round: dal secondo bisogna ricordarsela. Ogni clic corretto illumina il router e gli assegna il numero d'ordine.
- **Fase 4** — la cancellazione sceglie di preferenza un nodo con **due figli**, il caso più istruttivo, e spiega che al suo posto sale il **successore in-order**. Lo sfondo pulsa in rosso durante l'attacco.
- **Fase 5** — l'hacker, ritirandosi, riattiva i **cavi ridondanti**: l'albero diventa un **grafo pesato**, ogni cavo mostra la sua latenza in ms e fra due router esistono più strade. Il giocatore esegue il ciclo di Dijkstra a mano: a ogni turno deve cliccare il router **non ancora fissato con il costo provvisorio più basso**. Il gioco si occupa del **rilassamento** dei vicini e aggiorna i badge (`∞` → costo provvisorio → costo definitivo), così l'algoritmo si *vede* lavorare; alla fine il cammino ottimo si illumina in oro. Cliccare troppo presto un router costoso spiega l'errore: «Troppo presto: 62.4 costa 11, ma c'è ancora un router non fissato a 8. Dijkstra prende sempre il minimo!». È lo stesso algoritmo che il protocollo **OSPF** usa davvero nei router.

### Comandi

| Azione | Comando |
|---|---|
| Trascinare un router | Mouse (tieni premuto e rilascia sulla postazione) |
| Selezionare/scansionare un router | Clic sinistro |
| Instradare a sinistra / destra | Pulsanti oppure **←** / **→** |
| Dichiarare che il valore non è in rete | Pulsante **`✖ NON IN RETE`** oppure **↓** |
| Avanzare nell'introduzione | **Invio / Spazio**, indietro con **Esc** |

---

## Struttura del progetto

```
res://
├── scenes/
│   ├── main_menu.tscn          scena principale del gioco
│   ├── introduction.tscn       teoria Livello 1 (4 pagine)
│   ├── level.tscn              Livello 1 — rete di router
│   ├── introduction2.tscn      teoria Livello 2 (6 pagine)
│   ├── level2.tscn             Livello 2 — database MySQL
│   ├── introduction3.tscn      teoria Livello 3 (7 pagine)
│   ├── level3.tscn             Livello 3 — calcolabilità
│   ├── introduction4.tscn      teoria Livello 4 (4 pagine)
│   └── level4.tscn             Livello 4 — code review Java
├── scripts/
│   ├── global/
│   │   ├── GameManager.gd      autoload: timer, penalità, cambio scena
│   │   └── Sfx.gd              autoload: audio sintetizzato a runtime
│   ├── bst/BSTModel.gd         il BST puro (nessuna grafica)
│   ├── graph/NetworkGraph.gd   grafo pesato + algoritmo di Dijkstra
│   ├── sql/
│   │   ├── SqlTokenizer.gd     da testo a token
│   │   ├── SqlParser.gd        da token ad albero sintattico
│   │   ├── SqlEngine.gd        esegue l'albero sul database
│   │   ├── SqlDatabase.gd      tabelle, righe, confronti, snapshot
│   │   └── SqlTask.gd          obiettivi e correzione per equivalenza
│   ├── ui/
│   │   ├── NetworkView.gd      disegna la rete: cavi, slot, pacchetti
│   │   ├── RouterNode.gd       un router: stati, drag & drop, clic
│   │   ├── SqlTableView.gd     una tabella con colonne e righe
│   │   ├── SqlConsole.gd       editor di query + griglia risultato
│   │   └── SqlManual.gd        manuale in sovraimpressione (-10 s)
│   ├── phases/
│   │   ├── lvl1/                Lvl1PhaseBase.gd (PhaseBase.gd) + le cinque fasi del Livello 1
│   │   ├── lvl2/                SqlPhaseBase.gd + le cinque fasi SQL
│   │   ├── lvl3/                Lvl3PhaseBase.gd, Lvl3Pools.gd + le cinque fasi
│   │   └── lvl4/                Lvl4PhaseBase.gd, Lvl4Catalogo.gd + le quattro fasi
│   └── scenes/
│       ├── MainMenu.gd
│       ├── IntroductionScreen.gd · Introduction2Screen.gd
│       └── Level.gd · Level2.gd    orchestratori + HUD
├── tests/
│   ├── autoplay.tscn           bot che gioca il Livello 1
│   ├── autoplay_level2.tscn    bot che gioca il Livello 2
│   ├── autoplay_level3.tscn    bot che gioca il Livello 3
│   ├── timeout.tscn            verifica la schermata "tempo scaduto"
│   └── test_sql_engine.gd      52 test del motore SQL
└── assets/generated/           sprite pixel art generati
```

### Idea architetturale

Tre strati separati, ognuno ignaro di quello sopra:

```
BSTModel          ← solo dati e algoritmi, nessun nodo Godot
   ↑
NetworkView       ← solo rendering e animazioni, nessuna regola di gioco
   ↑
Lvl1PhaseBase     ← le regole dei mini-giochi (che cosa è giusto o sbagliato)
   ↑
Phase1..4         ← la sceneggiatura: quali mini-giochi, con quali parametri
   ↑
LevelController   ← HUD, timer, sequenza delle fasi, schermate di fine
```

Grazie a questa separazione un nuovo livello su un'altra struttura dati riusa quasi tutto: si scrive un nuovo *model*, si adatta la *view* e si compongono nuove fasi. La guida passo-passo è in **[`docs/CREARE_UN_LIVELLO.md`](docs/CREARE_UN_LIVELLO.md)**.

### Audio

Nessun file audio nel repository: `Sfx.gd` sintetizza a runtime tutti i suoni (clic, conferma, errore, allarme, vittoria, sconfitta) generando le forme d'onda PCM in un `AudioStreamWAV`. Per aggiungere una nuova voce basta una riga in `_ready()`.

---

## Come eseguire il gioco

1. Apri il progetto con **Godot 4.5** o superiore.
2. Premi **F5** (la scena principale è `res://scenes/main_menu.tscn`).

Per provare direttamente il livello: apri `res://scenes/level.tscn` e premi **F6**.

> **Nota:** il progetto usa due autoload (`GameManager` e `Sfx`). Se dopo aver clonato il repo l'editor segnala `Identifier not found: GameManager`, riavvia l'editor: gli autoload vengono registrati all'avvio.

## Test automatici

Il progetto include due scene di verifica, utili dopo ogni modifica:

| Scena | Cosa fa |
|---|---|
| `res://tests/autoplay.tscn` | Istanzia il Livello 1 e lo **gioca da solo in modo sempre corretto**, attraversando tutte e 5 le fasi fino alla vittoria. Stampa in console ogni mossa. |
| `res://tests/autoplay_level2.tscn` | Gioca il Livello 2 inviando alla console le soluzioni dei 19 obiettivi, e verifica anche penalità e manuale. |
| `res://tests/autoplay_level3.tscn` | Gioca il Livello 3: esegue automi, determinizza, fa girare le macchine di Turing e scrive i programmi WHILE. `STOP_AT_PHASE` lo ferma su una fase per guardarla, `CHOICE_DELAY` ritarda la risposta alle scelte multiple. |
| `res://tests/timeout.tscn` | Porta il cronometro a zero e verifica la schermata *Tempo Scaduto* con i due pulsanti. |
| `res://tests/test_sql_engine.gd` | 52 test del motore SQL, eseguibili senza aprire l'editor (vedi sopra). |

Esegui `autoplay.tscn` con **F6**: se arriva a `RETE RIPRISTINATA` senza errori runtime, l'intera catena (modello, vista, fasi, HUD) è sana. Alza `TIME_SCALE` in `AutoPlayHarness.gd` per accelerare la verifica.

## Il suggerimento a scadenza

In tutti e quattro i livelli la riga in basso contiene un **suggerimento**, e quel suggerimento spesso contiene mezza risposta. Se fosse visibile da subito, nessuno proverebbe a ragionare.

Resta quindi **nascosto** finché il giocatore non è davvero in difficoltà, cioè quando si verifica una di queste due condizioni:

- ha commesso **almeno 5 errori nella fase corrente**, oppure
- è fermo **sulla stessa fase** da un tempo pari al **25% della durata totale** del livello.

Al posto del suggerimento compare, in grigio, quanto manca allo sblocco: *«🔒 Suggerimento: si sblocca dopo altri 3 errori in questa fase, oppure fra 2:14»*.

**Entrambe le condizioni ripartono da zero a ogni fase:** all'inizio di una fase nuova il suggerimento torna sempre bloccato. È il motivo per cui il tempo si misura dall'inizio della fase e non dall'inizio del livello — altrimenti, superata la soglia una volta, il suggerimento resterebbe visibile per tutte le fasi successive.

Il tempo contato è quello *passato a pensare*: la pausa non lo fa avanzare, e nemmeno le penalità (che accorciano il cronometro ma non fanno passare il tempo). Non contano come errori i costi scelti volontariamente — aprire il manuale nel Livello 2 toglie tempo ma non avvicina lo sblocco.

La regola sta tutta in `scripts/ui/HintGate.gd`, nelle costanti `ERRORS_TO_UNLOCK` e `TIME_RATIO_TO_UNLOCK`.

---

## Aggiungere esercizi

Ogni livello ha una guida pratica dedicata, con il formato dei dati, i vincoli, come verificare e un elenco di idee da implementare:

| Livello | Guida | Dove stanno gli esercizi |
|---|---|---|
| 1 · Router | [docs/esercizi/LIVELLO_1.md](docs/esercizi/LIVELLO_1.md) | Costanti nelle fasi (`ROUTERS_TO_PLACE`, `CHALLENGE_COUNT`, …) |
| 2 · SQL | [docs/esercizi/LIVELLO_2.md](docs/esercizi/LIVELLO_2.md) | Elenchi `SqlTask.make(...)` in `scripts/phases/lvl2/` |
| 3 · Calcolabilità | [docs/esercizi/LIVELLO_3.md](docs/esercizi/LIVELLO_3.md) | Catalogo `scripts/phases/lvl3/Lvl3Pools.gd` |
| 4 · Java | [docs/esercizi/LIVELLO_4.md](docs/esercizi/LIVELLO_4.md) | **File JSON**: `data/esercizi_livello_4.json` |

Il Livello 4 è l'unico con gli esercizi in un **file di dati** invece che nel codice: si aggiungono senza aprire uno script. Il formato è documentato per intero nella sua guida.

---

## Bilanciamento

Tutte le manopole sono raccolte in pochi punti:

| Cosa | Dove |
|---|---|
| Durata dei livelli | `GameManager.LEVEL_DURATION`, `LEVEL2_DURATION`, `LEVEL3_DURATION`, `LEVEL4_DURATION` |
| Costo del manuale | `SqlManual.COST_SECONDS` |
| Penalità del Livello 2 | `Level2Controller.PENALTY_SYNTAX`, `PENALTY_WRONG` |
| Obiettivi del Livello 2 | le liste `SqlTask.make(...)` in `scripts/phases/lvl2/Phase1..5.gd` |
| Penalità delle 4 fasi | `Lvl1PhaseBase.PENALTY_PLACE / ROUTE / SCAN / ATTACK` |
| Router da posizionare | `Phase1.ROUTERS_TO_PLACE` |
| Numero di pacchetti e valori assenti | `Phase2.PRESENT_PACKETS`, `ABSENT_PACKETS`, `ABSENT_CANDIDATES` |
| Numero di visite | `Phase3.ROUNDS` |
| Numero e mix di sfide finali | `Phase4.CHALLENGE_COUNT`, `Phase4._build_plan()` |
| Cavi ridondanti e latenze | `Phase5.EXTRA_LINKS`, `MIN_WEIGHT`, `MAX_WEIGHT` |

---

---

## Livello 2 · Database Recovery (MySQL)

Il database della LearnIT Corp è stato attaccato. Qui non si clicca: **si scrive SQL**. Durata **10 minuti**.

Lo schermo è diviso in due: in alto le **tabelle sempre visibili** (nome, colonne con il loro tipo, righe), in basso la **console** in cui scrivere le query, con la griglia del risultato accanto all'editor. Le righe nuove o modificate lampeggiano in verde, le eliminazioni tingono di rosso il titolo della tabella.

### Le cinque fasi (19 obiettivi)

| Fase | Comandi | Esempi di obiettivo |
|---|---|---|
| **1 · Interrogazione** | `SELECT`, `WHERE`, `ORDER BY`, `COUNT` | *"Mostra nome ed eta dei clienti con più di 30 anni, dal più vecchio"* |
| **2 · Ricostruzione** | `CREATE TABLE`, `INSERT INTO` | *"La tabella prodotti è andata perduta: ricreala con id, nome, prezzo"* |
| **3 · Correzione** | `UPDATE ... SET ... WHERE` | *"Tutti i clienti di Roma hanno compiuto gli anni"* → `SET eta = eta + 1` |
| **4 · Bonifica** | `DELETE`, `DROP TABLE` | *"La tabella temp_backup è spazzatura: eliminala completamente"* |
| **5 · Query nidificate** | subquery scalari, `IN`, `NOT IN` | *"I clienti più vecchi della media"* → `WHERE eta > (SELECT AVG(eta) ...)` |

### Il manuale a pagamento

In alto c'è il pulsante **MANUALE**: apre in sovraimpressione la sintassi completa su 4 pagine, **al costo di 10 secondi di cronometro per ogni apertura** — l'idea è quella del manuale di *Keep Talking and Nobody Explodes*. Si apre già sulla pagina utile alla fase in corso, e il pulsante mostra quante volte l'hai consultato. Sapere la sintassi a memoria è un vantaggio concreto in secondi.

### Come vengono corrette le query

La correzione **non confronta il testo** della query. La query del giocatore e una soluzione di riferimento vengono eseguite su due copie identiche del database, poi si confrontano:

- per le `SELECT` → il **risultato** (colonne e righe; l'ordine conta solo se la soluzione usa `ORDER BY`);
- per le modifiche → lo **stato finale del database**.

Quindi ogni formulazione corretta è accettata: condizioni in ordine diverso, `IN (...)` invece di una catena di `OR`, alias, maiuscole/minuscole, spazi e a capo. Una modifica sbagliata **non viene applicata**, così il database non resta in uno stato incoerente.

Penalità: **−8 s** per una query con errore di sintassi, **−12 s** per una query valida che non risolve l'obiettivo, **−10 s** per ogni apertura del manuale.

### Il motore SQL

`scripts/sql/` contiene un interprete SQL scritto da zero in GDScript (tokenizer → parser a discesa recursiva → esecutore), che supporta:

`SELECT` (con `*`, elenco di colonne, alias, `DISTINCT`) · `WHERE` con `AND`/`OR`/`NOT`/parentesi, `=` `!=` `<` `<=` `>` `>=`, `IN`, `NOT IN`, `BETWEEN`, `LIKE` (`%` e `_`), `IS NULL` · aggregati `COUNT`/`SUM`/`AVG`/`MIN`/`MAX` con `GROUP BY` · `ORDER BY` e `LIMIT` · **subquery** scalari e di colonna · espressioni aritmetiche · `INSERT INTO` (con e senza elenco colonne) · `UPDATE ... SET` · `DELETE` · `CREATE TABLE` · `DROP TABLE`.

Gli errori sono messaggi didattici in italiano, non stack trace. È coperto da **52 test**:

```
godot --headless --script res://tests/run_sql_tests.gd
```

---

## Livello 3 · Laboratorio di Calcolabilità

Fondamenti dell'informatica teorica: dai riconoscitori più semplici fino ai **limiti del calcolo**. Durata **12 minuti**.

Il principio è sempre lo stesso: non si risponde a domande sulla teoria, **si esegue la teoria**.

### Introduzione teorica (7 pagine)

Automi di riconoscimento · non determinismo, ε-transizioni e costruzione per sottoinsiemi · macchine di Turing, funzioni calcolabili, linguaggi decidibili e semidecidibili, tesi di Church-Turing, macchine non deterministiche · macchina universale, problema dell'arresto, teoremi di Rice e Kleene, decimo problema di Hilbert · funzioni ricorsive, calcolabilità secondo Church, minimalizzazione μ e funzioni parziali ricorsive · sintassi e semantica del linguaggio WHILE · la missione.

### Le quattro fasi

| Fase | Argomento | Che cosa fa il giocatore |
|---|---|---|
| 1 · Automi deterministici | DFA, linguaggi regolari | **Esegue** l'automa: legge un simbolo, clicca lo stato di arrivo, poi dichiara se la parola è accettata |
| 2 · Determinizzazione | NFA, ε-chiusura, trasformazioni | Esegue a mano la **costruzione per sottoinsiemi**: seleziona tutti gli stati raggiungibili |
| 3 · Macchine di Turing | nastro, quintuple, δ | Applica la **quintupla giusta** a ogni passo, poi progetta la regola mancante e guarda la macchina girare |
| 4 · Linguaggio WHILE | calcolabilità e programmazione | **Scrive programmi veri** nella notazione del corso: divisione con resto, moltiplicazione, MCD, fattoriale |

Gli esercizi sono **sorteggiati a ogni partita** da un catalogo (`scripts/phases/lvl3/Lvl3Pools.gd`): due partite di fila non propongono gli stessi.

> La fase sul **problema dell'arresto** (argomento diagonale) è scritta e funzionante in `scripts/phases/lvl3/Phase4.gd`, ma è **fuori rotazione**: per rimetterla in gioco basta aggiungere il suo percorso a `PHASE_SCRIPTS` in `Level3.gd` e il banner corrispondente. La teoria resta comunque nell'introduzione.

Penalità: **−6 s** per un passo di esecuzione sbagliato, **−10 s** per una scelta sbagliata, **−8 s** per un programma che non compila, **−12 s** per un programma che gira ma non risolve.

### L'interprete WHILE

`scripts/computability/WhileInterpreter.gd` è un interprete completo (tokenizer → parser a discesa ricorsiva → semantica operazionale) del linguaggio WHILE: assegnamento, sequenza, `while`, `if`, aritmetica sui naturali con **sottrazione troncata** (`3 - 5` fa `0`).

Accetta **due notazioni** per lo stesso linguaggio. Quella compatta:

```
z := x; while y != 0 do z := z + 1; y := y - 1 end
```

e quella **accademica del corso**, che è anche quella in cui sono scritte le soluzioni di riferimento:

```
begin
INPUT(X); INPUT(Y);
Z := 0;
while Y > 0 do
     begin Z := Z + X; Y := Y - 1 end
OUTPUT(Z)
end
```

con blocchi `begin`…`end`, `INPUT`/`OUTPUT`, il successore `s(x)` e il predecessore `pd(x)`, e il `;` facoltativo dopo un `end`. Gli esercizi provengono dall'eserciziario del corso (`docs/esercizi_livello_3.pdf`).

Il **limite di passi** non è un dettaglio tecnico ma il cuore didattico del livello: un programma può non terminare, e in quel caso calcola una funzione **parziale**. L'interprete non può saperlo in anticipo — è esattamente il problema dell'arresto — quindi a un certo punto si arrende e lo dichiara.

Come nel Livello 2 la correzione è **per equivalenza**: il programma del giocatore e quello di riferimento girano sugli stessi stati iniziali e si confrontano le variabili di uscita. Qualunque algoritmo corretto viene accettato.

I modelli (`Automaton`, `TuringMachine`, `WhileInterpreter`, `WhileTask`) non contengono nessun riferimento a Godot e sono coperti da **66 test**:

```
godot --headless --script res://tests/run_lvl3_tests.gd
```

---

## Livello 4 · Code Review (metodologie di programmazione)

Sei il revisore di una base di codice **Java** che deve andare in produzione. Durata **16 minuti**.

### Introduzione teorica (4 pagine)

Clean code (nomi, numeri magici, metodi corti, commenti inutili, duplicazione) · i cinque principi **SOLID** con un esempio concreto ciascuno · manutenibilità: incapsulamento, coesione e accoppiamento, i tre strati (dominio, interfaccia, persistenza) · JavaFX e persistenza in sintesi · la missione.

### Le quattro fasi

| Fase | Argomento | Che cosa fa il giocatore |
|---|---|---|
| 1 · Clean code | nomi, numeri magici, duplicazione | Il codice è a schermo con i numeri di riga: **clicca le righe difettose** e conferma |
| 2 · Principi SOLID | SRP, OCP, DIP | Individua la violazione, poi **separa una classe che fa troppe cose** assegnando ogni metodo alla classe giusta |
| 3 · Riscrivi il codice | refactoring | Riceve codice con difetti e lo **riscrive** nell'editor |
| 4 · Scrivi il codice | classi, JavaFX, persistenza | Scrive una **classe incapsulata**, una **schermata JavaFX** e una **mappatura persistente** (JPA/Hibernate o XML con JAXB) |

Penalità: **−8 s** per una riga segnalata a torto, **−10 s** per una scelta sbagliata, **−8 s** per codice che non sta in piedi, **−12 s** per controlli non superati.

### Come viene corretto il Java

Questo livello **non compila il codice**: scrivere un compilatore Java è fuori scala. `scripts/java/JavaCode.gd` è un **analizzatore strutturale** che estrae classi, campi con i loro modificatori, metodi con lunghezza e parametri, annotazioni, numeri magici, nomi troppo corti e righe duplicate. La parte delicata è la pulizia preliminare: commenti e stringhe vengono sostituiti con spazi mantenendo il numero di righe, così una graffa dentro un commento non falsa l'analisi.

`scripts/java/JavaTask.gd` corregge con **regole dichiarative**, ognuna col proprio messaggio che spiega il perché invece di dire «sbagliato»:

```gdscript
{"kind": "field_private", "field": "saldo"}
{"kind": "max_method_lines", "max": 12}
{"kind": "no_magic_numbers"}
```

> **Il limite, dichiarato anche nell'introduzione:** si giudica la *struttura*, non la sintassi. Codice ben strutturato che non compilerebbe viene accettato. Per clean code e SOLID è la scelta giusta — un metodo di 40 righe è un difetto anche se compila — ma non è un compilatore.

Il riquadro laterale mostra sempre **che cosa l'analizzatore ha capito** del codice scritto: classe, campi con la loro visibilità, metodi con il numero di righe, numeri magici trovati. Vedere il proprio codice riassunto così è già metà della revisione.

Coperto da **167 test**, fra cui la validazione di ogni voce del catalogo:

```
godot --headless --script res://tests/run_lvl4_tests.gd
```

---

## Roadmap

- [x] Livello 1 — Binary Search Tree e Dijkstra
- [x] Livello 2 — Database relazionali e SQL
- [x] Livello 3 — Calcolabilità: automi, macchine di Turing, WHILE
- [x] Livello 4 — Metodologie di programmazione: clean code, SOLID, Java
- [ ] Menu principale completo con progressi e punteggi
- [ ] Schermata di riepilogo con statistiche (confronti risparmiati, errori, manuale)

## Licenza

Progetto sviluppato a scopo didattico nell'ambito di una tesi.
