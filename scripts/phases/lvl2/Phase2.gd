extends SqlPhaseBase

## FASE 2 — Ricostruzione: creare una tabella e inserire righe.


func _start() -> void:
	level.set_phase_header("FASE 2 — RICOSTRUZIONE (CREATE / INSERT)", Color(0.4, 1.0, 0.7))

	var tasks: Array = [
		SqlTask.make(
			"La tabella prodotti è andata perduta. Ricreala con le colonne id (INT), nome (VARCHAR(40)) e prezzo (INT).",
			"CREATE TABLE prodotti (id INT, nome VARCHAR(40), prezzo INT)",
			SqlTask.KIND_MUTATE,
			"CREATE TABLE nome (colonna TIPO, colonna TIPO, ...);",
			"La tabella esiste ma è vuota: la struttura è separata dai dati."),
		SqlTask.make(
			"Inserisci in prodotti il record: id 1, nome 'Tastiera', prezzo 45.",
			"INSERT INTO prodotti VALUES (1, 'Tastiera', 45)",
			SqlTask.KIND_MUTATE,
			"INSERT INTO tabella (colonne) VALUES (valori);   ·   i numeri senza apici, il testo con gli apici.",
			"INSERT INTO aggiunge una riga nuova."),
		SqlTask.make(
			"Inserisci anche: id 2, nome 'Monitor', prezzo 180.",
			"INSERT INTO prodotti VALUES (2, 'Monitor', 180)",
			SqlTask.KIND_MUTATE,
			"Se ometti l'elenco delle colonne, i valori devono seguire l'ordine della tabella.",
			"Due righe in tabella: la struttura si riempie di dati."),
		SqlTask.make(
			"È arrivato un nuovo cliente: id 6, nome 'Ivo Fontana', citta 'Torino', eta 51. Aggiungilo.",
			"INSERT INTO clienti VALUES (6, 'Ivo Fontana', 'Torino', 51)",
			SqlTask.KIND_MUTATE,
			"Guarda l'ordine delle colonne di clienti nella tabella a sinistra.",
			"Cliente aggiunto: l'anagrafica è di nuovo completa."),
	]

	await do_tasks(tasks)
	await complete("Tabelle e righe ricostruite: CREATE TABLE e INSERT INTO.")
