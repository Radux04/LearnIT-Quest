# Guida per chi lavora su LearnIT Quest

Questo documento serve a due cose diverse:

- **ampliare i livelli che già esistono** — aggiungere esercizi, fasi, dati o comandi al Livello 1 e al Livello 2 (capitoli 2 e 3);
- **costruire un livello nuovo** da zero, riusando l'impianto esistente (capitoli 4 e seguenti).

Se è la prima volta che apri il progetto, leggi comunque il capitolo 1: sono le cinque regole a cui tutto il resto obbedisce.

### Da dove comincio?

| Voglio... | Vai a |
|---|---|
| aggiungere un esercizio SQL al Livello 2 | **§ 3.1** — cinque stringhe, nessuna logica nuova |
| aggiungere un programma WHILE al Livello 3 | **§ 4.4** — anche qui solo dati |
| cambiare quanti router / pacchetti / attacchi ci sono nel Livello 1 | **§ 2.1** — una tabella di costanti |
| aggiungere un automa, una macchina di Turing o un passo di determinizzazione | **§ 4.1**, **§ 4.2**, **§ 4.3** |
| aggiungere una fase a un livello che esiste | **§ 2.3** (L1) · **§ 3.2** (L2) · **§ 4.6** (L3) |
| cambiare le tabelle e i dati del database | **§ 3.3** |
| far accettare un comando nuovo al motore SQL o all'interprete WHILE | **§ 3.5** e **§ 4.5** |
| aggiungere una pagina al manuale | **§ 3.4** |
| ritoccare difficoltà, penalità o durata | **§ 2.1**, **§ 3.6**, **§ 4.7** |
| aggiungere un esercizio Java al Livello 4 | **§ 5** |
| creare un Livello 5 da zero | **§ 6** e **§ 7** |
| capire perché una modifica ha rotto qualcosa | **§ 9** — trappole già incontrate |

> **Regola che vale per ogni modifica:** prima di dire «fatto», rilancia i controlli automatici del **§ 3.7** e del **§ 4.7**. Ci mettono meno di un minuto e ti dicono subito se hai rotto qualcosa altrove.

---

## 1. Le regole di design

Prima del codice, i cinque principi a cui il Livello 1 obbedisce. Se il livello nuovo li rispetta, sembrerà parte dello stesso gioco.

1. **L'algoritmo è il gameplay.** Non si chiede *"qual è la complessità della ricerca?"*. Si fa fare al giocatore la ricerca, e il gioco gli mostra a posteriori quanti confronti ha risparmiato. Se una meccanica si può sostituire con una domanda a risposta multipla, è la meccanica sbagliata.
2. **Nessuna schermata di testo durante il gioco.** Tutta la teoria sta nell'introduzione. Durante il livello parlano solo l'obiettivo (una riga), il *toast* di feedback e il suggerimento in basso.
3. **L'errore insegna.** Mai «Sbagliato!». Sempre «25.9 NON è minore di 25.5: non può stare a sinistra». Il messaggio deve contenere il *perché*, con i numeri veri della partita.
4. **Fasi consecutive, zero caricamenti.** La struttura disegnata a schermo resta la stessa e si trasforma dal vivo. Il giocatore deve percepire una sola scena continua.
5. **Cinque minuti, timer sempre visibile, penalità di tempo.** La pressione temporale è ciò che trasforma la conoscenza in automatismo.

---

## 2. Ampliare il Livello 1 (router, BST e Dijkstra)

Dove sta cosa:

| File | Contiene |
|---|---|
| `scripts/bst/BSTModel.gd` | L'albero: `insert`, `erase`, `minimum`, `maximum`, `successor`, `predecessor`, le 4 visite. Zero pixel. |
| `scripts/bst/NetworkGraph.gd` | Il grafo pesato della Fase 5 e l'algoritmo di Dijkstra |
| `scripts/phases/PhaseBase.gd` | I mini-giochi riusabili e le penalità |
| `scripts/phases/Phase1.gd` … `Phase5.gd` | La sceneggiatura di ogni fase: *quali* mini-giochi, con *quali* numeri |
| `scripts/scenes/Level.gd` | L'elenco delle fasi, l'HUD, vittoria e sconfitta |
| `scripts/ui/NetworkView.gd`, `RouterNode.gd` | Il disegno: cavi, nodi, pacchetti |

### 2.1 Cambiare i numeri in gioco (senza scrivere codice nuovo)

Quasi tutto il bilanciamento è in costanti dichiarate in cima ai file:

| Voglio | File | Costante |
|---|---|---|
| Più o meno router da posizionare | `scripts/phases/Phase1.gd` | `ROUTERS_TO_PLACE` |
| Una radice diversa | `scripts/scenes/Level.gd` | `ROOT_VALUE` |
| Più pacchetti da instradare | `scripts/phases/Phase2.gd` | `PRESENT_PACKETS`, `ABSENT_PACKETS` |
| Più giri di visita | `scripts/phases/Phase3.gd` | `ROUNDS` |
| Più attacchi dell'hacker | `scripts/phases/Phase4.gd` | `CHALLENGE_COUNT` |
| Un grafo Dijkstra più fitto o più costoso | `scripts/phases/Phase5.gd` | `EXTRA_LINKS`, `MIN_WEIGHT`, `MAX_WEIGHT` |
| Penalità più o meno severe | `scripts/phases/PhaseBase.gd` | `PENALTY_PLACE`, `PENALTY_ROUTE`, `PENALTY_SCAN`, `PENALTY_ATTACK` |
| Durata del livello | `scripts/global/GameManager.gd` | `LEVEL_DURATION` |

Tre vincoli da rispettare quando tocchi `ROUTERS_TO_PLACE`:

1. **Niente duplicati** e nessun valore uguale a `ROOT_VALUE`: in un BST i duplicati non esistono e il gioco li rifiuterebbe.
2. **Tieni la profondità entro 4 livelli**, altrimenti i nodi più bassi finiscono sotto il vassoio. Il layout si adatta, ma lo spazio verticale no.
3. **Mantieni le coppie-trappola decimali** (`25.5`/`25.9`, `62.4`/`62.1`): sono il motivo didattico della fase, senza di esse basta guardare la parte intera.

> Ogni volta che cambi uno di questi numeri cambia anche il **tempo necessario**. Rilancia il bot (§ 2.5): se finisce con meno di metà cronometro residuo, il livello è diventato troppo lungo.

### 2.2 Aggiungere una sfida al repertorio dell'hacker (Fase 4)

È l'ampliamento più economico del Livello 1: la Fase 4 pesca da un elenco di tipi di sfida. Il model espone già `predecessor()`, quindi aggiungere «clicca il predecessore» costa poche righe.

In `scripts/phases/Phase4.gd` aggiungi il metodo:

```gdscript
func _challenge_predecessor() -> void:
	var ordered: Array[float] = level.model.inorder()
	if ordered.size() < 2:
		await _challenge_route()
		return
	var index: int = 1 + randi() % (ordered.size() - 1)
	var reference: float = ordered[index]
	var target: float = ordered[index - 1]
	level.set_objective("Rollback: clicca il PREDECESSORE di %s (la metrica subito più piccola)." % fmt(reference))
	level.set_hint("Il predecessore in-order è il router che viene prima di %s nella visita Inorder." % fmt(reference))
	await pick_router(target, false, "Corretto: prima di %s viene %s." % [fmt(reference), fmt(target)], PENALTY_ATTACK)
```

poi registralo nei due punti che governano il mix:

```gdscript
	match kind:
		...
		"predecessor":
			await _challenge_predecessor()

func _build_plan() -> Array[String]:
	var plan: Array[String] = ["insert", "route", "delete", "min", "max", "successor", "predecessor", "route"]
```

e alza `CHALLENGE_COUNT` se vuoi che compaia spesso: `_build_plan()` tronca l'elenco a quel numero, quindi con `CHALLENGE_COUNT = 5` le ultime voci non escono mai.

Lo stesso schema vale per qualsiasi altra sfida: **un metodo `_challenge_*` + una voce nel `match` + una nel piano**.

### 2.3 Aggiungere una fase intera al Livello 1

1. Crea `scripts/phases/Phase6.gd` che `extends PhaseBase`, sovrascrive `_start()` e chiude con `finished.emit()` (lo scheletro è al § 7, passo 4).
2. In `scripts/scenes/Level.gd` aggiungi **nella stessa posizione** una voce a `PHASE_SCRIPTS` e una a `PHASE_BANNERS`: sono due array paralleli, se le lunghezze non coincidono il livello va in errore all'avvio.
3. Aggiungi la teoria all'introduzione (`scripts/scenes/IntroductionScreen.gd`, costante `PAGES`) e la nuova fase all'elenco nella pagina della missione.
4. Estendi il bot di autoplay perché sappia giocarla, altrimenti il test automatico si blocca lì.
5. Riduci qualche costante del § 2.1: il tetto restano **5 minuti**.

### 2.4 Aggiungere un mini-gioco nuovo

Se la meccanica è generica (vale per qualunque struttura ad albero) mettila in `PhaseBase`; se serve solo a una fase, tienila in quella fase. In entrambi i casi segui il pattern `await helper_done` descritto al § 7, passo 3, e rispetta le due regole non negoziabili: **`_is_over()` dopo ogni `await`** e **messaggi d'errore che spiegano il perché con i numeri veri**.

### 2.5 Verifica dopo ogni modifica

```bash
# il bot gioca il Livello 1 da solo, sempre in modo corretto
"$GODOT" tests/autoplay.tscn
```

Se arriva alla schermata di vittoria senza errori runtime, la catena regge. Il tempo residuo che stampa è la tua misura di difficoltà.

---

## 3. Ampliare il Livello 2 (database e SQL)

Dove sta cosa:

| File | Contiene |
|---|---|
| `scripts/sql/SqlTokenizer.gd` | Da testo a token |
| `scripts/sql/SqlParser.gd` | Da token ad albero sintattico (AST) |
| `scripts/sql/SqlEngine.gd` | Esegue l'AST sul database |
| `scripts/sql/SqlDatabase.gd` | Tabelle, righe, `snapshot()`/`restore()` per il confronto |
| `scripts/sql/SqlTask.gd` | La correzione **per equivalenza** (§ 10) |
| `scripts/phases/lvl2/Phase1.gd` … `Phase5.gd` | Gli elenchi di obiettivi |
| `scripts/scenes/Level2.gd` | Fasi, dati iniziali, penalità, HUD |
| `scripts/ui/SqlConsole.gd`, `SqlManual.gd`, `SqlTableView.gd` | Console, manuale, viste delle tabelle |

### 3.1 Aggiungere un esercizio (il caso più frequente)

Un obiettivo è **solo dati**: cinque stringhe in un array. Nessuna logica, nessun rischio di rompere il resto. Apri la fase giusta in `scripts/phases/lvl2/` e aggiungi una voce:

```gdscript
		SqlTask.make(
			"Mostra le città dei clienti senza ripetizioni.",   # 1. richiesta per il giocatore
			"SELECT DISTINCT citta FROM clienti",               # 2. UNA soluzione di riferimento
			SqlTask.KIND_SELECT,                                # 3. select oppure mutate
			"DISTINCT elimina i duplicati dal risultato.",      # 4. suggerimento in basso
			"DISTINCT tiene una sola riga per ogni valore."),   # 5. spiegazione dopo il successo
```

Quattro regole:

- **`kind` deve essere giusto.** `KIND_SELECT` se l'esercizio legge dati, `KIND_MUTATE` se li modifica. La correzione controlla cose diverse nei due casi: nel primo confronta il risultato, nel secondo lo stato finale del database.
- **La soluzione di riferimento deve essere eseguibile dal motore.** Non è un commento: viene eseguita davvero. Se contiene un comando non supportato, il giocatore riceve «Soluzione di riferimento non valida» qualunque cosa scriva.
- **Non serve prevedere le varianti.** La correzione confronta l'effetto, non il testo: `WHERE` in ordine diverso, `IN` al posto di `OR`, maiuscole e alias sono già accettati.
- **Se l'ordine delle righe conta, la soluzione deve usare `ORDER BY`.** È quello che dice al correttore di essere rigoroso sull'ordine; senza, l'ordine è libero.

Quello che puoi usare nelle soluzioni **senza toccare il motore** (verificato, funziona):

`SELECT` · `DISTINCT` · `WHERE` · `AND` `OR` `NOT` · `= <> != < <= > >=` · `+ - * / %` · `IN` / `NOT IN` · `LIKE` (con `%`) · `BETWEEN ... AND ...` · `IS NULL` / `IS NOT NULL` · `ORDER BY ... ASC|DESC` · `LIMIT n` · `GROUP BY` · `COUNT SUM AVG MIN MAX` · alias con `AS` · subquery scalari e con `IN` · `INSERT INTO ... VALUES` · `UPDATE ... SET ... WHERE` · `DELETE FROM ... WHERE` · `CREATE TABLE` · `DROP TABLE`

Quello che **non** è supportato oggi: `JOIN`, `HAVING`, nomi qualificati tipo `c.nome`, `UNION`. Se ti servono, § 3.5.

### 3.2 Aggiungere una fase al Livello 2

1. Crea `scripts/phases/lvl2/Phase6.gd`:

```gdscript
extends SqlPhaseBase

## FASE 6 — Titolo e riga che spiega perché questa fase esiste.

func _start() -> void:
	level.set_phase_header("FASE 6 — TITOLO", Color(0.4, 0.85, 1.0))
	var tasks: Array = [
		SqlTask.make("...", "...", SqlTask.KIND_SELECT, "...", "..."),
	]
	await do_tasks(tasks)
	await complete("Frase che riassume cosa hai imparato.")
```

2. Aggiungi la voce a `PHASE_SCRIPTS` **e** a `PHASE_BANNERS` in `Level2.gd` (array paralleli, stessa posizione).
3. Aggiorna `_suggested_manual_page()`: associa al numero della nuova fase la pagina di manuale che le serve, così il manuale si apre già al punto giusto.
4. Aggiorna l'elenco delle fasi nell'introduzione (`Introduction2Screen.gd`) e valuta se allungare `LEVEL2_DURATION`.

### 3.3 Cambiare le tabelle e i dati iniziali

Il database di partenza è costruito in `Level2._seed_database()`:

```gdscript
	db.define("prodotti",
		[["id", "INT"], ["nome", "VARCHAR(40)"], ["prezzo", "INT"]],   # colonne: nome + tipo
		[
			[1, "Tastiera", 45],                                        # righe, nell'ordine delle colonne
			[2, "Monitor", 180],
		])
```

⚠️ **Attenzione al lato pericoloso di questa modifica.** Le soluzioni di riferimento di tutti gli esercizi vengono eseguite su questi dati: se cambi una riga, cambi in silenzio il risultato atteso di ogni esercizio che la tocca. Un esercizio può diventare banale (nessuna riga da filtrare) o impossibile. Dopo ogni modifica ai dati **rilancia il bot del § 3.7**: è l'unico modo per accorgersene.

Le viste delle tabelle a schermo si aggiornano da sole: `refresh_tables()` legge il database e ricrea le `SqlTableView` che servono, comprese quelle create o eliminate dal giocatore.

### 3.4 Aggiungere una pagina al manuale

Il manuale è una costante in `scripts/ui/SqlManual.gd`:

```gdscript
const MANUAL_PAGES: Array = [
	{
		"title": "MANUALE  ·  5. Raggruppamenti",
		"body": """[b][color=#7fd8ff]GROUP BY[/color][/b]
Testo in BBCode.""",
	},
]
```

Poi collega la pagina alla fase che ne ha bisogno in `Level2._suggested_manual_page()` (**gli indici partono da 0**: la pagina 5 è l'indice 4). Ricorda che aprire il manuale costa `COST_SECONDS` secondi: più pagine aggiungi, più deve essere facile trovare quella giusta, altrimenti il costo diventa ingiusto.

### 3.5 Insegnare al motore SQL un comando nuovo

Serve solo per ciò che oggi non è supportato (`JOIN`, `HAVING`, …). Il motore è a tre stadi e si estende **sempre nello stesso ordine**:

1. **`SqlTokenizer.gd`** — se il comando introduce simboli nuovi (per esempio il punto di `c.nome`), insegnaglieli qui. Le parole invece arrivano già come identificatori.
2. **`SqlParser.gd`** — riconosci la parola chiave e producine un pezzo di AST, cioè un `Dictionary`. Segui `_accept_keyword("GROUP")` come modello. **Ogni messaggio d'errore deve spiegare la forma giusta** («Dopo GROUP serve BY, cioè GROUP BY colonna»): quei messaggi finiscono in faccia al giocatore ed è lì che impara.
3. **`SqlEngine.gd`** — esegui il nuovo nodo. Per un comando nuovo aggiungi un ramo al `match` di `execute_ast()`; per una clausola di `SELECT`, agganciala dove viene costruito il risultato.
4. **`tests/test_sql_engine.gd`** — aggiungi i casi: quello che funziona, quello che deve fallire e il messaggio d'errore atteso.

Il motore non solleva mai eccezioni: ogni funzione ritorna `{"ok": false, "error": "..."}`. Mantieni questa convenzione, perché la console mostra `error` al giocatore così com'è.

### 3.6 Bilanciamento del Livello 2

| Costante | File | Oggi |
|---|---|---|
| `LEVEL2_DURATION` | `GameManager.gd` | 600 s (10 minuti) |
| `PENALTY_SYNTAX` | `Level2.gd` | 8 s — query non valida |
| `PENALTY_WRONG` | `Level2.gd` | 12 s — query valida ma che non risolve |
| `COST_SECONDS` | `SqlManual.gd` | 10 s per apertura del manuale |

Il criterio: **l'errore di sintassi costa meno dell'errore di ragionamento**, perché il primo è una svista e il secondo no. E siccome il manuale si paga, le penalità non possono essere alte: il giocatore finirebbe per non consultarlo mai.

### 3.7 Verifica dopo ogni modifica (obbligatoria)

Due comandi, in quest'ordine:

```bash
GODOT="C:/Users/UTENTE/Desktop/Godot_v4.5-stable_win64.exe/Godot_v4.5-stable_win64.exe"

# 1. i 52 test del motore SQL (tokenizer, parser, engine, correzione)
"$GODOT" --headless --script res://tests/run_sql_tests.gd

# 2. il bot risolve tutti gli obiettivi e verifica penalità e manuale
"$GODOT" tests/autoplay_level2.tscn
```

Il primo deve stampare `0 falliti`. Il secondo deve arrivare a `FINE — DATABASE RIPRISTINATO` e stampare il tempo residuo: se è meno di un terzo, il livello è diventato troppo lungo.

> Se un test si lamenta di `SqlEngine` o `SqlDatabase` «non dichiarati» dopo aver aggiunto file nuovi, lancia una volta `"$GODOT" --headless --editor --quit-after 300`: registra le classi globali nella cache del progetto.

---

## 4. Ampliare il Livello 3 (calcolabilità)

Dove sta cosa:

| File | Contiene |
|---|---|
| `scripts/computability/Automaton.gd` | DFA e NFA: esecuzione, ε-chiusura, `move()`, costruzione per sottoinsiemi |
| `scripts/computability/TuringMachine.gd` | Nastro, quintuple, `step()`, `run()` con limite di passi |
| `scripts/computability/WhileInterpreter.gd` | Tokenizer, parser e semantica del linguaggio WHILE |
| `scripts/computability/WhileTask.gd` | Correzione per equivalenza dei programmi |
| `scripts/phases/lvl3/Lvl3Pools.gd` | **Il catalogo degli esercizi**: è qui che se ne aggiungono |
| `scripts/phases/lvl3/Phase1.gd` … `Phase5.gd` | Le fasi (Phase4, il problema dell'arresto, è fuori rotazione) |
| `scripts/ui/AutomatonView.gd`, `StateNode.gd` | Stati e archi etichettati |
| `scripts/ui/TapeView.gd`, `RuleTableView.gd` | Nastro e tabella delle quintuple |
| `scripts/ui/DiagonalTable.gd`, `CodeConsole.gd` | Tabella diagonale e console WHILE |

Questo livello è diverso dagli altri due: **non c'è una struttura unica** che si trasforma. Ogni fase porta in scena il proprio strumento su un «palco» (`level.stage`) che il controller svuota a ogni cambio. Per aggiungere una fase basta quindi montare la propria vista con `level.mount(view)`.

### 4.0 Il catalogo: dove stanno gli esercizi

Gli esercizi **non sono nel codice delle fasi**: sono dati dichiarativi in `scripts/phases/lvl3/Lvl3Pools.gd`, e ogni fase ne pesca a caso a ogni partita. Aggiungere un esercizio significa aggiungere una voce a un array, senza toccare nessuna fase.

I test di `tests/test_lvl3.gd` **validano ogni voce del catalogo**: se aggiungi un automa non deterministico dove serve un DFA, una macchina di Turing che non si ferma o un programma la cui soluzione non gira, te lo dicono subito. Sono la rete di sicurezza di chi aggiunge esercizi — usali.

### 4.1 Aggiungere un automa alla Fase 1

Una voce in `DFA_POOL`:

```gdscript
	{
		"name": "finisce per 0",
		"states": ["t0", "t1"], "alphabet": ["0", "1"],
		"start": "t0", "accepting": ["t1"],
		"transitions": [
			["t0", "0", "t1"], ["t0", "1", "t0"],
			["t1", "0", "t1"], ["t1", "1", "t0"],
		],
		"words": ["1010", "1101", "010", "011"],
		"hint": "Riga di suggerimento mostrata in basso.",
	},
```

Tre vincoli (li controllano i test):
1. L'automa deve essere **completo e deterministico**: da ogni stato, per ogni simbolo dell'alfabeto, esattamente una freccia. Altrimenti l'esecuzione si blocca a metà parola.
2. **Massimo 5 stati**: la vista li dispone in fila orizzontale e oltre non ci stanno.
3. Le parole devono usare solo simboli dell'alfabeto dichiarato, e servono almeno due parole.

### 4.2 Aggiungere un passo di determinizzazione (Fase 2)

Una voce in `NFA_POOL`, con i passi che il giocatore dovrà rifare:

```gdscript
		"steps": [
			[["q0"], "a", "Suggerimento per questo passo."],
			[["q0", "q1"], "b", "Un altro suggerimento."],
		],
```

Il primo elemento è l'insieme di partenza, il secondo il simbolo. **La risposta attesa non si scrive**: la calcola il model con `automaton.move(insieme, simbolo)`, ε-chiusura compresa. Fai in modo che i passi si susseguano come nella costruzione vera, altrimenti perdono senso didattico.

Il campo `"epsilon"` dice se l'automa ha ε-transizioni: la Fase 2 pesca **un automa di ciascun tipo**, quindi il catalogo deve contenerne sempre almeno uno per tipo.

### 4.3 Aggiungere una macchina di Turing (Fase 3)

Una voce in `TM_POOL` (da eseguire) o in `DESIGN_POOL` (da completare):

```gdscript
	{
		"name": "inverte i bit",
		"start": "q0", "accept": "qf", "input": "101",
		"rules": [                       # [stato, letto, scritto, direzione, nuovo stato]
			["q0", "0", "1", R, "q0"],   # R = destra, L = sinistra, S = ferma
			["q0", "1", "0", R, "q0"],
			["q0", "□", "□", S, "qf"],
		],
		"result": "ogni bit invertito",  # compare nel messaggio finale
		"hint": "Suggerimento.",
	},
```

Due avvertenze:
- ⚠️ **La macchina deve fermarsi**, e in pochi passi: il giocatore clicca una regola a ogni passo, quindi oltre la ventina diventa una tortura. I test verificano l'arresto e il numero di passi.
- **Poche regole**: la tabella cresce verso l'alto in base a quante ne ha (`RuleTableView.preferred_height()`), ma oltre le 7-8 lo spazio finisce.

Per `DESIGN_POOL` serve anche `"missing"` (la regola che manca) e `"options"` con **esattamente una** alternativa `"correct": true`; le alternative vengono mescolate a ogni partita.

### 4.4 Aggiungere un programma WHILE (Fase 4)

Una voce in `WHILE_POOL`. Le soluzioni di riferimento si scrivono nella **notazione accademica del corso**:

```gdscript
	{
		"prompt": "Metti in R il resto di X diviso Y (Y > 0).",
		"solution": """begin
INPUT(X);
INPUT(Y);
while X >= Y do
	 begin X := X - Y end
R := X;
OUTPUT(R)
end""",
		"cases": [{"X": 0, "Y": 3}, {"X": 7, "Y": 2}, {"X": 8, "Y": 8}],
		"outputs": ["R"],
		"hint": "Suggerimento.", "explain": "Spiegazione dopo il successo.",
	},
```

Quattro regole:
- **Scegli esercizi che il linguaggio non risolve con un operatore.** Divisione, resto, MCD, fattoriale vanno bene; «somma di X e Y» no, perché `Z := X + Y` è una risposta legittima e il ciclo non serve.
- **Metti fra i casi di prova quelli limite**: zero, valori uguali, primo minore del secondo. La correzione li prova tutti e si ferma al primo che fallisce.
- **La soluzione di riferimento deve terminare** su ogni caso, altrimenti il giocatore riceve «Soluzione di riferimento non valida».
- **Non serve prevedere le varianti**: si confronta l'effetto, non il testo, quindi il giocatore può rispondere anche nella notazione compatta.

Il linguaggio accetta **due scritture equivalenti**:

| | Compatta | Accademica (del corso) |
|---|---|---|
| Raggruppare | `;` | `begin ... end` |
| Ciclo | `while c do P end` (anche `od`) | `while c do begin P end` |
| Condizione | `if c then P else Q end` (anche `fi`) | `if c then begin P end else begin Q end` |
| Ingressi/uscite | — | `INPUT(X)` · `OUTPUT(Y)` |
| Successore/predecessore | `x + 1` · `x - 1` | `s(x)` · `pd(x)` |
| Commenti | `# ...` | `/* ... */` |

In entrambe: variabili sui **naturali** (valgono 0 se mai assegnate), operatori `+ - *` con **sottrazione troncata**, confronti `= != < <= > >=`, e una condizione senza confronto significa «≠ 0». Dopo un `end` il `;` può mancare. Non esistono divisione, resto, array o funzioni diverse da `s` e `pd`: se ti servono, § 4.5.

### 4.5 Estendere l'interprete WHILE

Stessa procedura in tre stadi del motore SQL (§ 3.5): `tokenize()` per i simboli nuovi, la classe `Parser` per la grammatica, `_exec`/`_eval` per la semantica, e i casi in `tests/test_lvl3.gd`. I messaggi d'errore devono dire **la forma giusta**, non solo che c'è un errore: li legge il giocatore.

### 4.6 Aggiungere (o togliere) una fase

Crea `scripts/phases/lvl3/Phase6.gd` che `extends Lvl3PhaseBase`, monta la sua vista con `level.mount(...)`, e aggiungi la voce a `PHASE_SCRIPTS` **e** a `PHASE_BANNERS` di `Level3.gd` (array paralleli). Poi aggiorna l'introduzione e insegna la fase al bot.

Per **togliere** una fase basta rimuovere le sue due voci: il file resta sul disco e si riattiva rimettendole. È quello che è stato fatto con `Phase4.gd`, la fase sul problema dell'arresto.

⚠️ Se una fase mostra pulsanti sopra una vista, ricorda che **le viste stanno dentro `Stage`, che non parte dal bordo dello schermo, mentre i pulsanti stanno in `ActionBar`, che è a schermo intero.** Per posizionare un pulsante rispetto a una vista usa il rettangolo di `Stage`, non `level.size` — vedi `Phase3._design_round()`.

### 4.7 Verifica

```bash
"$GODOT" --headless --script res://tests/run_lvl3_tests.gd   # 66 test dei modelli
"$GODOT" tests/autoplay_level3.tscn                          # il bot gioca tutto il livello
```

Il bot ha una costante comoda: **`STOP_AT_PHASE`**. Messa a `N`, gioca le fasi precedenti in fretta e poi si ferma all'inizio della fase `N` a velocità normale — è il modo più rapido per guardare (o fotografare) una singola fase senza giocarsela a mano.

---

## 5. Ampliare il Livello 4 (metodologie e Java)

Il Livello 4 corregge in modo **strutturale**: non compila il Java, ne analizza la forma. Il catalogo è `scripts/phases/lvl4/Lvl4Pools.gd` e ha quattro elenchi.

**`REVIEW_POOL`** — righe da cliccare. `"bad"` sono gli indici delle righe difettose, **contati da 0**:

```gdscript
	{
		"topic": "clean",          # "clean" o "solid": la fase pesca da entrambi
		"name": "nomi e numeri magici",
		"question": "Clicca le righe con nomi che non spiegano nulla.",
		"code": "public class Fattura {\n    private double t;\n}",
		"bad": [1],
		"hint": "...", "explain": "...",
	},
```

⚠️ **Conta le righe con attenzione**: i test verificano che ogni indice esista e non sia una riga vuota, ed è l'errore che si fa più spesso.

**`SPLIT_POOL`** — separazione delle responsabilità: due classi di destinazione e i metodi con l'indice della classe giusta. Entrambe le classi devono ricevere almeno un metodo, altrimenti non c'è niente da separare.

**`REFACTOR_POOL`** e **`WRITE_POOL`** — esercizi da scrivere nell'editor:

```gdscript
	{
		"prompt": "Riscrivi togliendo il numero magico.",
		"code": "...codice di partenza...",       # "" per scrivere da zero
		"checks": [
			{"kind": "no_magic_numbers"},
			{"kind": "contains", "text": "static final",
				"message": "Messaggio che spiega perché serve."},
		],
		"solution": "...soluzione di riferimento...",
		"hint": "...", "explain": "...",
	},
```

Tre regole che i test verificano:
- Il **codice di partenza non deve già superare i controlli**, altrimenti l'esercizio nasce risolto.
- La **soluzione di riferimento deve superarli tutti** — la usa anche il bot per giocare.
- Ogni controllo può portare un `"message"` proprio: usalo, perché il messaggio predefinito è generico e questo livello insegna proprio col messaggio d'errore.

I tipi di controllo disponibili sono elencati in `JavaTask._run_check()`: `class_named`, `kind_is`, `extends`, `implements`, `has_field`, `field_private`, `no_public_fields`, `has_method`, `lacks_method`, `method_count_at_least`, `method_count_at_most`, `max_method_lines`, `no_magic_numbers`, `meaningful_names`, `no_duplicated_lines`, `contains`, `lacks`, `has_annotation`, `field_annotated`, `max_code_lines`.

Per aggiungerne uno nuovo: un ramo nel `match` di `_run_check()`, l'interrogazione corrispondente in `JavaCode.gd` e i casi in `tests/test_lvl4.gd`.

---

## 6. Anatomia di un livello

Cinque strati, ognuno ignaro di quello sopra. Questo è il motivo per cui si riusa quasi tutto.

```
┌─ LevelController (scripts/scenes/Level.gd) ────────────────┐
│  HUD, timer, sequenza delle fasi, vittoria/sconfitta       │
│  ┌─ PhaseN (scripts/phases/PhaseN.gd) ───────────────────┐ │
│  │  La sceneggiatura: quali mini-giochi, con che numeri  │ │
│  │  ┌─ PhaseBase (scripts/phases/PhaseBase.gd) ────────┐ │ │
│  │  │  I mini-giochi: cosa è giusto, cosa è sbagliato  │ │ │
│  │  │  ┌─ NetworkView + RouterNode (scripts/ui/) ────┐ │ │ │
│  │  │  │  Solo pixel: cavi, nodi, pacchetti, tween   │ │ │ │
│  │  │  │  ┌─ BSTModel + NetworkGraph ─────────────┐  │ │ │ │
│  │  │  │  │  Solo dati e algoritmi. Zero Godot.   │  │ │ │ │
│  │  │  │  └───────────────────────────────────────┘  │ │ │ │
│  │  │  └─────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

**Regola d'oro:** il *model* non deve mai importare `Node`, `Control`, `Tween` o `Color`. Se ti ritrovi a scrivere `queue_redraw()` dentro il model, hai mescolato gli strati.

---

## 7. Procedura passo-passo per un livello nuovo

### Passo 0 — Scegli argomento e meccaniche (la parte più importante)

Compila questa tabella **prima** di scrivere codice. Se una casella resta vuota, il livello non è pronto.

| Domanda | Esempio (Livello 1) |
|---|---|
| Qual è la struttura dati? | Binary Search Tree, che nell'ultima fase diventa un grafo pesato |
| Quale metafora visiva? | Rete di router e cavi |
| Quali operazioni deve interiorizzare il giocatore? | insert, search (positiva e negativa), 4 visite, delete, min/max/successore, cammino minimo con Dijkstra |
| Che **gesto fisico** corrisponde a ogni operazione? | insert = *trascinare*; search = *scegliere un bivio*; visita = *cliccare in sequenza*; delete = *cliccare il nodo infetto*; Dijkstra = *fissare ogni volta il nodo a costo minimo* |
| Come si vede l'errore? | Cavo rosso, router che trema, spiegazione col perché |
| Come si vede il costo dell'algoritmo? | «trovato in 2 confronti invece di 9 router» |

Lo stesso schema compilato per il **Livello 2**, che è di natura diversa (si scrive invece di cliccare):

| Domanda | Livello 2 |
|---|---|
| Struttura dati | Database relazionale (tabelle, righe, chiavi) |
| Metafora visiva | Il pannello di amministrazione di un DBMS |
| Operazioni | SELECT/WHERE/ORDER BY/COUNT, CREATE, INSERT, UPDATE, DELETE, DROP, subquery |
| Gesto fisico | **Scrivere una query** ed eseguirla |
| Errore | Messaggio del database in console + penalità di tempo |
| Costo dell'algoritmo | Il tempo: consultare il manuale costa 10 s |

Idee ancora libere per i livelli futuri:

| Argomento | Metafora | Gesto |
|---|---|---|
| Stack / Queue | Magazzino di pacchetti, nastro trasportatore | Impilare / prelevare nell'ordine giusto |
| Grafi + BFS/DFS | Mappa di città e strade | Colorare le città nell'ordine di visita |
| Hash table | Armadietti numerati | Mettere l'oggetto nell'armadietto `hash(x) % n`, gestire le collisioni |
| Sorting | Barre da riordinare | Scambiare coppie seguendo l'algoritmo |
| Alberi bilanciati (AVL) | Rete che si "raddrizza" | Applicare la rotazione giusta |

### Passo 1 — Scrivi il model

Crea `res://scripts/<argomento>/<Nome>Model.gd`. Deve essere un `RefCounted` con `class_name`, contenere **solo** dati e algoritmi, ed esporre:

- le operazioni della struttura (`insert`, `erase`, `find`, ...);
- le **query che servono al gioco per giudicare una mossa** (in `BSTModel`: `insertion_slot()` dice qual è l'unico slot legale per un valore, `step_direction()` dice da che parte scendere);
- le **metriche didattiche** (`comparisons_for()` per mostrare quanti confronti sono serviti);
- un formattatore statico `fmt(value)` per avere numeri identici ovunque.

```gdscript
class_name QueueModel
extends RefCounted

var items: Array[float] = []

static func fmt(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return String.num(value, 1)

func enqueue(value: float) -> void:
	items.append(value)

func dequeue() -> float:
	return items.pop_front()

## La query che serve al gioco per validare una mossa.
func next_expected() -> float:
	return items[0] if not items.is_empty() else NAN
```

> Il model si testa senza aprire il gioco: `execute_script` o una scena vuota con qualche `print()`.

### Passo 2 — La vista

Hai due strade.

**A. Riusi `NetworkView`** se la tua struttura è ancora un albero (AVL, heap, trie): è già pronta per nodi con valore `float`, layout adattivo, cavi animati e slot di inserimento. Devi solo passarle un model che esponga `root`, `values()`, `max_depth()` ed `empty_slots()`.

**B. Scrivi una nuova view** per strutture non ad albero (pila, coda, grafo, array). Copia lo scheletro di `NetworkView.gd`:

```gdscript
class_name StackView
extends Control

var model: QueueModel = null
var _items: Dictionary = {}          # valore -> RouterNode

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # i clic vanno ai figli
	set_process(true)

func setup(m: QueueModel) -> void:
	model = m
	rebuild()

func rebuild(animate: bool = true) -> void:
	# 1. calcola le posizioni    2. riusa i nodi esistenti e li anima
	# 3. crea i nuovi            4. dissolve quelli spariti
	queue_redraw()

func _draw() -> void:
	# sfondo, connessioni, effetti: il genitore disegna PRIMA dei figli
	pass
```

`RouterNode` è riusabile così com'è per qualsiasi "cella con un numero dentro": ha già stati, alone, drag & drop, clic, `pop()`, `shake()`, `flash()` e badge numerico.

### Passo 3 — I mini-giochi

Se le meccaniche sono quelle del Livello 1 (trascinare, scegliere un bivio, cliccare in sequenza, selezionare un elemento), **non scrivere niente**: `PhaseBase` le ha già.

Se ti serve una meccanica nuova, aggiungila a `PhaseBase` (se è generica) o a una nuova base `PhaseBaseLivello2`. Lo schema di ogni mini-gioco è sempre lo stesso:

```gdscript
## 1. Prepara lo stato e collega gli input
func my_minigame(target: float) -> void:
	if _is_over():
		return
	_my_target = target
	_my_active = true
	_connect_router_clicks(_on_my_click)

	await helper_done          # 2. sospende finché il giocatore non finisce

	_my_active = false         # 3. pulisce
	_disconnect_router_clicks()

## 4. L'handler giudica la mossa ed emette helper_done quando ha finito
func _on_my_click(router: RouterNode) -> void:
	if not _my_active or _is_over():
		return
	if is_equal_approx(router.value, _my_target):
		Sfx.play("correct")
		router.pop()
		level.toast("Esatto: %s.  Motivo." % fmt(router.value), COLOR_OK)
		_my_active = false
		helper_done.emit()
	else:
		Sfx.play("error")
		router.shake()
		level.toast("No: %s perché ...spiegazione con i numeri veri..." % fmt(router.value), COLOR_BAD)
		level.penalty(PENALTY_ATTACK)
```

Il pattern `await helper_done` è il cuore di tutto: rende il codice di gioco **lineare e leggibile** invece che una macchina a stati.

### Passo 4 — Le fasi

Una fase è un file corto che decide *cosa* succede e con *quali numeri*. Deve estendere `PhaseBase`, sovrascrivere `_start()` ed emettere `finished` alla fine.

```gdscript
extends PhaseBase

## FASE 2 — Titolo e una riga di spiegazione del perché esiste questa fase.

const PACKET_COUNT := 7

func _start() -> void:
	level.set_phase_header("FASE 2 — INSTRADAMENTO", Color(0.35, 1.0, 0.7))

	for i in range(PACKET_COUNT):
		if _is_over():
			return
		level.set_objective("Pacchetto %d/%d — destinazione %s" % [i + 1, PACKET_COUNT, fmt(target)])
		await route_packet(target)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Frase che riassume che cosa hai appena imparato.", COLOR_OK)
	await _wait(1.2)
	finished.emit()
```

**Controlla sempre `_is_over()` dopo ogni `await`**: se il tempo scade mentre una fase è sospesa, deve smettere di agire.

### Passo 5 — La scena del livello

Il modo più rapido è **duplicare `res://scenes/level.tscn`** e rinominarla `level2.tscn`. `LevelController` cerca questi nodi per nome, quindi non rinominarli:

```
Level (Control)            ← script LevelController
├── Background (ColorRect)
├── Circuit (TextureRect)
├── NetworkView (Control)  ← la tua view; full rect, mouse_filter = Ignore
├── Tray (Control)         ← contenitore dei nodi trascinabili
├── ActionBar (Control)    ← contenitore dei pulsanti creati dalle fasi
├── HUD (Control)
│   ├── TopBar · PhaseTitle · Objective · TimerLabel · TimerBar · Toast · Hint
└── Overlays (Control)
	├── Banner (Panel) → BannerTitle, BannerSub
	└── EndScreen (Control) → Dim, Title, Subtitle, RestartButton, MenuButton
```

`NetworkView`, `Tray` e `ActionBar` sono **tutti a schermo intero e sovrapposti**: è ciò che permette di trascinare un router dal vassoio alla rete senza conversioni di coordinate.

Poi crea `Level2.gd` copiando `Level.gd` e cambiando solo:

```gdscript
const PHASE_SCRIPTS: Array[String] = [
	"res://scripts/phases/lvl2/Phase1.gd",
	"res://scripts/phases/lvl2/Phase2.gd",
]

const PHASE_BANNERS: Array = [
	["FASE 1 — TITOLO", "Sottotitolo che anticipa la meccanica.", Color(0.35, 0.85, 1.0)],
	["FASE 2 — TITOLO", "Sottotitolo.", Color(0.35, 1.0, 0.7)],
]

var model: QueueModel = QueueModel.new()   # il tuo model
```

e la parte di `_ready()` che inizializza il model e chiama `network.setup(model)`.

### Passo 6 — Aggancia il livello al gioco

In `GameManager.gd` aggiungi il percorso e un metodo di navigazione:

```gdscript
const SCENE_LEVEL_2 := "res://scenes/level2.tscn"
const SCENE_INTRO_2 := "res://scenes/introduction2.tscn"

func go_to_level_2() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_2)
```

e nel menu principale aggiungi il pulsante che porta a `SCENE_INTRO_2`.

### Passo 7 — L'introduzione teorica

Duplica `introduction.tscn` + `IntroductionScreen.gd`. Tutto il testo sta nella costante `PAGES`, quindi si modifica in un punto solo:

```gdscript
const PAGES: Array = [
	{
		"diagram": true,                       # mostra il diagramma a destra
		"diagram_title": "La struttura di esempio",
		"diagram_note": "Riga sotto al disegno.",
		"body": """[b][color=#7fd8ff]Titolo sezione[/color][/b]
Testo in BBCode, con [b]grassetti[/b] sulle parole chiave.""",
	},
]
```

Tre pagine sono la misura giusta: **cos'è**, **come funziona l'operazione centrale**, **la missione**. Ogni pagina deve stare nel riquadro senza scroll: al massimo **20 righe renderizzate** a font 15 con il diagramma, ~18 a tutta larghezza. Se sfori, il testo viene tagliato — verificalo sempre eseguendo la scena.

L'ultima pagina deve elencare fasi, comandi e penalità, altrimenti il giocatore entra al buio.

### Passo 8 — Il test automatico

Duplica `tests/AutoPlayHarness.gd`. È un bot che gioca **sempre in modo corretto** leggendo lo stato della fase e calcolando la mossa giusta dal model:

```gdscript
func _process(_delta: float) -> void:
	var phase: PhaseBase = _current_phase()
	if phase == null or level.is_over:
		return
	if _try_place_router(phase):   # c'è roba nel vassoio? posizionala
		return
	if _try_pick(phase):           # aspetta un clic su un nodo? cliccalo
		return
	_try_route(phase)              # aspetta una direzione? calcolala dal model
```

Eseguilo con **F6**: se arriva al messaggio di vittoria senza errori runtime, l'intera catena funziona. È il modo più veloce per accorgersi di una regressione dopo una modifica al bilanciamento.

---

## 8. API di riferimento

### `level` (LevelController), disponibile in ogni fase

| Membro | A che serve |
|---|---|
| `level.model` | Il model del livello |
| `level.network` | La view |
| `level.tray` | Dove mettere i nodi trascinabili |
| `level.action_bar` | Dove finiscono i pulsanti |
| `level.is_over` | `true` se il tempo è scaduto o il livello è finito |
| `set_phase_header(titolo, colore)` | Titolo in alto a sinistra |
| `set_objective(testo)` | La riga dell'obiettivo corrente |
| `set_hint(testo)` | Il suggerimento in basso |
| `toast(testo, colore)` | Messaggio di feedback che sfuma |
| `await show_banner(titolo, sottotitolo, colore)` | Cartello a centro schermo |
| `make_action_button(testo, centro, dimensione)` | Crea un pulsante stilizzato |
| `clear_action_bar()` | Cancella tutti i pulsanti |
| `penalty(secondi)` | Applica la penalità e mostra il "−N s" volante |
| `set_alert_mode(true/false)` | Sfondo che pulsa in rosso |

### `PhaseBase`, ereditato da ogni fase

| Membro | A che serve |
|---|---|
| `await place_routers(valori, penalità)` | Mini-gioco di inserimento drag & drop |
| `await route_packet(destinazione)` | Mini-gioco di ricerca (gestisce anche il valore assente) |
| `await scan_network(tipo, mostra_regola)` | Mini-gioco di visita |
| `await pick_router(valore, evidenzia, messaggio, penalità)` | «Clicca il nodo giusto» |
| `await delete_router(valore)` | Selezione + cancellazione + riorganizzazione |
| `await shortest_path_game(grafo, sorgente, destinazione)` | Ciclo di Dijkstra eseguito a mano dal giocatore |
| `await _wait(secondi)` | Pausa |
| `_is_over()` | Da controllare dopo ogni `await` |
| `fmt(valore)` | Formattazione numerica coerente |
| `finished.emit()` | Segnala che la fase è conclusa |
| `COLOR_OK` / `COLOR_BAD` / `COLOR_INFO` / `COLOR_WARN` | Palette dei messaggi |

### `NetworkView`

`setup(model)` · `rebuild(animate)` · `adopt_router(router, valore)` · `show_all_free_slots()` · `clear_slots()` · `nearest_slot(pos_globale)` · `slot_center(padre, lato)` · `center_of(valore)` · `get_router(valore)` · `all_routers()` · `set_edge_color(da, a, colore)` · `reset_edges()` · `spawn_packet(valore, pos)` · `await move_packet(pacchetto, pos, durata)` · `destroy_packet(pacchetto, esploso)`

### `RouterNode`

Proprietà `value`, `draggable`, `clickable`, `home_position` · segnali `clicked`, `drag_started`, `dropped` · metodi `set_state(State.X)`, `set_pulsing(bool)`, `show_badge(testo)`, `pop()`, `shake()`, `flash(colore)`, `return_home()`, `move_to_center(pos)`
Stati disponibili: `IDLE`, `ACTIVE`, `SUCCESS`, `ERROR`, `SCANNED`, `HACKED`, `GHOST`.

### `Sfx.play(nome)`

`"click"` · `"place"` · `"correct"` · `"error"` · `"packet"` · `"scan"` · `"alarm"` · `"victory"` · `"fail"`
Per aggiungerne uno, una riga in `Sfx._ready()`: `_streams["nuovo"] = _tone([440.0, 660.0], 0.2, 0.3, "sine")`.

### `level` nel Livello 2 (Level2Controller)

| Membro | A che serve |
|---|---|
| `level.db` | Il database (`SqlDatabase`) |
| `level.active_task` | L'obiettivo in corso |
| `level.is_over` | `true` se il tempo è scaduto o il livello è finito |
| `set_task(task, indice, totale)` | Propone un obiettivo e aggiorna l'HUD |
| `refresh_tables(animate)` | Ridisegna le tabelle leggendo il database |
| `set_phase_header` · `set_objective` · `set_hint` · `toast` · `show_banner` · `penalty` | Come nel Livello 1 |
| segnale `task_solved` | Emesso quando l'obiettivo corrente è risolto |

### `SqlPhaseBase`, ereditato da ogni fase del Livello 2

`await do_tasks(elenco)` propone gli obiettivi uno alla volta · `await complete(messaggio)` chiude la fase · `await _wait(secondi)` · `_is_over()` · `COLOR_OK` / `COLOR_BAD` / `COLOR_INFO`

### `SqlDatabase`

`define(nome, colonne, righe)` · `clear()` · `table_names()` · `has_table(nome)` · `column_names(tabella)` · `row_count(tabella)` · `create_table` · `drop_table` · `insert_row` · `snapshot()` / `restore(snap)` / `matches_snapshot(snap)` · statici `same_rows`, `values_equal`, `format_value`

### `SqlEngine` e `SqlTask`

`SqlEngine.execute(db, sql)` ritorna `{"ok": bool, "kind": String, "columns": Array, "rows": Array, "error": String}` — non solleva mai eccezioni.
`SqlTask.make(richiesta, soluzione, kind, suggerimento, spiegazione)` · `SqlTask.check(db, sql_giocatore, task)` ritorna `{"status": "ok"|"error"|"wrong", "message": String}`.

### `level` nel Livello 3 (Level3)

| Membro | A che serve |
|---|---|
| `level.stage` | Il «palco»: le fasi ci montano la loro vista |
| `level.mount(view)` | Aggiunge la vista al palco a schermo intero |
| `level.clear_stage()` | Svuota il palco (lo fa già `_cleanup()`) |
| `level.action_bar` · `make_action_button(testo, centro, dimensione)` · `clear_action_bar()` | I pulsanti creati dalle fasi |
| `level.phase_node` | La fase in esecuzione (la usa il bot di collaudo) |
| `level.solved_count` | Prove superate, mostrate nel riepilogo finale |
| `set_phase_header` · `set_objective` · `set_hint` · `toast` · `show_banner` · `penalty` | Come negli altri livelli |

### `Lvl3PhaseBase`

`await complete(messaggio)` · `await _wait(secondi)` · `_is_over()` · `_score()` registra una prova superata · segnale `helper_done` per il pattern `await` · penalità `PENALTY_STEP` (6 s), `PENALTY_CHOICE` (10 s), `PENALTY_SYNTAX` (8 s), `PENALTY_WRONG` (12 s)

### `Automaton`

`Automaton.make(stati, alfabeto, iniziale, finali)` · `add_transition(da, simbolo, a)` · `targets(stato, simbolo)` · `step_dfa(stato, simbolo)` · `run_dfa(parola)` traccia · `accepts(parola)` (vale anche per NFA) · `epsilon_closure(insieme)` · `move(insieme, simbolo)` con ε-chiusura · `sort_states(insieme)` · `subset_construction()` · statici `set_label(insieme)`, `symbols_of(parola)` · costante `EPSILON`

### `TuringMachine`

`set_rule(stato, letto, scritto, direzione, nuovo_stato)` · `load_input(parola)` · `read_symbol()` · `current_rule()` · `step()` · `run(max_passi)` → `{halted, steps, accepted, tape}` · `is_halted()` · `cell(posizione)` · `tape_string()` · costanti `BLANK`, `LEFT`, `RIGHT`, `STAY`

### `WhileInterpreter` e `WhileTask`

`WhileInterpreter.run(sorgente, stato_iniziale, max_passi)` → `{ok, error, state, steps, terminated}` — `terminated == false` significa «per quanto ne sappiamo cicla».
`WhileTask.make(richiesta, soluzione, casi, variabili_uscita, suggerimento, spiegazione)` · `WhileTask.check(task, sorgente)` → `{status, message}` · `WhileTask.preview(sorgente, stato)` esegue senza giudicare.

---

## 9. Trappole già incontrate (leggile, fanno risparmiare ore)

| Sintomo | Causa | Rimedio |
|---|---|---|
| Disegno con `_draw()` invisibile | In Godot il genitore disegna **prima** dei figli: uno sfondo opaco copre il `_draw()` del genitore | Metti il disegno in un `Control` figlio posizionato dopo lo sfondo e collega il suo segnale `draw` |
| I clic non arrivano ai nodi | `mouse_filter` sbagliato | I contenitori a schermo intero vanno su `Ignore`, gli elementi cliccabili su `Stop` |
| Il drag "si perde" muovendo veloce il mouse | Il rilascio arriva fuori dal controllo | Gestisci il rilascio in `_input()`, non in `_gui_input()` (vedi `RouterNode`) |
| `Identifier not found: GameManager` nell'editor | Gli autoload si registrano all'avvio dell'editor | Riavvia l'editor dopo aver modificato gli autoload |
| Modifiche a una `.tscn` che spariscono | L'editor tiene la scena aperta e la risalva sopra | Apri un'altra scena prima di modificare quel file da fuori |
| Elementi nuovi disegnati **sopra** i vecchi, che non spariscono | `queue_free()` libera il nodo solo a fine frame: fino ad allora il contenitore continua a disporlo | `remove_child(nodo)` **prima** di `queue_free()` |
| Un pulsante finisce sopra una vista | Le viste stanno in un contenitore che non parte dal bordo dello schermo, i pulsanti sì | Calcola la posizione dal rettangolo del contenitore, non da `level.size` |
| Alberi profondi che escono dallo schermo | Layout a passo fisso | Passo verticale adattivo alla profondità (`NetworkView.compute_layout()`) |
| Confronti fra `float` che falliscono | Errori di virgola mobile | Sempre `is_equal_approx(a, b)`, mai `a == b` |
| Una fase continua ad agire a tempo scaduto | `await` sospeso quando è scattato il game over | `if _is_over(): return` dopo ogni `await` |

---

## 10. Un livello "da tastiera" invece che "da mouse"

Il Livello 2 mostra la seconda famiglia possibile di livelli: il giocatore non manipola oggetti, **scrive**. Se il tuo Livello 3 è di questo tipo, riusa questi tre pezzi:

- **`SqlConsole`** → l'editor di testo con pulsante Esegui, Ctrl+Invio, messaggi di stato e griglia del risultato. Emette `query_submitted(testo)`: ti basta collegarti.
- **`SqlManual`** → il manuale in sovraimpressione a pagine. Cambiando la costante `MANUAL_PAGES` diventa il manuale di qualunque argomento; il costo in secondi è in `COST_SECONDS`.
- **`SqlTask`** → il pattern di correzione **per equivalenza**, il pezzo più importante da copiare.

### Il pattern «correggi l'effetto, non il testo»

Mai confrontare quello che il giocatore ha scritto con la soluzione carattere per carattere: esistono decine di formulazioni corrette e il giocatore si sentirebbe truffato. Confronta invece il **risultato**:

```gdscript
static func check(state, player_input: String, task) -> Dictionary:
	var sandbox = state.clone()            # copia dello stato
	var mine = esegui(sandbox, player_input)
	if not mine.ok:
		return {"status": "error", "message": mine.error}   # penalità piccola

	var expected_state = state.clone()
	var theirs = esegui(expected_state, task.solution)      # soluzione di riferimento

	if uguali(mine, theirs):                                # oppure sandbox == expected_state
		return {"status": "ok"}
	return {"status": "wrong", "message": "spiegazione del perché"}
```

Tre regole che rendono il pattern equo:
1. **Tre esiti distinti**, non due: `error` (input non valido), `wrong` (valido ma non risolve), `ok`. Penalità diverse, messaggi diversi.
2. **Nulla viene applicato se non è corretto**: si lavora su una copia, così una mossa sbagliata non lascia lo stato incoerente.
3. **Tolleranza dove non conta**: maiuscole, spazi, ordine delle righe se non hai chiesto un ordinamento, alias sui nomi. Rigore solo su ciò che l'esercizio vuole insegnare.

### Obiettivi come dati, non come codice

Una fase del Livello 2 è solo un elenco dichiarativo:

```gdscript
var tasks: Array = [
	SqlTask.make(
		"Mostra nome e citta dei clienti di Roma.",          # richiesta
		"SELECT nome, citta FROM clienti WHERE citta='Roma'", # soluzione di riferimento
		SqlTask.KIND_SELECT,
		"Filtra con WHERE. Il testo va fra apici singoli.",   # suggerimento
		"WHERE filtra le righe, l'elenco dopo SELECT le colonne."),  # spiegazione finale
]
await do_tasks(tasks)
```

Aggiungere un esercizio significa aggiungere cinque stringhe: nessuna logica nuova, nessun rischio di rompere il resto.

---

## 11. Checklist finale prima di dire "fatto"

- [ ] Il model non contiene nessun riferimento a nodi Godot
- [ ] Ogni messaggio d'errore spiega il **perché**, con i numeri della partita
- [ ] Ogni fase controlla `_is_over()` dopo ogni `await`
- [ ] Le tre pagine dell'introduzione stanno nel riquadro senza tagli
- [ ] L'ultima pagina elenca fasi, comandi e penalità
- [ ] Il bot di autoplay completa il livello e mostra la schermata di vittoria
- [ ] La scena di timeout mostra i due pulsanti e funzionano entrambi
- [ ] Un giocatore esperto finisce in circa metà del tempo disponibile
- [ ] La scansione del progetto non produce errori né warning
- [ ] Se il livello si gioca scrivendo: la correzione accetta ogni formulazione corretta

E se invece hai **ampliato un livello esistente**:

- [ ] I 52 test del motore SQL passano ancora (`0 falliti`)
- [ ] Il bot completa il livello che hai toccato e arriva alla vittoria
- [ ] Hai controllato il tempo residuo del bot: il livello non è diventato troppo lungo
- [ ] `PHASE_SCRIPTS` e `PHASE_BANNERS` hanno ancora la stessa lunghezza
- [ ] Se hai cambiato i dati iniziali, nessun esercizio è diventato banale o impossibile
- [ ] Se hai aggiunto una fase o una pagina di manuale, l'introduzione le cita
- [ ] Se hai toccato il Livello 3: i 66 test dei modelli passano e il bot arriva in fondo
- [ ] Hai committato con percorsi espliciti, dopo aver controllato che non ci siano cancellazioni impreviste
