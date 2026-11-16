class_name LunarTerrain3D
extends Node3D

## 3D Lunar Terrain with real-time GPU dirt masking.
## Erases dust under the player's broom without spawning thousands of nodes.

signal clean_percentage_changed(percentage: float)
signal sector_cleaned()
signal dust_scrubbed(amount_kg: float)

@export var terrain_size: Vector2 = Vector2(80.0, 80.0) ## Playable area in meters
@export var image_resolution: int = 256
@export var total_sector_dust: float = 400.0

var dust_image: Image
var dust_texture: ImageTexture
var total_pixels: int = 0
var cleaned_pixels: int = 0
var is_completed: bool = false

@onready var terrain_mesh: MeshInstance3D = $GroundMesh

func _ready() -> void:
	total_pixels = image_resolution * image_resolution
	_init_dust_mask()
	apply_theme(GameState.get_current_theme())

func _init_dust_mask() -> void:
	cleaned_pixels = 0
	is_completed = false
	
	# Create single-channel or RGBA8 image for dust density
	dust_image = Image.create(image_resolution, image_resolution, false, Image.FORMAT_RGBA8)
	dust_image.fill(Color(1.0, 1.0, 1.0, 1.0)) # 1.0 = 100% dust
	
	dust_texture = ImageTexture.create_from_image(dust_image)
	
	# Assign to terrain shader material
	var mat := terrain_mesh.get_active_material(0) as ShaderMaterial
	if mat:
		mat.set_shader_parameter("dust_mask", dust_texture)
	
	clean_percentage_changed.emit(0.0)

func apply_theme(theme: Dictionary) -> void:
	total_sector_dust = GameState.get_sector_total_dust()
	var mat := terrain_mesh.get_active_material(0) as ShaderMaterial
	if mat:
		mat.set_shader_parameter("dust_color", theme.get("dust_color", Color(0.48, 0.44, 0.38)))
		mat.set_shader_parameter("clean_color", theme.get("bedrock_color", Color(0.13, 0.14, 0.18)))

## Called when player's broom sweeps at a 3D world coordinate
func erase_dust_at_world_pos(world_pos: Vector3, radius_meters: float) -> float:
	if is_completed or GameState.is_storage_full:
		return 0.0
	
	var half_w := terrain_size.x * 0.5
	var half_h := terrain_size.y * 0.5
	
	# Check if inside terrain bounds
	if absf(world_pos.x) > half_w or absf(world_pos.z) > half_h:
		return 0.0
	
	# Map world (-half_w..+half_w) to UV (0..1)
	var u := (world_pos.x + half_w) / terrain_size.x
	var v := (world_pos.z + half_h) / terrain_size.y
	
	var center_x := u * float(image_resolution)
	var center_y := v * float(image_resolution)
	var radius_in_img := (radius_meters / terrain_size.x) * float(image_resolution)
	
	var r_ceil := int(ceil(radius_in_img))
	var r_sq := radius_in_img * radius_in_img
	
	var min_x := clampi(int(center_x) - r_ceil, 0, image_resolution - 1)
	var max_x := clampi(int(center_x) + r_ceil, 0, image_resolution - 1)
	var min_y := clampi(int(center_y) - r_ceil, 0, image_resolution - 1)
	var max_y := clampi(int(center_y) + r_ceil, 0, image_resolution - 1)
	
	var pixels_erased: int = 0
	
	for y in range(min_y, max_y + 1):
		var dy := float(y) - center_y
		var dy_sq := dy * dy
		for x in range(min_x, max_x + 1):
			var dx := float(x) - center_x
			if (dx * dx + dy_sq) <= r_sq:
				if dust_image.get_pixel(x, y).r > 0.1:
					dust_image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
					cleaned_pixels += 1
					pixels_erased += 1
	
	if pixels_erased > 0:
		dust_texture.update(dust_image)
		var pct := (float(cleaned_pixels) / float(total_pixels)) * 100.0
		clean_percentage_changed.emit(pct)
		
		var kg_per_pixel := total_sector_dust / float(total_pixels)
		var kg_gained := float(pixels_erased) * kg_per_pixel
		dust_scrubbed.emit(kg_gained)
		
		if pct >= 95.0 and not is_completed:
			is_completed = true
			sector_cleaned.emit()
		
		return kg_gained
	
	return 0.0

func reset_terrain() -> void:
	_init_dust_mask()
