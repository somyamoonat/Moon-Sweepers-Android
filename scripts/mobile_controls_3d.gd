class_name MobileControls3D
extends Control

## Virtual Floating Joystick and Action Buttons for Mobile 3D Gameplay (Landscape Widescreen).

@export var player_path: NodePath
var player: Player3D

# Virtual Joystick Variables
var joystick_active: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var joystick_touch_index: int = -1
var joystick_vector: Vector2 = Vector2.ZERO
const JOYSTICK_MAX_RADIUS: float = 120.0

# Camera Look Touch Variables
var camera_touch_index: int = -1

@onready var joystick_base: Control = $JoystickBase
@onready var joystick_knob: Control = $JoystickBase/Knob
@onready var sweep_btn: Button = $ActionButtons/SweepToggleBtn
@onready var lock_btn: Button = $ActionButtons/AngleLockBtn
@onready var jetpack_btn: Button = $ActionButtons/JetpackBtn
@onready var compress_btn: Button = $ActionButtons/CompressBtn
@onready var view_btn: Button = $ActionButtons/ViewToggleBtn

var is_jetpack_holding: bool = false

func _ready() -> void:
	if has_node(player_path):
		player = get_node(player_path)
	joystick_base.visible = false

func _process(delta: float) -> void:
	if is_jetpack_holding and player:
		player.apply_jetpack_thrust(delta)
	
	if compress_btn:
		compress_btn.disabled = (GameState.dust < 10.0)

func _input(event: InputEvent) -> void:
	if not player:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			# Left 45% of screen = Virtual Joystick
			if event.position.x < size.x * 0.45 and joystick_touch_index == -1:
				joystick_touch_index = event.index
				joystick_active = true
				joystick_center = event.position
				joystick_base.global_position = joystick_center - (joystick_base.size * 0.5)
				joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5)
				joystick_base.visible = true
			# Right 55% of screen = Camera look
			elif event.position.x >= size.x * 0.45 and camera_touch_index == -1:
				camera_touch_index = event.index
		else:
			if event.index == joystick_touch_index:
				joystick_touch_index = -1
				joystick_active = false
				joystick_vector = Vector2.ZERO
				joystick_base.visible = false
				player.set_move_vector(Vector2.ZERO)
			elif event.index == camera_touch_index:
				camera_touch_index = -1
	
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index and joystick_active:
			var offset: Vector2 = event.position - joystick_center
			if offset.length() > JOYSTICK_MAX_RADIUS:
				offset = offset.normalized() * JOYSTICK_MAX_RADIUS
			
			joystick_knob.position = (joystick_base.size * 0.5) - (joystick_knob.size * 0.5) + offset
			joystick_vector = offset / JOYSTICK_MAX_RADIUS
			player.set_move_vector(joystick_vector)
		
		elif event.index == camera_touch_index:
			player.rotate_camera(event.relative)
	
	# Desktop testing fallback
	elif event is InputEventMouseButton and (OS.has_feature("editor") or not OS.has_feature("mobile")):
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				camera_touch_index = 999
			else:
				camera_touch_index = -1
	elif event is InputEventMouseMotion and camera_touch_index == 999:
		player.rotate_camera(event.relative)

func _on_sweep_toggle_pressed() -> void:
	if player:
		var active := player.toggle_auto_sweep()
		sweep_btn.text = "🧹 SWEEP: ON" if active else "🧹 SWEEP: OFF"
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()

func _on_angle_lock_pressed() -> void:
	if player:
		var locked := player.toggle_angle_lock()
		lock_btn.text = "🔒 L-LOCK: ON" if locked else "🔓 L-LOCK: OFF"
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()

func _on_jetpack_down() -> void:
	is_jetpack_holding = true

func _on_jetpack_up() -> void:
	is_jetpack_holding = false

func _on_compress_pressed() -> void:
	if player:
		player.compress_capsule()

func _on_view_toggle_pressed() -> void:
	if player:
		var is_1p := player.toggle_camera_view()
		view_btn.text = "👁️ 1P" if is_1p else "👁️ 3P"
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
