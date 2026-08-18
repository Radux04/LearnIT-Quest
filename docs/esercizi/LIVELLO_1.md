# Allungare il Livello 1 — Rete di router (BST e Dijkstra)

Questo livello **non ha un catalogo di esercizi**: genera tutto da un albero binario di ricerca e da un grafo pesato. Allungarlo significa quindi cambiare i **numeri in gioco** o aggiungere una **meccanica**.

I file:

| File | Contiene |
|---|---|
| `scripts/bst/BSTModel.gd` | L'albero: `insert`, `erase`, `minimum`, `maximum`, `successor`, `predecessor`, le 4 visite |
| `scripts/bst/NetworkGraph.gd` | Il grafo pesato della Fase 5 e Dijkstra |
| `scripts/phases/lvl1/PhaseBase.gd` (`class_name Lvl1PhaseBase`) | I mini-giochi riusabili e le penalità |
| `scripts/phases/lvl1/Phase1.gd` … `Phase5.gd` | Le cinque fasi: *quali* mini-giochi, con *quali* numeri |
| `scripts/scenes/Level.gd` | Elenco delle fasi, HUD, vittoria e sconfitta |

---

## 1. Cambiare i numeri (nessun codice nuovo)

| Voglio | File | Costante |
|---|---|---|
| Più o meno router da posizionare | `Phase1.gd` | `ROUTERS_TO_PLACE` |
| Una radice diversa | `Level.gd` | `ROOT_VALUE` |
| Più pacchetti da instradare | `Phase2.gd` | `PRESENT_PACKETS`, `ABSENT_PACKETS` |
| Più giri di visita | `Phase3.gd` | `ROUNDS` |
| Più attacchi dell'hacker | `Phase4.gd` | `CHALLENGE_COUNT` |
| Grafo di Dijkstra più fitto | `Phase5.gd` | `EXTRA_LINKS`, `MIN_WEIGHT`, `MAX_WEIGHT` |
| Penalità | `Lvl1PhaseBase` (`PhaseBase.gd`) | `PENALTY_PLACE`, `PENALTY_ROUTE`, `PENALTY_SCAN`, `PENALTY_ATTACK` |
| Durata | `GameManager.gd` | `LEVEL_DURATION` |

**Tre vincoli su `ROUTERS_TO_PLACE`:**

1. **Niente duplicati** e nessun valore uguale a `ROOT_VALUE`: in un BST i duplicati non esistono e il gioco li rifiuterebbe.
2. **Profondità entro 4 livelli**, altrimenti i nodi più bassi finiscono sotto il vassoio.
3. **Mantieni le coppie decimali vicine** (`25.5`/`25.9`, `62.4`/`62.1`): sono il motivo didattico della fase. Senza, basta guardare la parte intera.

---

## 2. Aggiungere una sfida all'hacker (Fase 4)

È l'aggiunta più economica: la Fase 4 pesca da un elenco di tipi di sfida. Il model espone già `predecessor()`, quindi «clicca il predecessore» costa poche righe.

```gdscript
func _challenge_predecessor() -> void:
	var ordered: Array[float] = level.model.inorder()
	if ordered.size() < 2:
		await _challenge_route()
		return
	var index: int = 1 + randi() % (ordered.size() - 1)
	var reference: float = ordered[index]
	var target: float = ordered[index - 1]
	level.set_objective("Rollback: clicca il PREDECESSORE di %s." % fmt(reference))
	level.set_hint("È il router che viene prima di %s nella visita Inorder." % fmt(reference))
	await pick_router(target, false, "Corretto: prima di %s viene %s." % [
		fmt(reference), fmt(target)], PENALTY_ATTACK)
```

Poi due righe: una voce nel `match` di `_start()` e una in `_build_plan()`. Occhio: `_build_plan()` **tronca** l'elenco a `CHALLENGE_COUNT`, quindi se non alzi quella costante le ultime voci non escono mai.

---

## 3. I mini-giochi già pronti

Prima di scriverne uno nuovo, controlla se `Lvl1PhaseBase` ha già quello che ti serve:

`await place_routers(valori, penalità)` · `await route_packet(destinazione)` (gestisce anche il valore assente) · `await scan_network(tipo, mostra_regola)` · `await pick_router(valore, evidenzia, messaggio, penalità)` · `await delete_router(valore)` · `await shortest_path_game(grafo, sorgente, destinazione)`

---

## 4. Verificare

```bash
"$GODOT" tests/autoplay.tscn      # il bot gioca il livello da solo
```

Se arriva alla vittoria senza errori, la catena regge. Il **tempo residuo** che stampa è la misura della difficoltà: se scende sotto la metà, il livello è diventato troppo lungo per i 5 minuti.

---

## Idee di cosa si potrebbe implementare

**Con quello che c'è già** — una fase sulle **rotazioni AVL** (la rete «si raddrizza» dopo un inserimento sbilanciato) · far scegliere al giocatore **dove inserire per tenere l'albero bilanciato**, mostrando la profondità risultante · una fase a **eliminazione multipla** dove l'ordine delle cancellazioni cambia la forma finale.

**Con un model nuovo** — **heap**: la stessa vista ad albero, ma la regola è padre ≤ figli, e il gesto è il «sift-up» dopo l'inserimento · **trie** di prefissi, con i router etichettati da lettere · **alberi di ricerca su stringhe** invece che su numeri.

**Sul grafo della Fase 5** — **A\*** con un'euristica mostrata a schermo, per far vedere la differenza con Dijkstra · **albero di copertura minimo** (Prim o Kruskal): il gesto è scegliere ogni volta il cavo più economico che non chiude un ciclo · **cammino minimo con pesi negativi** per far vedere dove Dijkstra sbaglia.

---

Per la struttura del livello vedi [CREARE_UN_LIVELLO.md](../CREARE_UN_LIVELLO.md), capitolo 2.
