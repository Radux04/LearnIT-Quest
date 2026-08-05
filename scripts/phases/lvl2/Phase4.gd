extends SqlPhaseBase

## FASE 4 — Bonifica: eliminare righe e tabelle.
## Qui si impara la lezione più importante: DELETE senza WHERE svuota tutto.


func _start() -> void:
	level.set_phase_header("FASE 4 — BONIFICA (DELETE / DROP)", Color(1.0, 0.5, 0.45))
	level.toast("Attenzione: senza WHERE, DELETE cancella TUTTE le righe.", Color(1.0, 0.7, 0.35))

	var tasks: Array = [
		SqlTask.make(
			"L'ordine con id 2 era un duplicato: eliminalo.",
			"DELETE FROM ordini WHERE id = 2",
			SqlTask.KIND_MUTATE,
			"DELETE FROM tabella WHERE condizione;   ·   il WHERE qui è obbligatorio, o perdi tutto.",
			"Una riga eliminata, le altre intatte: merito del WHERE."),
		SqlTask.make(
			"Per policy aziendale vanno rimossi i clienti con meno di 25 anni.",
			"DELETE FROM clienti WHERE eta < 25",
			SqlTask.KIND_MUTATE,
			"La condizione può essere un confronto: eta < 25.",
			"DELETE può colpire più righe in una volta: la condizione decide quante."),
		SqlTask.make(
			"I prodotti sopra i 100 euro sono fuori catalogo: eliminali.",
			"DELETE FROM prodotti WHERE prezzo > 100",
			SqlTask.KIND_MUTATE,
			"Filtra sul prezzo con >.",
			"Il catalogo è ripulito."),
		SqlTask.make(
			"La tabella temp_backup è spazzatura lasciata dall'attacco: eliminala completamente.",
			"DROP TABLE temp_backup",
			SqlTask.KIND_MUTATE,
			"DELETE svuota una tabella, DROP TABLE la fa sparire con struttura e dati.",
			"DROP TABLE elimina la tabella stessa, non solo le sue righe."),
	]

	await do_tasks(tasks)
	await complete("Database bonificato: DELETE ... WHERE e DROP TABLE.")
