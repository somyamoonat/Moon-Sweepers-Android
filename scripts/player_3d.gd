class_name Player3D
extends CharacterBody3D

## 3D Astronaut Player with low-gravity movement, jetpack, and sweeper tool.

signal dust_collected(amount: float)
signal capsule_compressed()

@export var walk_speed: float = 6.5
@export var jetpack_thrust: float = 5.5
@export var gravity_strength: float = 4.8 ## Low lunar gravity (moon floatiness)
@export var sweep_radius: float = 1.6 ## Radius of sweeping broom in meters

var move_input: Vector2 = Vector2.ZERO
var look_input: Vector2 = Vector2.ZERO
var is_sweeping: bool = false
var auto_sweep_enabled: bool = false
var is_first_person: bool = false

var terrain_ref: LunarTerrain3D
var sweep_cooldown: float = 0.0

@onready var visual_root: Node3D = $Visuals
@onready var broom_tool: Node3D = $Visuals/BroomTool
@onready var broom_brush: Node3D = $Visuals/BroomTool/BrushHead
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var dust_particles: CPUParticles3D = $Visuals/BroomTool/DustParticles
@onready var jetpack_particles: CPUParticles3D = $Visuals/Backpack/JetpackParticles

const CapsuleScene = preload("res://scenes/dust_capsule_3d.tscn")

func _ready() -> void:
	add_to_group("player")
	_update_tool_radius()
	GameState.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_upgrade_purchased(upgrade_id: String, _level: int) -> void:
	if upgrade_id == "brush_size":
		_update_tool_radius()

func _update_tool_radius() -> void:
	# Convert upgrade brush size into 3D meters
	sweep_radius = 1.2 + (GameState.brush_size * 0.015)
	if broom_brush:
		broom_brush.scale.x = sweep_radius * 0.65

func set_move_vector(input: Vector2) -> void:
	move_input = input

func rotate_camera(relative: Vector2) -> void:
	# Horizontal camera yaw
	camera_pivot.rotate_y(-relative.x * 0.005)
	# Vertical camera pitch clamped
	spring_arm.rotate_x(-relative.y * 0.005)
	spring_arm.rotation.x = clampf(spring_arm.rotation.x, -1.2, 0.4)

func toggle_camera_view() -> bool:
	is_first_person = not is_first_person
	if is_first_person:
		spring_arm.spring_length = 0.0
		visual_root.visible = false
	else:
		spring_arm.spring_length = 4.2
		visual_root.visible = true
	return is_first_person

func toggle_auto_sweep() -> bool:
	auto_sweep_enabled = not auto_sweep_enabled
	return auto_sweep_enabled

## Compresses 10 kg of raw collected dust into a physical low-gravity capsule
func compress_capsule() -> bool:
	if GameState.dust < 10.0:
		return false
	
	GameState.dust -= 10.0
	GameState.dust_changed.emit(GameState.dust, GameState.capacity)
	
	var capsule = CapsuleScene.instantiate() as RigidBody3D
	# Spawn in front of player
	var spawn_pos := global_position + (-global_transform.basis.z * 1.5) + Vector3(0, 0.8, 0)
	capsule.position = spawn_pos
	# Apply gentle forward toss
	capsule.linear_velocity = -global_transform.basis.z * 3.5 + Vector3(0, 1.5, 0)
	
	get_parent().add_child(capsule)
	capsule_compressed.emit()
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	return true

func _physics_process(delta: float) -> void:
	_handle_input_fallback()
	
	# Apply low lunar gravity
	if not is_on_floor():
		velocity.y -= gravity_strength * delta
	
	# Calculate move direction aligned with camera yaw
	var cam_forward := -camera_pivot.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()
	
	var cam_right := camera_pivot.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	
	var target_dir := (cam_right * move_input.x + cam_forward * -move_input.y)
	if target_dir.length() > 0.05:
		velocity.x = target_dir.x * walk_speed
		velocity.z = target_dir.z * walk_speed
		
		# Smoothly rotate visual body to face movement
		var look_rot := atan2(-target_dir.x, -target_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, look_rot, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed * 6.0 * delta)
	
	move_and_slide()
	
	# Process sweeping
	_process_sweeping(delta)

## Keyboard testing fallback for Mac desktop
func _handle_input_fallback() -> void:
	if move_input == Vector2.ZERO:
		var k_input := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			k_input.y += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			k_input.y -= 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			k_input.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			k_input.x += 1.0
		if k_input != Vector2.ZERO:
			move_input = k_input.normalized()
	
	# Spacebar for jetpack jump
	if Input.is_key_pressed(KEY_SPACE):
		apply_jetpack_thrust(get_physics_process_delta_time())

func apply_jetpack_thrust(delta: float) -> void:
	velocity.y = minf(velocity.y + jetpack_thrust * delta * 8.0, 5.0)
	if jetpack_particles:
		jetpack_particles.emitting = true

func _process_sweeping(delta: float) -> void:
	var active_sweep: bool = is_sweeping or auto_sweep_enabled
	
	if active_sweep and not GameState.is_storage_full:
		# Lower the broom
		broom_tool.rotation.x = lerpf(broom_tool.rotation.x, deg_to_rad(35.0), 10.0 * delta)
		
		sweep_cooldown -= delta
		if sweep_cooldown <= 0.0:
			sweep_cooldown = 0.06 # ~16 Hz for butter-smooth mobile cleaning
			
			if not terrain_ref:
				terrain_ref = get_parent().find_child("LunarTerrain3D", true, false)
			
			if terrain_ref:
				var sweep_pos := broom_brush.global_position
				var gained := terrain_ref.erase_dust_at_world_pos(sweep_pos, sweep_radius)
				if gained > 0.0:
					GameState.add_dust(gained)
					dust_collected.emit(gained)
					if dust_particles:
						dust_particles.emitting = true
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").play_scrub()
	else:
		# Raise the broom to idle
		broom_tool.rotation.x = lerpf(broom_tool.rotation.x, 0.0, 10.0 * delta)
		if dust_particles:
			dust_particles.emitting = false
