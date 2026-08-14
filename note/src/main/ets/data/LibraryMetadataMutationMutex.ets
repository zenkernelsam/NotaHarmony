import { AsyncMutex } from './AsyncMutex';

// Repository mutations that change note/folder metadata share one writer gate across instances.
// When an operation also needs assetMutationMutex, acquire the asset mutex first and this mutex
// second. Metadata-only operations must not retain this mutex while doing post-commit I/O.
export const libraryMetadataMutationMutex: AsyncMutex = new AsyncMutex();
