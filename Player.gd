extends CharacterBody2D

# 移动速度
@export var speed: int = 100

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# 1. 获取输入 (使用你 Input Map 里的名字)
	var direction = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	
	# 2. 移动
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# 3. 播放动画
	update_animation(direction)

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		animated_sprite.stop()
		return

	# 只要有特定的动画，就直接播放对应的名字
	if direction.y < 0:
		animated_sprite.play("walk_up")
	elif direction.y > 0:
		animated_sprite.play("walk_down")
	elif direction.x < 0:
		animated_sprite.play("walk_left")  # 直接播放向左的动画
	elif direction.x > 0:
		animated_sprite.play("walk_right") # 直接播放向右的动画
