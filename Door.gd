extends StaticBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D

var _players_in_area: Dictionary = {}

func _ready() -> void:
	close_door()
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	call_deferred("_sync_initial_overlap")

func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		_players_in_area[body.get_instance_id()] = true
		_update_door()

func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		_players_in_area.erase(body.get_instance_id())
		_update_door()

func _sync_initial_overlap() -> void:
	_players_in_area.clear()
	for body in area_2d.get_overlapping_bodies():
		if _is_player(body):
			_players_in_area[body.get_instance_id()] = true
	_update_door()

func _update_door() -> void:
	if not _players_in_area.is_empty():
		open_door()
	else:
		close_door()

func open_door() -> void:
	animated_sprite.play("door_open")
	collision_shape.set_deferred("disabled", true)

func close_door() -> void:
	animated_sprite.play("door_close")
	collision_shape.set_deferred("disabled", false)

func _is_player(body: Node) -> bool:
	return body.name == "Player"
