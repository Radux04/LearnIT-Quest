extends SqlPhaseBase

## FASE 1 — Interrogazione: leggere i dati con SELECT.
## Si parte dal caso più semplice e si arriva a WHERE composti,
## ordinamento e funzioni di aggregazione.


func _start() -> void:
	level.set_phase_header("FASE 1 — INTERROGAZIONE (SELECT)", Color(0.4, 0.85, 1.0))

	var tasks: Array = [
		SqlTask.make(
			"Mostra tutto il contenuto della tabella clienti.",
			"SELECT * FROM clienti",
			SqlTask.KIND_SELECT,
			"SELECT * FROM tabella;   ·   l'asterisco significa «tutte le colonne».",
			"SELECT * legge ogni colonna di ogni riga."),
		SqlTask.make(
			"Mostra solo nome e citta dei clienti che abitano a Roma.",
			"SELECT nome, citta FROM clienti WHERE citta = 'Roma'",
			SqlTask.KIND_SELECT,
			"Elenca le colonne dopo SELECT e filtra con WHERE. Il testo va fra apici singoli: 'Roma'.",
			"WHERE filtra le righe, l'elenco dopo SELECT sceglie le colonne."),
		SqlTask.make(
			"Mostra nome ed eta dei clienti con più di 30 anni, dal più vecchio al più giovane.",
			"SELECT nome, eta FROM clienti WHERE eta > 30 ORDER BY eta DESC",
			SqlTask.KIND_SELECT,
			"Confronto con > e ordinamento con ORDER BY colonna DESC.",
			"ORDER BY ... DESC ordina dal valore più grande al più piccolo."),
		SqlTask.make(
			"Conta quanti clienti abitano a Milano.",
			"SELECT COUNT(*) FROM clienti WHERE citta = 'Milano'",
			SqlTask.KIND_SELECT,
			"COUNT(*) conta le righe che superano il filtro WHERE.",
			"COUNT(*) restituisce un unico numero: quante righe corrispondono."),
	]

	await do_tasks(tasks)
	await complete("Sai interrogare il database: SELECT, WHERE, ORDER BY e COUNT.")
