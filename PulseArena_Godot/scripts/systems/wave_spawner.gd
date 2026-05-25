extends Node2D
class_name WaveSpawner
##
## WaveSpawner — drives the enemy wave cadence.
##
## Each wave grows in size and gradually introduces the shooter type.
## Enemies spawn at the perimeter of the arena, off-screen, so the player
## never sees them pop into existence mid-arena.
##

@export var arena_size: Vector2 = Vector2(1280, 720)
@export var spawn_padding: float = 40.0       ## Pixels outside the arena edge where enemies appear.
@export var inter_wave_delay: float = 2.5
@export var chaser_scene: PackedScene
@export var shooter_scene: PackedScene

var _alive_enemies: int = 0
var _wave_number: int = 0
var _spawning: bool = false


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	# Kick the first wave on a small delay so the player can settle.
	get_tree().create_timer(1.0).timeout.connect(_start_next_wave)


func _start_next_wave() -> void:
	_wave_number += 1
	var enemy_count := _enemies_for_wave(_wave_number)
	var shooter_count := _shooters_for_wave(_wave_number)
	EventBus.wave_started.emit(_wave_number, enemy_count)
	_spawning = true
	_alive_enemies = enemy_count
	# Stagger spawns over a couple of seconds so a wave doesn't dump in one frame.
	for i in enemy_count:
		var use_shooter := i < shooter_count
		_spawn_one(use_shooter)
		await get_tree().create_timer(0.18).timeout
	_spawning = false


func _spawn_one(use_shooter: bool) -> void:
	var scene := shooter_scene if use_shooter else chaser_scene
	if scene == null:
		push_warning("WaveSpawner: enemy scene unassigned.")
		return
	var enemy := scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _random_perimeter_point()


# --- Difficulty curve ------------------------------------------------------

func _enemies_for_wave(n: int) -> int:
	# Linear-ish growth, capped so late waves don't get unmanageable.
	return mini(5 + n * 2, 30)

func _shooters_for_wave(n: int) -> int:
	# Shooters only start appearing on wave 3, and never more than a third of the wave.
	if n < 3:
		return 0
	return mini((n - 2), _enemies_for_wave(n) / 3)


# --- Spawn placement -------------------------------------------------------

func _random_perimeter_point() -> Vector2:
	# Pick a side, then a random point along it, then push outside the arena edge.
	var side := randi() % 4
	match side:
		0: return Vector2(randf() * arena_size.x, -spawn_padding)
		1: return Vector2(randf() * arena_size.x, arena_size.y + spawn_padding)
		2: return Vector2(-spawn_padding, randf() * arena_size.y)
		_: return Vector2(arena_size.x + spawn_padding, randf() * arena_size.y)


# --- Event handlers --------------------------------------------------------

func _on_enemy_killed(_points: int, _pos: Vector2) -> void:
	_alive_enemies = maxi(_alive_enemies - 1, 0)
	if _alive_enemies == 0 and not _spawning:
		EventBus.wave_cleared.emit(_wave_number)
		await get_tree().create_timer(inter_wave_delay).timeout
		_start_next_wave()
