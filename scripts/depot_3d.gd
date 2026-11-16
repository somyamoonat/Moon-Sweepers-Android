class_name Depot3D
extends Node3D

## 3D Lunar Depot Building & Intake Pad
## Accepts physical capsules and direct player deliveries for Credits.

signal capsule_delivered(payout: int)
signal player_docked(is_docked: bool)

@onready var intake_area: Area3D = $IntakeArea
@onready var dock_area: Area3D = $DockArea
@onready var holographic_ring: MeshInstance3D = $IntakeArea/HoloRing

func _ready() -> void:
	intake_area.body_entered.connect(_on_intake_body_entered)
	dock_area.body_entered.connect(_on_dock_body_entered)
	dock_area.body_exited.connect(_on_dock_body_exited)
	
	# Gentle rotating pulse for the holographic ring
	var tween := create_tween().set_loops()
	tween.tween_property(holographic_ring, "rotation:y", TAU, 4.0).as_relative()

func _on_intake_body_entered(body: Node3D) -> void:
	if body is DustCapsule3D:
		var payout: int = body.collect_at_depot()
		if payout > 0:
			capsule_delivered.emit(payout)

func _on_dock_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_docked.emit(true)

func _on_dock_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_docked.emit(false)
