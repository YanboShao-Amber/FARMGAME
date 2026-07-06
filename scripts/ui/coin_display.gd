extends Control

# Dedicated, read-only HUD showing the player's current coin balance.
# Observes Data only: it never adds or spends coins itself.
# Coin texture is shared with the shop via Data.get_item_texture(Enum.Item.COIN).

@onready var coin_icon: TextureRect = %CoinIcon
@onready var coin_amount: Label = %CoinAmount


func _ready() -> void:
	_apply_coin_texture()
	_refresh_coin_amount()

	# Guard against duplicate connections if this node is ever re-readied.
	if not Data.coin_balance_changed.is_connected(_on_coin_balance_changed):
		Data.coin_balance_changed.connect(_on_coin_balance_changed)


func _on_coin_balance_changed(new_balance: int) -> void:
	coin_amount.text = str(maxi(new_balance, 0))


func _apply_coin_texture() -> void:
	# Reuse the same coin texture source as the shop cost icons.
	coin_icon.texture = Data.get_item_texture(Enum.Item.COIN)


func _refresh_coin_amount() -> void:
	if not Data.ITEMS_AMOUNT.has(Enum.Item.COIN):
		push_warning("Coin balance key missing from Data.ITEMS_AMOUNT; displaying 0.")
	var balance: int = int(Data.ITEMS_AMOUNT.get(Enum.Item.COIN, 0))
	coin_amount.text = str(maxi(balance, 0))
