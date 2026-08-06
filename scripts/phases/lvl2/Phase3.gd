extends SqlPhaseBase

## FASE 3 — Correzione: modificare i dati esistenti con UPDATE.


func _start() -> void:
	level.set_phase_header("FASE 3 — CORREZIONE (UPDATE)", Color(1.0, 0.82, 0.35))

	var tasks: Array = [
		SqlTask.make(
			"Anna Bianchi (id 2) si è trasferita a Bologna: aggiorna la sua citta.",
			"UPDATE clienti SET citta = 'Bologna' WHERE id = 2",
			SqlTask.KIND_MUTATE,
			"UPDATE tabella SET colonna = valore WHERE condizione;   ·   senza WHERE cambieresti tutte le righe!",
			"UPDATE con WHERE modifica solo le righe che interessano."),
		SqlTask.make(
			"Tutti i clienti di Roma hanno compiuto gli anni: aumenta di 1 la loro eta.",
			"UPDATE clienti SET eta = eta + 1 WHERE citta = 'Roma'",
			SqlTask.KIND_MUTATE,
			"Nel SET puoi usare il valore attuale della colonna: eta = eta + 1.",
			"Il SET può contenere un'espressione che parte dal valore attuale."),
		SqlTask.make(
			"L'ordine con id 3 era stato registrato male: il totale corretto è 250.",
			"UPDATE ordini SET totale = 250 WHERE id = 3",
			SqlTask.KIND_MUTATE,
			"Filtra sulla chiave: WHERE id = 3.",
			"Aggiornare per chiave primaria è il modo più sicuro."),
	]

	await do_tasks(tasks)
	await complete("Dati corretti: UPDATE ... SET ... WHERE.")
