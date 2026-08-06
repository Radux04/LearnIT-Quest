extends SqlPhaseBase

## FASE 5 — Query nidificate: una SELECT dentro un'altra SELECT.
## Sono i casi in cui il valore da confrontare non è noto in anticipo
## e va calcolato dal database stesso.


func _start() -> void:
	level.set_phase_header("FASE 5 — QUERY NIDIFICATE (SUBQUERY)", Color(0.75, 0.65, 1.0))

	var tasks: Array = [
		SqlTask.make(
			"Mostra il nome dei clienti che hanno almeno un ordine.",
			"SELECT nome FROM clienti WHERE id IN (SELECT cliente_id FROM ordini)",
			SqlTask.KIND_SELECT,
			"La subquery interna restituisce un elenco di id: usalo con IN (...).",
			"La subquery produce l'elenco dei cliente_id, IN tiene chi vi compare."),
		SqlTask.make(
			"Ora il contrario: mostra il nome dei clienti che non hanno nessun ordine.",
			"SELECT nome FROM clienti WHERE id NOT IN (SELECT cliente_id FROM ordini)",
			SqlTask.KIND_SELECT,
			"Basta negare l'appartenenza all'elenco: NOT IN (...).",
			"NOT IN restituisce il complemento: chi non appare nella subquery."),
		SqlTask.make(
			"Mostra nome ed eta dei clienti più vecchi della media di tutti i clienti.",
			"SELECT nome, eta FROM clienti WHERE eta > (SELECT AVG(eta) FROM clienti)",
			SqlTask.KIND_SELECT,
			"La media non la sai in anticipo: fatti calcolare (SELECT AVG(eta) FROM clienti) dal database.",
			"Subquery scalare: restituisce un solo valore, usabile in un confronto."),
		SqlTask.make(
			"Mostra il nome dei clienti che hanno fatto almeno un ordine sopra i 100 euro.",
			"SELECT nome FROM clienti WHERE id IN (SELECT cliente_id FROM ordini WHERE totale > 100)",
			SqlTask.KIND_SELECT,
			"Anche la subquery può avere il suo WHERE.",
			"Filtri dentro filtri: la subquery seleziona gli ordini, quella esterna i clienti."),
	]

	await do_tasks(tasks)
	await complete("Query nidificate padroneggiate: database completamente ripristinato!")
