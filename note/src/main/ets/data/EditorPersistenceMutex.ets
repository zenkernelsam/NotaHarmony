import { AsyncMutex } from './AsyncMutex';
import { databaseWriteMutex } from './DatabaseWriteMutex';

// Compatibility name for editor callers. DatabaseManager exposes one RdbStore, so editor writes
// share the same writer with library metadata, assets and tool state.
export const editorPersistenceMutex: AsyncMutex = databaseWriteMutex;
