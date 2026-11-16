extends Node

## Central GameState and Economy Manager
## Holds all balance parameters, economy counters, and data-driven upgrades in one place.

signal money_changed(new_amount: int)
signal dust_changed(current: float, capacity: float)
signal storage_status_changed(is_full: bool)
signal upgrade_purchased(upgrade_id: String, new_level: int)

var money: int = 0
var dust: float = 0.0
var capacity: float = 100.0
var dust_value: int = 1
var brush_size: float = 48.0
var is_storage_full: bool = false

## Data-driven upgrades dictionary.
## Easy to add new upgrades (e.g. vacuum bots, speed, jetpack) anytime.
var upgrades: Dictionary = {
	"brush_size": {
		"id": "brush_size",
		"name": "Brush Width",
		"icon": "🧹",
		"description": "Cleans a wider path with every swipe.",
		"level": 1,
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
		"base_cost": 40,
		"cost_mult": 1.6,
		"base_val": 1.0,
		"val_step": 1.0,
		"unit": "🪙/kg"
	}
}

func _ready() -> void:
	_recalculate_stats()

## Recalculates active stats based on upgrade levels
func _recalculate_stats() -> void:
	brush_size = get_upgrade_current_val("brush_size")
	capacity = get_upgrade_current_val("dust_capacity")
	dust_value = int(get_upgrade_current_val("dust_value"))
	_check_storage_status()

## Attempts to add dust. Returns the actual amount added.
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

## Sells all stored dust for credits. Returns the total money earned.
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

## Calculates cost for an upgrade at its current level
func get_upgrade_cost(id: String) -> int:
	if not upgrades.has(id):
		return 999999
	var data: Dictionary = upgrades[id]
	return int(round(data.base_cost * pow(data.cost_mult, data.level - 1)))

## Gets current numerical value for an upgrade
func get_upgrade_current_val(id: String) -> float:
	if not upgrades.has(id):
		return 0.0
	var data: Dictionary = upgrades[id]
	return data.base_val + (data.level - 1) * data.val_step

## Gets the next level's numerical value for an upgrade
func get_upgrade_next_val(id: String) -> float:
	if not upgrades.has(id):
		return 0.0
	var data: Dictionary = upgrades[id]
	return data.base_val + data.level * data.val_step

func can_afford(id: String) -> bool:
	return money >= get_upgrade_cost(id)

## Purchases an upgrade, deductions money, updates stats, and emits signals
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
	return true
