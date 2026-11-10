extends Area2D

## A monster of the apocalypse flying toward the canyon gate.

signal died(souls: int, pos: Vector2)
signal reached_gate

const STATS := {
	"imp": {"hp": 1, "speed": 120.0, "amp": 40.0, "freq": 3.2, "souls": 10, "anim": "imp", "scale": 1.0, "flash": Color(1.0, 0.45, 0.45)},
	"wogol": {"hp": 2, "speed": 82.0, "amp": 28.0, "freq": 2.4, "souls": 15, "anim": "wogol", "scale": 1.0, "flash": Color(1.0, 0.4, 0.4)},
	"chort": {"hp": 4, "speed": 56.0, "amp": 18.0, "freq": 1.8, "souls": 25, "anim": "chort", "scale": 1.0, "flash": Color(1.0, 0.35, 0.3)},
	"pumpkin": {"hp": 1, "speed": 150.0, "amp": 55.0, "freq": 4.2, "souls": 12, "anim": "pumpkin", "scale": 1.0, "flash": Color(1.0, 0.6, 0.2)},
	"necromancer": {"hp": 24, "speed": 34.0, "amp": 14.0, "freq": 1.2, "souls": 100, "anim": "necro", "scale": 1.25, "flash": Color(0.8, 0.3, 1.0)},
}
const GATE_X := 130.0
const PUFF_TEXTURE := preload("res://assets/game/bolt.png")

@export var type := "imp"
@export var speed_mult := 1.0

var _hp := 1
var _speed := 100.0
var _amp := 40.0
var _freq := 3.0
var _souls := 10
var _base_y := 0.0
var _t := 0.0
var _dying := false

@onready var _anim: AnimatedSprite2D = $Anim


func _ready() -> void:
	var s: Dictionary = STATS[type]
	_hp = s.hp
	_speed = s.speed
	_amp = s.amp
	_freq = s.freq
	_souls = s.souls
	_anim.scale = Vector2.ONE * float(s.scale)
	_anim.play(s.anim)
	_base_y = position.y
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	if _dying:
		return
	position.x -= _speed * speed_mult * delta
	_t += delta
	position.y = _base_y + sin(_t * _freq) * _amp
	if position.x < GATE_X:
		_dying = true
		_puff(Color(0.55, 0.45, 0.65, 0.9), 8)
		reached_gate.emit()
		queue_free()
		return


func take_hit(dmg: int) -> void:
	if _dying:
		return
	_hp -= dmg
	if _hp <= 0:
		_dying = true
		var s: Dictionary = STATS[type]
		_puff(s.flash, 14)
		died.emit(_souls, global_position)
		queue_free()
	else:
		_anim.modulate = Color(1.0, 0.3, 0.3)
		var tw := create_tween()
		tw.tween_property(_anim, "modulate", Color.WHITE, 0.16)


func _puff(color: Color, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.texture = PUFF_TEXTURE
	p.amount = amount
	p.lifetime = 0.38
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 130.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1
	p.color = color
	p.global_position = global_position
	p.emitting = true
	get_tree().current_scene.add_child(p)
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)
