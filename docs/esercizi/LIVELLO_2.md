# Aggiungere esercizi al Livello 2 — Database Recovery (SQL)

Gli esercizi stanno nelle cinque fasi, in `scripts/phases/lvl2/Phase1.gd` … `Phase5.gd`, come **elenchi dichiarativi**. Aggiungerne uno significa aggiungere cinque stringhe: nessuna logica nuova, nessun rischio di rompere il resto.

---

## Aggiungere un esercizio

```gdscript
		SqlTask.make(
			"Mostra le città dei clienti senza ripetizioni.",   # 1. richiesta
			"SELECT DISTINCT citta FROM clienti",               # 2. UNA soluzione di riferimento
			SqlTask.KIND_SELECT,                                # 3. select oppure mutate
			"DISTINCT elimina i duplicati dal risultato.",      # 4. suggerimento
			"DISTINCT tiene una sola riga per ogni valore."),   # 5. spiegazione finale
```

**Quattro regole:**

- **`kind` deve essere giusto.** `KIND_SELECT` se l'esercizio legge, `KIND_MUTATE` se modifica. La correzione controlla cose diverse: nel primo caso confronta il risultato, nel secondo lo stato finale del database.
- **La soluzione di riferimento viene eseguita davvero.** Se contiene un comando non supportato, il giocatore riceve «Soluzione di riferimento non valida» qualunque cosa scriva.
- **Non serve prevedere le varianti.** La correzione confronta l'effetto, non il testo: `WHERE` in ordine diverso, `IN` al posto di `OR`, maiuscole e alias sono già accettati.
- **Se l'ordine delle righe conta, la soluzione deve usare `ORDER BY`.** È quello che dice al correttore di essere rigoroso sull'ordine.

---

## Che cosa il motore accetta già

Verificato eseguendo query vere:

`SELECT` · `DISTINCT` · `WHERE` · `AND` `OR` `NOT` · `= <> != < <= > >=` · `+ - * / %` · `IN` / `NOT IN` · `LIKE` (con `%`) · `BETWEEN … AND …` · `IS NULL` / `IS NOT NULL` · `ORDER BY … ASC|DESC` · `LIMIT n` · `GROUP BY` · `COUNT SUM AVG MIN MAX` · alias con `AS` · subquery scalari e con `IN` · `INSERT INTO … VALUES` · `UPDATE … SET … WHERE` · `DELETE FROM … WHERE` · `CREATE TABLE` · `DROP TABLE`

**Non supportati:** `JOIN`, `HAVING`, nomi qualificati come `c.nome`, `UNION`.

---

## Cambiare i dati di partenza

Il database iniziale è in `Level2._seed_database()`:

```gdscript
	db.define("prodotti",
		[["id", "INT"], ["nome", "VARCHAR(40)"], ["prezzo", "INT"]],
		[[1, "Tastiera", 45], [2, "Monitor", 180]])
```

⚠️ **È la modifica più pericolosa.** Le soluzioni di riferimento di *tutti* gli esercizi girano su questi dati: se cambi una riga, cambi in silenzio il risultato atteso di ogni esercizio che la tocca. Un esercizio può diventare banale (nessuna riga da filtrare) o impossibile. Dopo ogni modifica ai dati **rilancia il bot**.

---

## Il manuale

È in `scripts/ui/SqlManual.gd`, costante `MANUAL_PAGES`. Aprirlo costa `COST_SECONDS` secondi: più pagine aggiungi, più dev'essere facile trovare quella giusta, altrimenti il costo diventa ingiusto. Collega la pagina alla fase in `Level2._suggested_manual_page()` — **gli indici partono da 0**.

---

## Insegnare al motore un comando nuovo

Tre stadi, sempre in quest'ordine:

1. **`SqlTokenizer.gd`** — solo se il comando introduce simboli nuovi.
2. **`SqlParser.gd`** — riconosci la parola chiave e producine un pezzo di AST. **Ogni messaggio d'errore deve spiegare la forma giusta** («Dopo GROUP serve BY, cioè GROUP BY colonna»): finisce in faccia al giocatore ed è lì che impara.
3. **`SqlEngine.gd`** — esegui il nuovo nodo. Il motore non solleva mai eccezioni: ritorna `{"ok": false, "error": "..."}`.
4. **`tests/test_sql_engine.gd`** — il caso che funziona, quello che deve fallire, e il messaggio d'errore atteso.

---

## Verificare

```bash
"$GODOT" --headless --script res://tests/run_sql_tests.gd   # 52 test del motore
"$GODOT" tests/autoplay_level2.tscn                          # il bot risolve tutti gli obiettivi
```

---

## Idee di esercizi da aggiungere

**Con quello che il motore già supporta** — un `GROUP BY` con `COUNT` per contare gli ordini per cliente · una subquery con `AVG` per trovare chi spende sopra la media · `LIKE` per cercare per iniziale · `BETWEEN` su un intervallo di date (memorizzate come testo) · un `UPDATE` che usa il valore attuale della colonna (`eta = eta + 1`) · un `DELETE` con subquery per rimuovere i clienti senza ordini · una `CREATE TABLE` seguita da `INSERT` che copia dati da un'altra tabella.

**Che richiedono di estendere il motore** — `JOIN` fra clienti e ordini (è la mancanza più sentita: oggi si simula con `IN`) · `HAVING` per filtrare i gruppi · `ORDER BY` su più colonne · le transazioni (`BEGIN`/`ROLLBACK`), che permetterebbero una fase sul «annulla l'errore».

**Fasi nuove possibili** — **progettazione dello schema**: dato un testo, il giocatore scrive le `CREATE TABLE` con le chiavi giuste · **normalizzazione**: una tabella con dati ripetuti da spezzare in due · **indici e prestazioni**: mostrare quante righe sono state lette con e senza indice.

---

Per la struttura del livello vedi [CREARE_UN_LIVELLO.md](../CREARE_UN_LIVELLO.md), capitolo 3.
