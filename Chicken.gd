extends CharacterBody2D

# 小鸡移动速度 (稍微比牛快一点，设为 50)
@export var move_speed: float = 20.0

# 定义状态：0=发呆，1=走路
enum State { IDLE, WALK }

var current_state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	randomize() # 确保每次随机结果不一样
	pick_new_state()
	timer.timeout.connect(_on_timer_timeout)

func _physics_process(_delta: float) -> void:
	# --- 状态机逻辑 ---
	if current_state == State.WALK:
		velocity = move_direction * move_speed
		# 播放走路动画
		animated_sprite.play("chicken_walk")
		
		# 处理左右翻转 (脸朝左就翻转，脸朝右就不翻)
		if move_direction.x < 0:
			animated_sprite.flip_h = true 
		elif move_direction.x > 0:
			animated_sprite.flip_h = false
			
	elif current_state == State.IDLE:
		velocity = Vector2.ZERO
		# 播放发呆动画 (注意这里用的是你提供的 idel)
		animated_sprite.play("chicken_idel")
	
	# --- 移动并处理碰撞 ---
	move_and_slide()

# --- AI 决策大脑 ---
func pick_new_state() -> void:
	# 随机选一个状态 (0 或 1)
	var random_choice = randi() % 2
	
	if random_choice == 0:
		current_state = State.IDLE
		# 发呆时间随机 1 到 2 秒
		timer.wait_time = randf_range(1.0, 2.0)
		
	else:
		current_state = State.WALK
		# 随机选一个移动方向
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		# 走路时间随机 2 到 3 秒
		timer.wait_time = randf_range(2.0, 3.0)
	
	# 启动倒计时
	timer.start()

# 倒计时结束，重新做决定
func _on_timer_timeout() -> void:
	pick_new_state()
