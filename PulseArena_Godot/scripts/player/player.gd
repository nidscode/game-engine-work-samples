extends CharacterBody2D
class_name Player
##
## Player — top-down twin-stick character.
##
## - WASD moves; mouse aims; LMB (action: "fire") shoots.
## - Movement uses an exponential smoothing to avoid the "ice-skating" feel
##   you get from raw acceleration math while staying snappy.
## - Shoots through a scene-instanced Bullet that the player itself doesn't
##   parent — bullets are added to the run root so they survive the player
##   moving / despawning.
##

# --- Tunables (exported for designer iteration in the inspector) -----------

@export var max_speed: float = 320.0
@export var accel_lerp_weight: float = 14.0   ## Higher = snappier, lower = floatier.
@export var fire_cooldown: float = 0.12       ## Seconds between shots.
@export var muzzle_offset: float = 22.0       ## Spawn bullets slightly ahead of origin.
@export var bullet_scene: PackedScene
@export var hit_invuln_seconds: float = 0.9

# --- Internal --------------------------------------------------------------

var _fire_timer: float = 0.0
var _invuln_timer: float = 0.0
var _lives: int = GameManager.STARTING_LIVES

@onready var _sprite: Node2D = $Visual          ## Whatever visual node you wire up.
@onready var _muzzle: Marker2D = $Muzzle


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_aim()
	_handle_fire(delta)
	_tick_invuln(delta)


# --- Movement --------------------------------------------------------------

func _handle_movement(delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target := input_vec * max_speed
	# lerp() with a weight scaled by delta gives frame-rate-independent smoothing.
	velocity = velocity.lerp(target, clamp(accel_lerp_weight * delta, 0.0, 1.0))
	move_and_slide()

func _handle_aim() -> void:
	# Rotate the visual to face the mouse without rotating the collision shape.
	var aim_dir := (get_global_mouse_position() - global_position)
	if aim_dir.length_squared() > 1.0:
		_sprite.rotation = aim_dir.angle()


# --- Combat ---------------------------------------------------------------

func _handle_fire(delta: float) -> void:
	_fire_timer = maxf(_fire_timer - delta, 0.0)
	if _fire_timer == 0.0 and Input.is_action_pressed("fire"):
		_fire()
		_fire_timer = fire_cooldown

func _fire() -> void:
	if bullet_scene == null:
		push_warning("Player.bullet_scene is unassigned.")
		return
	var bullet := bullet_scene.instantiate()
	# Add to the run root so bullets persist independently.
	get_tree().current_scene.add_child(bullet)
	var aim := (get_global_mouse_position() - global_position).normalized()
	bullet.global_position = global_position + aim * muzzle_offset
	bullet.launch(aim, true)  # `true` = friendly bullet
	EventBus.request_screen_shake.emit(2.0, 0.05)


# --- Damage ---------------------------------------------------------------

## Called by enemies / enemy bullets when they overlap the player.
func take_hit(_amount: int = 1) -> void:
	if _invuln_timer > 0.0:
		return
	_lives -= 1
	_invuln_timer = hit_invuln_seconds
	if _lives <= 0:
		EventBus.player_died.emit()
		queue_free()
	else:
		EventBus.player_damaged.emit(_lives)

func _tick_invuln(delta: float) -> void:
	if _invuln_timer > 0.0:
		_invuln_timer = maxf(_invuln_timer - delta, 0.0)
		# Flicker the sprite while invulnerable for clear visual feedback.
		_sprite.modulate.a = 0.35 if (int(_invuln_timer * 20) % 2 == 0) else 1.0
	else:
		_sprite.modulate.a = 1.0
