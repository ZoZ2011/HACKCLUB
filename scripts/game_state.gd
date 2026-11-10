extends Node

## Autoload singleton: carries progress, mute state and the selected level
## between the menu, the level select and the game.

const SAVE_PATH := "user://save.cfg"

const LEVEL_COUNT := 6

var selected_level := 1
var unlocked := 1
var muted := false


func _ready() -> void:
	load_progress()
	load_settings()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, LEVEL_COUNT)


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)


func mark_cleared(level: int) -> void:
	unlocked = clampi(maxi(unlocked, level + 1), 1, LEVEL_COUNT)
	save_progress()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	muted = bool(cfg.get_value("audio", "muted", false))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", muted)
	cfg.save(SAVE_PATH)


func set_muted(value: bool) -> void:
	muted = value
	save_settings()
