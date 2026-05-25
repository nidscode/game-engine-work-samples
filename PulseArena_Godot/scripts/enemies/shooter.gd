extends EnemyBase
class_name Shooter
##
## Shooter — keeps its distance from the player and fires bullets.
##
## State machine is tiny (kite vs. attack) but written as an explicit enum
## so it's easy to extend (add "reposition", "retreat", etc.).
##

enum State { KITE, ATTACK }

@export var preferred_range: float = 320.0
@export var range_band: float = 60.0           ## ±band around preferred_range counts as "in range".
@export var move_speed: float = 90.0
@export var fire_cooldown: float = 1.1
@export var bullet_speed: float = 380.0
@export var bullet_scene: PackedScene

var _state: State = State.KITE
var _fire_timer: float = 0.0


func _ai_tick(delta: float) -> void:
	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	_update_state(dist)

	# Movement: get closer if too far, back away if too close, hold if in band.
	var move_dir := Vector2.ZERO
	if dist > preferred_range + range_band:
		move_dir = to_player.normalized()
	elif dist < preferred_range - range_band:
		move_dir = -to_player.normalized()
	velocity = move_dir * move_speed

	# Always face the player.
	$Visual.rotation = to_player.angle()

	# Fire while in attack state.
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _state == State.ATTACK and _fire_timer == 0.0:
		_fire(to_player.normalized())
		_fire_timer = fire_cooldown


func _update_state(dist: float) -> void:
	# Hysteresis: only flip to ATTACK once we're inside the band, only flip
	# back to KITE if we're clearly outside it. Prevents jitter at the edge.
	match _state:
		State.KITE:
			if absf(dist - preferred_range) <= range_band:
				_state = State.ATTACK
		State.ATTACK:
			if absf(dist - preferred_range) > range_band * 1.5:
				_state = State.KITE


func _fire(direction: Vector2) -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + direction * 20.0
	bullet.launch(direction, false, bullet_speed)  # false = enemy bullet
