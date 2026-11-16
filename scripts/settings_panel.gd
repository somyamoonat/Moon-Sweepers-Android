extends Control

signal settings_closed()

@onready var save_status_label: Label = $DimBackdrop/Panel/Margin/VBox/SaveStatusLabel

func open_settings() -> void:
	visible = true
	save_status_label.text = ""

func close_settings() -> void:
	visible = false
	settings_closed.emit()

func _on_save_button_pressed() -> void:
	GameState.save_game()
	# Tell surface to save mask
	var surface = get_tree().root.find_child("LunarSurface", true, false)
	if surface and surface.has_method("save_dust_mask"):
		surface.save_dust_mask()
	save_status_label.text = "✓ Game & Dust Progress Saved!"

func _on_reset_button_pressed() -> void:
	GameState.reset_all_progress()
	save_status_label.text = "All progress reset to zero!"
	close_settings()
