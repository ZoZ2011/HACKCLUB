extends Node2D

## Canyon Defense: the last mage guards the gate against the monster apocalypse.
## Aim with the mouse, click / hold to cast magic bolts, survive every wave.

const FireballScene := preload("res://scenes/fireball.tscn")
const EnemyScene := preload("res://scenes/enemy.tscn")
const COIN_TEXTURE := preload("res://assets/game/coin_f0.png")
const HEART_FULL := preload("res://assets/game/heart_full.png")
const HEART_EMPTY := preload("res://assets/game/heart_empty.png")
const SFX_CAST := preload("res://assets/sfx/knifeSlice.ogg")
const SFX_HIT := preload("res://assets/sfx/chop.ogg")
const SFX_HURT := preload("res://assets/sfx/bong_001.ogg")
const SFX_COIN := preload("res://assets/sfx/handleCoins.ogg")
const SFX_CLEAR := preload("res://assets/sfx/confirmation_001.ogg")
const SFX_OVER := preload("res://assets/sfx/drop_001.ogg")

## Each level: enemy speed multiplier + waves of [type, count, interval seconds].
const LEVELS := [
	{"speed": 1.0, "waves": [["imp", 6, 1.3]]},
	{"speed": 1.05, "waves": [["imp", 8, 1.1], ["wogol", 4, 1.2]]},
	{"speed": 1.12, "waves": [["imp", 8, 1.0], ["pumpkin", 6, 0.9], ["wogol", 6, 1.0]]},
	{"speed": 1.2, "waves": [["wogol", 8, 0.9], ["imp", 10, 0.8], ["chort", 4, 1.4], ["pumpkin", 8, 0.8]]},
	{"speed": 1.3, "waves": [["imp", 12, 0.7], ["chort", 6, 1.2], ["pumpkin", 10, 0.7], ["wogol", 8, 0.8], ["chort", 4, 1.1]]},
	{"speed": 1.4, "waves": [["pumpkin", 12, 0.6], ["imp", 14, 0.55], ["chort", 8, 1.0], ["wogol", 10, 0.7], ["necromancer", 1, 1.0], ["pumpkin", 10, 0.6]]},
]
const MAX_HEARTS := 3
const FIRE_COOLDOWN := 0.26
const FIREBALL_SPEED := 680.0

enum State { ANNOUNCING, FIGHTING, CLEAR, OVER }

var level := 1
var speed_mult := 1.0
var hearts := MAX_HEARTS
var souls := 0
var state := State.ANNOUNCING

var _wave_idx := -1
var _spawn_left := 0
var _spawn_timer := 0.0
var _spawn_interval := 1.0
var _spawn_type := "imp"
var _alive := 0
var _cooldown := 0.0

@onready var _world: Node2D = $World
@onready var _mage: AnimatedSprite2D = $World/Mage
@onready var _muzzle: Marker2D = $World/Muzzle
@onready var _enemies: Node2D = $World/Enemies
@onready var _projectiles: Node2D = $World/Projectiles
@onready var _clouds := {
	%CloudA: 7.0,
	%CloudB: 16.0,
	%CloudC: 11.0,
	%CloudD: 24.0,
}

func _ready() -> void:
	level = clampi(GameState.selected_level, 1, GameState.LEVEL_COUNT)
	speed_mult = LEVELS[level - 1].speed
	%LevelLabel.text = "LEVEL %d" % level
	%SoulsLabel.text = "SOULS 0"
	_update_hearts()
	%NextBtn.pressed.connect(_on_next_pressed)
	%RetryBtn.pressed.connect(_on_retry_pressed)
	%MenuBtn.pressed.connect(_on_menu_pressed)
	%Retry2Btn.pressed.connect(_on_retry_pressed)
	%Menu2Btn.pressed.connect(_on_menu_pressed)
	%Announce.text = "LEVEL %d" % level
	_announce_in()
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if state == State.ANNOUNCING:
			state = State.FIGHTING
			_next_wave())


func _process(delta: float) -> void:
	for cloud: Sprite2D in _clouds:
		cloud.position.x += _clouds[cloud] * delta
		var width := 0.0
		if cloud.texture:
			width = cloud.texture.get_width()
		if cloud.position.x > 1200.0 + width:
			cloud.position.x = -width
	if state == State.FIGHTING:
		_spawn_tick(delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	var shooting := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if shooting and _cooldown == 0.0 and (state == State.FIGHTING or state == State.ANNOUNCING):
		_cast()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# --- waves ----------------------------------------------------------------

func _spawn_tick(delta: float) -> void:
	if _spawn_left > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_enemy()
			_spawn_timer = _spawn_interval
	elif _alive == 0:
		_next_wave()


func _next_wave() -> void:
	_wave_idx += 1
	var waves: Array = LEVELS[level - 1].waves
	if _wave_idx >= waves.size():
		_level_cleared()
		return
	var w: Array = waves[_wave_idx]
	_spawn_type = w[0]
	_spawn_left = w[1]
	_spawn_interval = w[2]
	_spawn_timer = 0.6


func _spawn_enemy() -> void:
	var enemy := EnemyScene.instantiate()
	enemy.type = _spawn_type
	enemy.speed_mult = speed_mult
	enemy.position = Vector2(1270.0, randf_range(140.0, 460.0))
	enemy.died.connect(_on_enemy_died)
	enemy.reached_gate.connect(_on_enemy_gate)
	_enemies.add_child(enemy)
	_alive += 1
	_spawn_left -= 1


func _on_enemy_died(soul_amount: int, pos: Vector2) -> void:
	_alive -= 1
	_play(%SfxHit, SFX_HIT, randf_range(0.9, 1.15))
	_spawn_soul(pos, soul_amount)


func _on_enemy_gate() -> void:
	_alive -= 1
	_lose_heart()


# --- player ----------------------------------------------------------------

func _cast() -> void:
	_cooldown = FIRE_COOLDOWN
	var dir := (get_global_mouse_position() - _muzzle.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var bolt := FireballScene.instantiate()
	bolt.velocity = dir * FIREBALL_SPEED
	bolt.rotation = dir.angle()
	bolt.position = _muzzle.global_position
	_projectiles.add_child(bolt)
	_mage.play("hit")
	get_tree().create_timer(0.14).timeout.connect(func() -> void:
		if state != State.OVER:
			_mage.play("idle"))
	_play(%SfxCast, SFX_CAST, randf_range(0.85, 1.1))


func _lose_heart() -> void:
	if state == State.OVER:
		return
	hearts -= 1
	_update_hearts()
	_play(%SfxHurt, SFX_HURT, randf_range(0.5, 0.62))
	var tw := create_tween()
	%HurtFlash.modulate.a = 0.9
	tw.tween_property(%HurtFlash, "modulate:a", 0.0, 0.4)
	_shake()
	if hearts <= 0:
		state = State.OVER
		_play(%SfxOver, SFX_OVER, 0.7)
		%OverSub.text = "YOU REACHED LEVEL %d WITH %d SOULS" % [level, souls]
		get_tree().create_timer(0.7).timeout.connect(func() -> void:
			%OverPanel.visible = true)


func _shake() -> void:
	var tw := create_tween()
	for i in 4:
		tw.tween_property(_world, "position",
			Vector2(randf_range(-6.0, 6.0), randf_range(-4.0, 4.0)), 0.04)
	tw.tween_property(_world, "position", Vector2.ZERO, 0.05)


# --- souls ----------------------------------------------------------------

func _spawn_soul(pos: Vector2, amount: int) -> void:
	var coin := Sprite2D.new()
	coin.texture = COIN_TEXTURE
	coin.position = pos
	coin.scale = Vector2(1.2, 1.2)
	_world.add_child(coin)
	var target: Vector2 = %SoulsSign.global_position + %SoulsSign.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(coin, "position", target, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(coin, "rotation", TAU * 1.5, 0.55)
	tw.chain().tween_callback(func() -> void:
		souls += amount
		%SoulsLabel.text = "SOULS %d" % souls
		_play(%SfxCoin, SFX_COIN, randf_range(0.95, 1.15))
		coin.queue_free())


# --- level flow ------------------------------------------------------------

func _announce_in() -> void:
	%Announce.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(%Announce, "modulate:a", 1.0, 0.35)
	tw.tween_interval(1.1)
	tw.tween_property(%Announce, "modulate:a", 0.0, 0.5)


func _level_cleared() -> void:
	state = State.CLEAR
	GameState.mark_cleared(level)
	_play(%SfxClear, SFX_CLEAR, 1.0)
	if level >= GameState.LEVEL_COUNT:
		%ClearTitle.text = "THE APOCALYPSE IS AVERTED!"
		%NextBtn.visible = false
	else:
		%ClearTitle.text = "LEVEL %d CLEARED!" % level
		%NextBtn.visible = true
	%ClearSouls.text = "SOULS COLLECTED: %d" % souls
	get_tree().create_timer(0.8).timeout.connect(func() -> void:
		%ClearPanel.visible = true)


func _on_next_pressed() -> void:
	GameState.selected_level = level + 1
	get_tree().reload_current_scene()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# --- helpers ---------------------------------------------------------------

func _update_hearts() -> void:
	for i in MAX_HEARTS:
		var icon: TextureRect = %Hearts.get_child(i)
		icon.texture = HEART_FULL if i < hearts else HEART_EMPTY


func _play(player: AudioStreamPlayer, stream: AudioStream, pitch := 1.0) -> void:
	if GameState.muted:
		return
	player.stream = stream
	player.pitch_scale = pitch
	player.play()
