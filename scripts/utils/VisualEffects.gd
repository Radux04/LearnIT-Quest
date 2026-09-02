extends Node

class_name VisualEffects

static func play_correct_feedback(parent: Node, position: Vector2, duration: float = 0.5) -> void:
	var tween_helper: Node = Node.new()
	parent.add_child(tween_helper)
	
	var particle: Node2D = Node2D.new()
	particle.position = position
	parent.add_child(particle)
	
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://assets/generated/token_glow.png")
	sprite.centered = true
	sprite.scale = Vector2(0.5, 0.5)
	sprite.modulate = Color.GREEN
	particle.add_child(sprite)
	
	var tween: Tween = tween_helper.create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), duration)
	tween.parallel()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	await tween.finished
	particle.queue_free()
	tween_helper.queue_free()

static func play_error_feedback(parent: Node, position: Vector2, duration: float = 0.4) -> void:
	var tween_helper: Node = Node.new()
	parent.add_child(tween_helper)
	
	var particle: Node2D = Node2D.new()
	particle.position = position
	parent.add_child(particle)
	
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = load("res://assets/generated/error_flash.png")
	sprite.centered = true
	sprite.scale = Vector2(0.8, 0.8)
	sprite.modulate = Color.RED
	particle.add_child(sprite)
	
	var tween: Tween = tween_helper.create_tween()
	tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), duration)
	tween.parallel()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)
	await tween.finished
	particle.queue_free()
	tween_helper.queue_free()

static func shake_effect(node: Node, intensity: float = 10.0, duration: float = 0.3) -> void:
	var original_pos: Vector2 = node.position if node is Node2D else Vector2.ZERO
	var tween_helper: Node = Node.new()
	node.add_child(tween_helper)
	
	var tween: Tween = tween_helper.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	for _i in range(4):
		var offset: Vector2 = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(node, "position", original_pos + offset, duration / 4)
	
	tween.tween_property(node, "position", original_pos, 0.1)
	await tween.finished
	tween_helper.queue_free()

static func pulse_effect(node: Node, scale_factor: float = 1.2, duration: float = 0.3) -> void:
	var original_scale: Vector2 = node.scale
	var tween_helper: Node = Node.new()
	node.add_child(tween_helper)
	
	var tween: Tween = tween_helper.create_tween()
	tween.tween_property(node, "scale", original_scale * scale_factor, duration / 2)
	tween.tween_property(node, "scale", original_scale, duration / 2)
	await tween.finished
	tween_helper.queue_free()

static func flash_effect(node: Control, color: Color, duration: float = 0.3) -> void:
	var original_color: Color = node.modulate
	var tween_helper: Node = Node.new()
	node.add_child(tween_helper)
	
	var tween: Tween = tween_helper.create_tween()
	tween.tween_property(node, "modulate", color, duration / 2)
	tween.tween_property(node, "modulate", original_color, duration / 2)
	await tween.finished
	tween_helper.queue_free()
