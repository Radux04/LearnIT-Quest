# LearnIT Quest

**Edugame 2D in Godot 4.5 che insegna le strutture dati e gli algoritmi facendoli usare, non spiegandoli.**

Ogni livello è una "missione informatica" da completare in **5 minuti**: niente quiz a risposta multipla, ma meccaniche di gioco in cui l'algoritmo *è* il gameplay. Se il tempo scade la partita è persa e si può ricominciare o tornare al menu.

| | |
|---|---|
| **Engine** | Godot 4.5 (Forward+) |
| **Risoluzione** | 1280×720, stretch `canvas_items` / `expand` |
| **Lingua** | Italiano |
| **Livelli disponibili** | 1 — Binary Search Tree Network |

---

## Livello 1 · Binary Search Tree Network

La rete informatica è rappresentata come un albero di **router futuristici** collegati da **cavi luminosi** percorsi da **pacchetti animati**. Ogni router è un nodo del BST e la sua "metrica" è la chiave.

Le metriche sono **numeri decimali** scelti a coppie ravvicinate (`25.5` / `25.9`, `62.1` / `62.4`): non basta guardare la parte intera, bisogna confrontare davvero.

### Introduzione teorica (3 pagine)

Prima del gameplay c'è una spiegazione navigabile con diagramma animato:

1. **Che cos'è un BST** — nodi, cavi, radice, la regola d'oro (minori a sinistra, maggiori a destra) e il fatto che vale a *ogni* livello, non solo alla radice.
2. **La ricerca** — perché costa quanto l'*altezza* dell'albero e non il numero di nodi, cosa succede quando il valore **non esiste** (vicolo cieco), e le quattro visite. Il diagramma evidenzia il percorso di ricerca reale.
3. **La missione** — le 4 fasi, il timer, i comandi e le penalità.

Il livello parte solo premendo *"Inizia la missione"*.

### Le quattro fasi

Le fasi si susseguono **senza caricamenti**: la rete disegnata a schermo è sempre la stessa e viene riorganizzata dal vivo.

| Fase | Cosa fa il giocatore | Concetto di algoritmi | Penalità |
|---|---|---|---|
| **1 · Ricostruzione** | Trascina 8 router nelle postazioni libere della rete | **Inserimento** in un BST | −5 s |
| **2 · Instradamento** | Guida 7 pacchetti dalla radice alla destinazione scegliendo SINISTRA/DESTRA — e riconosce i **vicoli ciechi** | **Ricerca** con esito positivo *e negativo* | −12 s |
| **3 · Scansione** | Clicca i router nell'ordine di una visita estratta a caso | **Preorder, Inorder, Postorder, BFS** | −10 s |
| **4 · Attacco finale** | Risponde a 7 richieste rapide e casuali | **Inserimento, cancellazione (con successore in-order), ricerca, minimo, massimo, successore** | −15 s |

Dettagli che rendono l'esperienza didattica e non un quiz:

- **Fase 1** — se sbagli, il messaggio spiega *esattamente perché*: «25.9 NON è minore di 25.5: non può stare a sinistra». Le postazioni libere sono cerchi tratteggiati pulsanti, quindi il giocatore vede subito dove *si potrebbe* inserire.
- **Fase 2** — 2 pacchetti su 7 hanno una destinazione che **non esiste** in rete. Il giocatore deve accorgersi che dal lato in cui dovrebbe scendere non parte alcun cavo e premere **`✖ NON IN RETE`**. A consegna riuscita il gioco mostra il costo reale: *«Consegnato a 74.5 in 2 confronti invece di 9 router controllati!»*.
- **Fase 3** — la regola della visita è mostrata solo nel **primo** dei tre round: dal secondo bisogna ricordarsela. Ogni clic corretto illumina il router e gli assegna il numero d'ordine.
- **Fase 4** — la cancellazione sceglie di preferenza un nodo con **due figli**, il caso più istruttivo, e spiega che al suo posto sale il **successore in-order**. Lo sfondo pulsa in rosso durante l'attacco.

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
│   ├── introduction.tscn       spiegazione teorica a 3 pagine
│   └── level.tscn              Livello 1 (HUD + rete + overlay)
├── scripts/
│   ├── global/
│   │   ├── GameManager.gd      autoload: timer, penalità, cambio scena
│   │   └── Sfx.gd              autoload: audio sintetizzato a runtime
│   ├── bst/
│   │   └── BSTModel.gd         il BST puro (nessuna grafica)
│   ├── ui/
│   │   ├── NetworkView.gd      disegna la rete: cavi, slot, pacchetti
│   │   └── RouterNode.gd       un router: stati, drag & drop, clic
│   ├── phases/
│   │   ├── PhaseBase.gd        i mini-giochi riusabili
│   │   └── Phase1..4.gd        le quattro fasi del Livello 1
│   └── scenes/
│       ├── MainMenu.gd
│       ├── IntroductionScreen.gd
│       └── Level.gd            orchestratore del livello + HUD
├── tests/
│   ├── autoplay.tscn           bot che gioca il livello intero
│   └── timeout.tscn            verifica la schermata "tempo scaduto"
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
| `res://tests/autoplay.tscn` | Istanzia il livello e lo **gioca da solo in modo sempre corretto**, attraversando tutte e 4 le fasi fino alla vittoria. Stampa in console ogni mossa. |
| `res://tests/timeout.tscn` | Porta il cronometro a zero e verifica la schermata *Tempo Scaduto* con i due pulsanti. |

Esegui `autoplay.tscn` con **F6**: se arriva a `RETE RIPRISTINATA` senza errori runtime, l'intera catena (modello, vista, fasi, HUD) è sana. Alza `TIME_SCALE` in `AutoPlayHarness.gd` per accelerare la verifica.

## Bilanciamento

Tutte le manopole sono raccolte in pochi punti:

| Cosa | Dove |
|---|---|
| Durata del livello | `GameManager.LEVEL_DURATION` |
| Penalità delle 4 fasi | `PhaseBase.PENALTY_PLACE / ROUTE / SCAN / ATTACK` |
| Router da posizionare | `Phase1.ROUTERS_TO_PLACE` |
| Numero di pacchetti e valori assenti | `Phase2.PRESENT_PACKETS`, `ABSENT_PACKETS`, `ABSENT_CANDIDATES` |
| Numero di visite | `Phase3.ROUNDS` |
| Numero e mix di sfide finali | `Phase4.CHALLENGE_COUNT`, `Phase4._build_plan()` |

---

## Roadmap

- [x] Livello 1 — Binary Search Tree
- [ ] Menu principale completo con selezione livelli e progressi
- [ ] Livello 2 — argomento da definire
- [ ] Schermata di riepilogo con statistiche (confronti risparmiati, errori)

## Licenza

Progetto sviluppato a scopo didattico nell'ambito di una tesi.
