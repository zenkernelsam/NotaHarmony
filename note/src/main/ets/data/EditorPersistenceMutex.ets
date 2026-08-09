import { AsyncMutex } from './AsyncMutex';

// Serializes editor snapshot transactions with persistent-history checkpoint replacement.
export const editorPersistenceMutex: AsyncMutex = new AsyncMutex();
