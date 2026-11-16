extends Control

signal settings_closed()

@onready var sound_toggle_btn: Button = $DimBackdrop/Panel/Margin/VBox/SoundToggleBtn
@onready var save_status_label: Label = $DimBackdrop/Panel/Margin/VBox/SaveStatusLabel

func _ready() -> void:
	GameState.sound_toggled.connect(_on_sound_toggled)
	_update_sound_button()

func open_settings() -> void:
	visible = true
	save_status_label.text = ""
	_update_sound_button()

func close_settings() -> void:
	visible = false
	settings_closed.emit()

func _update_sound_button() -> void:
	if sound_toggle_btn:
		if GameState.sound_enabled:
			sound_toggle_btn.text = "🔊 SOUND EFFECTS: ON"
		else:
			sound_toggle_btn.text = "🔇 SOUND EFFECTS: OFF"

func _on_sound_toggle_pressed() -> void:
	GameState.toggle_sound()
	_update_sound_button()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()

func _on_sound_toggled(_enabled: bool) -> void:
	_update_sound_button()

func _on_save_button_pressed() -> void:
	GameState.save_game()
	var surface = get_tree().root.find_child("LunarSurface", true, false)
	if surface and surface.has_method("save_dust_mask"):
		surface.save_dust_mask()
	save_status_label.text = "✓ Game & Dust Progress Saved!"
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()

func _on_reset_button_pressed() -> void:
	GameState.reset_all_progress()
	save_status_label.text = "All progress reset to zero!"
	close_settings()

func _on_main_menu_pressed() -> void:
	GameState.save_game()
	var surface = get_tree().root.find_child("LunarSurface", true, false)
	if surface and surface.has_method("save_dust_mask"):
		surface.save_dust_mask()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
