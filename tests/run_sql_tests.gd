extends SceneTree

## Avvia la batteria di test del motore SQL in un processo headless:
##   godot --headless --script res://tests/run_sql_tests.gd


func _initialize() -> void:
	var script: GDScript = load("res://tests/test_sql_engine.gd")
	if script == null:
		print("[SQL-TEST] impossibile caricare i test")
		quit(1)
		return
	var runner: Node = Node.new()
	runner.set_script(script)
	root.add_child(runner)
	quit(0)
