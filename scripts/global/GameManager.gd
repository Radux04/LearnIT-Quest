extends Node

## Global game state: level timer, penalties and scene routing.

signal time_updated(time_left: float, ratio: float)
signal time_expired
signal penalty_applied(seconds: float)

const LEVEL_DURATION := 300.0          # 5 minuti — Livello 1
const LEVEL2_DURATION := 360.0         # 6 minuti — Livello 2 (si scrive, non si clicca)
const WRONG_ANSWER_PENALTY := 10.0

const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_INTRO := "res://scenes/introduction.tscn"
const SCENE_LEVEL := "res://scenes/level.tscn"
const SCENE_INTRO_2 := "res://scenes/introduction2.tscn"
const SCENE_LEVEL_2 := "res://scenes/level2.tscn"

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
