# Aggiungere esercizi al Livello 3 — Calcolabilità

Gli esercizi stanno tutti in un catalogo:

```
scripts/phases/lvl3/Lvl3Pools.gd
```

Ogni fase ne pesca a caso a ogni partita. Per aggiungerne uno si aggiunge una voce a un array: non si tocca il codice delle fasi.

> **Dopo ogni modifica lancia i test.** Validano ogni voce del catalogo:
> ```
> godot --headless --script res://tests/run_lvl3_tests.gd
> ```

---

## 1. Un automa per la Fase 1 (`DFA_POOL`)

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
		"hint": "Conta solo l'ULTIMO simbolo letto.",
	},
```

**Tre vincoli (li verificano i test):**

1. L'automa dev'essere **completo e deterministico**: da ogni stato, per ogni simbolo, **esattamente una** freccia. Altrimenti l'esecuzione si blocca a metà parola.
2. **Massimo 5 stati**: la vista li dispone in fila orizzontale.
3. Le parole devono usare solo simboli dell'alfabeto, e ne servono almeno due.

---

## 2. Un automa non deterministico per la Fase 2 (`NFA_POOL`)

Oltre all'automa servono i **passi** della costruzione per sottoinsiemi che il giocatore rifarà:

```gdscript
		"epsilon": false,
		"steps": [
			[["q0"], "a", "Da q0 con 'a' l'automa può fare DUE cose."],
			[["q0", "q1"], "b", "Considera ogni stato dell'insieme e unisci i risultati."],
		],
```

Ogni passo è `[insieme di partenza, simbolo, suggerimento]`. **La risposta attesa non si scrive**: la calcola il model con `move()`, ε-chiusura compresa.

Il campo `"epsilon"` dice se l'automa ha ε-transizioni: la Fase 2 pesca **un automa per tipo**, quindi il catalogo deve contenerne sempre almeno uno per ciascuno. I test verificano anche che ogni passo porti a un insieme **non vuoto**, altrimenti non insegna nulla.

---

## 3. Una macchina di Turing per la Fase 3

Due elenchi: `TM_POOL` (da eseguire) e `DESIGN_POOL` (da completare).

```gdscript
	{
		"name": "inverte i bit",
		"start": "q0", "accept": "qf", "input": "101",
		"rules": [                       # [stato, letto, scritto, direzione, nuovo stato]
			["q0", "0", "1", R, "q0"],   # R = destra, L = sinistra, S = ferma
			["q0", "1", "0", R, "q0"],
			["q0", "□", "□", S, "qf"],
		],
		"result": "ogni bit invertito",
		"hint": "La regola dipende SOLO da stato corrente e simbolo letto.",
	},
```

**Due avvertenze:**

- ⚠️ **La macchina deve fermarsi, e in pochi passi.** Il giocatore clicca una regola a ogni passo: oltre la ventina diventa una tortura. I test verificano arresto e numero di passi (limite 40). *Un test ha già bocciato una macchina «raddoppia in unario» che non si fermava mai.*
- **Poche regole**: la tabella cresce verso l'alto in base a quante ne ha, ma oltre le 7-8 lo spazio finisce.

Per `DESIGN_POOL` servono anche `"missing"` (la regola che manca) e `"options"` con **esattamente una** alternativa `"correct": true`. Le alternative vengono mescolate a ogni partita.

---

## 4. Un programma WHILE per la Fase 4 (`WHILE_POOL`)

Le soluzioni si scrivono nella **notazione accademica del corso**:

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
		"hint": "...", "explain": "...",
	},
```

**Quattro regole:**

- **Scegli esercizi che il linguaggio non risolve con un operatore.** Divisione, resto, MCD, fattoriale vanno bene; «somma di X e Y» no, perché `Z := X + Y` è una risposta legittima e il ciclo non serve.
- **Metti fra i casi di prova quelli limite**: zero, valori uguali, primo minore del secondo. La correzione li prova tutti e si ferma al primo che fallisce.
- **La soluzione deve terminare** su ogni caso.
- **Non serve prevedere le varianti**: si confronta l'effetto, quindi il giocatore può rispondere anche nella forma compatta.

### Le due notazioni accettate

| | Compatta | Accademica (del corso) |
|---|---|---|
| Raggruppare | `;` | `begin … end` |
| Ciclo | `while c do P end` (anche `od`) | `while c do begin P end` |
| Condizione | `if c then P else Q end` (anche `fi`) | `if c then begin P end else begin Q end` |
| Ingressi/uscite | — | `INPUT(X)` · `OUTPUT(Y)` |
| Successore/predecessore | `x + 1` · `x - 1` | `s(x)` · `pd(x)` |
| Commenti | `# …` | `/* … */` |

In entrambe: variabili sui **naturali** (valgono 0 se mai assegnate), operatori `+ - *` con **sottrazione troncata**, confronti `= != < <= > >=`, e una condizione senza confronto significa «≠ 0». Dopo un `end` il `;` può mancare.

---

## Verificare

```bash
"$GODOT" --headless --script res://tests/run_lvl3_tests.gd   # 399 test
"$GODOT" tests/autoplay_level3.tscn                           # il bot gioca il livello
```

`STOP_AT_PHASE` nel bot lo ferma all'inizio di una fase per poterla guardare; `CHOICE_DELAY` ritarda la risposta alle scelte multiple.

---

## Idee di cosa si potrebbe implementare

**Automi** — automi su alfabeti di tre simboli · un automa da **minimizzare** (unire gli stati equivalenti) · il passaggio da **espressione regolare a automa** (costruzione di Thompson), con il giocatore che monta i pezzi.

**Macchine di Turing** — palindromi su `{a,b}` · confronto di due numeri unari · una macchina a **due nastri**, che richiederebbe una vista nuova ma mostra bene perché non aggiunge potenza.

**WHILE** — numeri primi (con un ciclo dentro l'altro) · massimo di una sequenza codificata · una funzione che **non termina su alcuni input**, per far toccare con mano la differenza fra funzione totale e parziale — servirebbe però un modo di correggere che accetti la non terminazione come risposta giusta.

**Fasi nuove** — le **funzioni ricorsive primitive** costruite componendo blocchi (zero, successore, proiezione, composizione, ricorsione) con i mattoncini da incastrare · la **macchina universale**: dato il codice di una macchina come stringa sul nastro, eseguirla · il **problema dell'arresto** — c'è già scritta in `Phase4.gd` ma è fuori rotazione, si riattiva rimettendo due righe in `Level3.PHASE_SCRIPTS` e `PHASE_BANNERS`.

---

Per la struttura del livello vedi [CREARE_UN_LIVELLO.md](../CREARE_UN_LIVELLO.md), capitolo 4.
