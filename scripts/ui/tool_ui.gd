extends Control

@onready var tool_container: HBoxContainer = $ToolContainer
@onready var seed_container: HBoxContainer = $SeedContainer

var tool_texture_scene = preload("res://scenes/ui/tool_ui_texture.tscn")


func _ready() -> void:
	tool_container.hide()
	seed_container.hide()
	_setup_tool_textures()
	_setup_seed_textures()
	_update_seed_tool_icon(Enum.Seed.TOMATO)
	
	
func _setup_tool_textures() -> void:
	for tool in Enum.Tool.values():
		_add_texture(tool, Data.get_tool_texture(tool), tool_container)


func _setup_seed_textures() -> void:
	for seed in Enum.Seed.values():
		_add_texture(seed, Data.get_seed_texture(seed), seed_container)


func _add_texture(enum_id: int, texture: Texture2D, container: HBoxContainer) -> void:
	var tool_texture = tool_texture_scene.instantiate()
	container.add_child(tool_texture)
	tool_texture.setup(enum_id, texture)


func reveal(current_tool=null, current_seed=null):
	$Timer.start()
	if current_tool != null:
		tool_container.show()
		seed_container.hide()
		for texture in tool_container.get_children():
			texture.highlight(current_tool == texture.tool_enum)
	elif current_seed != null:
		_update_seed_tool_icon(current_seed)
		tool_container.hide()
		seed_container.show()	
		for texture in seed_container.get_children():
			texture.highlight(current_seed == texture.tool_enum)


func _update_seed_tool_icon(current_seed: int) -> void:
	Data.set_current_seed_tool_texture(current_seed)
	var seed_tool_texture: Texture2D = Data.get_tool_texture(Enum.Tool.SEED)
	for texture in tool_container.get_children():
		if texture.tool_enum == Enum.Tool.SEED:
			texture.set_texture(seed_tool_texture)
			return


func _on_timer_timeout() -> void:
	tool_container.hide()
	seed_container.hide()
