extends Area2D

## A spinning magic bolt cast by the mage. Flies straight, bursts on contact.

var velocity := Vector2.ZERO
var _dead := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _trail: CPUParticles2D = $Trail
@onready var _burst: CPUParticles2D = $Burst


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	position += velocity * delta
	_sprite.rotation += 12.0 * delta
	if not Rect2(-100, -100, 1400, 875).has_point(global_position):
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _dead:
		return
	if area.has_method("take_hit"):
		area.take_hit(1)
		_dead = true
		_sprite.visible = false
		$Col.set_deferred("disabled", true)
		_trail.emitting = false
		_burst.emitting = true
		get_tree().create_timer(0.6).timeout.connect(queue_free)
