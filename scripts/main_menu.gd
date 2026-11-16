extends Control

## Main Menu Controller for Moon Sweepers

@onready var mission_label: Label = $HUD/CenterBox/SectorPill/Margin/MissionLabel
@onready var settings_panel = $SettingsPanel
@onready var how_to_play_panel: Panel = $HowToPlayPanel

func _ready() -> void:
	settings_panel.visible = false
	how_to_play_panel.visible = false
	_update_mission_info()

func _update_mission_info() -> void:
	var theme := GameState.get_current_theme()
	mission_label.text = "Sector %02d: %s  •  Sectors Cleared: %d" % [
		GameState.current_sector,
		theme.get("name", "Lunar Region"),
		GameState.sectors_cleared
	]

func _on_play_button_pressed() -> void:
	_animate_button_punch($HUD/CenterBox/PlayBtn)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	# Transition into the main cleaning mission
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_button_pressed() -> void:
	_animate_button_punch($HUD/CenterBox/SettingsBtn)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	settings_panel.open_settings()

func _on_how_to_play_button_pressed() -> void:
	_animate_button_punch($HUD/CenterBox/HowToPlayBtn)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()
	how_to_play_panel.visible = true

func _on_close_help_pressed() -> void:
	how_to_play_panel.visible = false
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_click()

func _animate_button_punch(button: Button) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.08)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.08)
