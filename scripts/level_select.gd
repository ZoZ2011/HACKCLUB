extends Control

## LEVELS screen: pick any unlocked level. Locked levels show LOCKED on a
## dimmed wooden plaque. Progress comes from the GameState autoload.

const SFX_SELECT: Array[AudioStream] = [
	preload("res://assets/sfx/select_001.ogg"),
	preload("res://assets/sfx/select_002.ogg"),
]
const SFX_PRESS := preload("res://assets/sfx/bong_001.ogg")
const SFX_CONFIRM := preload("res://assets/sfx/confirmation_001.ogg")

@onready var _plaques: Array[TextureButton] = [%L1, %L2, %L3, %L4, %L5, %L6]
@onready var _labels: Array[Label] = [
	%L1Label, %L2Label, %L3Label, %L4Label, %L5Label, %L6Label,
]


func _ready() -> void:
	for i in _plaques.size():
		var btn := _plaques[i]
		btn.pressed.connect(_on_plaque_pressed.bind(i + 1))
		btn.mouse_entered.connect(_on_plaque_hovered)
	%BackBtn.pressed.connect(_on_back_pressed)
	%BackBtn.mouse_entered.connect(_play_hover)
	_refresh()


func _refresh() -> void:
	for i in _plaques.size():
		var unlocked := (i + 1) <= GameState.unlocked
		var btn := _plaques[i]
		var label := _labels[i]
		btn.disabled = not unlocked
		btn.modulate = Color.WHITE if unlocked else Color(0.6, 0.53, 0.48)
		if unlocked:
			label.text = str(i + 1)
			label.add_theme_font_size_override("font_size", 48)
		else:
			label.text = "LOCKED"
			label.add_theme_font_size_override("font_size", 22)


func _on_plaque_pressed(number: int) -> void:
	_play(%SfxPress, SFX_PRESS, randf_range(0.96, 1.04))
	GameState.selected_level = number
	var p := AudioStreamPlayer.new()
	p.stream = SFX_CONFIRM
	p.volume_db = -5.0
	p.finished.connect(p.queue_free)
	get_tree().root.add_child(p)
	p.play()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_plaque_hovered() -> void:
	_play_hover()


func _on_back_pressed() -> void:
	_play(%SfxPress, SFX_PRESS, randf_range(0.96, 1.04))
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _play_hover() -> void:
	_play(%SfxHover, SFX_SELECT.pick_random(), randf_range(0.92, 1.1))


func _play(player: AudioStreamPlayer, stream: AudioStream, pitch := 1.0) -> void:
	if GameState.muted:
		return
	player.stream = stream
	player.pitch_scale = pitch
	player.play()

