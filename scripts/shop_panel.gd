extends Control

signal shop_closed()

@onready var items_container: VBoxContainer = $DimBackdrop/Panel/Margin/VBox/ScrollContainer/ItemsContainer
@onready var credits_label: Label = $DimBackdrop/Panel/Margin/VBox/Header/CreditsLabel

func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)
	refresh_shop()

func open_shop() -> void:
	visible = true
	refresh_shop()

func close_shop() -> void:
	visible = false
	shop_closed.emit()

func _on_money_changed(_new_money: int) -> void:
	if visible:
		refresh_shop()

func _on_upgrade_purchased(_id: String, _level: int) -> void:
	if visible:
		refresh_shop()

func refresh_shop() -> void:
	credits_label.text = "🪙 Credits: $%d" % GameState.money
	
	# Clear existing card children
	for child in items_container.get_children():
		child.queue_free()
	
	# Populate upgrade cards dynamically from GameState.upgrades
	for upgrade_id in GameState.upgrades:
		var data: Dictionary = GameState.upgrades[upgrade_id]
		var card := _create_upgrade_card(data)
		items_container.add_child(card)

func _create_upgrade_card(data: Dictionary) -> PanelContainer:
	var id: String = data.id
	var cost: int = GameState.get_upgrade_cost(id)
	var current_val: float = GameState.get_upgrade_current_val(id)
	var next_val: float = GameState.get_upgrade_next_val(id)
	var can_buy: bool = GameState.can_afford(id)
	
	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.14, 0.16, 0.22, 1.0)
	card_style.border_color = Color(0.28, 0.32, 0.44, 1.0)
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.corner_radius_top_left = 16
	card_style.corner_radius_top_right = 16
	card_style.corner_radius_bottom_right = 16
	card_style.corner_radius_bottom_left = 16
	card.add_theme_stylebox_override("panel", card_style)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Header line: Icon + Name + Level
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title_lbl := Label.new()
	title_lbl.text = "%s %s" % [data.get("icon", "🔧"), data.name]
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)
	
	var lvl_lbl := Label.new()
	lvl_lbl.text = "Lv. %d" % data.level
	lvl_lbl.add_theme_font_size_override("font_size", 30)
	lvl_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header_hbox.add_child(lvl_lbl)
	
	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = data.description
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 24)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.73, 0.8))
	vbox.add_child(desc_lbl)
	
	# Stats progression
	var stats_lbl := Label.new()
	if data.unit == "🪙/kg":
		stats_lbl.text = "Effect: %d -> %d %s" % [int(current_val), int(next_val), data.unit]
	else:
		stats_lbl.text = "Effect: %d -> %d %s" % [int(current_val), int(next_val), data.unit]
	stats_lbl.add_theme_font_size_override("font_size", 26)
	stats_lbl.add_theme_color_override("font_color", Color(0.45, 0.9, 0.55))
	vbox.add_child(stats_lbl)
	
	# Large Thumb-Friendly Buy Button
	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(0, 84)
	buy_btn.text = "BUY UPGRADE  •  $%d" % cost
	buy_btn.add_theme_font_size_override("font_size", 30)
	buy_btn.disabled = not can_buy
	
	var btn_normal := StyleBoxFlat.new()
	if can_buy:
		btn_normal.bg_color = Color(0.12, 0.45, 0.28, 1.0)
		btn_normal.border_color = Color(0.3, 0.8, 0.5, 1.0)
	else:
		btn_normal.bg_color = Color(0.2, 0.22, 0.28, 0.6)
		btn_normal.border_color = Color(0.3, 0.33, 0.4, 0.6)
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.corner_radius_top_left = 14
	btn_normal.corner_radius_top_right = 14
	btn_normal.corner_radius_bottom_right = 14
	btn_normal.corner_radius_bottom_left = 14
	buy_btn.add_theme_stylebox_override("normal", btn_normal)
	
	buy_btn.pressed.connect(func():
		if GameState.buy_upgrade(id):
			refresh_shop()
	)
	vbox.add_child(buy_btn)
	
	return card
