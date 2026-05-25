// Scripts/GameServices.cs
//
// Tiny shared-state holder registered with Stride's IServiceRegistry on Start
// and looked up by other scripts (e.g. ChaseCamera) instead of holding a
// direct entity reference. Decouples wiring order — the camera doesn't have
// to be assigned a target in the editor; it asks the registry for the
// "current player ship" the first time it needs one.

namespace DriftHangar.Scripts;

/// <summary>
/// Run-state shared across scripts. Lookup via
/// <c>this.Services.GetService&lt;GameState&gt;()</c>.
/// </summary>
public sealed class GameState
{
    /// <summary>The currently-controlled player ship, if any.</summary>
    public Entity? PlayerShip { get; set; }

    /// <summary>Total time the player has been alive this run (seconds).</summary>
    public float ElapsedSeconds { get; set; }

    /// <summary>Distance the player has traveled this run (world units).</summary>
    public float DistanceTraveled { get; set; }

    /// <summary>True while the pause menu owns input.</summary>
    public bool Paused { get; set; }
}

/// <summary>
/// Helper script that registers a fresh <see cref="GameState"/> when the scene
/// starts. Add to a single bootstrap entity in the scene.
/// </summary>
public sealed class GameStateInstaller : StartupScript
{
    public override void Start()
    {
        // GetServiceProvider on older Stride; Services in 4.x. Either way,
        // adding the service once per scene-load is the contract.
        var existing = Services.GetService<GameState>();
        if (existing == null)
        {
            Services.AddService(new GameState());
        }
    }
}
