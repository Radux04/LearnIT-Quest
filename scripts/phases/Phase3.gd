extends PhaseBase

## FASE 3 — Scansione della rete.
## Tre visite estratte a caso fra Preorder, Inorder, Postorder e BFS.
## La regola viene mostrata solo nel primo round: dal secondo il giocatore
## deve ricordarsela da solo.

const ROUNDS := 3


func _start() -> void:
	level.set_phase_header("FASE 3 — SCANSIONE ANTIVIRUS", Color(0.75, 0.6, 1.0))

	var kinds: Array[String] = ["Preorder", "Inorder", "Postorder", "BFS"]
	kinds.shuffle()

	for i in range(mini(ROUNDS, kinds.size())):
		if _is_over():
			return
		var kind: String = kinds[i]
		var show_rule: bool = i == 0
		var subtitle: String = traversal_rule(kind) if show_rule else "Round %d/%d — questa volta senza aiuto." % [i + 1, ROUNDS]
		await level.show_banner("SCANSIONE %s" % kind.to_upper(), subtitle, Color(0.75, 0.6, 1.0))
		if _is_over():
			return
		await scan_network(kind, show_rule)

	if _is_over():
		return
	Sfx.play("victory")
	level.toast("Rete completamente scansionata: conosci tutte le visite!", COLOR_OK)
	await _wait(1.2)
	finished.emit()
