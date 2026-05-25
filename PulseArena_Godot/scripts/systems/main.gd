extends Node2D
##
## Main — top-level scene controller.
##
## Wires the run together: resets state, listens for game-over, and reloads
## on player input after death.
##

@onready var _game_over_overlay: CanvasLayer = $GameOverOverlay


func _ready() -> void:
	GameManager.reset_run()
	_game_over_overlay.visible = false
	EventBus.player_died.connect(_on_player_died)


func _on_player_died() -> void:
	# Brief wait so the death feedback (shake, hitstop) lands before the UI.
	await get_tree().create_timer(0.8).timeout
	_game_over_overlay.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_game_over:
		return
	# Any key/click reloads the scene for a fresh run.
	if event is InputEventKey and event.pressed:
		get_tree().reload_current_scene()
	elif event is InputEventMouseButton and event.pressed:
		get_tree().reload_current_scene()
