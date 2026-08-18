class_name Progressi
extends RefCounted

## Progressi e punteggi del giocatore, salvati fra una partita e l'altra.
##
## Stanno in `user://`, che è l'unica cartella scrivibile anche nel gioco
## esportato: dentro il pacchetto non si può scrivere nulla.
##
## Che cosa si tiene, per ogni livello:
##   - se è mai stato completato, e quante volte;
##   - il MIGLIOR tempo rimasto sul cronometro (più alto = meglio: significa
##     averlo finito più in fretta e con meno penalità);
##   - il miglior punteggio, cioè quante prove sono state superate;
##   - quanti tentativi in tutto.

const PERCORSO := "user://progressi.cfg"

## Nome mostrato nel menu, per livello.
const NOMI := {
	1: "Binary Search Tree",
	2: "Database MySQL",
	3: "Calcolabilità",
	4: "Metodologie di programmazione",
}

static var _config: ConfigFile = null


static func _apri() -> ConfigFile:
	if _config != null:
		return _config
	_config = ConfigFile.new()
	# Se il file non esiste ancora, resta semplicemente vuoto: la prima
	# partita di sempre non è un errore.
	_config.load(PERCORSO)
	return _config


static func _sezione(livello: int) -> String:
	return "livello_%d" % livello


## Da chiamare alla fine di una partita, sia vinta sia persa.
static func registra(livello: int, completato: bool, tempo_rimasto: float, punteggio: int) -> void:
	var config: ConfigFile = _apri()
	var sezione: String = _sezione(livello)

	config.set_value(sezione, "tentativi", tentativi(livello) + 1)

	if completato:
		config.set_value(sezione, "completato", true)
		config.set_value(sezione, "completamenti", completamenti(livello) + 1)
		# Il tempo rimasto più alto è la prova migliore.
		if tempo_rimasto > miglior_tempo(livello):
			config.set_value(sezione, "miglior_tempo", tempo_rimasto)

	if punteggio > miglior_punteggio(livello):
		config.set_value(sezione, "miglior_punteggio", punteggio)

	config.save(PERCORSO)


static func completato(livello: int) -> bool:
	return bool(_apri().get_value(_sezione(livello), "completato", false))


static func miglior_tempo(livello: int) -> float:
	return float(_apri().get_value(_sezione(livello), "miglior_tempo", 0.0))


static func miglior_punteggio(livello: int) -> int:
	return int(_apri().get_value(_sezione(livello), "miglior_punteggio", 0))


static func tentativi(livello: int) -> int:
	return int(_apri().get_value(_sezione(livello), "tentativi", 0))


static func completamenti(livello: int) -> int:
	return int(_apri().get_value(_sezione(livello), "completamenti", 0))


## Quanti livelli sono stati completati almeno una volta.
static func livelli_completati() -> int:
	var totale: int = 0
	for livello in NOMI.keys():
		if completato(int(livello)):
			totale += 1
	return totale


static func totale_livelli() -> int:
	return NOMI.size()


## Riga di riepilogo mostrata sotto al nome del livello, nel menu.
static func riepilogo(livello: int) -> String:
	if tentativi(livello) == 0:
		return "mai giocato"
	if not completato(livello):
		return "non ancora completato  ·  %d tentativ%s" % [
			tentativi(livello), "o" if tentativi(livello) == 1 else "i"]
	return "completato  ·  record %s sul cronometro  ·  %d prove" % [
		formatta_tempo(miglior_tempo(livello)), miglior_punteggio(livello)]


static func formatta_tempo(secondi: float) -> String:
	var totale: int = int(ceil(maxf(secondi, 0.0)))
	@warning_ignore("integer_division")
	return "%02d:%02d" % [totale / 60, totale % 60]


## Cancella tutto e riparte da zero.
static func azzera() -> void:
	_config = ConfigFile.new()
	_config.save(PERCORSO)


## Ricarica dal disco: serve ai test, che scrivono il file da fuori.
static func ricarica() -> void:
	_config = null
