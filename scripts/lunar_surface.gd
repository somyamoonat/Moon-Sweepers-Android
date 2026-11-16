class_name LunarSurface
extends Control

signal clean_percentage_changed(percentage: float)
signal sector_cleaned()
signal dust_scrubbed(amount: float)
signal scrub_blocked()

@export var brush_size: float = 48.0
@export var image_resolution: int = 256
@export var total_sector_dust: float = 350.0
@export var can_scrub: bool = true

var current_dust_color := Color(0.48, 0.44, 0.38, 1.0)
const ERASED_COLOR := Color(0.0, 0.0, 0.0, 0.0)

@onready var dust_rect: TextureRect = $DustLayer
@onready var bedrock: Control = $Bedrock
@onready var bedrock_base: ColorRect = $Bedrock/CleanBaseColor
@onready var bots_container: Control = $BotsContainer

var dust_image: Image
var dust_texture: ImageTexture
var total_pixels: int = 0
var cleaned_pixels: int = 0
var is_scrubbing: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO
var is_completed: bool = false

const BotScene = preload("res://scenes/cleaning_bot.tscn")

func _ready() -> void:
	total_pixels = image_resolution * image_resolution
	apply_theme(GameState.get_current_theme())
	_init_or_load_dust_layer()

func apply_theme(theme: Dictionary) -> void:
	current_dust_color = theme.get("dust_color", Color(0.48, 0.44, 0.38, 1.0))
	total_sector_dust = GameState.get_sector_total_dust()
	
	if bedrock_base:
		bedrock_base.color = theme.get("bedrock_color", Color(0.141, 0.157, 0.204, 1.0))
	
	# Update craters
	var crater_color: Color = theme.get("crater_color", Color(0.082, 0.090, 0.118, 1.0))
	for crater_name in ["Crater1", "Crater2", "Crater3"]:
		var crater_node = bedrock.get_node_or_null(crater_name)
		if crater_node and crater_node is Panel:
			var sb := crater_node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if sb:
				sb.bg_color = crater_color
				crater_node.add_theme_stylebox_override("panel", sb)

func _init_or_load_dust_layer() -> void:
	cleaned_pixels = 0
	is_completed = false
	
	# Check if saved dust mask exists
	if FileAccess.file_exists(GameState.DUST_MASK_PATH):
		dust_image = Image.load_from_file(GameState.DUST_MASK_PATH)
		if dust_image and dust_image.get_width() == image_resolution:
			# Count already cleaned pixels
			for y in range(image_resolution):
				for x in range(image_resolution):
					if dust_image.get_pixel(x, y).a <= 0.1:
						cleaned_pixels += 1
		else:
			_create_fresh_dust()
	else:
		_create_fresh_dust()
	
	dust_texture = ImageTexture.create_from_image(dust_image)
	dust_rect.texture = dust_texture
	dust_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	var pct: float = get_clean_percentage()
	clean_percentage_changed.emit(pct)
	if pct >= 95.0:
		is_completed = true
		sector_cleaned.emit()

func _create_fresh_dust() -> void:
	dust_image = Image.create(image_resolution, image_resolution, false, Image.FORMAT_RGBA8)
	dust_image.fill(current_dust_color)
	cleaned_pixels = 0

func save_dust_mask() -> void:
	if dust_image:
		dust_image.save_png(GameState.DUST_MASK_PATH)

func reset_surface() -> void:
	if FileAccess.file_exists(GameState.DUST_MASK_PATH):
		DirAccess.remove_absolute(GameState.DUST_MASK_PATH)
	_create_fresh_dust()
	dust_texture.update(dust_image)
	is_completed = false
	clean_percentage_changed.emit(0.0)

func update_bots_count(target_count: int) -> void:
	if not bots_container:
		return
	
	var clamped_count: int = clampi(target_count, 0, GameState.upgrades["cleaning_bot"].max_level)
	var current_bots := bots_container.get_children()
	
	while current_bots.size() > clamped_count:
		var bot = current_bots.pop_back()
		bot.queue_free()
	
	while current_bots.size() < clamped_count:
		var new_bot = BotScene.instantiate()
		bots_container.add_child(new_bot)
		current_bots.append(new_bot)

## Called by autonomous cleaning bots to sweep an area
func bot_scrub_at(local_pos: Vector2, radius: float) -> void:
	if not can_scrub or is_completed:
		return
	_apply_brush_erase(local_pos, radius)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not can_scrub:
					scrub_blocked.emit()
					return
				is_scrubbing = true
				last_touch_pos = event.position
				_scrub_at(event.position)
			else:
				is_scrubbing = false
	elif event is InputEventScreenTouch:
		if event.pressed:
			if not can_scrub:
				scrub_blocked.emit()
				return
			is_scrubbing = true
			last_touch_pos = event.position
			_scrub_at(event.position)
		else:
			is_scrubbing = false
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_scrubbing:
			if not can_scrub:
				is_scrubbing = false
				scrub_blocked.emit()
				return
			_scrub_line(last_touch_pos, event.position)
			last_touch_pos = event.position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		is_scrubbing = false
	elif event is InputEventScreenTouch and not event.pressed:
		is_scrubbing = false

func _scrub_line(from: Vector2, to: Vector2) -> void:
	var distance: float = from.distance_to(to)
	var step_size: float = maxf(4.0, brush_size * 0.35)
	
	if distance <= step_size:
		_scrub_at(to)
		return
	
	var steps: int = int(ceil(distance / step_size))
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		_scrub_at(from.lerp(to, t))

func _scrub_at(local_pos: Vector2) -> void:
	_apply_brush_erase(local_pos, brush_size)

func _apply_brush_erase(local_pos: Vector2, radius_px: float) -> void:
	if size.x <= 0 or size.y <= 0 or not can_scrub:
		return
	
	var center_x: float = (local_pos.x / size.x) * float(image_resolution)
	var center_y: float = (local_pos.y / size.y) * float(image_resolution)
	var radius_in_img: float = (radius_px / size.x) * float(image_resolution)
	
	var r_ceil: int = int(ceil(radius_in_img))
	var r_sq: float = radius_in_img * radius_in_img
	
	var min_x: int = clampi(int(center_x) - r_ceil, 0, image_resolution - 1)
	var max_x: int = clampi(int(center_x) + r_ceil, 0, image_resolution - 1)
	var min_y: int = clampi(int(center_y) - r_ceil, 0, image_resolution - 1)
	var max_y: int = clampi(int(center_y) + r_ceil, 0, image_resolution - 1)
	
	var pixels_erased_this_stamp: int = 0
	
	for y in range(min_y, max_y + 1):
		var dy: float = float(y) - center_y
		var dy_sq: float = dy * dy
		for x in range(min_x, max_x + 1):
			var dx: float = float(x) - center_x
			if (dx * dx + dy_sq) <= r_sq:
				if dust_image.get_pixel(x, y).a > 0.1:
					dust_image.set_pixel(x, y, ERASED_COLOR)
					cleaned_pixels += 1
					pixels_erased_this_stamp += 1
	
	if pixels_erased_this_stamp > 0:
		dust_texture.update(dust_image)
		var percentage: float = (float(cleaned_pixels) / float(total_pixels)) * 100.0
		clean_percentage_changed.emit(percentage)
		
		var dust_per_pixel: float = total_sector_dust / float(total_pixels)
		var dust_gained: float = float(pixels_erased_this_stamp) * dust_per_pixel
		dust_scrubbed.emit(dust_gained)
		
		# Stage 7 threshold: 95% clean completes sector!
		if percentage >= 95.0 and not is_completed:
			is_completed = true
			sector_cleaned.emit()

func get_clean_percentage() -> float:
	if total_pixels == 0:
		return 0.0
	return (float(cleaned_pixels) / float(total_pixels)) * 100.0

func set_brush_size(new_size: float) -> void:
	brush_size = maxf(10.0, new_size)
