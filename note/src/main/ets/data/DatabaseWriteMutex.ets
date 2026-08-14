import { AsyncMutex } from './AsyncMutex';

// DatabaseManager publishes one shared RdbStore. All runtime writes must use the same writer so
// a statement cannot join another subsystem's active transaction and two beginTransaction calls
// cannot overlap. Domain locks (for example assetMutationMutex) are acquired before this mutex.
export const databaseWriteMutex: AsyncMutex = new AsyncMutex();
