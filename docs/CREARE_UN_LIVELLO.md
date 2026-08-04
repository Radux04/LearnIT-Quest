# Come creare un nuovo livello di LearnIT Quest

Guida operativa per costruire il **Livello 2** (e successivi) da solo, riusando l'impianto del Livello 1.

---

## 1. Le regole di design

Prima del codice, i cinque principi a cui il Livello 1 obbedisce. Se il livello nuovo li rispetta, sembrerà parte dello stesso gioco.

1. **L'algoritmo è il gameplay.** Non si chiede *"qual è la complessità della ricerca?"*. Si fa fare al giocatore la ricerca, e il gioco gli mostra a posteriori quanti confronti ha risparmiato. Se una meccanica si può sostituire con una domanda a risposta multipla, è la meccanica sbagliata.
2. **Nessuna schermata di testo durante il gioco.** Tutta la teoria sta nell'introduzione. Durante il livello parlano solo l'obiettivo (una riga), il *toast* di feedback e il suggerimento in basso.
3. **L'errore insegna.** Mai «Sbagliato!». Sempre «25.9 NON è minore di 25.5: non può stare a sinistra». Il messaggio deve contenere il *perché*, con i numeri veri della partita.
4. **Fasi consecutive, zero caricamenti.** La struttura disegnata a schermo resta la stessa e si trasforma dal vivo. Il giocatore deve percepire una sola scena continua.
5. **Cinque minuti, timer sempre visibile, penalità di tempo.** La pressione temporale è ciò che trasforma la conoscenza in automatismo.

---

## 2. Anatomia di un livello

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
│  │  │  │  ┌─ BSTModel (scripts/bst/) ─────────────┐  │ │ │ │
│  │  │  │  │  Solo dati e algoritmi. Zero Godot.   │  │ │ │ │
│  │  │  │  └───────────────────────────────────────┘  │ │ │ │
│  │  │  └─────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

**Regola d'oro:** il *model* non deve mai importare `Node`, `Control`, `Tween` o `Color`. Se ti ritrovi a scrivere `queue_redraw()` dentro il model, hai mescolato gli strati.

---

## 3. Procedura passo-passo

### Passo 0 — Scegli argomento e meccaniche (la parte più importante)

Compila questa tabella **prima** di scrivere codice. Se una casella resta vuota, il livello non è pronto.

| Domanda | Esempio (Livello 1) |
|---|---|
| Qual è la struttura dati? | Binary Search Tree |
| Quale metafora visiva? | Rete di router e cavi |
| Quali operazioni deve interiorizzare il giocatore? | insert, search (positiva e negativa), 4 visite, delete, min/max/successore |
| Che **gesto fisico** corrisponde a ogni operazione? | insert = *trascinare*; search = *scegliere un bivio*; visita = *cliccare in sequenza*; delete = *cliccare il nodo infetto* |
| Come si vede l'errore? | Cavo rosso, router che trema, spiegazione col perché |
| Come si vede il costo dell'algoritmo? | «trovato in 2 confronti invece di 9 router» |

Idee già mappate per i livelli futuri:

| Argomento | Metafora | Gesto |
|---|---|---|
| Stack / Queue | Magazzino di pacchetti, nastro trasportatore | Impilare / prelevare nell'ordine giusto |
| Grafi + BFS/DFS | Mappa di città e strade | Colorare le città nell'ordine di visita |
| Dijkstra | Rete con costi sui cavi | Scegliere il prossimo nodo a costo minimo |
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

## 4. API di riferimento

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

---

## 5. Trappole già incontrate (leggile, fanno risparmiare ore)

| Sintomo | Causa | Rimedio |
|---|---|---|
| Disegno con `_draw()` invisibile | In Godot il genitore disegna **prima** dei figli: uno sfondo opaco copre il `_draw()` del genitore | Metti il disegno in un `Control` figlio posizionato dopo lo sfondo e collega il suo segnale `draw` |
| I clic non arrivano ai nodi | `mouse_filter` sbagliato | I contenitori a schermo intero vanno su `Ignore`, gli elementi cliccabili su `Stop` |
| Il drag "si perde" muovendo veloce il mouse | Il rilascio arriva fuori dal controllo | Gestisci il rilascio in `_input()`, non in `_gui_input()` (vedi `RouterNode`) |
| `Identifier not found: GameManager` nell'editor | Gli autoload si registrano all'avvio dell'editor | Riavvia l'editor dopo aver modificato gli autoload |
| Modifiche a una `.tscn` che spariscono | L'editor tiene la scena aperta e la risalva sopra | Apri un'altra scena prima di modificare quel file da fuori |
| Alberi profondi che escono dallo schermo | Layout a passo fisso | Passo verticale adattivo alla profondità (`NetworkView.compute_layout()`) |
| Confronti fra `float` che falliscono | Errori di virgola mobile | Sempre `is_equal_approx(a, b)`, mai `a == b` |
| Una fase continua ad agire a tempo scaduto | `await` sospeso quando è scattato il game over | `if _is_over(): return` dopo ogni `await` |

---

## 6. Checklist finale prima di dire "fatto"

- [ ] Il model non contiene nessun riferimento a nodi Godot
- [ ] Ogni messaggio d'errore spiega il **perché**, con i numeri della partita
- [ ] Ogni fase controlla `_is_over()` dopo ogni `await`
- [ ] Le tre pagine dell'introduzione stanno nel riquadro senza tagli
- [ ] L'ultima pagina elenca fasi, comandi e penalità
- [ ] Il bot di autoplay completa il livello e mostra la schermata di vittoria
- [ ] La scena di timeout mostra i due pulsanti e funzionano entrambi
- [ ] Un giocatore esperto finisce in circa metà del tempo disponibile
- [ ] La scansione del progetto non produce errori né warning
