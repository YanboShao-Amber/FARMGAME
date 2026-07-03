extends StaticBody2D

# 自动获取子节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	# 1. 游戏刚开始时，先关门
	close_door()
	
	# 2. 连接信号 (当有人进出感应区时触发)
	# 确保你的 Area2D 名字就叫 "Area2D"，否则这里会报错
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

# --- 信号处理函数 ---

func _on_body_entered(body: Node2D) -> void:
	# 只有名字叫 "Player" 的节点才能触发开门
	# 这样牛 (Cow) 或者是其他东西靠近时，门不会开
	if body.name == "Player":
		open_door()

func _on_body_exited(body: Node2D) -> void:
	# 只有玩家离开时，才关门
	if body.name == "Player":
		close_door()

# --- 动作逻辑 ---

func open_door() -> void:
	# 播放开门动画 (使用你设置的新名字)
	animated_sprite.play("door_open")
	# 禁用碰撞体 -> 墙消失 -> 可以穿过
	collision_shape.set_deferred("disabled", true)

func close_door() -> void:
	# 播放关门动画 (使用你设置的新名字)
	animated_sprite.play("door_close")
	# 启用碰撞体 -> 墙出现 -> 挡住路
	collision_shape.set_deferred("disabled", false)
