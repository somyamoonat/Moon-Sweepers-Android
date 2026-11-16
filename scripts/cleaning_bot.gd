class_name CleaningBot
extends Control

@export var move_speed: float = 110.0
@export var bot_brush_size: float = 24.0

var surface_ref: Control
var target_pos: Vector2 = Vector2.ZERO
var scrub_cooldown: float = 0.0

@onready var chassis: Panel = $Chassis
@onready var light: ColorRect = $Chassis/StatusLight

func _ready() -> void:
	# Start at random position within parent bounds
	if get_parent() is Control:
		surface_ref = get_parent()
		var psize: Vector2 = surface_ref.size
		position = Vector2(randf_range(40.0, psize.x - 40.0), randf_range(40.0, psize.y - 40.0))
		_pick_new_target()

func _pick_new_target() -> void:
	if surface_ref:
		var psize: Vector2 = surface_ref.size
		target_pos = Vector2(randf_range(40.0, psize.x - 40.0), randf_range(40.0, psize.y - 40.0))

func _process(delta: float) -> void:
	if not surface_ref:
		return
	
	# If storage is full, pause cleaning
	if GameState.is_storage_full:
		light.color = Color(1.0, 0.4, 0.2, 1.0) # Amber pause light
		return
	else:
		light.color = Color(0.1, 1.0, 0.8, 1.0) # Active cyan light
	
	# Move toward target position
	var to_target: Vector2 = target_pos - position
	if to_target.length() < 16.0:
		_pick_new_target()
	else:
		position += to_target.normalized() * move_speed * delta
	
	# Keep within boundaries
	position.x = clampf(position.x, 30.0, surface_ref.size.x - 30.0)
	position.y = clampf(position.y, 30.0, surface_ref.size.y - 30.0)
	
	# Scrub dust periodically (8-10 times/sec for maximum mobile efficiency)
	scrub_cooldown -= delta
	if scrub_cooldown <= 0.0:
		scrub_cooldown = 0.12
		if surface_ref.has_method("bot_scrub_at"):
			surface_ref.bot_scrub_at(position, bot_brush_size)
