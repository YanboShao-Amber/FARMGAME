extends StaticBody2D

@onready var flash_sprite_2d: Sprite2D = $FlashSprite2D
const apple_texture = preload("res://graphics/plants/apple.png")
const dropped_apple_scene = preload("res://scenes/objects/dropped_apple.tscn")
var tree_health := Data.APPLE_TREE_HEALTH
var apple_range = [2, 4]


func _ready() -> void:
	$FlashSprite2D.frame = [0, 1, 1].pick_random()
	add_to_group("Tree")
	create_apple()


func hit(tool: Enum.Tool, _attacker_position: Vector2):
	if tool == Enum.Tool.AXE:
		shake()
		drop_apple()
		tree_health -= 1
		if tree_health == 0:
			Data.ITEMS_AMOUNT[Enum.Item.WOOD] += 1
			self.flash_sprite_2d.hide()
			$CollisionShapeTree2D.disabled = true
			$Stump.show()
			$CollisionShapeStumpD2.disabled = false


func shake():
	# Wobble the tree back and forth when it gets chopped
	var tween = create_tween()
	flash_sprite_2d.rotation = 0.0
	tween.tween_property(flash_sprite_2d, "rotation", deg_to_rad(5), 0.05)
	tween.tween_property(flash_sprite_2d, "rotation", deg_to_rad(-4), 0.05)
	tween.tween_property(flash_sprite_2d, "rotation", deg_to_rad(2), 0.05)
	tween.tween_property(flash_sprite_2d, "rotation", 0.0, 0.05)


func drop_apple():
	if $Apples.get_children().is_empty():
		return

	# Remove one apple from the branch...
	var apple_sprite: Sprite2D = $Apples.get_children().pick_random()
	var start_global := apple_sprite.global_position
	apple_sprite.queue_free()

	# ...and spawn a physical apple that falls to the ground for the
	# player to pick up.
	var dropped = dropped_apple_scene.instantiate()
	get_parent().add_child(dropped)
	dropped.global_position = start_global

	var land_global := global_position + Vector2(randf_range(-10, 10), 12)
	dropped.fall_to(land_global)


func create_apple():
	var num = randi_range(apple_range[0], apple_range[1])
	
	if $CollisionShapeStumpD2.disabled == false:
		return
		
	if $Apples.get_children():
		for child in $Apples.get_children():
			child.queue_free()
			
	var apple_markers = $AppleSpawnPositions.get_children().duplicate(true)
	apple_markers.shuffle()
	
	if num > apple_markers.size():
		num = apple_markers.size()
		
	# Trees heals over days
	tree_health = min(Data.APPLE_TREE_HEALTH, tree_health + 1)
	
	# Apple counts should be equal or less than tree health
	num = min(tree_health, num)
	
	for i in num:
		var sprite = Sprite2D.new()
		sprite.texture = apple_texture
		sprite.position = apple_markers[i].position
		$Apples.add_child(sprite)
