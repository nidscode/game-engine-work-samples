extends CharacterBody2D
class_name EnemyBase
##
## EnemyBase — shared behavior for all enemies.
##
## Subclasses override `_ai_tick` to implement their own movement / attack
## logic. Damage handling, death, and reward are centralized here so we can
## tweak feel (hit flash, screen shake on death) in one place.
##

@export var max_hp: int = 3
@export var point_value: int = 100
@export var contact_damage: int = 1

var _hp: int

@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_hp = max_hp
	# Layer/mask are set in the scene file; nothing to do here.

func _physics_process(delta: float) -> void:
	_ai_tick(delta)
	move_and_slide()


# --- Hooks for subclasses --------------------------------------------------

func _ai_tick(_delta: float) -> void:
	# Override in subclasses (chaser, shooter, etc.).
	pass

## Returns the live player node, or null if the player is dead.
## Subclasses use this for targeting; it's centralized so we can switch
## from group-lookup to a cached reference later without touching subclasses.
func _get_player() -> Node2D:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null


# --- Damage / death --------------------------------------------------------

func take_damage(amount: int) -> void:
	_hp -= amount
	_flash_white()
	if _hp <= 0:
		_die()

func _flash_white() -> void:
	# Brief tint to communicate the hit registered.
	_visual.modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(_visual, "modulate", Color(1, 1, 1), 0.12)

func _die() -> void:
	EventBus.enemy_killed.emit(point_value, global_position)
	EventBus.request_screen_shake.emit(4.0, 0.1)
	queue_free()


# --- Contact damage --------------------------------------------------------

## Wired up via Area2D body_entered in the scene; we expose it as a method
## so subclasses can override (e.g., shooter doesn't melee).
func _on_player_contact(body: Node) -> void:
	if body.has_method("take_hit"):
		body.take_hit(contact_damage)
