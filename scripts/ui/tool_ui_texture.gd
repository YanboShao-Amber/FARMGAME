extends Control

var tool_enum: int
@onready var texture_rect: TextureRect = $TextureRect
 
func setup(new_tool_enum: int, main_texture: Texture2D):
	tool_enum = new_tool_enum
	set_texture(main_texture)


func set_texture(main_texture: Texture2D) -> void:
	texture_rect.texture = main_texture


func highlight(selected: bool):
	var tween = create_tween()
	var target_size = Vector2(16, 16) if selected else Vector2(12, 12)	
	tween.tween_property($TextureRect, "custom_minimum_size", target_size, 0.05)
