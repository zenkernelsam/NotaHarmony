export interface AssetAvailabilityChange {
  storageHash: string;
  noteIds: string[];
  generation: number;
}

export type AssetAvailabilityListener = (change: AssetAvailabilityChange) => void;

export class AssetAvailabilityHub {
  private nextListenerId: number = 1;
  private generation: number = 0;
  private listeners: Map<number, AssetAvailabilityListener> = new Map<number, AssetAvailabilityListener>();
  private noteGenerations: Map<string, number> = new Map<string, number>();

  subscribe(listener: AssetAvailabilityListener): number {
    const listenerId: number = this.nextListenerId++;
    this.listeners.set(listenerId, listener);
    return listenerId;
  }

  unsubscribe(listenerId: number): void {
    this.listeners.delete(listenerId);
  }

  publish(storageHash: string, noteIds: string[]): AssetAvailabilityChange {
    const uniqueNoteIds: string[] = [];
    for (const noteId of noteIds) {
      if (noteId.length > 0 && uniqueNoteIds.indexOf(noteId) < 0) {
        uniqueNoteIds.push(noteId);
      }
    }
    const generation: number = ++this.generation;
    for (const noteId of uniqueNoteIds) {
      this.noteGenerations.set(noteId, generation);
    }
    const change: AssetAvailabilityChange = {
      storageHash: storageHash,
      noteIds: uniqueNoteIds,
      generation: generation,
    };
    const callbacks: AssetAvailabilityListener[] = Array.from(this.listeners.values());
    for (const callback of callbacks) {
      try {
        callback(change);
      } catch (error) {
        console.error(`Asset availability listener failed: ${JSON.stringify(error)}`);
      }
    }
    return change;
  }

  getNoteGeneration(noteId: string): number {
    return this.noteGenerations.get(noteId) ?? 0;
  }
}

export const assetAvailabilityHub: AssetAvailabilityHub = new AssetAvailabilityHub();
