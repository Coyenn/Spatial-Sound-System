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
