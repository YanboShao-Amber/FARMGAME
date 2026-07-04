extends StaticBody2D

# An apple that has fallen off a tree. It drops to the ground with a little
# bounce, then waits for the player to walk up and press the action key to
# pick it up (handled through the player's interact system).

var can_interact: bool = false


func fall_to(target_global: Vector2) -> void:
	var tween = create_tween()
	tween.set_parallel(true)

	# Horizontal drift towards the landing spot
	tween.tween_property(self, "global_position:x", target_global.x, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Vertical fall with a bounce when it hits the ground
	tween.tween_property(self, "global_position:y", target_global.y, 0.5) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func interact(_player: CharacterBody2D) -> void:
	if can_interact:
		Data.ITEMS_AMOUNT[Enum.Item.APPLE] += 1
		queue_free()
