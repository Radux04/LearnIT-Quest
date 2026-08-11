extends SceneTree

## Avvia la batteria di test dell'analizzatore Java in un processo headless:
##   godot --headless --script res://tests/run_lvl4_tests.gd


func _initialize() -> void:
	var script: GDScript = load("res://tests/test_lvl4.gd")
	if script == null:
		print("[LVL4-TEST] impossibile caricare i test")
		quit(1)
		return
	var runner: Node = Node.new()
	runner.set_script(script)
	root.add_child(runner)
	quit(0)
