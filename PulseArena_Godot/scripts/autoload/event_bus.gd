extends Node
##
## EventBus — global signal hub.
##
## Decouples emitters from listeners. Anything in the project can connect
## to these signals without holding a direct reference to the source node.
## This keeps systems (HUD, GameManager, CameraShake, AudioManager) loosely
## coupled and easy to refactor.
##

# --- Gameplay events --------------------------------------------------------

## Emitted whenever an enemy dies. Carries the points it was worth and the
## world position so feedback systems (particles, score popups) can react.
signal enemy_killed(points: int, world_position: Vector2)

## Emitted when the player takes damage. `remaining_lives` lets the HUD
## update without polling.
signal player_damaged(remaining_lives: int)

## Emitted when the player dies. GameManager listens to transition state.
signal player_died()

## Emitted when a new wave is about to begin.
signal wave_started(wave_number: int, enemy_count: int)

## Emitted when a wave has been fully cleared.
signal wave_cleared(wave_number: int)

# --- Feel / juice events ----------------------------------------------------

## Request a screen shake. `strength` is in pixels of max offset;
## `duration` is seconds. CameraShake listens for this.
signal request_screen_shake(strength: float, duration: float)

## Request a brief hitstop (engine time scale dip). Useful on big impacts.
signal request_hitstop(duration: float)
