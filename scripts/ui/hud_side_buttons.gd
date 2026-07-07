extends CanvasLayer
## HUD relationship button (Phase H5.1). A single square HUD button that reuses
## the exact style of the Quest button (Small Square Buttons atlas, 52x52) and
## sits directly below it, so the column reads:
##   任务 (quest, lives in QuestTracker)  →  关系 (relationship)

signal relationship_pressed

const SQUARE_BUTTONS: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/Sprite sheets/buttons/Small Square Buttons.png")
const HEART_SHEET: Texture2D = preload("res://graphics/ui/Sprout Lands - UI Pack - Basic pack/emojis-free/emoji style ui/Inventory_Herat_Spritesheet.png")

# Quest button occupies screen y 243..295 at x 26 (see quest_tracker.tscn).
# The relationship button sits directly below it.
const BUTTON_SIZE := Vector2(52, 52)
const BUTTON_X := 26.0
const RELATIONSHIP_Y := 299.0

var _relationship_button: TextureButton


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_relationship_button = _make_button(_heart_icon(), Vector2(BUTTON_X, RELATIONSHIP_Y))
	_relationship_button.pressed.connect(func() -> void: relationship_pressed.emit())
	root.add_child(_relationship_button)


func set_buttons_enabled(enabled: bool) -> void:
	if _relationship_button != null:
		_relationship_button.disabled = not enabled


func _make_button(icon: Texture2D, pos: Vector2) -> TextureButton:
	var button := TextureButton.new()
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.texture_normal = _atlas(SQUARE_BUTTONS, Rect2(0, 0, 16, 16))
	button.texture_pressed = _atlas(SQUARE_BUTTONS, Rect2(16, 0, 16, 16))
	button.texture_hover = _atlas(SQUARE_BUTTONS, Rect2(16, 0, 16, 16))
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = BUTTON_SIZE
	button.size = BUTTON_SIZE
	button.position = pos
	button.focus_mode = Control.FOCUS_ALL

	var icon_rect := TextureRect.new()
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.set_anchors_preset(Control.PRESET_CENTER)
	icon_rect.offset_left = -11.0
	icon_rect.offset_top = -11.0
	icon_rect.offset_right = 11.0
	icon_rect.offset_bottom = 11.0
	button.add_child(icon_rect)
	return button


func _heart_icon() -> AtlasTexture:
	return _atlas(HEART_SHEET, Rect2(0, 0, 16, 16))


func _atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = region
	return tex
