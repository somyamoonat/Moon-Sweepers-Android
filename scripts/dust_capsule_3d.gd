class_name DustCapsule3D
extends RigidBody3D

## Physical Dust Capsule with low-gravity lunar physics
## Can be picked up, rolled, thrown, or dropped into the Depot for Credits.

@export var dust_content: float = 10.0 ## Kilograms of compressed dust inside
@export var base_value_per_kg: int = 1

var is_collected: bool = false

func _ready() -> void:
	# Low moon gravity scaling
	gravity_scale = 0.35
	contact_monitor = true
	max_contacts_reported = 4

## Called when deposited into the Lunar Depot
func collect_at_depot() -> int:
	if is_collected:
		return 0
	is_collected = true
	
	var payout: int = int(ceil(dust_content * GameState.dust_value))
	GameState.money += payout
	GameState.money_changed.emit(GameState.money)
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sell()
	
	# Shrink and disappear
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
	return payout
