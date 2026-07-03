extends CharacterBody2D

@export var move_speed: float = 20.0
@export var min_sound_interval: float = 3.0
@export var max_sound_interval: float = 8.0

enum State { IDLE, WALK }

const CLUCK_SOUNDS: Array[AudioStream] = [
	preload("res://audio/sfx/chicken-cluck-1.ogg"),
	preload("res://audio/sfx/chicken-cluck-2.ogg"),
	preload("res://audio/sfx/chicken-cluck-3.ogg"),
]

var current_state: State = State.IDLE
var move_direction: Vector2 = Vector2.ZERO
var _sound_player: AudioStreamPlayer2D
var _sound_timer: Timer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	randomize()
	_setup_sound_player()
	pick_new_state()
	timer.timeout.connect(_on_timer_timeout)

func _physics_process(_delta: float) -> void:
	if current_state == State.WALK:
		velocity = move_direction * move_speed
		animated_sprite.play("chicken_walk")

		if move_direction.x < 0:
			animated_sprite.flip_h = true
		elif move_direction.x > 0:
			animated_sprite.flip_h = false
	elif current_state == State.IDLE:
		velocity = Vector2.ZERO
		animated_sprite.play("chicken_idel")

	move_and_slide()

func pick_new_state() -> void:
	if randi() % 2 == 0:
		current_state = State.IDLE
		timer.wait_time = randf_range(1.0, 2.0)
	else:
		current_state = State.WALK
		move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		timer.wait_time = randf_range(2.0, 3.0)

	timer.start()

func _setup_sound_player() -> void:
	_sound_player = AudioStreamPlayer2D.new()
	_sound_player.name = "CluckPlayer"
	add_child(_sound_player)

	_sound_timer = Timer.new()
	_sound_timer.name = "CluckTimer"
	_sound_timer.one_shot = true
	add_child(_sound_timer)
	_sound_timer.timeout.connect(_play_cluck)
	_schedule_next_cluck()

func _schedule_next_cluck() -> void:
	_sound_timer.wait_time = randf_range(min_sound_interval, max_sound_interval)
	_sound_timer.start()

func _play_cluck() -> void:
	_sound_player.stream = CLUCK_SOUNDS.pick_random()
	_sound_player.pitch_scale = randf_range(0.95, 1.08)
	_sound_player.play()
	_schedule_next_cluck()

func _on_timer_timeout() -> void:
	pick_new_state()
