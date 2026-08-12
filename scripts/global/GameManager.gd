extends Node

## Global game state: level timer, penalties and scene routing.

signal time_updated(time_left: float, ratio: float)
signal time_expired
signal penalty_applied(seconds: float)

const LEVEL_DURATION := 300.0          # 5 minuti — Livello 1
const LEVEL2_DURATION := 600.0         # 10 minuti — Livello 2 (si scrive, non si clicca)
const LEVEL3_DURATION := 720.0         # 12 minuti — Livello 3 (teoria: serve pensare)
const LEVEL4_DURATION := 960.0         # 16 minuti — Livello 4 (si scrive codice: serve tempo)
const WRONG_ANSWER_PENALTY := 10.0

const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_INTRO := "res://scenes/introduction.tscn"
const SCENE_LEVEL := "res://scenes/level.tscn"
const SCENE_INTRO_2 := "res://scenes/introduction2.tscn"
const SCENE_LEVEL_2 := "res://scenes/level2.tscn"
const SCENE_INTRO_3 := "res://scenes/introduction3.tscn"
const SCENE_LEVEL_3 := "res://scenes/level3.tscn"
const SCENE_INTRO_4 := "res://scenes/introduction4.tscn"
const SCENE_LEVEL_4 := "res://scenes/level4.tscn"

var time_left: float = LEVEL_DURATION
var level_duration: float = LEVEL_DURATION
var timer_running: bool = false
var level_failed: bool = false
var level_completed: bool = false


func _process(delta: float) -> void:
	if not timer_running:
		return
	time_left = maxf(time_left - delta, 0.0)
	time_updated.emit(time_left, time_left / level_duration)
	if time_left <= 0.0:
		timer_running = false
		level_failed = true
		time_expired.emit()


func start_level(duration: float = LEVEL_DURATION) -> void:
	level_duration = duration
	time_left = duration
	timer_running = true
	level_failed = false
	level_completed = false
	time_updated.emit(time_left, 1.0)


func stop_timer() -> void:
	timer_running = false


## Riprende il conteggio dopo una pausa, solo se la partita è ancora in corso.
func resume_timer() -> void:
	if not level_failed and not level_completed and time_left > 0.0:
		timer_running = true


func complete_level() -> void:
	timer_running = false
	level_completed = true


## Applies a time penalty. Returns true if it caused the timer to expire.
func apply_penalty(seconds: float = WRONG_ANSWER_PENALTY) -> bool:
	if not timer_running:
		return false
	time_left = maxf(time_left - seconds, 0.0)
	penalty_applied.emit(seconds)
	time_updated.emit(time_left, time_left / level_duration)
	if time_left <= 0.0:
		timer_running = false
		level_failed = true
		time_expired.emit()
		return true
	return false


## Quanta parte del livello è già trascorsa, da 0 a 1.
func elapsed_ratio() -> float:
	if level_duration <= 0.0:
		return 1.0
	return clampf((level_duration - time_left) / level_duration, 0.0, 1.0)


## Secondi che mancano perché sia trascorsa la frazione indicata del livello.
## Zero se quel momento è già passato.
func time_until_ratio(ratio: float) -> float:
	return maxf(time_left - (1.0 - ratio) * level_duration, 0.0)


func formatted_time() -> String:
	var total: int = int(ceil(time_left))
	@warning_ignore("integer_division")
	var minutes: int = total / 60
	return "%02d:%02d" % [minutes, total % 60]


# ------------------------------------------------------------- navigation ---

func restart_game() -> void:
	stop_timer()
	get_tree().change_scene_to_file(SCENE_INTRO)


func go_to_menu() -> void:
	stop_timer()
	get_tree().change_scene_to_file(SCENE_MENU)


func go_to_level() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL)


func go_to_intro_2() -> void:
	stop_timer()
	get_tree().change_scene_to_file(SCENE_INTRO_2)


func go_to_level_2() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_2)


func go_to_intro_3() -> void:
	stop_timer()
	get_tree().change_scene_to_file(SCENE_INTRO_3)


func go_to_level_3() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_3)


func go_to_intro_4() -> void:
	stop_timer()
	get_tree().change_scene_to_file(SCENE_INTRO_4)


func go_to_level_4() -> void:
	get_tree().change_scene_to_file(SCENE_LEVEL_4)
