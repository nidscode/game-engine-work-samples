// Scripts/ChaseCamera.cs
//
// Critically-damped spring chase camera. Sits behind & slightly above the
// target ship. The "spring" is a second-order PD controller on position and
// orientation — position responds with mass+damping, orientation with a
// shortest-arc slerp toward where the camera *should* be looking.
//
// Why a spring instead of a constant lerp:
//   * A spring overshoots a touch on hard direction changes, which sells
//     mass/momentum visually.
//   * Critical damping (damping = 2*sqrt(stiffness)) settles in finite time
//     with no oscillation — clean look without ringing.
//   * Frame-rate independence is built into the closed-form math.

namespace DriftHangar.Scripts;

public sealed class ChaseCamera : SyncScript
{
    // ---- Inspector tunables ----------------------------------------------

    [DataMember] public Entity? Target { get; set; }

    /// <summary>Offset behind and above the target, in the target's local space.</summary>
    [DataMember] public Vector3 LocalOffset { get; set; } = new(0f, 1.6f, 6.0f);

    /// <summary>Lower stiffness = more lag/drift. 36 ≈ ~1s settling at critical damping.</summary>
    [DataMember] public float PositionStiffness { get; set; } = 36f;

    /// <summary>Slerp speed for rotation, in 1/sec.</summary>
    [DataMember] public float RotationSpeed { get; set; } = 8f;

    /// <summary>FOV widening when the target is going fast — adds a sense of speed.</summary>
    [DataMember] public float FovBase  { get; set; } = 60f;
    [DataMember] public float FovKick  { get; set; } = 14f;   // degrees added at top speed
    [DataMember] public float MaxSpeed { get; set; } = 60f;

    // ---- Internal state --------------------------------------------------

    private Vector3 _posVelocity;        // PD controller state
    private CameraComponent? _camera;
    private GameState? _state;

    // ----------------------------------------------------------------------

    public override void Start()
    {
        _camera = Entity.Get<CameraComponent>();
        _state  = Services.GetService<GameState>();
        if (_camera != null) _camera.VerticalFieldOfView = FovBase;
    }

    public override void Update()
    {
        var target = Target ?? _state?.PlayerShip;
        if (target == null) return;

        float dt = (float)Game.UpdateTime.Elapsed.TotalSeconds;
        if (dt <= 0f) return;

        UpdatePosition(target, dt);
        UpdateRotation(target, dt);
        UpdateFov(target, dt);
    }

    // ---- Position: PD spring ---------------------------------------------

    private void UpdatePosition(Entity target, float dt)
    {
        // Desired = target position + target's basis vectors applied to LocalOffset.
        Matrix m = target.Transform.WorldMatrix;
        Vector3 right   = new(m.M11, m.M12, m.M13);
        Vector3 up      = new(m.M21, m.M22, m.M23);
        Vector3 forward = new(m.M31, m.M32, m.M33);  // Stride is RH; this is +Z

        Vector3 desired = target.Transform.WorldMatrix.TranslationVector
                        + right   * LocalOffset.X
                        + up      * LocalOffset.Y
                        + forward * LocalOffset.Z;

        // Critically-damped spring: ω = sqrt(k), damping = 2ω.
        float omega = MathF.Sqrt(PositionStiffness);
        float damping = 2f * omega;

        Vector3 currentPos = Entity.Transform.Position;
        Vector3 displacement = currentPos - desired;
        Vector3 acceleration = -PositionStiffness * displacement - damping * _posVelocity;

        _posVelocity      += acceleration * dt;
        Entity.Transform.Position = currentPos + _posVelocity * dt;
    }

    // ---- Rotation: look at the target, slerp toward it -------------------

    private void UpdateRotation(Entity target, float dt)
    {
        Vector3 to = target.Transform.WorldMatrix.TranslationVector - Entity.Transform.Position;
        if (to.LengthSquared() < 1e-4f) return;

        // Build a "look at the target with the target's up" quaternion. We
        // bias upward by the target's local up so the camera rolls with the
        // ship — feels more like a chase camera, less like a tripod.
        Matrix targetWorld = target.Transform.WorldMatrix;
        Vector3 up = new(targetWorld.M21, targetWorld.M22, targetWorld.M23);

        Matrix look = Matrix.LookAtRH(Entity.Transform.Position,
                                      target.Transform.WorldMatrix.TranslationVector,
                                      up);
        // LookAt returns a view matrix; we want world rotation, so invert.
        Matrix world;
        Matrix.Invert(ref look, out world);
        Quaternion desired = Quaternion.RotationMatrix(world);

        float k = 1f - MathF.Exp(-RotationSpeed * dt);
        Entity.Transform.Rotation = Quaternion.Slerp(Entity.Transform.Rotation, desired, k);
    }

    // ---- FOV "speed kick" -------------------------------------------------

    private void UpdateFov(Entity target, float dt)
    {
        if (_camera == null) return;

        var ship = target.Get<ShipController>();
        float speed = ship?.Velocity.Length() ?? 0f;
        float t = MathUtil.Clamp(speed / MaxSpeed, 0f, 1f);
        float desiredFov = FovBase + t * FovKick;

        // Smooth FOV so a sudden burst doesn't snap.
        float k = 1f - MathF.Exp(-4f * dt);
        _camera.VerticalFieldOfView += (desiredFov - _camera.VerticalFieldOfView) * k;
    }
}
