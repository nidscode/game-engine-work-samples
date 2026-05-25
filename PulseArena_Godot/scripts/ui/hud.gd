extends CanvasLayer
##
## HUD — top-of-screen score, wave, and lives readout.
##
## Pure listener: it never queries the rest of the game directly, it just
## reacts to EventBus signals and re-reads GameManager state when something
## changes. This means we could swap the entire HUD scene without breaking
## any other system.
##

@onready var _score_label: Label = $Margin/Row/ScoreLabel
@onready var _wave_label: Label = $Margin/Row/WaveLabel
@onready var _lives_label: Label = $Margin/Row/LivesLabel
@onready var _wave_banner: Label = $WaveBanner


func _ready() -> void:
	EventBus.enemy_killed.connect(_refresh)
	EventBus.player_damaged.connect(_refresh)
	EventBus.wave_started.connect(_on_wave_started)
	_refresh()


func _refresh(_a = null, _b = null) -> void:
	_score_label.text = "SCORE  %06d" % GameManager.score
	_wave_label.text  = "WAVE  %02d" % GameManager.current_wave
	_lives_label.text = "LIVES  %d" % GameManager.lives


func _on_wave_started(wave_number: int, _count: int) -> void:
	_refresh()
	_wave_banner.text = "WAVE %d" % wave_number
	_wave_banner.modulate.a = 1.0
	# Fade the banner out over ~1.2s.
	var tw := create_tween()
	tw.tween_property(_wave_banner, "modulate:a", 0.0, 1.2)
