// Scripts/PauseMenu.cs
//
// Toggles a paused state on Esc. Other scripts read GameState.Paused and
// short-circuit their Update — that's all the cooperation needed. We also
// flip the cursor visibility so the user can actually click the menu.

namespace DriftHangar.Scripts;

public sealed class PauseMenu : SyncScript
{
    [DataMember] public Entity? MenuRoot { get; set; }
    [DataMember] public Keys ToggleKey { get; set; } = Keys.Escape;

    private GameState? _state;
    private bool _cursorVisibleBeforePause;

    public override void Start()
    {
        _state = Services.GetService<GameState>();
        SetMenuVisible(false);
    }

    public override void Update()
    {
        if (_state == null) return;

        if (Input.IsKeyPressed(ToggleKey))
        {
            TogglePause();
        }
    }

    private void TogglePause()
    {
        if (_state == null) return;
        bool nowPaused = !_state.Paused;
        _state.Paused = nowPaused;

        if (nowPaused)
        {
            _cursorVisibleBeforePause = Game.IsMouseVisible;
            Game.IsMouseVisible = true;
        }
        else
        {
            Game.IsMouseVisible = _cursorVisibleBeforePause;
        }

        SetMenuVisible(nowPaused);
    }

    private void SetMenuVisible(bool visible)
    {
        if (MenuRoot == null) return;
        // Cheap on/off: disable the whole MenuRoot subtree by removing/adding
        // it as an active child of its parent's hierarchy. For simplicity here,
        // we just toggle EnableAll on each component-bearing entity child.
        SetEntityActive(MenuRoot, visible);
    }

    private static void SetEntityActive(Entity entity, bool active)
    {
        // Hide model & UI components on the entity itself.
        foreach (var c in entity.Components)
        {
            if (c is ActivableEntityComponent activable)
            {
                activable.Enabled = active;
            }
        }
        // Recurse into children.
        foreach (var child in entity.Transform.Children)
        {
            SetEntityActive(child.Entity, active);
        }
    }
}
