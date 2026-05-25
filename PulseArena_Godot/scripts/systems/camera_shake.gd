extends Camera2D
class_name CameraShake
##
## CameraShake — additive trauma-based shake driven by EventBus.
##
## Based on Squirrel Eiserloh's "trauma" approach: trauma is a 0..1 value
## that decays linearly. Actual shake magnitude is trauma², so small hits
## are barely visible and big ones really land. Output is layered on top of
## the camera's normal offset so it composes with camera follow logic.
##

@export var trauma_decay: float = 1.6           ## How fast trauma falls off per second.
@export var max_offset: Vector2 = Vector2(24, 24)
@export var max_rotation_deg: float = 4.0

var _trauma: float = 0.0
var _base_offset: Vector2


func _ready() -> void:
	_base_offset = offset
	EventBus.request_screen_shake.connect(_on_request_screen_shake)
	EventBus.request_hitstop.connect(_on_request_hitstop)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = _base_offset
		rotation = 0.0
		return
	_trauma = maxf(_trauma - trauma_decay * delta, 0.0)
	# Square the trauma so small values produce subtle shake.
	var shake_amount := _trauma * _trauma
	offset = _base_offset + Vector2(
		max_offset.x * shake_amount * randf_range(-1.0, 1.0),
		max_offset.y * shake_amount * randf_range(-1.0, 1.0)
	)
	rotation = deg_to_rad(max_rotation_deg) * shake_amount * randf_range(-1.0, 1.0)


# --- Event handlers --------------------------------------------------------

func _on_request_screen_shake(strength: float, _duration: float) -> void:
	# Normalize incoming strength against max_offset.x so callers can think in pixels.
	_trauma = minf(_trauma + strength / max_offset.x, 1.0)


func _on_request_hitstop(duration: float) -> void:
	# Brief engine time scale dip for big hits. Resetting via a tween keeps
	# this clean even if multiple hitstops overlap.
	Engine.time_scale = 0.15
	var tw := create_tween()
	tw.tween_property(Engine, "time_scale", 1.0, duration).set_trans(Tween.TRANS_QUAD)
