extends CharacterBody2D

# 移动速度 (牛不需要太快，30-50 比较合适)
@export var move_speed: float = 30.0

# 定义两个状态：0 是站着不动，1 是走路
enum State { IDLE, WALK }

# 当前的状态变量
var current_state: State = State.IDLE
# 当前的移动方向
var move_direction: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	# 游戏开始时，先随机选一个状态
	pick_new_state()
	# 连接计时器的信号（这是关键！）
	timer.timeout.connect(_on_timer_timeout)

func _physics_process(_delta: float) -> void:
	# 状态机逻辑
	if current_state == State.WALK:
		velocity = move_direction * move_speed
		animated_sprite.play("cow_walk")
		
		# 处理左右翻转
		if move_direction.x < 0:
			animated_sprite.flip_h = true # 向左走，翻转
		elif move_direction.x > 0:
			animated_sprite.flip_h = false # 向右走，复原
			
	elif current_state == State.IDLE:
		velocity = Vector2.ZERO
		animated_sprite.play("cow_idle")
	
	# 让牛移动并处理碰撞
	move_and_slide()

# --- AI 的核心大脑 ---
func pick_new_state() -> void:
	# 1. 随机决定是 站着(0) 还是 走(1)
	# randi() % 2 会随机返回 0 或 1
	var random_choice = randi() % 2
	
	if random_choice == 0:
		current_state = State.IDLE
		# 如果决定站着，就把计时器设短一点（比如站 1-2 秒）
		timer.wait_time = randf_range(1.0, 2.0)
		
	else:
		current_state = State.WALK
		# 如果决定走，就随机选一个方向
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		# 走路的时间也可以随机（比如走 2-3 秒）
		timer.wait_time = randf_range(2.0, 3.0)
	
	# 重新启动计时器，开始倒计时
	timer.start()

# 当计时器时间到了，就重新做一次决定
func _on_timer_timeout() -> void:
	pick_new_state()
