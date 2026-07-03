extends Node2D

@onready var _roof: Node2D = $Roof
@onready var _enter_zone: Area2D = $EnterZone

var _players_inside: Dictionary = {}

func _ready() -> void:
	_enter_zone.body_entered.connect(_on_body_entered)
	_enter_zone.body_exited.connect(_on_body_exited)
	call_deferred("_sync_initial_overlap")

func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		_players_inside[body.get_instance_id()] = true
		_update_roof()

func _on_body_exited(body: Node2D) -> void:
	if _is_player(body):
		_players_inside.erase(body.get_instance_id())
		_update_roof()

func _sync_initial_overlap() -> void:
	_players_inside.clear()
	for body in _enter_zone.get_overlapping_bodies():
		if _is_player(body):
			_players_inside[body.get_instance_id()] = true
	_update_roof()

func _update_roof() -> void:
	_roof.visible = _players_inside.is_empty()

func _is_player(body: Node) -> bool:
	return body.name == "Player"
