extends Node

## Batteria di test dei modelli del Livello 3: automi, macchine di Turing e
## interprete WHILE. Non fa parte del gioco.

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	run_all()


func run_all() -> void:
	_passed = 0
	_failed = 0
	test_dfa_run()
	test_dfa_reject()
	test_nfa_accepts()
	test_epsilon_closure()
	test_move()
	test_subset_construction()
	test_turing_successor()
	test_turing_halt_limit()
	test_while_basic()
	test_while_monus()
	test_while_loop()
	test_while_if()
	test_while_nontermination()
	test_while_errors()
	test_while_task_equivalence()
	test_while_task_wrong()
	print("\n[LVL3-TEST] %d passati, %d falliti" % [_passed, _failed])


# ------------------------------------------------------------- helpers -----

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: %s" % label)


func _equal(got: Variant, want: Variant, label: String) -> void:
	if str(got) == str(want):
		_passed += 1
	else:
		_failed += 1
		print("  FAIL: %s  (ottenuto %s, atteso %s)" % [label, str(got), str(want)])


## DFA che accetta le parole su {a,b} con un numero PARI di 'a'.
func _even_a_dfa() -> Automaton:
	var dfa: Automaton = Automaton.make(["q0", "q1"], ["a", "b"], "q0", ["q0"])
	dfa.add_transition("q0", "a", "q1")
	dfa.add_transition("q0", "b", "q0")
	dfa.add_transition("q1", "a", "q0")
	dfa.add_transition("q1", "b", "q1")
	return dfa


## NFA che accetta le parole che FINISCONO per "ab".
func _ends_ab_nfa() -> Automaton:
	var nfa: Automaton = Automaton.make(["q0", "q1", "q2"], ["a", "b"], "q0", ["q2"])
	nfa.add_transition("q0", "a", "q0")
	nfa.add_transition("q0", "b", "q0")
	nfa.add_transition("q0", "a", "q1")
	nfa.add_transition("q1", "b", "q2")
	return nfa


# --------------------------------------------------------------- automi ----

func test_dfa_run() -> void:
	var dfa: Automaton = _even_a_dfa()
	_check(dfa.is_deterministic(), "il DFA è deterministico")
	_equal(dfa.run_dfa("aab"), ["q0", "q1", "q0", "q0"], "traccia di 'aab'")
	_check(dfa.accepts("aab"), "'aab' ha due 'a': accettata")
	_check(dfa.accepts(""), "la parola vuota ha zero 'a': accettata")
	_equal(dfa.step_dfa("q0", "a"), "q1", "transizione q0 -a-> q1")


func test_dfa_reject() -> void:
	var dfa: Automaton = _even_a_dfa()
	_check(not dfa.accepts("ab"), "'ab' ha una sola 'a': rifiutata")
	_check(not dfa.accepts("ababa"), "'ababa' ha tre 'a': rifiutata")
	_check(dfa.accepts("abababa"), "'abababa' ha quattro 'a': accettata")
	_equal(dfa.step_dfa("q0", "z"), "", "simbolo fuori alfabeto: nessuna transizione")


func test_nfa_accepts() -> void:
	var nfa: Automaton = _ends_ab_nfa()
	_check(not nfa.is_deterministic(), "l'NFA non è deterministico")
	_check(nfa.accepts("ab"), "'ab' finisce per ab")
	_check(nfa.accepts("bbaab"), "'bbaab' finisce per ab")
	_check(not nfa.accepts("aba"), "'aba' non finisce per ab")
	_check(not nfa.accepts(""), "parola vuota non accettata")


func test_epsilon_closure() -> void:
	var nfa: Automaton = Automaton.make(["q0", "q1", "q2"], ["a"], "q0", ["q2"])
	nfa.add_transition("q0", Automaton.EPSILON, "q1")
	nfa.add_transition("q1", Automaton.EPSILON, "q2")
	nfa.add_transition("q2", "a", "q2")
	_equal(nfa.epsilon_closure(["q0"]), ["q0", "q1", "q2"], "ε-chiusura transitiva")
	_check(nfa.accepts(""), "la parola vuota arriva a q2 via ε")
	_check(nfa.has_epsilon(), "l'automa ha transizioni ε")


func test_move() -> void:
	var nfa: Automaton = _ends_ab_nfa()
	_equal(nfa.move(["q0"], "a"), ["q0", "q1"], "da {q0} con 'a' si va in {q0,q1}")
	_equal(nfa.move(["q0"], "b"), ["q0"], "da {q0} con 'b' si resta in {q0}")
	_equal(nfa.move(["q0", "q1"], "b"), ["q0", "q2"], "da {q0,q1} con 'b' si va in {q0,q2}")
	_equal(nfa.move(["q2"], "a"), [], "da {q2} con 'a' non si va da nessuna parte")


func test_subset_construction() -> void:
	var nfa: Automaton = _ends_ab_nfa()
	var dfa: Dictionary = nfa.subset_construction()
	_equal(Automaton.set_label(dfa["start"]), "{q0}", "stato iniziale del DFA")
	_equal(dfa["labels"].size(), 3, "la costruzione produce 3 stati raggiungibili")
	_equal(dfa["transitions"]["{q0}|a"], "{q0,q1}", "{q0} -a-> {q0,q1}")
	_equal(dfa["transitions"]["{q0,q1}|b"], "{q0,q2}", "{q0,q1} -b-> {q0,q2}")
	_equal(dfa["accepting"], ["{q0,q2}"], "accetta solo l'insieme che contiene q2")


# ---------------------------------------------------- macchine di Turing ----

## Macchina che aggiunge 1 a un numero in unario: scorre a destra e scrive '1'.
func _successor_tm() -> TuringMachine:
	var tm: TuringMachine = TuringMachine.new()
	tm.start_state = "q0"
	tm.accept_state = "qf"
	tm.set_rule("q0", "1", "1", TuringMachine.RIGHT, "q0")
	tm.set_rule("q0", TuringMachine.BLANK, "1", TuringMachine.STAY, "qf")
	return tm


func test_turing_successor() -> void:
	var tm: TuringMachine = _successor_tm()
	tm.load_input("111")
	var result: Dictionary = tm.run(100)
	_check(bool(result["halted"]), "la macchina si ferma")
	_check(bool(result["accepted"]), "termina nello stato finale")
	_equal(String(result["tape"]), "1111", "3 + 1 = 4 in unario")
	_equal(int(result["steps"]), 4, "quattro passi")


func test_turing_halt_limit() -> void:
	# Macchina che non si ferma mai: va a destra per sempre.
	var tm: TuringMachine = TuringMachine.new()
	tm.start_state = "q0"
	tm.set_rule("q0", "1", "1", TuringMachine.RIGHT, "q0")
	tm.set_rule("q0", TuringMachine.BLANK, TuringMachine.BLANK, TuringMachine.RIGHT, "q0")
	tm.load_input("1")
	var result: Dictionary = tm.run(50)
	_check(not bool(result["halted"]), "dopo 50 passi non si è ancora fermata")
	_equal(int(result["steps"]), 50, "il limite di passi ha fermato la simulazione")

	var successor: TuringMachine = _successor_tm()
	successor.load_input("1")
	_check(not successor.is_halted(), "all'inizio c'è una regola applicabile")
	_equal(String(successor.current_rule()["next"]), "q0", "la regola porta in q0")


# ------------------------------------------------------ linguaggio WHILE ----

func test_while_basic() -> void:
	var result: Dictionary = WhileInterpreter.run("x := 2 + 3 * 4", {})
	_check(bool(result["ok"]), "il programma è valido")
	_equal(int(result["state"]["x"]), 14, "la moltiplicazione ha la precedenza")

	var parens: Dictionary = WhileInterpreter.run("x := (2 + 3) * 4", {})
	_equal(int(parens["state"]["x"]), 20, "le parentesi cambiano la precedenza")

	var seq: Dictionary = WhileInterpreter.run("x := 1; y := x + 1; z := y + 1", {})
	_equal(int(seq["state"]["z"]), 3, "sequenza di assegnamenti")

	var unset: Dictionary = WhileInterpreter.run("y := x + 1", {})
	_equal(int(unset["state"]["y"]), 1, "una variabile mai assegnata vale 0")


func test_while_monus() -> void:
	var result: Dictionary = WhileInterpreter.run("x := 3 - 5", {})
	_equal(int(result["state"]["x"]), 0, "la sottrazione è troncata ai naturali")
	var normal: Dictionary = WhileInterpreter.run("x := 9 - 4", {})
	_equal(int(normal["state"]["x"]), 5, "sottrazione normale")


func test_while_loop() -> void:
	# Somma: z := x + y usando solo incrementi e decrementi.
	var source: String = "z := x; while y != 0 do z := z + 1; y := y - 1 end"
	var result: Dictionary = WhileInterpreter.run(source, {"x": 4, "y": 3})
	_check(bool(result["terminated"]), "il ciclo termina")
	_equal(int(result["state"]["z"]), 7, "4 + 3 = 7")

	# 'od' è accettato come chiusura alternativa di 'end'.
	var od: Dictionary = WhileInterpreter.run("while x != 0 do x := x - 1 od", {"x": 5})
	_equal(int(od["state"]["x"]), 0, "'od' chiude il while")

	# Una condizione senza confronto significa "diverso da zero".
	var bare: Dictionary = WhileInterpreter.run("while x do x := x - 1 end", {"x": 3})
	_equal(int(bare["state"]["x"]), 0, "condizione nuda = diverso da zero")


func test_while_if() -> void:
	var source: String = "if x < y then m := x else m := y end"
	var first: Dictionary = WhileInterpreter.run(source, {"x": 2, "y": 9})
	_equal(int(first["state"]["m"]), 2, "il minimo è x")
	var second: Dictionary = WhileInterpreter.run(source, {"x": 9, "y": 2})
	_equal(int(second["state"]["m"]), 2, "il minimo è y")

	var no_else: Dictionary = WhileInterpreter.run("if x = 0 then y := 1 end", {"x": 0})
	_equal(int(no_else["state"]["y"]), 1, "l'else è facoltativo")


func test_while_nontermination() -> void:
	var result: Dictionary = WhileInterpreter.run("while 1 = 1 do x := x + 1 end", {}, 500)
	_check(bool(result["ok"]), "il programma è sintatticamente valido")
	_check(not bool(result["terminated"]), "ma non termina: funzione parziale")

	var terminating: Dictionary = WhileInterpreter.run("x := 1", {}, 500)
	_check(bool(terminating["terminated"]), "questo invece termina")


func test_while_errors() -> void:
	var missing_assign: Dictionary = WhileInterpreter.run("x = 1", {})
	_check(not bool(missing_assign["ok"]), "'=' non assegna")
	_check(String(missing_assign["error"]).contains(":="), "l'errore suggerisce ':='")

	var unclosed: Dictionary = WhileInterpreter.run("while x != 0 do x := x - 1", {})
	_check(not bool(unclosed["ok"]), "while non chiuso")
	_check(String(unclosed["error"]).contains("end"), "l'errore nomina 'end'")

	var empty: Dictionary = WhileInterpreter.run("", {})
	_check(not bool(empty["ok"]), "programma vuoto rifiutato")

	var bad_char: Dictionary = WhileInterpreter.run("x := 1 @ 2", {})
	_check(not bool(bad_char["ok"]), "carattere non riconosciuto")

	var colon: Dictionary = WhileInterpreter.run("x : 1", {})
	_check(String(colon["error"]).contains(":="), "':' da solo spiega ':='")


func test_while_task_equivalence() -> void:
	var task: WhileTask = WhileTask.make(
		"Metti in z la somma di x e y.",
		"z := x; while y != 0 do z := z + 1; y := y - 1 end",
		[{"x": 0, "y": 0}, {"x": 3, "y": 4}, {"x": 7, "y": 1}],
		["z"])

	# Formulazione diversa dalla soluzione ma con lo stesso effetto: va accettata.
	var different: Dictionary = WhileTask.check(task, "z := y; while x != 0 do z := z + 1; x := x - 1 end")
	_equal(String(different["status"]), "ok", "un algoritmo diverso ma corretto è accettato")

	# La soluzione stessa deve ovviamente passare.
	var same: Dictionary = WhileTask.check(task, task.solution)
	_equal(String(same["status"]), "ok", "la soluzione di riferimento passa")

	# Una scorciatoia corretta è comunque corretta.
	var shortcut: Dictionary = WhileTask.check(task, "z := x + y")
	_equal(String(shortcut["status"]), "ok", "z := x + y è accettato")


func test_while_task_wrong() -> void:
	var task: WhileTask = WhileTask.make(
		"Metti in z la somma di x e y.",
		"z := x + y",
		[{"x": 0, "y": 0}, {"x": 3, "y": 4}],
		["z"])

	var wrong: Dictionary = WhileTask.check(task, "z := x")
	_equal(String(wrong["status"]), "wrong", "z := x non calcola la somma")
	_check(String(wrong["message"]).contains("z"), "il messaggio nomina la variabile sbagliata")

	var broken: Dictionary = WhileTask.check(task, "z := ")
	_equal(String(broken["status"]), "error", "programma non compilabile")

	var looping: Dictionary = WhileTask.check(task, "while 1 = 1 do z := 0 end")
	_equal(String(looping["status"]), "wrong", "un programma che cicla non risolve")
	_check(String(looping["message"]).contains("PARZIALE"), "il messaggio parla di funzione parziale")
