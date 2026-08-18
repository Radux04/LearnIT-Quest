extends Control

## Harness di verifica: istanzia il livello e lo gioca automaticamente
## sempre in modo corretto, per validare l'intero flusso delle 4 fasi
## (inserimenti, ricerca positiva E negativa, visite, min/max/successore,
## cancellazione). Non fa parte del gioco: serve solo ai test.

## Impostato a 1.0 per catturare screenshot leggibili, alzalo per test rapidi.
const TIME_SCALE := 4.0

## Da questa fase in poi il tempo torna normale, così gli screenshot delle
## ultime fasi sono leggibili anche partendo da una corsa accelerata.
const SLOW_DOWN_AT_PHASE := 5

## 0 = gioca tutto. N = arrivato alla fase N smette di giocare e resta lì, a
## velocità normale: serve per guardare (e fotografare) quella fase.
const STOP_AT_PHASE := 0

## Router su cui simulare il passaggio del mouse, per fotografare
## l'evidenziazione dei collegamenti. NAN = nessuno.
const HOVER_ROUTER_VALUE := NAN

var level: LevelController = null
var _phase_seen: int = 0
var _last_action_time: float = 0.0


func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	var packed: PackedScene = load(GameManager.SCENE_LEVEL)
	level = packed.instantiate()
	add_child(level)
	print("[AUTOPLAY] livello istanziato")
	set_process(true)


func _current_phase() -> Lvl1PhaseBase:
	for child in level.get_children():
		if child is Lvl1PhaseBase:
			return child
	return null


func _process(_delta: float) -> void:
	if level == null or not is_instance_valid(level):
		return

	if level.is_over:
		if _phase_seen != 99:
			_phase_seen = 99
			print("[AUTOPLAY] FINE — titolo: %s" % level.end_title.text)
			print("[AUTOPLAY] tempo rimasto: %s" % GameManager.formatted_time())
			print("[AUTOPLAY] nodi finali (%d): %s" % [level.model.size(), str(level.model.inorder())])
			Engine.time_scale = 1.0
		return

	var phase: Lvl1PhaseBase = _current_phase()
	if phase == null:
		return

	if level.current_phase != _phase_seen:
		_phase_seen = level.current_phase
		print("[AUTOPLAY] --> fase %d avviata" % _phase_seen)
	if level.current_phase >= SLOW_DOWN_AT_PHASE and not is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = 1.0

	# Arrivati alla fase da osservare, il bot si ferma e lascia la scena com'è.
	if STOP_AT_PHASE > 0 and level.current_phase >= STOP_AT_PHASE:
		Engine.time_scale = 1.0
		_simulate_hover()
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_action_time < 0.10:
		return
	_last_action_time = now

	if _try_place_router(phase):
		return
	if _try_pick(phase):
		return
	if _try_route(phase):
		return
	if _try_dijkstra(phase):
		return
	_try_scan(phase)


## Simula il passaggio del mouse su un router (il clic sintetico dei test non
## genera l'evento di hover). Serve solo per fotografare l'evidenziazione.
func _simulate_hover() -> void:
	if is_nan(HOVER_ROUTER_VALUE) or level.network == null:
		return
	var router: RouterNode = level.network.get_router(HOVER_ROUTER_VALUE)
	if router != null:
		level.network._on_router_hovered(router, true)


func _try_place_router(phase: Lvl1PhaseBase) -> bool:
	var tray: Dictionary = phase.get("_tray_routers")
	if tray == null or tray.is_empty():
		return false
	for value in tray.keys():
		var router: RouterNode = tray[value]
		if not is_instance_valid(router):
			continue
		var slot: Dictionary = level.model.insertion_slot(float(value))
		if slot.is_empty():
			continue
		var target: Vector2 = level.network.slot_center(float(slot["parent"]), String(slot["side"]))
		phase._on_router_dropped(router, level.network.global_position + target)
		print("[AUTOPLAY] router %s -> %s di %s" % [
			BSTModel.fmt(float(value)), slot["side"], BSTModel.fmt(float(slot["parent"]))])
		return true
	return false


func _try_pick(phase: Lvl1PhaseBase) -> bool:
	if not phase.get("_pick_active"):
		return false
	var target: float = float(phase.get("_pick_target"))
	if is_nan(target):
		return false
	var router: RouterNode = level.network.get_router(target)
	if router == null:
		return false
	phase._on_pick_click(router)
	print("[AUTOPLAY] selezionato router %s" % BSTModel.fmt(target))
	return true


func _try_route(phase: Lvl1PhaseBase) -> bool:
	if not phase.get("_accepting_direction"):
		return false
	var direction: String = phase.expected_direction()
	if direction == "":
		return false
	phase._on_direction_pressed(direction)
	print("[AUTOPLAY] router %s -> %s (cerca %s)" % [
		BSTModel.fmt(phase.current_router), direction, BSTModel.fmt(phase.current_target)])
	return true


## Esegue il ciclo di Dijkstra: fissa il router non fissato a distanza minima.
func _try_dijkstra(phase: Lvl1PhaseBase) -> bool:
	if not phase.get("_dij_active"):
		return false
	var dist: Dictionary = phase.get("_dij_dist")
	var settled: Array = phase.get("_dij_settled")
	var best: float = NAN
	var best_dist: float = NetworkGraph.INF
	for value in dist.keys():
		if settled.has(float(value)):
			continue
		if float(dist[value]) < best_dist:
			best_dist = float(dist[value])
			best = float(value)
	if is_nan(best):
		return false
	var router: RouterNode = level.network.get_router(best)
	if router == null:
		return false
	phase._on_dijkstra_click(router)
	print("[AUTOPLAY] Dijkstra: fissato %s a costo %d" % [BSTModel.fmt(best), int(best_dist)])
	return true


func _try_scan(phase: Lvl1PhaseBase) -> bool:
	if not phase.get("_scan_active"):
		return false
	var expected: Array = phase.get("_expected")
	var index: int = int(phase.get("_scan_index"))
	if index >= expected.size():
		return false
	var router: RouterNode = level.network.get_router(float(expected[index]))
	if router == null:
		return false
	phase._on_scan_click(router)
	return true
