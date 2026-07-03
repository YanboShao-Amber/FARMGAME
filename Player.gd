extends CharacterBody2D

# 移动速度
@export var speed: int = 100
@export var tool_action_duration := 0.35

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# 最近一次朝向（供 World 判断工具作用的格子）
var player_direction := Vector2.DOWN
var current_state := "idle_state"
var _world: Node
var _action_timer := 0.0

func _ready() -> void:
	_world = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if _is_busy_with_tool():
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var action_state := ""
		if _world != null and _world.has_method("use_current_tool_from_player"):
			action_state = _world.use_current_tool_from_player(self)
		if action_state != "":
			current_state = action_state
			_action_timer = tool_action_duration
			velocity = Vector2.ZERO
			get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# 使用工具时短暂停顿
	if _is_busy_with_tool():
		_action_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if _action_timer <= 0.0:
			current_state = "idle_state"
		return

	# 1. 获取输入
	var direction := Input.get_vector("player_left", "player_right", "player_up", "player_down")

	# 2. 自由移动
	velocity = direction * speed
	move_and_slide()

	# 3. 记录朝向 + 播放动画
	if direction != Vector2.ZERO:
		player_direction = direction
	update_animation(direction)

func _is_busy_with_tool() -> bool:
	return current_state == "tilling_state" \
		or current_state == "watering_state" \
		or current_state == "chopping_state" \
		or current_state == "planting_state"

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animated_sprite.stop()
		return

	if direction.y < 0:
		animated_sprite.play("walk_up")
	elif direction.y > 0:
		animated_sprite.play("walk_down")
	elif direction.x < 0:
		animated_sprite.play("walk_left")
	elif direction.x > 0:
		animated_sprite.play("walk_right")
