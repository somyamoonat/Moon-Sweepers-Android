extends Node

## Central Audio Manager
## Handles all sound effects, volume checks, and placeholder audio hooks.
## Drop your own .wav or .ogg files into res://assets/sounds/ anytime!

var scrub_player: AudioStreamPlayer
var sell_player: AudioStreamPlayer
var upgrade_player: AudioStreamPlayer
var fanfare_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

var last_scrub_sound_time: float = 0.0

func _ready() -> void:
	_init_players()

func _init_players() -> void:
	scrub_player = _create_player("ScrubPlayer")
	sell_player = _create_player("SellPlayer")
	upgrade_player = _create_player("UpgradePlayer")
	fanfare_player = _create_player("FanfarePlayer")
	click_player = _create_player("ClickPlayer")

func _create_player(pname: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = pname
	add_child(player)
	return player

## Plays a gentle scrub puff sound (rate limited to avoid audio spamming on fast swipes)
func play_scrub() -> void:
	if not GameState.sound_enabled:
		return
	
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_scrub_sound_time < 0.14:
		return
	last_scrub_sound_time = now
	
	# Hook for res://assets/sounds/scrub.wav
	_play_or_log(scrub_player, "res://assets/sounds/scrub.wav", "Scrub SFX")

## Plays the rewarding cash register / chime sound when selling dust
func play_sell() -> void:
	if not GameState.sound_enabled:
		return
	_play_or_log(sell_player, "res://assets/sounds/sell.wav", "Sell SFX")

## Plays the level-up power sound when buying an upgrade in the shop
func play_upgrade() -> void:
	if not GameState.sound_enabled:
		return
	_play_or_log(upgrade_player, "res://assets/sounds/upgrade.wav", "Upgrade SFX")

## Plays celebration fanfare when a sector reaches 95%+ completion
func play_sector_complete() -> void:
	if not GameState.sound_enabled:
		return
	_play_or_log(fanfare_player, "res://assets/sounds/complete.wav", "Sector Complete Fanfare SFX")

## Plays a subtle click sound for buttons and UI interactions
func play_click() -> void:
	if not GameState.sound_enabled:
		return
	_play_or_log(click_player, "res://assets/sounds/click.wav", "UI Click SFX")

func _play_or_log(player: AudioStreamPlayer, sound_path: String, debug_label: String) -> void:
	if FileAccess.file_exists(sound_path):
		if player.stream == null or player.stream.resource_path != sound_path:
			player.stream = load(sound_path)
		player.play()
	else:
		# Placeholder sound hook notice:
		# print("[Audio Hook] %s (To add sound, place file at: %s)" % [debug_label, sound_path])
		pass
