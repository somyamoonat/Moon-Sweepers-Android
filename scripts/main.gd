extends Control

@onready var lunar_surface = $LunarSurface
@onready var clean_label: Label = $HUD/TopBar/CleanPercentageLabel
@onready var clean_progress_bar: ProgressBar = $HUD/TopBar/CleanProgressBar
@onready var money_label: Label = $HUD/TopBar/HeaderRow/MoneyPill/Margin/HBox/MoneyLabel
@onready var shop_btn: Button = $HUD/TopBar/HeaderRow/ShopBtn
@onready var dust_label: Label = $HUD/TopBar/DustStorageBox/DustLabel
@onready var dust_progress_bar: ProgressBar = $HUD/TopBar/DustStorageBox/DustProgressBar
@onready var storage_warning: Panel = $HUD/TopBar/DustStorageBox/StorageWarning
@onready var sell_button: Button = $HUD/BottomBar/SellButton
@onready var completion_banner: Panel = $HUD/CompletionBanner
@onready var shop_panel = $ShopPanel
@onready var floating_text_spawn: Marker2D = $HUD/BottomBar/FloatingTextSpawn

func _ready() -> void:
	completion_banner.visible = false
	shop_panel.visible = false
	storage_warning.visible = false
	
	# Connect surface signals
	lunar_surface.clean_percentage_changed.connect(_on_clean_percentage_changed)
	lunar_surface.sector_cleaned.connect(_on_sector_cleaned)
	lunar_surface.dust_scrubbed.connect(_on_dust_scrubbed)
	lunar_surface.scrub_blocked.connect(_on_scrub_blocked)
	
	# Connect GameState signals
	GameState.money_changed.connect(_on_money_changed)
	GameState.dust_changed.connect(_on_dust_changed)
	GameState.storage_status_changed.connect(_on_storage_status_changed)
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)
	
	# Initial UI refresh
	lunar_surface.brush_size = GameState.brush_size
	_on_money_changed(GameState.money)
	_on_dust_changed(GameState.dust, GameState.capacity)
	_on_storage_status_changed(GameState.is_storage_full)

func _on_clean_percentage_changed(percentage: float) -> void:
	clean_label.text = "Sector Clean: %4.1f%%" % percentage
	clean_progress_bar.value = percentage

func _on_sector_cleaned() -> void:
	completion_banner.visible = true

func _on_dust_scrubbed(amount: float) -> void:
	GameState.add_dust(amount)

func _on_scrub_blocked() -> void:
	# Flash storage warning when player attempts to scrub with a full tank
	_pulse_storage_warning()

func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$%d" % new_amount
	_update_sell_button()

func _on_dust_changed(current: float, capacity: float) -> void:
	dust_label.text = "Storage: %d / %d kg" % [int(ceil(current)), int(capacity)]
	dust_progress_bar.max_value = capacity
	dust_progress_bar.value = current
	_update_sell_button()

func _on_storage_status_changed(is_full: bool) -> void:
	lunar_surface.can_scrub = not is_full
	storage_warning.visible = is_full
	if is_full:
		_pulse_storage_warning()

func _on_upgrade_purchased(upgrade_id: String, _level: int) -> void:
	if upgrade_id == "brush_size":
		lunar_surface.set_brush_size(GameState.brush_size)

func _update_sell_button() -> void:
	var potential_earnings: int = int(floor(GameState.dust)) * GameState.dust_value
	if GameState.dust <= 0.0:
		sell_button.text = "SELL DUST  (Empty)"
		sell_button.disabled = true
	else:
		sell_button.text = "💰 SELL DUST  (+$%d)" % potential_earnings
		sell_button.disabled = false

func _on_sell_button_pressed() -> void:
	var earned: int = GameState.sell_dust()
	if earned > 0:
		_spawn_floating_text("+$%d" % earned)

func _spawn_floating_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.add_theme_font_size_override("font_size", 48)
	float_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
	float_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	float_label.add_theme_constant_override("shadow_offset_x", 3)
	float_label.add_theme_constant_override("shadow_offset_y", 3)
	
	# Spawn near the Sell button
	float_label.position = floating_text_spawn.global_position - Vector2(100, 40)
	$HUD.add_child(float_label)
	
	# Animate upward float and fade out smoothly
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(float_label, "position:y", float_label.position.y - 140.0, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "scale", Vector2(1.2, 1.2), 0.85)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(float_label.queue_free)

func _pulse_storage_warning() -> void:
	storage_warning.visible = true
	var tween := create_tween()
	tween.tween_property(storage_warning, "modulate", Color(1.4, 0.3, 0.3, 1.0), 0.15)
	tween.tween_property(storage_warning, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func _on_shop_button_pressed() -> void:
	shop_panel.open_shop()

func _on_reset_button_pressed() -> void:
	completion_banner.visible = false
	lunar_surface.reset_surface()
