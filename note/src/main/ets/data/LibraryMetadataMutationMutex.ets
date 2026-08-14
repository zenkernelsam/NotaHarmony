import { AsyncMutex } from './AsyncMutex';
import { databaseWriteMutex } from './DatabaseWriteMutex';

// Compatibility name for note/folder metadata mutations. When an operation also needs
// assetMutationMutex, acquire the asset mutex first and this shared database writer second.
export const libraryMetadataMutationMutex: AsyncMutex = databaseWriteMutex;
