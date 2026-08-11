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
		# Esercizio 1.6 del libro di esercizi del corso.
		"name": "raddoppia un numero binario",
		"start": "q0", "accept": "", "input": "101",
		"rules": [
			["q0", "0", "0", R, "q0"],
			["q0", "1", "1", R, "q1"],
			["q1", "0", "0", R, "q1"],
			["q1", "1", "1", R, "q1"],
			["q1", "□", "0", R, "q0"],
		],
		"result": "101 (cinque) è diventato 1010 (dieci)",
		"hint": "Raddoppiare in binario vuol dire aggiungere uno 0 in fondo. q0 serve a non toccare lo zero.",
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


# ================================================= FASE 4: programmi WHILE ===
#
# Le soluzioni sono scritte nella NOTAZIONE ACCADEMICA del corso, la stessa del
# libro di esercizi: blocchi begin ... end, INPUT/OUTPUT a dichiarare ingressi e
# uscite, variabili in maiuscolo. Il giocatore può rispondere anche nella forma
# compatta, perché la correzione confronta l'effetto e non il testo.
#
# Regola d'oro nello scegliere un esercizio: NON deve essere risolvibile con un
# solo operatore del linguaggio, altrimenti il ciclo non serve e l'esercizio non
# insegna nulla. "cases" deve contenere i casi limite (zero, valori uguali...).

const WHILE_POOL: Array = [
	{
		# Esercizio 5.1 del libro.
		"prompt": "Divisione con resto: dividendo A, divisore B. Metti il quoziente in Q e il resto in R (B > 0).",
		"solution": """begin
INPUT(A);
INPUT(B);
Q := 0;
while A >= B do
	 begin
	 A := A - B;
	 Q := Q + 1
	 end
R := A;
OUTPUT(Q);
OUTPUT(R)
end""",
		"cases": [{"A": 17, "B": 5}, {"A": 0, "B": 3}, {"A": 12, "B": 4}, {"A": 3, "B": 9}],
		"outputs": ["Q", "R"],
		"hint": "Togli B da A finché ci sta, contando quante volte: quello che resta è il resto.",
		"explain": "È l'esercizio 5.1 del corso: la divisione non è primitiva, si costruisce con un ciclo.",
	},
	{
		# Esercizio 5.2 del libro.
		"prompt": "Moltiplicazione fra naturali: metti in Z il prodotto di X per Y.",
		"solution": """begin
INPUT(X);
INPUT(Y);
Z := 0;
while Y > 0 do
	 begin
	 Z := Z + X;
	 Y := Y - 1
	 end
OUTPUT(Z)
end""",
		"cases": [{"X": 6, "Y": 7}, {"X": 6, "Y": 0}, {"X": 0, "Y": 4}, {"X": 9, "Y": 1}],
		"outputs": ["Z"],
		"hint": "Il prodotto è una somma ripetuta: somma X per Y volte.",
		"explain": "È l'esercizio 5.2 del corso: ogni operazione nasce iterando quella precedente.",
	},
	{
		# Esercizio 5.5 del libro.
		"prompt": "Metti in M il valore 1 se X è multiplo di Y, altrimenti 0. Puoi assumere Y > 0.",
		"solution": """begin
INPUT(X);
INPUT(Y);
while X >= Y do
	 begin X := X - Y end
if X != 0 then
	 begin M := 0 end
else
	 begin M := 1 end
OUTPUT(M)
end""",
		"cases": [{"X": 12, "Y": 4}, {"X": 13, "Y": 4}, {"X": 0, "Y": 5}, {"X": 7, "Y": 7}],
		"outputs": ["M"],
		"hint": "Senza usare la divisione: sottrai Y finché puoi e guarda che cosa resta.",
		"explain": "È l'esercizio 5.5 del corso: il resto zero è la definizione stessa di multiplo.",
	},
	{
		"prompt": "Copia il valore di Y dentro Z usando SOLO il successore s() e il predecessore pd().",
		"solution": """begin
INPUT(Y);
Z := 0;
while Y > 0 do
	 begin
	 Z := s(Z);
	 Y := pd(Y)
	 end
OUTPUT(Z)
end""",
		"cases": [{"Y": 0}, {"Y": 1}, {"Y": 5}, {"Y": 12}],
		"outputs": ["Z"],
		"hint": "s(X) vale X+1, pd(X) vale X-1 (e pd(0) resta 0). Sono le uniche operazioni del nucleo minimo.",
		"explain": "Il nucleo del linguaggio WHILE ha solo := 0, s() e pd(): tutto il resto sono macro-istruzioni.",
	},
	{
		"prompt": "Metti in M il più grande fra X e Y.",
		"solution": """begin
INPUT(X);
INPUT(Y);
if X < Y then
	 begin M := Y end
else
	 begin M := X end
OUTPUT(M)
end""",
		"cases": [{"X": 3, "Y": 8}, {"X": 9, "Y": 2}, {"X": 5, "Y": 5}, {"X": 0, "Y": 0}],
		"outputs": ["M"],
		"hint": "if <condizione> then begin ... end else begin ... end   ·   confronti: =, !=, <, <=, >, >=",
		"explain": "Il costrutto if sceglie fra due strade: nessun ciclo, quindi termina sempre.",
	},
	{
		"prompt": "Metti in S la somma di tutti i numeri da 1 a N (con N = 0 la somma è 0).",
		"solution": """begin
INPUT(N);
S := 0;
while N > 0 do
	 begin
	 S := S + N;
	 N := N - 1
	 end
OUTPUT(S)
end""",
		"cases": [{"N": 0}, {"N": 1}, {"N": 5}, {"N": 10}],
		"outputs": ["S"],
		"hint": "Serve un ciclo: while <condizione> do begin ... end. Usa una variabile che scende fino a 0.",
		"explain": "Il ciclo termina perché il contatore cala di 1 a ogni giro: è una funzione TOTALE.",
	},
	{
		"prompt": "Metti in F il fattoriale di N (0! vale 1).",
		"solution": """begin
INPUT(N);
F := 1;
while N > 0 do
	 begin
	 F := F * N;
	 N := N - 1
	 end
OUTPUT(F)
end""",
		"cases": [{"N": 0}, {"N": 1}, {"N": 4}, {"N": 6}],
		"outputs": ["F"],
		"hint": "Parti da F := 1 e moltiplica per i valori che scendono da N a 1.",
		"explain": "Con assegnamento, sequenza e while si calcola tutto il calcolabile: è la tesi di Church-Turing.",
	},
	{
		"prompt": "Metti in P il valore di B elevato alla E (con E = 0 il risultato è 1).",
		"solution": """begin
INPUT(B);
INPUT(E);
P := 1;
while E > 0 do
	 begin
	 P := P * B;
	 E := E - 1
	 end
OUTPUT(P)
end""",
		"cases": [{"B": 2, "E": 0}, {"B": 2, "E": 5}, {"B": 3, "E": 3}, {"B": 7, "E": 1}],
		"outputs": ["P"],
		"hint": "La potenza è una moltiplicazione ripetuta, come il prodotto è una somma ripetuta.",
		"explain": "Ogni operazione nasce iterando quella precedente: è l'idea della ricorsione primitiva.",
	},
	{
		"prompt": "Metti in P il valore 1 se X è pari, altrimenti 0.",
		"solution": """begin
INPUT(X);
while X >= 2 do
	 begin X := X - 2 end
P := 1 - X;
OUTPUT(P)
end""",
		"cases": [{"X": 0}, {"X": 1}, {"X": 8}, {"X": 7}],
		"outputs": ["P"],
		"hint": "Togli 2 finché puoi: quello che resta (0 o 1) ti dice tutto. Ricorda che 1 - 1 fa 0.",
		"explain": "La sottrazione troncata permette di calcolare un predicato senza costrutti aggiuntivi.",
	},
	{
		"prompt": "Metti in G il massimo comun divisore di X e Y. Puoi assumere X > 0 e Y > 0.",
		"solution": """begin
INPUT(X);
INPUT(Y);
while X != Y do
	 begin
	 if X > Y then
		  begin X := X - Y end
	 else
		  begin Y := Y - X end
	 end
G := X;
OUTPUT(G)
end""",
		"cases": [{"X": 12, "Y": 18}, {"X": 7, "Y": 7}, {"X": 9, "Y": 3}, {"X": 5, "Y": 8}],
		"outputs": ["G"],
		"hint": "Algoritmo di Euclide per sottrazioni: togli il più piccolo dal più grande finché non sono uguali.",
		"explain": "Il ciclo termina perché a ogni giro la somma X+Y cala: è la dimostrazione di terminazione.",
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
