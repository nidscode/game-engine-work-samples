// Scripts/GameHud.cs
//
// On-screen HUD: speed, distance, and a centered crosshair.
//
// In Stride, UI elements live under a UIComponent + UIPage. This script
// expects a UIComponent on the same entity with text controls named
// "SpeedText" and "DistanceText" (set in the editor). We grab them once
// in Start() and update their text each frame.

using Stride.UI;
using Stride.UI.Controls;
using Stride.UI.Panels;

namespace DriftHangar.Scripts;

public sealed class GameHud : SyncScript
{
    [DataMember] public string SpeedTextName    { get; set; } = "SpeedText";
    [DataMember] public string DistanceTextName { get; set; } = "DistanceText";

    private TextBlock? _speed;
    private TextBlock? _distance;
    private GameState? _state;

    public override void Start()
    {
        _state = Services.GetService<GameState>();

        var ui = Entity.Get<UIComponent>();
        if (ui?.Page?.RootElement == null)
        {
            Log.Warning("GameHud: no UIComponent / UIPage / RootElement found on this entity.");
            return;
        }

        // Stride 4.x exposes FindVisualChildOfType<T>() / FindName via the
        // UIElement extension methods. We look up by name set in the editor.
        var root = ui.Page.RootElement;
        _speed    = FindByName<TextBlock>(root, SpeedTextName);
        _distance = FindByName<TextBlock>(root, DistanceTextName);
    }

    public override void Update()
    {
        if (_state == null) return;

        Entity? ship = _state.PlayerShip;
        float speed = 0f;
        if (ship != null)
        {
            var controller = ship.Get<ShipController>();
            if (controller != null) speed = controller.Velocity.Length();
        }

        if (_speed    != null) _speed.Text    = $"{speed:0.0} m/s";
        if (_distance != null) _distance.Text = $"{_state.DistanceTraveled:0} m";
    }

    // ----------------------------------------------------------------------

    private static T? FindByName<T>(UIElement root, string name) where T : UIElement
    {
        if (root.Name == name && root is T match) return match;
        if (root is Panel panel)
        {
            foreach (var child in panel.Children)
            {
                var found = FindByName<T>(child, name);
                if (found != null) return found;
            }
        }
        else if (root is ContentControl content && content.Content != null)
        {
            return FindByName<T>(content.Content, name);
        }
        return null;
    }
}
