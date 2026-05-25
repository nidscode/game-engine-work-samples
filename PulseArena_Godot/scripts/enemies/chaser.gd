extends EnemyBase
class_name Chaser
##
## Chaser — closes on the player and tries to melee them.
##
## Simple seek behavior with a turning rate so it doesn't snap-rotate
## (which looked twitchy when many were on screen at once).
##

@export var move_speed: float = 140.0
@export var turn_rate_deg: float = 540.0   ## Max degrees per second the heading can change.

var _heading: Vector2 = Vector2.RIGHT


func _ai_tick(delta: float) -> void:
	var player := _get_player()
	if player == null:
		velocity = Vector2.ZERO
		return

	var desired := (player.global_position - global_position).normalized()
	# Smoothly rotate the heading toward the desired direction.
	var max_turn := deg_to_rad(turn_rate_deg) * delta
	_heading = _heading.rotated(clamp(_heading.angle_to(desired), -max_turn, max_turn))
	velocity = _heading * move_speed
	$Visual.rotation = _heading.angle()
