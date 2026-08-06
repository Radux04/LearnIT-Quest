extends Control

## Harness di verifica del Livello 2: istanzia il livello e lo gioca da solo
## inviando alla console le soluzioni degli obiettivi.
## Verifica anche una query con errore, una query valida ma sbagliata e
## l'apertura del manuale, per controllare le penalità.

const TIME_SCALE := 3.0

## Prove volutamente sbagliate, inviate prima del primo obiettivo.
const BAD_SYNTAX := "SELECT FROM clienti"
const BAD_ANSWER := "SELECT * FROM ordini"

var level: Level2Controller = null
var _phase_seen: int = 0
var _last_action: float = 0.0
var _did_error_probe: bool = false
var _did_wrong_probe: bool = false
var _did_manual: bool = false
var _solved: int = 0


func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	var packed: PackedScene = load(GameManager.SCENE_LEVEL_2)
	level = packed.instantiate()
	add_child(level)
	print("[L2] livello istanziato")
	set_process(true)


func _process(_delta: float) -> void:
	if level == null or not is_instance_valid(level):
		return

	if level.is_over:
		if _phase_seen != 99:
			_phase_seen = 99
			print("[L2] FINE — %s" % level.end_title.text)
			print("[L2] obiettivi risolti: %d" % _solved)
			print("[L2] manuale aperto %d volte" % level.manual_openings)
			print("[L2] tempo rimasto: %s" % GameManager.formatted_time())
			print("[L2] tabelle finali: %s" % str(level.db.table_names()))
			for table in level.db.table_names():
				print("       %s -> %d righe" % [table, level.db.row_count(table)])
			Engine.time_scale = 1.0
		return

	if level.current_phase != _phase_seen:
		_phase_seen = level.current_phase
		print("[L2] --> fase %d" % _phase_seen)

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_action < 0.30:
		return

	var task: SqlTask = level.active_task
	if task == null:
		return
	_last_action = now

	# Prima di tutto: verifica le penalità e il manuale.
	if not _did_error_probe:
		_did_error_probe = true
		print("[L2] prova query con errore di sintassi")
		level.console.query_submitted.emit(BAD_SYNTAX)
		return
	if not _did_wrong_probe:
		_did_wrong_probe = true
		print("[L2] prova query valida ma non richiesta")
		level.console.query_submitted.emit(BAD_ANSWER)
		return
	if not _did_manual:
		_did_manual = true
		print("[L2] apertura manuale (costo 10 s)")
		level.manual_button.pressed.emit()
		level.manual.close()
		return

	level.console.query_submitted.emit(task.solution)
	_solved += 1
	print("[L2] fase %d — risolto: %s" % [level.current_phase, task.solution])
