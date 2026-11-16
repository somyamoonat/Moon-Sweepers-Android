extends Control

const LunarSurfaceScript = preload("res://scripts/lunar_surface.gd")

@onready var lunar_surface = $LunarSurface
@onready var clean_label: Label = $HUD/TopBar/CleanPercentageLabel
@onready var progress_bar: ProgressBar = $HUD/TopBar/ProgressBar
@onready var brush_label: Label = $HUD/Controls/BrushControls/BrushSizeLabel
@onready var completion_banner: Panel = $HUD/CompletionBanner

func _ready() -> void:
	completion_banner.visible = false
	lunar_surface.clean_percentage_changed.connect(_on_clean_percentage_changed)
	lunar_surface.sector_cleaned.connect(_on_sector_cleaned)
	_update_brush_label()

func _on_clean_percentage_changed(percentage: float) -> void:
	clean_label.text = "Clean: %4.1f%%" % percentage
	progress_bar.value = percentage

func _on_sector_cleaned() -> void:
	completion_banner.visible = true

func _on_reset_button_pressed() -> void:
	completion_banner.visible = false
	lunar_surface.reset_surface()

func _on_brush_smaller_pressed() -> void:
	lunar_surface.set_brush_size(lunar_surface.brush_size - 10.0)
	_update_brush_label()

func _on_brush_larger_pressed() -> void:
	lunar_surface.set_brush_size(lunar_surface.brush_size + 10.0)
	_update_brush_label()

func _update_brush_label() -> void:
	if brush_label:
		brush_label.text = "Brush Size: %d px" % int(lunar_surface.brush_size)
