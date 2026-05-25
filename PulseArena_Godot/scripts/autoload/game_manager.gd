extends Node
##
## GameManager — central game state autoload.
##
## Owns the canonical score, current wave, and player-lives counts.
## Reacts to events from the EventBus rather than being called directly,
## so individual entities don't need to know it exists.
##

const STARTING_LIVES: int = 3

# --- State ------------------------------------------------------------------

var score: int = 0
var current_wave: int = 0
var lives: int = STARTING_LIVES
var is_game_over: bool = false


func _ready() -> void:
	# Listen for global gameplay events.
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.wave_started.connect(_on_wave_started)


# --- Public API -------------------------------------------------------------

## Resets all state. Called by Main when (re)starting a run.
func reset_run() -> void:
	score = 0
	current_wave = 0
	lives = STARTING_LIVES
	is_game_over = false


# --- Signal handlers --------------------------------------------------------

func _on_enemy_killed(points: int, _world_position: Vector2) -> void:
	score += points

func _on_player_damaged(remaining_lives: int) -> void:
	lives = remaining_lives
	# Punchy feedback on every hit.
	EventBus.request_screen_shake.emit(8.0, 0.18)
	EventBus.request_hitstop.emit(0.06)

func _on_player_died() -> void:
	is_game_over = true
	EventBus.request_screen_shake.emit(18.0, 0.6)

func _on_wave_started(wave_number: int, _enemy_count: int) -> void:
	current_wave = wave_number
