class_name MainGame3D
extends Node3D

## 3D Gameplay Controller for Moon Sweepers
## Orchestrates 3D Terrain, Low-Gravity Player, Lunar Depot, and Mobile HUD.

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var terrain: LunarTerrain3D = $LunarTerrain3D
@onready var depot: Depot3D = $Depot3D
@onready var player: Player3D = $Player3D
@onready var controls: MobileControls3D = $CanvasLayer/MobileControls3D

# HUD nodes
@onready var sector_label: Label = $CanvasLayer/HUD/TopBar/SectorInfoLabel
@onready var clean_label: Label = $CanvasLayer/HUD/TopBar/CleanPercentageLabel
@onready var clean_progress: ProgressBar = $CanvasLayer/HUD/TopBar/CleanProgressBar
@onready var money_label: Label = $CanvasLayer/HUD/TopBar/HeaderRow/RightControls/MoneyPill/Margin/HBox/MoneyLabel
@onready var shop_btn: Button = $CanvasLayer/HUD/TopBar/HeaderRow/RightControls/ShopBtn
@onready var settings_btn: Button = $CanvasLayer/HUD/TopBar/HeaderRow/RightControls/SettingsBtn
@onready var dust_label: Label = $CanvasLayer/HUD/TopBar/DustStorageBox/DustLabel
@onready var dust_progress: ProgressBar = $CanvasLayer/HUD/TopBar/DustStorageBox/DustProgressBar
@onready var storage_warning: Panel = $CanvasLayer/HUD/TopBar/DustStorageBox/StorageWarning
@onready var depot_sell_btn: Button = $CanvasLayer/HUD/DepotSellBtn
@onready var completion_banner: Panel = $CanvasLayer/HUD/CompletionBanner
@onready var completion_label: Label = $CanvasLayer/HUD/CompletionBanner/VBox/Label
@onready var next_sector_button: Button = $CanvasLayer/HUD/CompletionBanner/VBox/NextSectorButton
@onready var shop_panel = $CanvasLayer/ShopPanel
@onready var settings_panel = $CanvasLayer/SettingsPanel
@onready var floating_text_spawn: Marker2D = $CanvasLayer/HUD/FloatingTextSpawn

var auto_sell_timer: Timer

func _ready() -> void:
	completion_banner.visible = false
	shop_panel.visible = false
	settings_panel.visible = false
	storage_warning.visible = false
	depot_sell_btn.visible = false
	
	_setup_auto_sell_timer()
	
	# Connect terrain signals
	terrain.clean_percentage_changed.connect(_on_clean_percentage_changed)
	terrain.sector_cleaned.connect(_on_sector_cleaned)
	terrain.dust_scrubbed.connect(_on_dust_scrubbed)
	
	# Connect depot signals
	depot.capsule_delivered.connect(_on_capsule_delivered)
	depot.player_docked.connect(_on_player_docked)
	
	# Connect GameState signals
	GameState.money_changed.connect(_on_money_changed)
	GameState.dust_changed.connect(_on_dust_changed)
	GameState.storage_status_changed.connect(_on_storage_status_changed)
	GameState.sector_changed.connect(_on_sector_changed)
	GameState.game_reset.connect(_on_game_reset)
	
	# Initial visual & HUD setup
	_apply_sector_theme(GameState.current_sector, GameState.get_current_theme())
	_on_money_changed(GameState.money)
	_on_dust_changed(GameState.dust, GameState.capacity)
	_on_storage_status_changed(GameState.is_storage_full)

func _setup_auto_sell_timer() -> void:
	auto_sell_timer = Timer.new()
	auto_sell_timer.wait_time = 0.65
	auto_sell_timer.one_shot = true
	auto_sell_timer.timeout.connect(_on_auto_sell_triggered)
	add_child(auto_sell_timer)

func _apply_sector_theme(sector_num: int, theme: Dictionary) -> void:
	sector_label.text = "Sector %02d: %s  •  Cleared: %d" % [sector_num, theme.get("name", "Lunar Sector"), GameState.sectors_cleared]
	terrain.apply_theme(theme)

func _on_sector_changed(sector_num: int, theme: Dictionary) -> void:
	completion_banner.visible = false
	_apply_sector_theme(sector_num, theme)
	terrain.reset_terrain()
	player.global_position = Vector3(0, 1.0, 4.0)

func _on_clean_percentage_changed(percentage: float) -> void:
	clean_label.text = "Sector Clean: %4.1f%%" % percentage
	clean_progress.value = percentage

func _on_sector_cleaned() -> void:
	var bonus: int = GameState.current_sector * 75
	completion_label.text = "★ SECTOR %02d COMPLETE! ★\nCleaned 95%%+ • Bonus: +$%d" % [GameState.current_sector, bonus]
	completion_banner.visible = true

func _on_next_sector_pressed() -> void:
	_animate_button_punch(next_sector_button)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	GameState.advance_to_next_sector()

func _on_dust_scrubbed(amount: float) -> void:
	GameState.add_dust(amount)

func _on_capsule_delivered(payout: int) -> void:
	_spawn_floating_text("CAPSULE SOLD! +$%d" % payout)

func _on_player_docked(is_docked: bool) -> void:
	if is_docked and GameState.dust > 0.0:
		var payout := int(floor(GameState.dust)) * GameState.dust_value
		depot_sell_btn.text = "🛸 DEPOT DOCK: SELL DUST (+$%d)" % payout
		depot_sell_btn.visible = true
	else:
		depot_sell_btn.visible = false

func _on_depot_sell_pressed() -> void:
	var earned := GameState.sell_dust()
	if earned > 0:
		_spawn_floating_text("+$%d" % earned)
	depot_sell_btn.visible = false

func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$%d" % new_amount

func _on_dust_changed(current: float, capacity: float) -> void:
	dust_label.text = "Hopper: %d / %d kg" % [int(ceil(current)), int(capacity)]
	dust_progress.max_value = capacity
	dust_progress.value = current

func _on_storage_status_changed(is_full: bool) -> void:
	storage_warning.visible = is_full
	if is_full:
		if GameState.upgrades["auto_sell"].level >= 1:
			auto_sell_timer.start()

func _on_auto_sell_triggered() -> void:
	if GameState.is_storage_full and GameState.dust > 0.0:
		var earned := GameState.sell_dust()
		if earned > 0:
			_spawn_floating_text("AUTO-SOLD! +$%d" % earned)

func _spawn_floating_text(text: String) -> void:
	var float_label := Label.new()
	float_label.text = text
	float_label.add_theme_font_size_override("font_size", 44)
	float_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
	float_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	float_label.add_theme_constant_override("shadow_offset_x", 3)
	float_label.add_theme_constant_override("shadow_offset_y", 3)
	
	float_label.position = floating_text_spawn.global_position - Vector2(160, 40)
	$CanvasLayer/HUD.add_child(float_label)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(float_label, "position:y", float_label.position.y - 150.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(float_label, "scale", Vector2(1.15, 1.15), 0.9)
	tween.tween_property(float_label, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(float_label.queue_free)

func _animate_button_punch(button: Button) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.06)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.06)

func _on_shop_button_pressed() -> void:
	_animate_button_punch(shop_btn)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	shop_panel.open_shop()

func _on_settings_button_pressed() -> void:
	_animate_button_punch(settings_btn)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	settings_panel.open_settings()

func _on_game_reset() -> void:
	completion_banner.visible = false
	_apply_sector_theme(GameState.current_sector, GameState.get_current_theme())
	terrain.reset_terrain()
	player.global_position = Vector3(0, 1.0, 4.0)
