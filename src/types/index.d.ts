/**
 * Client-side 3D spatial audio system that applies directional attenuation to sounds
 * based on their position relative to the listener/camera. Provides:
 *
 * @remarks
 * - Spatial audio effects using EqualizerSoundEffect for directional attenuation
 * - Automatic position tracking of sound sources (both static and moving)
 * - Real-time audio processing through RenderStepped updates
 * - Support for both pre-existing Sound objects and new sound emitters
 * - Automatic cleanup of non-looped sounds
 *
 * @example
 * ```ts
 * // Create positional sound
 * const emitter = SoundSystem.Create("123456789", new Vector3(10, 5, 0));
 *
 * // Attach existing sound
 * SoundSystem.Attach(workspace.Part.Sound);
 * ```
 *
 * @note Must be used on the client side. Server interactions should use RemoteEvents
 *       to trigger client-side sound creation/management.
 */
export class SpatialSoundSystem {
    /**
     * Attaches an existing Sound object to the spatial sound system
     * @param soundObj Sound instance parented to a BasePart or Attachment in workspace
     */
    static Attach(soundObj: Sound): void;

    /**
     * Creates a new spatial sound emitter
     * @param ID Sound asset ID (e.g., "123456789")
     * @param Target Position, CFrame, or part/attachment to follow
     * @param Looped Whether the sound should loop (default: false)
     * @returns Attachment container for the created sound
     */
    static Create(
        ID: string,
        Target: BasePart | Attachment | Vector3 | CFrame,
        Looped?: boolean
    ): Attachment & { Sound?: Sound };
}
