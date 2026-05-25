// Scripts/ShipController.cs
//
// Player ship controller. 6-DoF-ish flight using local-axis input:
//   * W/S            - thrust forward/back along the ship's local forward
//   * A/D            - yaw left/right
//   * Q/E            - roll left/right
//   * mouse Y        - pitch (when right-mouse held; otherwise free look stays still)
//
// Velocity is integrated in world space, then drag is applied so the ship
// naturally coasts to a stop when the player stops thrusting. Drag is *not*
// realistic for space — it's a quality-of-life choice that makes the craft
// feel controllable instead of skidding forever after a tap.

namespace DriftHangar.Scripts;

public sealed class ShipController : SyncScript
{
    // -------- Inspector-exposed tunables -----------------------------------

    [DataMember] public float ThrustForce        { get; set; } = 28f;   // m/s^2
    [DataMember] public float MaxSpeed           { get; set; } = 60f;
    [DataMember] public float LinearDrag         { get; set; } = 0.55f; // higher = stops sooner
    [DataMember] public float YawRateDegPerSec   { get; set; } = 90f;
    [DataMember] public float PitchRateDegPerSec { get; set; } = 70f;
    [DataMember] public float RollRateDegPerSec  { get; set; } = 110f;
    [DataMember] public float AngularSmoothing   { get; set; } = 14f;   // higher = snappier

    [DataMember] public bool RequireRightMouseForLook { get; set; } = true;

    // -------- Internal state ----------------------------------------------

    private Vector3 _velocity;             // world-space, integrated each frame
    private Vector3 _angularInput;         // pitch / yaw / roll commanded this frame, deg/sec
    private GameState? _state;

    // ----------------------------------------------------------------------

    public override void Start()
    {
        _state = Services.GetService<GameState>();
        if (_state != null) _state.PlayerShip = Entity;
        // Hide & lock the cursor while flying so mouse delta works smoothly.
        Game.IsMouseVisible = false;
    }

    public override void Update()
    {
        if (_state is { Paused: true }) return;

        float dt = (float)Game.UpdateTime.Elapsed.TotalSeconds;

        ReadInput(dt);
        IntegrateRotation(dt);
        IntegrateVelocity(dt);
        UpdateStats(dt);
    }

    // ----------------------------------------------------------------------

    private void ReadInput(float dt)
    {
        // ---- thrust ----
        float thrustAxis = 0f;
        if (Input.IsKeyDown(Keys.W)) thrustAxis += 1f;
        if (Input.IsKeyDown(Keys.S)) thrustAxis -= 1f;

        if (thrustAxis != 0f)
        {
            Vector3 forward = Vector3.TransformNormal(-Vector3.UnitZ, Entity.Transform.WorldMatrix);
            _velocity += forward * (thrustAxis * ThrustForce * dt);
        }

        // Clamp speed.
        float speed = _velocity.Length();
        if (speed > MaxSpeed)
        {
            _velocity *= MaxSpeed / speed;
        }

        // ---- yaw / pitch / roll input collection ----
        float yaw = 0f, pitch = 0f, roll = 0f;
        if (Input.IsKeyDown(Keys.A)) yaw   -= 1f;
        if (Input.IsKeyDown(Keys.D)) yaw   += 1f;
        if (Input.IsKeyDown(Keys.Q)) roll  -= 1f;
        if (Input.IsKeyDown(Keys.E)) roll  += 1f;

        bool wantsLook = !RequireRightMouseForLook || Input.IsMouseButtonDown(MouseButton.Right);
        if (wantsLook)
        {
            // Mouse delta is fractional-screen — multiply to get a degree rate.
            pitch += Input.MouseDelta.Y * 90f;
            // Subtle yaw assist from horizontal mouse for fluent steering.
            yaw   += Input.MouseDelta.X * 90f;
        }

        // Smooth the angular input so quick taps don't snap.
        Vector3 raw = new(pitch * PitchRateDegPerSec,
                          yaw   * YawRateDegPerSec,
                          roll  * RollRateDegPerSec);
        float k = 1f - MathF.Exp(-AngularSmoothing * dt);
        _angularInput += (raw - _angularInput) * k;
    }

    private void IntegrateRotation(float dt)
    {
        // Apply rotations in the ship's local frame so they compose correctly
        // regardless of orientation (no gimbal-lock surprises).
        Quaternion deltaPitch = Quaternion.RotationAxis(Vector3.UnitX, MathUtil.DegreesToRadians(_angularInput.X * dt));
        Quaternion deltaYaw   = Quaternion.RotationAxis(Vector3.UnitY, MathUtil.DegreesToRadians(_angularInput.Y * dt));
        Quaternion deltaRoll  = Quaternion.RotationAxis(Vector3.UnitZ, MathUtil.DegreesToRadians(_angularInput.Z * dt));

        // Order: roll * pitch * yaw, applied in local space (right-multiply onto current).
        Entity.Transform.Rotation = Entity.Transform.Rotation
                                  * deltaRoll
                                  * deltaPitch
                                  * deltaYaw;
    }

    private void IntegrateVelocity(float dt)
    {
        Entity.Transform.Position += _velocity * dt;

        // Exponential drag — frame-rate independent.
        float dragFactor = MathF.Exp(-LinearDrag * dt);
        _velocity *= dragFactor;
    }

    private void UpdateStats(float dt)
    {
        if (_state == null) return;
        _state.ElapsedSeconds   += dt;
        _state.DistanceTraveled += _velocity.Length() * dt;
    }

    /// <summary>Read-only velocity, for HUD/camera/etc.</summary>
    public Vector3 Velocity => _velocity;
}
