extends Lvl3PhaseBase

## FASE 4 — Problemi senza soluzione.
##
## Il giocatore costruisce con le proprie mani la macchina diagonale D: per ogni
## input sceglie il comportamento OPPOSTO a quello della macchina sulla
## diagonale. Alla fine si accorge che D non può stare nell'elenco, e l'elenco
## conteneva tutte le macchine: è la dimostrazione dell'indecidibilità
## del problema dell'arresto.

const SIZE := 4

var _table: DiagonalTable = null
var _diagonal: Array[bool] = []
var _built: Array[bool] = []
var _filling: bool = false
var _row_target: int = -1
var _picking_row: bool = false


func _start() -> void:
	level.set_phase_header("FASE 4 — IL PROBLEMA DELL'ARRESTO", Color(1.0, 0.5, 0.45))

	_table = DiagonalTable.new()
	_table.cell_clicked.connect(_on_cell_clicked)
	level.mount(_table)

	_build_table()
	await _fill_diagonal_row()
	if _is_over():
		return
	await _find_difference()
	if _is_over():
		return
	await _conclusion()
	if _is_over():
		return

	await complete("Nessun programma può decidere se un programma si ferma: il problema dell'arresto è indecidibile.")


func _build_table() -> void:
	var rows: Array[String] = []
	var columns: Array[String] = []
	for i in range(SIZE):
		rows.append("M%d" % (i + 1))
		columns.append("w%d" % (i + 1))
	rows.append("D")

	var values: Array = []
	_diagonal.clear()
	for r in range(SIZE):
		var row: Array = []
		for c in range(SIZE):
			row.append(randi() % 2 == 0)
		values.append(row)
	for i in range(SIZE):
		_diagonal.append(bool(values[i][i]))

	# L'ultima riga è D: parte tutta a "non si ferma" e la riempie il giocatore.
	var d_row: Array = []
	_built.clear()
	for c in range(SIZE):
		d_row.append(false)
		_built.append(false)
	values.append(d_row)

	_table.setup(rows, columns, values)
	_table.mark_diagonal(Color(1.0, 0.82, 0.35))


## Passo 1: riempire la riga D invertendo la diagonale.
func _fill_diagonal_row() -> void:
	level.set_objective("Costruisci D: su ogni input w si comporta al CONTRARIO della macchina sulla diagonale.")
	level.set_hint("Le celle dorate sono la diagonale. Clicca le celle della riga D per farle passare da NO a SI.")
	_table.set_clickable(true)
	_filling = true

	var confirm: Button = level.make_action_button("CONFERMA LA RIGA D",
		Vector2(level.size.x * 0.5, level.size.y - 150.0), Vector2(300.0, 54.0))
	confirm.pressed.connect(_on_confirm_row)

	await helper_done
	_filling = false
	_table.set_clickable(false)
	level.clear_action_bar()


func _on_cell_clicked(row: int, column: int) -> void:
	if _is_over():
		return
	if _picking_row:
		_handle_difference_click(row, column)
		return
	if not _filling:
		return
	if row != SIZE:
		level.toast("Le righe M1..M4 sono date: puoi cambiare solo la riga D.", COLOR_INFO)
		return
	Sfx.play("click")
	_built[column] = not _built[column]
	_table.set_value(row, column, _built[column])


func _on_confirm_row() -> void:
	if not _filling or _is_over():
		return
	var wrong_column: int = -1
	for i in range(SIZE):
		if _built[i] == _diagonal[i]:
			wrong_column = i
			break

	if wrong_column == -1:
		_filling = false
		Sfx.play("correct")
		_score()
		for i in range(SIZE):
			_table.mark(SIZE, i, Color(0.35, 1.0, 0.6))
		level.toast("D è costruita: su ogni w si comporta al contrario della macchina corrispondente.", COLOR_OK)
		helper_done.emit()
		return

	Sfx.play("error")
	level.penalty(PENALTY_CHOICE)
	var machine_halts: bool = _diagonal[wrong_column]
	level.toast("Colonna w%d: M%d %s, quindi D deve %s. Ora invece fa la stessa cosa." % [
		wrong_column + 1, wrong_column + 1,
		"si ferma" if machine_halts else "non si ferma",
		"NON fermarsi" if machine_halts else "fermarsi"], COLOR_BAD)
	_table.mark(wrong_column, wrong_column, Color(1.0, 0.4, 0.42))


## Passo 2: verificare di aver capito che D differisce da OGNI macchina.
func _find_difference() -> void:
	var target: int = randi() % SIZE
	_row_target = target
	_picking_row = true
	level.set_objective("D è diversa da ogni macchina dell'elenco. Su quale input differisce da M%d?" % (target + 1))
	level.set_hint("Ogni macchina è stata «sabotata» in una sola colonna: quella dove la diagonale la incrocia.")
	_table.set_clickable(true)

	await helper_done
	_picking_row = false
	_table.set_clickable(false)


## Passo 3: la conclusione, mostrata invece che raccontata.
func _conclusion() -> void:
	level.clear_action_bar()
	level.set_objective("D è una macchina come le altre: allora deve essere una delle M dell'elenco. Ma quale?")
	level.set_hint("Se D fosse Mk, nella colonna wk dovrebbe comportarsi come sé stessa e al contrario di sé stessa.")
	Sfx.play("alarm")
	await _wait(1.0)
	if _is_over():
		return
	for i in range(SIZE):
		_table.mark(i, i, Color(1.0, 0.4, 0.42))
		await _wait(0.25)
		if _is_over():
			return
	level.toast("Contraddizione: D non è in nessuna riga, ma l'elenco conteneva TUTTE le macchine.", COLOR_WARN)
	await _wait(2.6)
	if _is_over():
		return
	level.toast("L'errore era supporre che esistesse H, il programma che decide l'arresto. H non esiste.", COLOR_WARN)
	await _wait(2.6)


## Gestione dei clic durante il passo 2 (scelta della cella che distingue).
func _handle_difference_click(row: int, column: int) -> void:
	if _is_over():
		return
	if column == _row_target and row == _row_target:
		_picking_row = false
		Sfx.play("correct")
		_score()
		_table.mark(row, column, Color(0.35, 1.0, 0.6))
		level.toast("Esatto: sulla colonna w%d, D fa il contrario di M%d per costruzione." % [
			column + 1, _row_target + 1], COLOR_OK)
		helper_done.emit()
	else:
		Sfx.play("error")
		level.penalty(PENALTY_STEP)
		level.toast("Non lì: cerca la cella dove la diagonale incrocia M%d." % (_row_target + 1), COLOR_BAD)
