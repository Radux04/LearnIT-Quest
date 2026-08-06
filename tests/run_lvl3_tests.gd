extends SceneTree

## Avvia la batteria di test dei modelli del Livello 3 in un processo headless:
##   godot --headless --script res://tests/run_lvl3_tests.gd


func _initialize() -> void:
	var script: GDScript = load("res://tests/test_lvl3.gd")
	if script == null:
		print("[LVL3-TEST] impossibile caricare i test")
		quit(1)
		return
	var runner: Node = Node.new()
	runner.set_script(script)
	root.add_child(runner)
	quit(0)
