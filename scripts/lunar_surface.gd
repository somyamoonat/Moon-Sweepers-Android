class_name LunarSurface
extends Control

## Emitted whenever the clean percentage changes.
signal clean_percentage_changed(percentage: float)

## Emitted when the sector reaches 100% (or completion threshold).
signal sector_cleaned()

@export var brush_size: float = 48.0 ## Brush radius in screen pixels
@export var image_resolution: int = 256 ## Internal resolution for dust layer (fast & lightweight)

const DUST_COLOR := Color(0.48, 0.44, 0.38, 1.0) # Dusty lunar regolith brown-gray
const ERASED_COLOR := Color(0.0, 0.0, 0.0, 0.0) # Fully transparent

@onready var dust_rect: TextureRect = $DustLayer
@onready var bedrock: Control = $Bedrock

var dust_image: Image
var dust_texture: ImageTexture
var total_pixels: int = 0
var cleaned_pixels: int = 0
var is_scrubbing: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO
var is_completed: bool = false

func _ready() -> void:
	_init_dust_layer()

func _init_dust_layer() -> void:
	total_pixels = image_resolution * image_resolution
	cleaned_pixels = 0
	is_completed = false
	
	# Create an uncompressed RGBA8 image for fast pixel manipulation
	dust_image = Image.create(image_resolution, image_resolution, false, Image.FORMAT_RGBA8)
	dust_image.fill(DUST_COLOR)
	
	# Create the GPU texture and assign it to the TextureRect
	dust_texture = ImageTexture.create_from_image(dust_image)
	dust_rect.texture = dust_texture
	dust_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	clean_percentage_changed.emit(0.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_scrubbing = true
				last_touch_pos = event.position
				_scrub_at(event.position)
			else:
				is_scrubbing = false
	elif event is InputEventScreenTouch:
		if event.pressed:
			is_scrubbing = true
			last_touch_pos = event.position
			_scrub_at(event.position)
		else:
			is_scrubbing = false
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_scrubbing:
			_scrub_line(last_touch_pos, event.position)
			last_touch_pos = event.position

func _unhandled_input(event: InputEvent) -> void:
	# Safely handle touch release outside this specific control
	if event is InputEventMouseButton and not event.pressed:
		is_scrubbing = false
	elif event is InputEventScreenTouch and not event.pressed:
		is_scrubbing = false

## Scrubs along a line between two points to prevent gaps during fast finger swipes.
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

## Erases dust in a circle at the given local screen coordinate.
func _scrub_at(local_pos: Vector2) -> void:
	if size.x <= 0 or size.y <= 0:
		return
	
	# Map screen coordinates into dust image coordinates
	var center_x: float = (local_pos.x / size.x) * float(image_resolution)
	var center_y: float = (local_pos.y / size.y) * float(image_resolution)
	var radius_in_img: float = (brush_size / size.x) * float(image_resolution)
	
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
				# Check if pixel has dust before erasing
				if dust_image.get_pixel(x, y).a > 0.1:
					dust_image.set_pixel(x, y, ERASED_COLOR)
					cleaned_pixels += 1
					pixels_erased_this_stamp += 1
	
	if pixels_erased_this_stamp > 0:
		dust_texture.update(dust_image)
		var percentage: float = (float(cleaned_pixels) / float(total_pixels)) * 100.0
		clean_percentage_changed.emit(percentage)
		
		if percentage >= 98.0 and not is_completed:
			is_completed = true
			sector_cleaned.emit()

## Public helper to retrieve current cleanliness percentage.
func get_clean_percentage() -> float:
	if total_pixels == 0:
		return 0.0
	return (float(cleaned_pixels) / float(total_pixels)) * 100.0

## Allows upgrade shop to modify brush size later.
func set_brush_size(new_size: float) -> void:
	brush_size = maxf(10.0, new_size)

## Resets the dust layer to 100% dirty.
func reset_surface() -> void:
	_init_dust_layer()
