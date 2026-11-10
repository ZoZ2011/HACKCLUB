extends Control

## MAGICOPALYPSE main menu.
## Hanging signs swing on pendulum physics and drop in with a spring,
## clouds drift by, corner icon buttons mute sound / stub settings,
## and every interaction is backed by CC0 UI sounds (Kenney Interface Sounds).

const SFX_SELECT: Array[AudioStream] = [
	preload("res://assets/sfx/select_001.ogg"),
	preload("res://assets/sfx/select_002.ogg"),
]
const SFX_DROP: Array[AudioStream] = [
	preload("res://assets/sfx/drop_001.ogg"),
	preload("res://assets/sfx/drop_002.ogg"),
]
const SFX_PRESS := preload("res://assets/sfx/bong_001.ogg")
const SFX_CONFIRM := preload("res://assets/sfx/confirmation_001.ogg")
const SFX_TOGGLE := preload("res://assets/sfx/toggle_001.ogg")

const ICON_ON := preload("res://assets/icon_sound_on.png")
const ICON_ON_HOVER := preload("res://assets/icon_sound_on_hover.png")
const ICON_OFF := preload("res://assets/icon_sound_off.png")
const ICON_OFF_HOVER := preload("res://assets/icon_sound_off_hover.png")

const SFX_CREAKS: Array[AudioStream] = [
	preload("res://assets/sfx/creak1.ogg"),
	preload("res://assets/sfx/creak2.ogg"),
	preload("res://assets/sfx/creak3.ogg"),
]
const WORLD_WIDTH := 1200.0
const ENTRANCE_STEP := 0.14  ## seconds between signs starting their drop
const ENTRANCE_FALL := 1.0   ## seconds each sign's drop takes
const THUD_DELAY := 0.72     ## when the sign visually touches down

@onready var _signs: Array[HangingSign] = [
	%TitleSign, %StartSign, %ShopSign, %LevelsSign, %QuitSign,
]
@onready var _cloud_speeds := {
	%CloudA: 7.0,
	%CloudB: 16.0,
	%CloudC: 11.0,
	%CloudD: 24.0,
}

var _toast_tween: Tween


func _ready() -> void:
	_apply_mute_icon(GameState.muted)
	%SoundBtn.set_pressed_no_signal(GameState.muted)
	for btn: TextureButton in [%StartBtn, %ShopBtn, %LevelsBtn, %QuitBtn]:
		btn.mouse_entered.connect(_on_menu_btn_hovered.bind(btn))
		btn.button_down.connect(_on_menu_btn_down.bind(btn))
		btn.pressed.connect(_on_menu_btn_pressed.bind(btn))
	%SoundBtn.mouse_entered.connect(_play_hover_sfx)
	%SoundBtn.toggled.connect(_on_sound_toggled)
	%GearBtn.mouse_entered.connect(_play_hover_sfx)
	%GearBtn.pressed.connect(_on_gear_pressed)
	_drop_in_signs()


func _process(delta: float) -> void:
	for cloud: Sprite2D in _cloud_speeds:
		cloud.position.x += _cloud_speeds[cloud] * delta
		var width := 0.0
		if cloud.texture:
			width = cloud.texture.get_width()
		if cloud.position.x > WORLD_WIDTH + width:
			cloud.position.x = -width


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() \
				== DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if fullscreen
			else DisplayServer.WINDOW_MODE_FULLSCREEN)


# --- entrance -----------------------------------------------------------

func _drop_in_signs() -> void:
	for i in _signs.size():
		var sign_node := _signs[i]
		var final_y := sign_node.position.y
		sign_node.position.y = final_y - 950.0
		var tween := create_tween()
		tween.tween_interval(ENTRANCE_STEP * i)
		tween.tween_property(sign_node, "position:y", final_y, ENTRANCE_FALL) \
			.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		var thud := get_tree().create_timer(ENTRANCE_STEP * i + THUD_DELAY)
		thud.timeout.connect(_on_sign_landed.bind(sign_node, i))


func _on_sign_landed(sign_node: HangingSign, index: int) -> void:
	_play_sfx(%SfxLand, SFX_DROP[index % SFX_DROP.size()], randf_range(0.95, 1.05))
	sign_node.impulse(randf_range(0.10, 0.16) * (1.0 if randf() < 0.5 else -1.0))
	if randf() < 0.5:
		_play_sfx(%SfxCreak, SFX_CREAKS.pick_random(), randf_range(0.85, 1.2))


# --- menu buttons ---------------------------------------------------------

func _on_menu_btn_hovered(btn: TextureButton) -> void:
	_play_hover_sfx()
	_wobble(btn, randf_range(0.04, 0.07))


func _on_menu_btn_down(btn: TextureButton) -> void:
	_play_sfx(%SfxPress, SFX_PRESS, randf_range(0.96, 1.04))
	_wobble(btn, randf_range(0.12, 0.18))


func _wobble(btn: TextureButton, strength: float) -> void:
	var sign_node := btn.get_parent() as HangingSign
	if sign_node:
		var dir := 1.0 if randf() < 0.5 else -1.0
		sign_node.impulse(strength * dir)


func _on_menu_btn_pressed(btn: TextureButton) -> void:
	match btn.name:
		&"StartBtn":
			GameState.selected_level = GameState.unlocked
			_go_to("res://scenes/game.tscn")
		&"LevelsBtn":
			_go_to("res://scenes/level_select.tscn")
		&"ShopBtn":
			_show_toast("SHOP - COMING SOON")
		&"QuitBtn":
			_play_sfx(%SfxConfirm, SFX_CONFIRM)
			await get_tree().create_timer(0.25).timeout
			get_tree().quit()


## Plays the confirm sound on a node that survives the scene change, then swaps.
func _go_to(path: String) -> void:
	if not GameState.muted:
		var p := AudioStreamPlayer.new()
		p.stream = SFX_CONFIRM
		p.volume_db = -5.0
		p.finished.connect(p.queue_free)
		get_tree().root.add_child(p)
		p.play()
	get_tree().change_scene_to_file(path)


func _show_toast(message: String) -> void:
	%Toast.text = message
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	%Toast.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(%Toast, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(%Toast, "modulate:a", 0.0, 0.5)


# --- corner buttons -------------------------------------------------------

func _on_gear_pressed() -> void:
	_show_toast("SETTINGS - COMING SOON")
	for sign_node in _signs:
		sign_node.impulse(randf_range(-0.09, 0.09))


func _on_sound_toggled(muted: bool) -> void:
	_apply_mute_icon(muted)
	GameState.set_muted(muted)
	if not muted:
		_play_sfx(%SfxToggle, SFX_TOGGLE, randf_range(0.98, 1.02))


func _apply_mute_icon(muted: bool) -> void:
	%SoundBtn.texture_normal = ICON_OFF if muted else ICON_ON
	%SoundBtn.texture_hover = ICON_OFF_HOVER if muted else ICON_ON_HOVER


# --- audio helpers --------------------------------------------------------

func _play_hover_sfx() -> void:
	_play_sfx(%SfxHover, SFX_SELECT.pick_random(), randf_range(0.92, 1.1))


func _play_sfx(player: AudioStreamPlayer, stream: AudioStream, pitch := 1.0) -> void:
	if GameState.muted:
		return
	player.stream = stream
	player.pitch_scale = pitch
	player.play()
