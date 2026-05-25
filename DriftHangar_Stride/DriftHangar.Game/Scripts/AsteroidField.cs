// Scripts/AsteroidField.cs
//
// Procedural asteroid placement. Spawns N asteroid prefabs in a spherical
// volume with seeded RNG so the field is reproducible run-to-run. We
// avoid placing any closer than MinDistance from the origin (so the player
// doesn't spawn inside one) and also enforce a soft minimum distance
// between asteroids via a cheap rejection-sample pass.
//
// Each asteroid gets a random uniform scale and rotation, which is enough
// visual variety with one shared mesh.

namespace DriftHangar.Scripts;

public sealed class AsteroidField : StartupScript
{
    [DataMember] public Prefab? AsteroidPrefab { get; set; }

    [DataMember] public int   Count           { get; set; } = 160;
    [DataMember] public float FieldRadius     { get; set; } = 220f;
    [DataMember] public float MinSpawnDistance{ get; set; } = 24f;   // from origin
    [DataMember] public float MinSeparation   { get; set; } = 6f;    // between asteroids
    [DataMember] public float ScaleMin        { get; set; } = 0.6f;
    [DataMember] public float ScaleMax        { get; set; } = 3.4f;
    [DataMember] public int   Seed            { get; set; } = 1337;
    [DataMember] public int   MaxPlacementTries { get; set; } = 24;

    public override void Start()
    {
        if (AsteroidPrefab == null)
        {
            Log.Warning("AsteroidField has no AsteroidPrefab assigned — nothing to spawn.");
            return;
        }

        var rng = new Random(Seed);
        var placed = new List<Vector3>(Count);
        var sceneRoot = Entity.Scene;

        int safety = 0;
        int spawned = 0;
        while (spawned < Count && safety < Count * MaxPlacementTries)
        {
            safety++;
            Vector3 candidate = RandomInSphere(rng, FieldRadius);

            if (candidate.Length() < MinSpawnDistance) continue;
            if (TooCloseToAny(candidate, placed)) continue;

            var instances = AsteroidPrefab.Instantiate();
            if (instances == null || instances.Count == 0) continue;

            // Apply transform to the root of the instantiated prefab.
            var root = instances[0];
            root.Transform.Position = candidate;
            root.Transform.Rotation = RandomQuaternion(rng);
            float s = ScaleMin + (float)rng.NextDouble() * (ScaleMax - ScaleMin);
            root.Transform.Scale = new Vector3(s, s, s);

            foreach (var entity in instances)
            {
                sceneRoot.Entities.Add(entity);
            }
            placed.Add(candidate);
            spawned++;
        }

        Log.Info($"AsteroidField spawned {spawned}/{Count} asteroids (tried {safety} placements).");
    }

    // ----------------------------------------------------------------------

    private bool TooCloseToAny(Vector3 candidate, List<Vector3> placed)
    {
        float minSqr = MinSeparation * MinSeparation;
        // O(n) per candidate. With Count ~200 it's fine; would switch to a
        // spatial hash if we pushed into the thousands.
        for (int i = 0; i < placed.Count; i++)
        {
            if (Vector3.DistanceSquared(candidate, placed[i]) < minSqr) return true;
        }
        return false;
    }

    private static Vector3 RandomInSphere(Random rng, float radius)
    {
        // Rejection-sample a point in the unit cube until it lies in the
        // unit sphere; then scale. Cheap and unbiased.
        while (true)
        {
            float x = (float)(rng.NextDouble() * 2.0 - 1.0);
            float y = (float)(rng.NextDouble() * 2.0 - 1.0);
            float z = (float)(rng.NextDouble() * 2.0 - 1.0);
            float lsq = x * x + y * y + z * z;
            if (lsq <= 1f && lsq > 1e-4f)
            {
                return new Vector3(x, y, z) * radius;
            }
        }
    }

    private static Quaternion RandomQuaternion(Random rng)
    {
        // Shoemake's uniform quaternion. Produces orientation uniformly on SO(3).
        float u1 = (float)rng.NextDouble();
        float u2 = (float)rng.NextDouble();
        float u3 = (float)rng.NextDouble();
        float s1 = MathF.Sqrt(1f - u1);
        float s2 = MathF.Sqrt(u1);
        return new Quaternion(
            s1 * MathF.Sin(2f * MathF.PI * u2),
            s1 * MathF.Cos(2f * MathF.PI * u2),
            s2 * MathF.Sin(2f * MathF.PI * u3),
            s2 * MathF.Cos(2f * MathF.PI * u3));
    }
}
