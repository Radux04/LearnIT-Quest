# Creare ed estendere un livello in LearnIT Quest

Questa guida indica come creare un livello generico riusando le meccaniche già presenti e come aggiungere fasi ai quattro livelli esistenti.

## Regole comuni

- Il concetto deve diventare un gesto: il giocatore applica una regola, non risponde a un quiz isolato.
- Ogni fase insegna una competenza: prima prove guidate, poi casi combinati.
- Ogni errore spiega la regola violata usando i dati reali della partita.
- Riusa `level.toast(...)`, `level.set_hint(...)`, `level.penalty(secondi)` e il timer di `GameManager`.
- Dopo ogni `await`, controlla `if _is_over(): return`.
- Quando esistono molte soluzioni corrette, valida il comportamento ottenuto e non una singola forma.

## Meccaniche già riusabili

| Famiglia | Riferimento | Elementi pronti |
|---|---|---|
| Manipolazione visuale | Livello 1 | drag & drop, click sui nodi, scelta direzione, click in sequenza |
| Console testuale | Livello 2 | editor, esecuzione, manuale, esiti `ok/error/wrong` |
| Palco dedicato | Livelli 3 e 4 | `Stage`, `level.mount(view)`, `ActionBar`, HUD, banner e pausa |
| Cataloghi di prove | Tutti | pool/dizionari di esercizi senza riscrivere la fase |

Non duplicare HUD, timer e schermate finali: sono già nei controller `Level.gd`, `Level2.gd`, `Level3.gd` e `Level4.gd`.

## Creare un livello nuovo

1. Definisci argomento, metafora, gesto, regola di validazione, feedback e successione delle fasi.
2. Crea `scripts/<argomento>/<Nome>Model.gd`: `class_name`, `extends RefCounted`, solo dati/regole/simulazione e nessun nodo Godot.
3. Scegli la base: `Lvl1PhaseBase` per meccaniche su alberi, `SqlPhaseBase` per comandi testuali, `Lvl3PhaseBase`/`Lvl4PhaseBase` per una view su palco.
4. Crea una view solo se necessaria: raccoglie input e disegna, mentre il model stabilisce se la mossa è corretta.
5. Crea `Phase1.gd`, `Phase2.gd`, ecc. Ogni fase imposta titolo, obiettivo e hint, poi chiude con `finished.emit()` o `complete(...)`.
6. Inserisci ogni file in `PHASE_SCRIPTS` e il banner corrispondente in `PHASE_BANNERS`: stessa lunghezza e stesso ordine.
7. Aggiorna introduzione, `GameManager.gd`, menu, test e autoplay.

```gdscript
extends Lvl3PhaseBase

func _start() -> void:
	level.set_phase_header("FASE - TITOLO", Color(0.4, 0.85, 1.0))
	level.set_objective("Azione richiesta.")
	level.set_hint("Regola breve.")
	var view: Control = MyView.new()
	level.mount(view)
	await helper_done
	if _is_over():
		return
	await complete("Regola applicata correttamente.")
```

## Idee per nuovi livelli

### Reti informatiche e cybersecurity

Metafora: sala operativa SOC. Model: host, IP, servizi, regole firewall, eventi e severità.

| Fase | Meccanica | Obiettivo |
|---|---|---|
| Topologia | trascinare server, switch e client | distinguere LAN, DMZ e Internet |
| Firewall | ordinare regole allow/deny | porte, protocolli e precedenza |
| Instradamento | scegliere next hop | gateway e percorsi |
| Incident response | cliccare eventi nei log | scansione, brute force, eventi leciti |
| Difesa finale | isolare host e applicare regole | minimo privilegio |

Esempio di feedback: “La porta 22 serve all'amministrazione, ma una regola aperta a tutti permette SSH da qualunque IP.”

### Logica: AND, OR, NOT, implicazione

Metafora: pannello di sicurezza con sensori e porta automatica. Model: variabili booleane, formule, tabella di verità e risultato.

| Fase | Meccanica | Obiettivo |
|---|---|---|
| Sensori | attivare/disattivare variabili | vero e falso |
| AND/OR | trascinare operatori nei blocchi | congiunzione e disgiunzione |
| NOT | negare un segnale | negazione e doppia negazione |
| Tabella | completare righe V/F | valutazione sistematica |
| Regola accesso | costruire una formula | parentesi e combinazione operatori |

Varianti: XOR, equivalenza, leggi di De Morgan e semplificazione.

### Probabilità e statistica

Metafora: laboratorio che analizza l'affidabilità dei server. Model: campioni, eventi, frequenze, misure centrali e distribuzioni.

| Fase | Meccanica | Obiettivo |
|---|---|---|
| Frequenze | trascinare osservazioni nelle classi | frequenza assoluta e relativa |
| Misure centrali | scegliere media, mediana o moda | outlier e interpretazione |
| Evento | selezionare esiti favorevoli | probabilità semplice |
| Condizionata | filtrare e calcolare | significato di “dato che” |
| Decisione | scegliere il server da investigare | soglie, percentili e sintesi dati |

Esempio di feedback: “Per P(attacco dato traffico notturno), il totale contiene soltanto gli eventi notturni.”

## Aggiungere fasi ai livelli esistenti

Per ogni livello: crea il file, registralo in `PHASE_SCRIPTS` e `PHASE_BANNERS`, aggiorna introduzione e autoplay, poi ribilancia il timer.

### Livello 1 - BST, alberi binari e Dijkstra

File: `scripts/phases/lvl1/PhaseN.gd`, controller `Level.gd`.

| Fase aggiuntiva | Meccanica | Concetto |
|---|---|---|
| Bilanciamento | scegliere LL, LR, RR, RL | altezza e costo di ricerca |
| Diagnostica BST | cliccare la prima violazione | proprietà globale BST |
| Backup ordinato | click Inorder | visita e ordinamento |
| Grafo resiliente | rimuovere un arco e ricalcolare | archi critici e cammini alternativi |

Riusa `Lvl1PhaseBase`: `place_nodes`, `search_key`, `traverse_tree`, `pick_node`, `delete_node`, `shortest_path_game`.

### Livello 2 - database e SQL

File: `scripts/phases/lvl2/PhaseN.gd`, `Level2.gd`, `SqlManual.gd`.

| Fase aggiuntiva | Meccanica | Concetto |
|---|---|---|
| Report | query con `GROUP BY`, `COUNT`, `AVG` | aggregazioni |
| Controllo accessi | filtri `AND`, `OR`, `NOT`, `IN` | condizioni complesse |
| Migrazione | `CREATE` e `INSERT` | schema e persistenza |
| Audit | rimuovere righe anomale | pulizia dati |

Aggiungi prove con `SqlTask.make(...)`. Per un costrutto SQL nuovo, estendi tokenizer, parser, engine e test insieme.

### Livello 3 - calcolabilità e macchina di Turing

File: `scripts/phases/lvl3/PhaseN.gd`, `Level3.gd`, `Lvl3Pools.gd`, view in `scripts/ui/`.

#### Esempio: Costruisci un automa con drag & drop

- Pool laterale: stati `q0`, `q1`, `q2`, stati finali e token di transizione.
- Area centrale: trascinamento degli stati; un collegamento tra due stati crea una freccia.
- Pannello transizione: assegna `0`, `1` oppure `ε` alla freccia.
- Pulsante “Verifica automa”: controlla stato iniziale/finale, completezza richiesta e parole test.
- `AutomatonView` disegna stati e frecce; una nuova view può emettere `state_dropped`, `transition_created`, `verify_requested`.

Valida il linguaggio accettato sulle parole test: non confrontare coordinate, nomi degli stati o una sola forma grafica dell'automa.

| Altre fasi | Meccanica | Concetto |
|---|---|---|
| Completa DFA | trascinare etichette sulle frecce | determinismo e completezza |
| Minimizza DFA | raggruppare stati equivalenti | equivalenza |
| Progetta TM | scegliere quintuple dal pool | nastro e movimenti |
| Traccia WHILE | ordinare blocchi o prevedere variabili | semantica dei cicli |
| Halting problem | completare diagonale | limiti della calcolabilità |

Usa `level.mount(view)` e pulisci palco, segnali e `ActionBar` alla chiusura.

### Livello 4 - metodologie e Java

File: `scripts/phases/lvl4/PhaseN.gd`, `Level4.gd`, `Lvl4Pools.gd`.

| Fase aggiuntiva | Meccanica | Concetto |
|---|---|---|
| Responsabilità | trascinare metodi dal pool alle classi | SRP e coesione |
| DIP | collegare interfacce e implementazioni | Dependency Inversion |
| Refactoring a passi | scegliere prossima trasformazione | modifiche sicure |
| Review sicurezza | cliccare input non validato, segreti, SQL concatenato | sicurezza nel codice |
| MVC/MVP | trascinare componenti nei ruoli | separazione UI, logica e dati |

Per le fasi testuali riusa i check di `JavaTask`; ogni nuovo check richiede analisi e test per caso corretto e scorretto.

## Checklist

- [ ] Model senza riferimenti a nodi Godot.
- [ ] `PHASE_SCRIPTS` e `PHASE_BANNERS` allineati.
- [ ] Nessuna fase prosegue dopo timeout.
- [ ] Errori che spiegano il perché.
- [ ] Introduzione e menu aggiornati.
- [ ] Timer ribilanciato.
- [ ] Test dei model e autoplay superati.
- [ ] Risposte equivalenti validate per comportamento, non per forma.
