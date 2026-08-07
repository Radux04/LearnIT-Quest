class_name Lvl3Pools
extends RefCounted

## CATALOGO DEGLI ESERCIZI DEL LIVELLO 3.
##
## Ogni fase pesca a caso dal proprio elenco a ogni partita, senza ripetizioni
## dentro la stessa partita. Per aggiungere un esercizio si aggiunge una voce
## qui: non serve toccare il codice delle fasi.
##
## Gli esercizi sono DATI, non codice: automi e macchine sono descritti da
## dizionari e costruiti dai metodi build_* in fondo al file. I test in
## tests/test_lvl3.gd controllano che ogni voce del catalogo sia ben formata e
## risolvibile, quindi se ne aggiungi una sbagliata te lo dicono subito.

# Direzioni della testina (equivalgono a TuringMachine.LEFT/RIGHT/STAY).
const L := -1
const R := 1
const S := 0


# ============================================================ FASE 1: DFA ===
#
# Automi DETERMINISTICI e COMPLETI: da ogni stato, per ogni simbolo
# dell'alfabeto, deve esistere esattamente una transizione. Massimo 5 stati,
# altrimenti non ci stanno in fila sullo schermo.

const DFA_POOL: Array = [
	{
		"name": "numero pari di 1",
		"states": ["q0", "q1"], "alphabet": ["0", "1"],
		"start": "q0", "accepting": ["q0"],
		"transitions": [
			["q0", "0", "q0"], ["q0", "1", "q1"],
			["q1", "0", "q1"], ["q1", "1", "q0"],
		],
		"words": ["1011", "110", "0110", "101"],
		"hint": "Accetta le parole con un numero PARI di 1. Lo stato finale è q0.",
	},
	{
		"name": "contiene ab",
		"states": ["s0", "s1", "s2"], "alphabet": ["a", "b"],
		"start": "s0", "accepting": ["s2"],
		"transitions": [
			["s0", "a", "s1"], ["s0", "b", "s0"],
			["s1", "a", "s1"], ["s1", "b", "s2"],
			["s2", "a", "s2"], ["s2", "b", "s2"],
		],
		"words": ["baab", "bba", "aab", "bab"],
		"hint": "Accetta le parole che contengono 'ab'. s2 è una trappola: una volta dentro non si esce.",
	},
	{
		"name": "finisce per 0",
		"states": ["t0", "t1"], "alphabet": ["0", "1"],
		"start": "t0", "accepting": ["t1"],
		"transitions": [
			["t0", "0", "t1"], ["t0", "1", "t0"],
			["t1", "0", "t1"], ["t1", "1", "t0"],
		],
		"words": ["1010", "1101", "010", "011"],
		"hint": "Accetta le parole che finiscono per 0. Conta solo l'ULTIMO simbolo letto.",
	},
	{
		"name": "multipli di 3 in binario",
		"states": ["m0", "m1", "m2"], "alphabet": ["0", "1"],
		"start": "m0", "accepting": ["m0"],
		"transitions": [
			["m0", "0", "m0"], ["m0", "1", "m1"],
			["m1", "0", "m2"], ["m1", "1", "m0"],
			["m2", "0", "m1"], ["m2", "1", "m2"],
		],
		"words": ["110", "1001", "101", "1100"],
		"hint": "Lo stato è il RESTO della divisione per 3. Leggere un bit b porta da r a (2r+b) mod 3.",
	},
	{
		"name": "numero dispari di a",
		"states": ["d0", "d1"], "alphabet": ["a", "b"],
		"start": "d0", "accepting": ["d1"],
		"transitions": [
			["d0", "a", "d1"], ["d0", "b", "d0"],
			["d1", "a", "d0"], ["d1", "b", "d1"],
		],
		"words": ["abba", "baaab", "ab", "bbab"],
		"hint": "Accetta le parole con un numero DISPARI di 'a'. Le 'b' non cambiano stato.",
	},
	{
		"name": "non contiene due 1 di fila",
		"states": ["n0", "n1", "n2"], "alphabet": ["0", "1"],
		"start": "n0", "accepting": ["n0", "n1"],
		"transitions": [
			["n0", "0", "n0"], ["n0", "1", "n1"],
			["n1", "0", "n0"], ["n1", "1", "n2"],
			["n2", "0", "n2"], ["n2", "1", "n2"],
		],
		"words": ["0101", "0110", "1010", "1101"],
		"hint": "n2 è lo stato «pozzo»: ci si finisce al primo '11' e non se ne esce più.",
	},
]


# ================================================ FASE 2: NFA e sottoinsiemi =
#
# Ogni voce porta con sé i passi della costruzione per sottoinsiemi che il
# giocatore dovrà rifare: [insieme_di_partenza, simbolo].
# "epsilon": true segnala che l'automa ha ε-transizioni (serve la ε-chiusura).

const NFA_POOL: Array = [
	{
		"name": "finisce per ab",
		"epsilon": false,
		"states": ["q0", "q1", "q2"], "alphabet": ["a", "b"],
		"start": "q0", "accepting": ["q2"],
		"transitions": [
			["q0", "a", "q0"], ["q0", "b", "q0"],
			["q0", "a", "q1"], ["q1", "b", "q2"],
		],
		"steps": [
			[["q0"], "a", "Da q0 con 'a' l'automa può fare DUE cose: restare o avanzare. Selezionale entrambe."],
			[["q0", "q1"], "b", "Considera ogni stato dell'insieme, uno per uno, e unisci i risultati."],
			[["q0", "q2"], "a", "q2 non ha frecce uscenti con 'a': non contribuisce nulla."],
		],
	},
	{
		"name": "contiene aa",
		"epsilon": false,
		"states": ["p0", "p1", "p2"], "alphabet": ["a", "b"],
		"start": "p0", "accepting": ["p2"],
		"transitions": [
			["p0", "a", "p0"], ["p0", "b", "p0"],
			["p0", "a", "p1"], ["p1", "a", "p2"],
			["p2", "a", "p2"], ["p2", "b", "p2"],
		],
		"steps": [
			[["p0"], "a", "L'automa indovina quando comincia la coppia 'aa': tieni aperte tutte le ipotesi."],
			[["p0", "p1"], "a", "Da p1 con 'a' si chiude la coppia. Ma p0 continua a valere."],
			[["p0", "p1"], "b", "La 'b' rompe la coppia: l'ipotesi p1 muore."],
		],
	},
	{
		"name": "il penultimo simbolo è a",
		"epsilon": false,
		"states": ["r0", "r1", "r2"], "alphabet": ["a", "b"],
		"start": "r0", "accepting": ["r2"],
		"transitions": [
			["r0", "a", "r0"], ["r0", "b", "r0"],
			["r0", "a", "r1"], ["r1", "a", "r2"], ["r1", "b", "r2"],
		],
		"steps": [
			[["r0"], "a", "r0 scommette che la parola non sia ancora finita, r1 che manchi un solo simbolo."],
			[["r0", "r1"], "b", "Da r1 qualsiasi simbolo porta in r2: è l'ultimo passo."],
			[["r0", "r1"], "a", "Qui contribuiscono entrambi gli stati: unisci i risultati."],
		],
	},
	{
		"name": "ε-transizioni in cascata",
		"epsilon": true,
		"states": ["e0", "e1", "e2"], "alphabet": ["a", "b"],
		"start": "e0", "accepting": ["e2"],
		"transitions": [
			["e0", "ε", "e1"],
			["e0", "a", "e0"], ["e1", "b", "e2"], ["e2", "a", "e2"],
		],
		"steps": [
			[["e0", "e1"], "a", "Dopo la mossa aggiungi sempre la ε-chiusura: da e0 si scivola in e1 senza leggere nulla."],
		],
	},
	{
		"name": "ε verso due rami",
		"epsilon": true,
		"states": ["f0", "f1", "f2"], "alphabet": ["a", "b"],
		"start": "f0", "accepting": ["f2"],
		"transitions": [
			["f0", "ε", "f1"], ["f1", "ε", "f2"],
			["f0", "a", "f0"], ["f2", "b", "f1"],
		],
		"steps": [
			[["f0", "f1", "f2"], "a", "La ε-chiusura è transitiva: da f0 si arriva a f2 passando per f1."],
		],
	},
]


# ============================================== FASE 3: macchine di Turing ===
#
# TM_POOL: macchine da ESEGUIRE passo per passo. Devono fermarsi.
# "rules": [stato, letto, scritto, direzione, nuovo_stato]  ·  □ = blank.

const BLANK := "□"

const TM_POOL: Array = [
	{
		"name": "inverte i bit",
		"start": "q0", "accept": "qf", "input": "101",
		"rules": [
			["q0", "0", "1", R, "q0"],
			["q0", "1", "0", R, "q0"],
			["q0", "□", "□", S, "qf"],
		],
		"result": "ogni bit invertito",
		"hint": "La regola da applicare dipende SOLO da due cose: lo stato corrente e il simbolo sotto la testina.",
	},
	{
		"name": "cancella gli 1",
		"start": "q0", "accept": "qf", "input": "1101",
		"rules": [
			["q0", "1", "□", R, "q0"],
			["q0", "0", "0", R, "q0"],
			["q0", "□", "□", S, "qf"],
		],
		"result": "restano solo gli 0",
		"hint": "Scrivere il blank □ significa cancellare la cella. Gli 0 vengono riscritti identici.",
	},
	{
		"name": "sostituisce a con b",
		"start": "q0", "accept": "qf", "input": "abba",
		"rules": [
			["q0", "a", "b", R, "q0"],
			["q0", "b", "b", R, "q0"],
			["q0", "□", "□", S, "qf"],
		],
		"result": "tutte b",
		"hint": "Due regole diverse portano allo stesso stato: cambia solo il simbolo scritto.",
	},
	{
		"name": "incrementa un numero binario",
		"start": "q0", "accept": "qf", "input": "1011",
		"rules": [
			["q0", "0", "0", R, "q0"],
			["q0", "1", "1", R, "q0"],
			["q0", "□", "□", L, "q1"],
			["q1", "1", "0", L, "q1"],
			["q1", "0", "1", S, "qf"],
			["q1", "□", "1", S, "qf"],
		],
		"result": "1011 + 1 = 1100 in binario",
		"hint": "Due fasi: q0 corre in fondo al numero, q1 torna indietro propagando il riporto.",
	},
]

## DESIGN_POOL: macchine a cui MANCA una regola. Il giocatore sceglie fra tre
## candidate; "correct": true su una sola.
const DESIGN_POOL: Array = [
	{
		"name": "successore in unario",
		"start": "q0", "accept": "qf", "input": "111",
		"rules": [["q0", "1", "1", R, "q0"]],
		"goal": "Questa macchina deve calcolare il SUCCESSORE in unario: 111 → 1111. Manca una regola.",
		"hint": "Quando la testina esce dal numero legge un blank □. Che cosa deve fare in quel momento?",
		"missing": ["q0", "□", "1", S, "qf"],
		"options": [
			{"text": "δ(q0, □) = (1, •, qf)", "correct": true,
				"why": "scrive il simbolo mancante e si ferma: 111 diventa 1111."},
			{"text": "δ(q0, □) = (□, →, q0)", "correct": false,
				"why": "non scrive nulla e continua a destra: la macchina non si fermerebbe mai."},
			{"text": "δ(q0, □) = (1, ←, q0)", "correct": false,
				"why": "scrive l'1 ma poi torna indietro e rilegge un 1, ripartendo a destra: ciclo infinito."},
		],
	},
	{
		"name": "cancella tutto",
		"start": "q0", "accept": "qf", "input": "111",
		"rules": [["q0", "1", "□", R, "q0"]],
		"goal": "Questa macchina deve SVUOTARE il nastro. Cancella gli 1, ma non sa quando fermarsi.",
		"hint": "Dopo l'ultimo 1 la testina legge un blank □: il lavoro è finito.",
		"missing": ["q0", "□", "□", S, "qf"],
		"options": [
			{"text": "δ(q0, □) = (□, •, qf)", "correct": true,
				"why": "riconosce la fine dell'input e si ferma senza toccare altro."},
			{"text": "δ(q0, □) = (□, →, q0)", "correct": false,
				"why": "scorre all'infinito su celle già vuote: non si ferma mai."},
			{"text": "δ(q0, □) = (1, •, qf)", "correct": false,
				"why": "si ferma, ma prima scrive un 1: il nastro non resta vuoto."},
		],
	},
]


# ================================================= FASE 5: programmi WHILE ===
#
# Regola d'oro nello scegliere un esercizio: NON deve essere risolvibile con un
# solo operatore del linguaggio, altrimenti il ciclo non serve e l'esercizio non
# insegna nulla. "cases" deve contenere i casi limite (zero, valori uguali...).

const WHILE_POOL: Array = [
	{
		"prompt": "Metti in m il più grande fra x e y.",
		"solution": "if x < y then m := y else m := x end",
		"cases": [{"x": 3, "y": 8}, {"x": 9, "y": 2}, {"x": 5, "y": 5}, {"x": 0, "y": 0}],
		"outputs": ["m"],
		"hint": "if <condizione> then ... else ... end   ·   i confronti sono =, !=, <, <=, >, >=",
		"explain": "Il costrutto if sceglie fra due strade: nessun ciclo, quindi termina sempre.",
	},
	{
		"prompt": "Metti in m il più piccolo fra x e y.",
		"solution": "if x < y then m := x else m := y end",
		"cases": [{"x": 3, "y": 8}, {"x": 9, "y": 2}, {"x": 4, "y": 4}, {"x": 0, "y": 7}],
		"outputs": ["m"],
		"hint": "Come il massimo, ma con i rami scambiati.",
		"explain": "Stesso schema del massimo: cambiare il ramo cambia la funzione calcolata.",
	},
	{
		"prompt": "Metti in s la somma di tutti i numeri da 1 a n (con n = 0 la somma è 0).",
		"solution": "s := 0; i := n; while i != 0 do s := s + i; i := i - 1 end",
		"cases": [{"n": 0}, {"n": 1}, {"n": 5}, {"n": 10}],
		"outputs": ["s"],
		"hint": "Serve un ciclo: while <condizione> do ... end. Usa una variabile che scende fino a 0.",
		"explain": "Il ciclo termina perché il contatore cala di 1 a ogni giro: è una funzione TOTALE.",
	},
	{
		"prompt": "Metti in q il quoziente intero di x diviso y, e in r il resto. Puoi assumere y > 0.",
		"solution": "q := 0; r := x; while r >= y do r := r - y; q := q + 1 end",
		"cases": [{"x": 0, "y": 3}, {"x": 7, "y": 2}, {"x": 12, "y": 4}, {"x": 5, "y": 9}],
		"outputs": ["q", "r"],
		"hint": "La divisione non esiste nel linguaggio: sottrai y finché puoi e conta quante volte.",
		"explain": "Hai costruito un operatore che il linguaggio non ha: è così che si estende la calcolabilità.",
	},
	{
		"prompt": "Metti in f il fattoriale di n (0! vale 1).",
		"solution": "f := 1; i := n; while i != 0 do f := f * i; i := i - 1 end",
		"cases": [{"n": 0}, {"n": 1}, {"n": 4}, {"n": 6}],
		"outputs": ["f"],
		"hint": "Parti da f := 1 e moltiplica per i valori che scendono da n a 1.",
		"explain": "Con assegnamento, sequenza e while si calcola tutto il calcolabile: è la tesi di Church-Turing.",
	},
	{
		"prompt": "Metti in p il valore di b elevato alla e (con e = 0 il risultato è 1).",
		"solution": "p := 1; i := e; while i != 0 do p := p * b; i := i - 1 end",
		"cases": [{"b": 2, "e": 0}, {"b": 2, "e": 5}, {"b": 3, "e": 3}, {"b": 7, "e": 1}],
		"outputs": ["p"],
		"hint": "La potenza è una moltiplicazione ripetuta, come il prodotto è una somma ripetuta.",
		"explain": "Ogni operazione nasce iterando quella precedente: è l'idea della ricorsione primitiva.",
	},
	{
		"prompt": "Metti in e il valore 1 se x è uguale a y, altrimenti 0.",
		"solution": "if x = y then e := 1 else e := 0 end",
		"cases": [{"x": 4, "y": 4}, {"x": 0, "y": 0}, {"x": 3, "y": 9}, {"x": 9, "y": 3}],
		"outputs": ["e"],
		"hint": "Il risultato è un numero, non un valore di verità: 1 sta per vero, 0 per falso.",
		"explain": "Codificare vero/falso come 1/0 è il modo in cui i predicati diventano funzioni calcolabili.",
	},
	{
		"prompt": "Metti in p il valore 1 se x è pari, altrimenti 0.",
		"solution": "r := x; while r >= 2 do r := r - 2 end; p := 1 - r",
		"cases": [{"x": 0}, {"x": 1}, {"x": 8}, {"x": 7}],
		"outputs": ["p"],
		"hint": "Togli 2 finché puoi: quello che resta (0 o 1) ti dice tutto. Ricorda che 1 - 1 fa 0.",
		"explain": "La sottrazione troncata permette di calcolare un predicato senza costrutti aggiuntivi.",
	},
	{
		"prompt": "Metti in g il massimo comun divisore di x e y. Puoi assumere x > 0 e y > 0.",
		"solution": "while x != y do if x > y then x := x - y else y := y - x end end; g := x",
		"cases": [{"x": 12, "y": 18}, {"x": 7, "y": 7}, {"x": 9, "y": 3}, {"x": 5, "y": 8}],
		"outputs": ["g"],
		"hint": "Algoritmo di Euclide per sottrazioni: togli il più piccolo dal più grande finché non sono uguali.",
		"explain": "Il ciclo termina perché a ogni giro la somma x+y cala: è la dimostrazione di terminazione.",
	},
	{
		"prompt": "Metti in c quante volte y sta dentro x, fermandoti prima di superarlo. Assumi y > 0.",
		"solution": "c := 0; t := x; while t >= y do t := t - y; c := c + 1 end",
		"cases": [{"x": 10, "y": 3}, {"x": 0, "y": 5}, {"x": 8, "y": 8}, {"x": 4, "y": 9}],
		"outputs": ["c"],
		"hint": "È il quoziente, ma senza tenere il resto: conta le sottrazioni riuscite.",
		"explain": "Contare le iterazioni di un ciclo è il modo più semplice di definire una funzione nuova.",
	},
]


# ================================================================ builders ===

static func build_automaton(entry: Dictionary) -> Automaton:
	var automaton: Automaton = Automaton.make(
		entry["states"], entry["alphabet"], String(entry["start"]), entry["accepting"])
	for transition in entry["transitions"]:
		automaton.add_transition(String(transition[0]), String(transition[1]), String(transition[2]))
	return automaton


static func build_machine(entry: Dictionary) -> TuringMachine:
	var machine: TuringMachine = TuringMachine.new()
	machine.start_state = String(entry["start"])
	machine.accept_state = String(entry.get("accept", ""))
	for rule in entry["rules"]:
		machine.set_rule(String(rule[0]), String(rule[1]), String(rule[2]),
			int(rule[3]), String(rule[4]))
	machine.load_input(String(entry["input"]))
	return machine


static func build_task(entry: Dictionary) -> WhileTask:
	return WhileTask.make(
		String(entry["prompt"]), String(entry["solution"]),
		entry["cases"], entry["outputs"],
		String(entry.get("hint", "")), String(entry.get("explain", "")))


# ================================================================ sorteggio ==

## `count` voci diverse pescate a caso. Se il catalogo è più piccolo, le
## restituisce tutte (mescolate): il gioco resta giocabile comunque.
static func pick(pool: Array, count: int) -> Array:
	var bag: Array = pool.duplicate()
	bag.shuffle()
	return bag.slice(0, mini(count, bag.size()))


static func pick_one(pool: Array) -> Dictionary:
	return pool[randi() % pool.size()]


## Voci filtrate per campo booleano, poi mescolate (serve per ε sì / ε no).
static func pick_where(pool: Array, key: String, value: bool, count: int) -> Array:
	var filtered: Array = []
	for entry in pool:
		if bool(entry.get(key, false)) == value:
			filtered.append(entry)
	return pick(filtered, count)
