extends Node

## Central GameState, Economy, Progression & Save/Load Manager

signal money_changed(new_amount: int)
signal dust_changed(current: float, capacity: float)
signal storage_status_changed(is_full: bool)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal sector_changed(sector_num: int, theme: Dictionary)
signal game_saved()
signal game_reset()

const SAVE_PATH := "user://savegame.json"
const DUST_MASK_PATH := "user://dust_mask.png"

var money: int = 0
var dust: float = 0.0
var capacity: float = 100.0
var dust_value: int = 1
var brush_size: float = 48.0
var is_storage_full: bool = false
var current_sector: int = 1
var sectors_cleared: int = 0

## Data-driven upgrades dictionary
var upgrades: Dictionary = {
	"brush_size": {
		"id": "brush_size",
		"name": "Brush Width",
		"icon": "🧹",
		"description": "Cleans a wider path with every swipe.",
		"level": 1,
		"max_level": 10,
		"base_cost": 20,
		"cost_mult": 1.5,
		"base_val": 48.0,
		"val_step": 14.0,
		"unit": "px"
	},
	"dust_capacity": {
		"id": "dust_capacity",
		"name": "Storage Tank",
		"icon": "🎒",
		"description": "Increases max dust capacity before selling.",
		"level": 1,
		"max_level": 10,
		"base_cost": 25,
		"cost_mult": 1.5,
		"base_val": 100.0,
		"val_step": 50.0,
		"unit": "kg"
	},
	"dust_value": {
		"id": "dust_value",
		"name": "Dust Value",
		"icon": "💎",
		"description": "Earn more credits for every kg of dust sold.",
		"level": 1,
		"max_level": 8,
		"base_cost": 40,
		"cost_mult": 1.6,
		"base_val": 1.0,
		"val_step": 1.0,
		"unit": "🪙/kg"
	},
	"cleaning_bot": {
		"id": "cleaning_bot",
		"name": "Cleaning Bot",
		"icon": "🤖",
		"description": "Autonomous rover that scrubs dust continuously.",
		"level": 0,
		"max_level": 6, # sensible cap for phone performance
		"base_cost": 75,
		"cost_mult": 1.7,
		"base_val": 0.0,
		"val_step": 1.0,
		"unit": "bots"
	},
	"auto_sell": {
		"id": "auto_sell",
		"name": "Auto-Sell Module",
		"icon": "⚡",
		"description": "Automatically sells dust when your tank is full.",
		"level": 0,
		"max_level": 1,
		"base_cost": 180,
		"cost_mult": 1.0,
		"base_val": 0.0,
		"val_step": 1.0,
		"unit": "installed"
	}
}

## Themes and visual color tints for different sectors
const SECTOR_THEMES: Array[Dictionary] = [
	{
		"name": "Mare Tranquillitatis",
		"bg_color": Color(0.047, 0.055, 0.09, 1.0),
		"bedrock_color": Color(0.141, 0.157, 0.204, 1.0),
		"crater_color": Color(0.082, 0.090, 0.118, 1.0),
		"dust_color": Color(0.48, 0.44, 0.38, 1.0),
		"base_dust": 350.0
	},
	{
		"name": "Oceanus Procellarum",
		"bg_color": Color(0.04, 0.065, 0.075, 1.0),
		"bedrock_color": Color(0.13, 0.18, 0.19, 1.0),
		"crater_color": Color(0.07, 0.11, 0.12, 1.0),
		"dust_color": Color(0.50, 0.46, 0.36, 1.0),
		"base_dust": 500.0
	},
	{
		"name": "Mare Imbrium",
		"bg_color": Color(0.065, 0.045, 0.075, 1.0),
		"bedrock_color": Color(0.18, 0.14, 0.20, 1.0),
		"crater_color": Color(0.11, 0.08, 0.13, 1.0),
		"dust_color": Color(0.52, 0.43, 0.40, 1.0),
		"base_dust": 700.0
	},
	{
		"name": "Sinus Iridum",
		"bg_color": Color(0.07, 0.06, 0.04, 1.0),
		"bedrock_color": Color(0.20, 0.18, 0.14, 1.0),
		"crater_color": Color(0.13, 0.11, 0.08, 1.0),
		"dust_color": Color(0.55, 0.48, 0.36, 1.0),
		"base_dust": 950.0
	}
]

var autosave_timer: Timer

func _ready() -> void:
	load_game()
	_recalculate_stats()
	_setup_autosave()

func _setup_autosave() -> void:
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 30.0
	autosave_timer.autostart = true
	autosave_timer.one_shot = false
	autosave_timer.timeout.connect(save_game)
	add_child(autosave_timer)

func _notification(what: int) -> void:
	# Save automatically on mobile app lifecycle events and window close
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()

func get_current_theme() -> Dictionary:
	var index: int = (current_sector - 1) % SECTOR_THEMES.size()
	return SECTOR_THEMES[index]

func get_sector_total_dust() -> float:
	var theme := get_current_theme()
	var multiplier := pow(1.25, float(current_sector - 1))
	return theme.base_dust * multiplier

func _recalculate_stats() -> void:
	brush_size = get_upgrade_current_val("brush_size")
	capacity = get_upgrade_current_val("dust_capacity")
	dust_value = int(get_upgrade_current_val("dust_value"))
	_check_storage_status()

func add_dust(amount: float) -> float:
	if is_storage_full or amount <= 0.0:
		return 0.0
	
	var space_left: float = capacity - dust
	var added: float = minf(amount, space_left)
	dust += added
	
	_check_storage_status()
	dust_changed.emit(dust, capacity)
	return added

func _check_storage_status() -> void:
	var now_full: bool = (dust >= capacity)
	if now_full != is_storage_full:
		is_storage_full = now_full
		storage_status_changed.emit(is_storage_full)

func sell_dust() -> int:
	if dust <= 0.0:
		return 0
	
	var earnings: int = int(floor(dust)) * dust_value
	money += earnings
	dust = 0.0
	
	_check_storage_status()
	money_changed.emit(money)
	dust_changed.emit(dust, capacity)
	return earnings

func advance_to_next_sector() -> void:
	current_sector += 1
	sectors_cleared += 1
	
	# Award a sector completion bonus
	var bonus: int = current_sector * 50
	money += bonus
	money_changed.emit(money)
	
	# Remove old saved dust mask so next sector starts fresh
	if FileAccess.file_exists(DUST_MASK_PATH):
		DirAccess.remove_absolute(DUST_MASK_PATH)
	
	sector_changed.emit(current_sector, get_current_theme())
	save_game()

func get_upgrade_cost(id: String) -> int:
	if not upgrades.has(id):
		return 999999
	var data: Dictionary = upgrades[id]
	if data.level >= data.get("max_level", 999):
		return -1 # Maxed out
	return int(round(data.base_cost * pow(data.cost_mult, data.level)))

func get_upgrade_current_val(id: String) -> float:
	if not upgrades.has(id):
		return 0.0
	var data: Dictionary = upgrades[id]
	return data.base_val + (data.level * data.val_step)

func get_upgrade_next_val(id: String) -> float:
	if not upgrades.has(id):
		return 0.0
	var data: Dictionary = upgrades[id]
	return data.base_val + ((data.level + 1) * data.val_step)

func is_max_level(id: String) -> bool:
	if not upgrades.has(id):
		return true
	var data: Dictionary = upgrades[id]
	return data.level >= data.get("max_level", 999)

func can_afford(id: String) -> bool:
	if is_max_level(id):
		return false
	var cost := get_upgrade_cost(id)
	return money >= cost

func buy_upgrade(id: String) -> bool:
	if not can_afford(id):
		return false
	
	var cost: int = get_upgrade_cost(id)
	money -= cost
	upgrades[id].level += 1
	_recalculate_stats()
	
	money_changed.emit(money)
	dust_changed.emit(dust, capacity)
	upgrade_purchased.emit(id, upgrades[id].level)
	save_game()
	return true

## Saves current progression to user://savegame.json
func save_game() -> void:
	var save_data := {
		"version": 1,
		"money": money,
		"dust": dust,
		"current_sector": current_sector,
		"sectors_cleared": sectors_cleared,
		"upgrades": {}
	}
	
	for id in upgrades:
		save_data["upgrades"][id] = upgrades[id].level
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		game_saved.emit()

## Loads saved progression from user://savegame.json
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	money = int(data.get("money", 0))
	dust = float(data.get("dust", 0.0))
	current_sector = int(data.get("current_sector", 1))
	sectors_cleared = int(data.get("sectors_cleared", 0))
	
	var saved_upgrades: Dictionary = data.get("upgrades", {})
	for id in saved_upgrades:
		if upgrades.has(id):
			upgrades[id].level = int(saved_upgrades[id])

## Resets all progression back to factory defaults
func reset_all_progress() -> void:
	money = 0
	dust = 0.0
	current_sector = 1
	sectors_cleared = 0
	
	# Reset upgrade levels
	upgrades["brush_size"].level = 1
	upgrades["dust_capacity"].level = 1
	upgrades["dust_value"].level = 1
	upgrades["cleaning_bot"].level = 0
	upgrades["auto_sell"].level = 0
	
	_recalculate_stats()
	
	# Delete save files
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(DUST_MASK_PATH):
		DirAccess.remove_absolute(DUST_MASK_PATH)
	
	money_changed.emit(money)
	dust_changed.emit(dust, capacity)
	sector_changed.emit(current_sector, get_current_theme())
	game_reset.emit()
