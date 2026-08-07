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
	test_pool_dfa()
	test_pool_nfa()
	test_pool_turing()
	test_pool_design()
	test_pool_while()
	test_pool_pick()
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


# ---------------------------------------------- validazione del catalogo ----
#
# Questi test controllano OGNI esercizio del pool: servono a chi aggiunge
# esercizi nuovi, perché segnalano subito una voce mal formata o irrisolvibile.

func test_pool_dfa() -> void:
	_check(Lvl3Pools.DFA_POOL.size() >= 2, "il catalogo dei DFA ha almeno 2 voci")
	for entry in Lvl3Pools.DFA_POOL:
		var label: String = String(entry["name"])
		var dfa: Automaton = Lvl3Pools.build_automaton(entry)

		_check(dfa.is_deterministic(), "[%s] è deterministico" % label)
		_check(dfa.states.size() <= 5, "[%s] non ha più di 5 stati (ci devono stare a schermo)" % label)
		_check(dfa.states.has(dfa.start_state), "[%s] lo stato iniziale esiste" % label)

		# Completo: da ogni stato, per ogni simbolo, esattamente una transizione.
		var complete: bool = true
		for state in dfa.states:
			for symbol in dfa.alphabet:
				if dfa.targets(state, symbol).size() != 1:
					complete = false
		_check(complete, "[%s] è completo: una transizione per ogni stato e simbolo" % label)

		for state in entry["accepting"]:
			_check(dfa.states.has(String(state)), "[%s] lo stato finale %s esiste" % [label, state])

		# Le parole devono usare solo simboli dell'alfabeto, e non essere vuote.
		_check(entry["words"].size() >= 2, "[%s] ha almeno 2 parole" % label)
		for word in entry["words"]:
			var text: String = String(word)
			_check(text.length() > 0, "[%s] la parola non è vuota" % label)
			var valid: bool = true
			for symbol in Automaton.symbols_of(text):
				if not dfa.alphabet.has(symbol):
					valid = false
			_check(valid, "[%s] la parola '%s' usa solo simboli dell'alfabeto" % [label, text])


func test_pool_nfa() -> void:
	var with_epsilon: int = 0
	var without_epsilon: int = 0
	for entry in Lvl3Pools.NFA_POOL:
		var label: String = String(entry["name"])
		var nfa: Automaton = Lvl3Pools.build_automaton(entry)

		if bool(entry["epsilon"]):
			with_epsilon += 1
			_check(nfa.has_epsilon(), "[%s] dichiara ε e ha davvero transizioni ε" % label)
		else:
			without_epsilon += 1
			_check(not nfa.has_epsilon(), "[%s] non dichiara ε e non ne ha" % label)

		_check(entry["steps"].size() >= 1, "[%s] ha almeno un passo" % label)
		for step in entry["steps"]:
			var source: Array = step[0]
			var symbol: String = String(step[1])
			for state in source:
				_check(nfa.states.has(String(state)),
					"[%s] lo stato %s del passo esiste" % [label, state])
			_check(nfa.alphabet.has(symbol),
				"[%s] il simbolo '%s' è nell'alfabeto" % [label, symbol])
			# Un passo che non porta da nessuna parte non insegna niente.
			_check(not nfa.move(source, symbol).is_empty(),
				"[%s] il passo %s con '%s' porta a un insieme non vuoto" % [
					label, Automaton.set_label(source), symbol])
			_check(String(step[2]).length() > 10, "[%s] il passo ha un suggerimento" % label)

	# La Fase 2 pesca un automa di ciascun tipo: servono entrambi.
	_check(with_epsilon >= 1, "il catalogo ha almeno un automa con ε")
	_check(without_epsilon >= 1, "il catalogo ha almeno un automa senza ε")


func test_pool_turing() -> void:
	for entry in Lvl3Pools.TM_POOL:
		var label: String = String(entry["name"])
		var machine: TuringMachine = Lvl3Pools.build_machine(entry)
		var result: Dictionary = machine.run(500)
		# Se una macchina del catalogo non si ferma, il giocatore resterebbe
		# a cliccare all'infinito: è l'errore più grave possibile qui.
		_check(bool(result["halted"]), "[%s] la macchina si ferma" % label)
		_check(int(result["steps"]) >= 2, "[%s] fa almeno due passi" % label)
		_check(int(result["steps"]) <= 40, "[%s] non è troppo lunga da eseguire a mano" % label)
		_check(String(entry["input"]).length() > 0, "[%s] ha un input" % label)


func test_pool_design() -> void:
	for entry in Lvl3Pools.DESIGN_POOL:
		var label: String = String(entry["name"])

		# Senza la regola mancante la macchina si deve bloccare: è il motivo
		# per cui esiste l'esercizio.
		var incomplete: TuringMachine = Lvl3Pools.build_machine(entry)
		var before: Dictionary = incomplete.run(200)
		_check(bool(before["halted"]), "[%s] senza la regola la macchina si blocca" % label)
		_check(String(incomplete.state) != String(entry["accept"]),
			"[%s] e si blocca PRIMA dello stato finale" % label)

		# Con la regola mancante deve arrivare in fondo.
		var fixed: TuringMachine = Lvl3Pools.build_machine(entry)
		var missing: Array = entry["missing"]
		fixed.set_rule(String(missing[0]), String(missing[1]), String(missing[2]),
			int(missing[3]), String(missing[4]))
		var after: Dictionary = fixed.run(500)
		_check(bool(after["halted"]), "[%s] con la regola la macchina termina" % label)
		_check(bool(after["accepted"]), "[%s] e termina nello stato finale" % label)

		# Esattamente una alternativa corretta, e tutte con la spiegazione.
		var correct: int = 0
		for option in entry["options"]:
			if bool(option["correct"]):
				correct += 1
			_check(String(option["why"]).length() > 10,
				"[%s] ogni alternativa spiega il perché" % label)
		_equal(correct, 1, "[%s] ha esattamente una alternativa corretta" % label)
		_check(entry["options"].size() >= 3, "[%s] ha almeno tre alternative" % label)


func test_pool_while() -> void:
	_check(Lvl3Pools.WHILE_POOL.size() >= 4, "il catalogo WHILE ha almeno 4 voci")
	for entry in Lvl3Pools.WHILE_POOL:
		var label: String = String(entry["prompt"]).substr(0, 40)
		var task: WhileTask = Lvl3Pools.build_task(entry)

		_check(task.cases.size() >= 3, "[%s] ha almeno 3 casi di prova" % label)
		_check(task.outputs.size() >= 1, "[%s] dichiara le variabili di uscita" % label)
		_check(task.hint.length() > 10, "[%s] ha un suggerimento" % label)
		_check(task.explain.length() > 10, "[%s] ha una spiegazione" % label)

		# La soluzione di riferimento deve compilare e terminare su OGNI caso.
		var parsed: Dictionary = WhileInterpreter.parse(task.solution)
		_check(bool(parsed["ok"]), "[%s] la soluzione compila" % label)
		for initial_state in task.cases:
			var run: Dictionary = WhileInterpreter.run(task.solution, initial_state)
			_check(bool(run["terminated"]), "[%s] la soluzione termina su ogni caso" % label)

		# La soluzione deve superare la propria correzione.
		var verdict: Dictionary = WhileTask.check(task, task.solution)
		_equal(String(verdict["status"]), "ok", "[%s] la soluzione supera la correzione" % label)

		# Un programma che non fa nulla NON deve passare: se passasse,
		# l'esercizio sarebbe banale (risultato atteso sempre zero).
		var lazy: Dictionary = WhileTask.check(task, "zzz := 0")
		_equal(String(lazy["status"]), "wrong", "[%s] un programma vuoto non passa" % label)


func test_pool_pick() -> void:
	var pool: Array = [{"a": 1}, {"a": 2}, {"a": 3}, {"a": 4}, {"a": 5}]
	var drawn: Array = Lvl3Pools.pick(pool, 3)
	_equal(drawn.size(), 3, "pick restituisce il numero richiesto")

	# Senza ripetizioni: tre voci pescate devono essere tre voci diverse.
	var seen: Array = []
	for entry in drawn:
		_check(not seen.has(entry["a"]), "pick non ripete la stessa voce")
		seen.append(entry["a"])

	# Se si chiede più di quanto c'è, restituisce tutto senza rompersi.
	_equal(Lvl3Pools.pick(pool, 99).size(), 5, "pick non supera la dimensione del catalogo")
	_equal(Lvl3Pools.pick([], 3).size(), 0, "pick su catalogo vuoto non esplode")

	# pick_where filtra davvero.
	var filtered: Array = Lvl3Pools.pick_where(Lvl3Pools.NFA_POOL, "epsilon", true, 5)
	for entry in filtered:
		_check(bool(entry["epsilon"]), "pick_where restituisce solo voci con ε")
