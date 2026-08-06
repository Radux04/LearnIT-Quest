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
│   └── level2.tscn             Livello 2 — database MySQL
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
│   │   ├── PhaseBase.gd        mini-giochi riusabili del Livello 1
│   │   ├── Phase1..5.gd        le cinque fasi del Livello 1
│   │   └── lvl2/               SqlPhaseBase.gd + le cinque fasi SQL
│   └── scenes/
│       ├── MainMenu.gd
│       ├── IntroductionScreen.gd · Introduction2Screen.gd
│       └── Level.gd · Level2.gd    orchestratori + HUD
├── tests/
│   ├── autoplay.tscn           bot che gioca il Livello 1
│   ├── autoplay_level2.tscn    bot che gioca il Livello 2
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
PhaseBase         ← le regole dei mini-giochi (che cosa è giusto o sbagliato)
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
| `res://tests/timeout.tscn` | Porta il cronometro a zero e verifica la schermata *Tempo Scaduto* con i due pulsanti. |
| `res://tests/test_sql_engine.gd` | 52 test del motore SQL, eseguibili senza aprire l'editor (vedi sopra). |

Esegui `autoplay.tscn` con **F6**: se arriva a `RETE RIPRISTINATA` senza errori runtime, l'intera catena (modello, vista, fasi, HUD) è sana. Alza `TIME_SCALE` in `AutoPlayHarness.gd` per accelerare la verifica.

## Bilanciamento

Tutte le manopole sono raccolte in pochi punti:

| Cosa | Dove |
|---|---|
| Durata dei livelli | `GameManager.LEVEL_DURATION`, `LEVEL2_DURATION` |
| Costo del manuale | `SqlManual.COST_SECONDS` |
| Penalità del Livello 2 | `Level2Controller.PENALTY_SYNTAX`, `PENALTY_WRONG` |
| Obiettivi del Livello 2 | le liste `SqlTask.make(...)` in `scripts/phases/lvl2/Phase1..5.gd` |
| Penalità delle 4 fasi | `PhaseBase.PENALTY_PLACE / ROUTE / SCAN / ATTACK` |
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

## Roadmap

- [x] Livello 1 — Binary Search Tree e Dijkstra
- [x] Livello 2 — Database relazionali e SQL
- [ ] Menu principale completo con progressi e punteggi
- [ ] Livello 3 — argomento da definire
- [ ] Schermata di riepilogo con statistiche (confronti risparmiati, errori, manuale)

## Licenza

Progetto sviluppato a scopo didattico nell'ambito di una tesi.
