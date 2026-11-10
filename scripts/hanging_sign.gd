class_name HangingSign
extends Node2D

## Pendulum swing for a sign hanging on chains.
## The node's origin is the chain anchor; the sign hangs below it.
## Idle sway is a slow sine target; impulses (hover/press) inject
## angular velocity that a damped spring resolves back to the sway.

@export var sway_amplitude := 0.02  ## radians of idle sway
@export var sway_speed := 1.4       ## radians/sec of idle sway
@export var stiffness := 30.0
@export var damping := 5.0

var _ang_vel := 0.0
var _angle := 0.0
var _time := 0.0
var _phase := 0.0

func _ready() -> void:
	_phase = randf() * TAU

func _process(delta: float) -> void:
	_time += delta
	var target := sway_amplitude * sin(_time * sway_speed + _phase)
	var accel := (target - _angle) * stiffness - _ang_vel * damping
	_ang_vel += accel * delta
	_angle += _ang_vel * delta
	rotation = _angle

func impulse(amount: float) -> void:
	_ang_vel += amount
