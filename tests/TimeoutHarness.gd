extends Control

## Verifica la schermata "Tempo Scaduto": avvia il livello e porta
## il cronometro quasi a zero.

var level: LevelController = null


func _ready() -> void:
	var packed: PackedScene = load(GameManager.SCENE_LEVEL)
	level = packed.instantiate()
	add_child(level)
	await get_tree().create_timer(1.0).timeout
	GameManager.time_left = 1.0
	print("[TIMEOUT-TEST] cronometro forzato a 1 secondo")
	await get_tree().create_timer(2.0).timeout
	print("[TIMEOUT-TEST] is_over = %s" % str(level.is_over))
	print("[TIMEOUT-TEST] titolo = %s" % level.end_title.text)
	print("[TIMEOUT-TEST] end screen visibile = %s" % str(level.end_screen.visible))
