extends CanvasLayer
class_name QuestCompletionToast

@export_group("Timing")
@export_range(0.0, 2.0, 0.05) var fade_in_duration: float = 0.2
@export_range(0.5, 10.0, 0.1) var visible_duration: float = 2.5
@export_range(0.0, 2.0, 0.05) var fade_out_duration: float = 0.3

@onready var root: Control = $Root
@onready var toast_panel: NinePatchRect = $Root/SafeMargin/ToastPanel
@onready var completion_label: Label = $Root/SafeMargin/ToastPanel/ContentMargin/ContentColumn/CompletionLabel
@onready var quest_title_label: Label = $Root/SafeMargin/ToastPanel/ContentMargin/ContentColumn/QuestTitleLabel
@onready var reward_row: HBoxContainer = $Root/SafeMargin/ToastPanel/ContentMargin/ContentColumn/RewardRow
@onready var coin_icon: TextureRect = $Root/SafeMargin/ToastPanel/ContentMargin/ContentColumn/RewardRow/CoinIcon
@onready var reward_label: Label = $Root/SafeMargin/ToastPanel/ContentMargin/ContentColumn/RewardRow/RewardLabel

var _toast_tween: Tween = null


func _ready() -> void:
	_set_mouse_filter_recursive(root)
	root.hide()
	if not QuestManager.quest_completed.is_connected(_on_quest_completed):
		QuestManager.quest_completed.connect(_on_quest_completed)


func show_quest_completion(quest_title: String, reward_coins: int) -> void:
	if _toast_tween != null:
		_toast_tween.kill()
		_toast_tween = null

	completion_label.text = "任务完成"
	quest_title_label.text = quest_title

	if reward_coins > 0:
		reward_row.show()
		coin_icon.visible = coin_icon.texture != null
		reward_label.text = "+%d 金币" % reward_coins
	else:
		reward_row.hide()
		reward_label.text = ""

	root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	root.show()

	_toast_tween = create_tween()
	_toast_tween.tween_property(root, "modulate:a", 1.0, fade_in_duration)
	_toast_tween.tween_interval(visible_duration)
	_toast_tween.tween_property(root, "modulate:a", 0.0, fade_out_duration)
	_toast_tween.tween_callback(root.hide)


func _on_quest_completed(quest_id: StringName) -> void:
	var quest_data: QuestData = QuestManager.get_quest_data(quest_id)
	if quest_data == null or not quest_data.is_valid_quest():
		return

	show_quest_completion(quest_data.get_title(), quest_data.reward_coins)


func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		var control: Control = node as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child: Node in node.get_children():
		_set_mouse_filter_recursive(child)
