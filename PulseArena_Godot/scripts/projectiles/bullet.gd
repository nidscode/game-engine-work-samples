extends Area2D
class_name Bullet
##
## Bullet — generic projectile used by player and enemies.
##
## Friendly status is set at launch time, which flips the collision layer/mask
## and the visual tint. One scene file, two behaviors.
##

@export var default_speed: float = 720.0
@export var lifetime: float = 1.4
@export var damage: int = 1

# Visual tints — exported so designers can tweak without touching code.
@export var friendly_color: Color = Color(0.4, 1.0, 0.9)
@export var hostile_color: Color  = Color(1.0, 0.35, 0.55)

var _velocity: Vector2 = Vector2.ZERO
var _life_left: float = 0.0
var _is_friendly: bool = true

@onready var _visual: Node2D = $Visual


## Call immediately after instancing. `direction` should be normalized.
func launch(direction: Vector2, friendly: bool, speed: float = -1.0) -> void:
	_is_friendly = friendly
	_velocity = direction * (default_speed if speed < 0.0 else speed)
	_life_left = lifetime

	# Layer/mask are set up so:
	#  layer 3 = PlayerBullets  (hits layer 4 Enemies)
	#  layer 5 = EnemyBullets   (hits layer 2 Player)
	if friendly:
		collision_layer = 1 << 2   # layer 3
		collision_mask  = 1 << 3   # layer 4
		_visual.modulate = friendly_color
	else:
		collision_layer = 1 << 4   # layer 5
		collision_mask  = 1 << 1   # layer 2
		_visual.modulate = hostile_color

	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_life_left -= delta
	if _life_left <= 0.0:
		queue_free()


# Wired in the scene file via Area2D `body_entered`.
func _on_body_entered(body: Node) -> void:
	if _is_friendly and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	elif not _is_friendly and body.has_method("take_hit"):
		body.take_hit(damage)
		queue_free()
