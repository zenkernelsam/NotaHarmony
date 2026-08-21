import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  originalHandwritingRecognitionLocaleCode,
} from '../core/model/OriginalHandwritingLanguagePolicy';
import { AsyncMutex } from './AsyncMutex';

export const ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_STORE_NAME: string =
  'handwritingRecognitionSettings';
export const ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_KEY: string =
  'recognitionLanguageId';

export interface OriginalHandwritingLanguagePreferenceStorage {
  has(): Promise<boolean>;
  read(): Promise<preferences.ValueType>;
  put(value: preferences.ValueType): Promise<void>;
  remove(): Promise<void>;
  flush(): Promise<void>;
}

export class OriginalHandwritingLanguagePreferenceTransaction {
  private storage: OriginalHandwritingLanguagePreferenceStorage;

  constructor(storage: OriginalHandwritingLanguagePreferenceStorage) {
    this.storage = storage;
  }

  async getRecognitionLanguageId(): Promise<string | null> {
    if (!await this.storage.has()) {
      return null;
    }
    const raw: preferences.ValueType = await this.storage.read();
    if (typeof raw !== 'string') {
      return null;
    }
    return originalHandwritingRecognitionLocaleCode(raw);
  }

  async saveRecognitionLanguageId(value: string): Promise<void> {
    const localeCode: string | null = originalHandwritingRecognitionLocaleCode(value);
    if (localeCode === null) {
      throw new Error('original handwriting recognition language preference is unsupported');
    }
    const hadPrevious: boolean = await this.storage.has();
    const previous: preferences.ValueType | null = hadPrevious ? await this.storage.read() : null;
    try {
      // Treat put() as part of the transaction too. Harmony may reject a
      // synchronous/in-memory mutation before flush(), and a failed put must
      // still be compensated because the API does not promise all-or-nothing
      // mutation semantics.
      await this.storage.put(localeCode);
      await this.storage.flush();
    } catch (error) {
      let rollbackError: Error | null = null;
      let rollbackMutationSucceeded: boolean = false;
      try {
        if (hadPrevious && previous !== null) {
          await this.storage.put(previous);
        } else {
          await this.storage.remove();
        }
        rollbackMutationSucceeded = true;
      } catch (error) {
        rollbackError = error as Error;
      }
      // Never flush an unknown in-memory state after compensation mutation
      // failed. A later caller may still recover the store object; persisting
      // here would turn an uncertain rollback into a committed new value.
      if (rollbackMutationSucceeded) {
        try {
          await this.storage.flush();
        } catch (flushRollbackError) {
          if (rollbackError === null) {
            rollbackError = flushRollbackError as Error;
          }
        }
      }
      if (rollbackError !== null) {
        throw new Error(`saveRecognitionLanguageId commit and rollback failed: ` +
          `${JSON.stringify(error)}; ${JSON.stringify(rollbackError)}`);
      }
      throw new Error(`saveRecognitionLanguageId failed: ${JSON.stringify(error)}`);
    }
  }
}

class HarmonyOriginalHandwritingLanguagePreferenceStorage implements
  OriginalHandwritingLanguagePreferenceStorage {
  private context: common.Context;
  private storePromise: Promise<preferences.Preferences> | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  private async getStore(): Promise<preferences.Preferences> {
    if (this.storePromise === null) {
      this.storePromise = preferences.getPreferences(
        this.context, ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_STORE_NAME);
    }
    try {
      return await this.storePromise;
    } catch (error) {
      // A rejected lookup must not poison all later attempts forever.
      this.storePromise = null;
      throw error;
    }
  }

  async has(): Promise<boolean> {
    const store: preferences.Preferences = await this.getStore();
    return store.hasSync(ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_KEY);
  }

  async read(): Promise<preferences.ValueType> {
    const store: preferences.Preferences = await this.getStore();
    return store.getSync(ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_KEY, '');
  }

  async put(value: preferences.ValueType): Promise<void> {
    const store: preferences.Preferences = await this.getStore();
    store.putSync(ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_KEY, value);
  }

  async remove(): Promise<void> {
    const store: preferences.Preferences = await this.getStore();
    store.deleteSync(ORIGINAL_HANDWRITING_LANGUAGE_PREFERENCE_KEY);
  }

  async flush(): Promise<void> {
    const store: preferences.Preferences = await this.getStore();
    await store.flush();
  }
}

export class OriginalHandwritingLanguagePreferenceStore {
  private static mutex: AsyncMutex = new AsyncMutex();
  private transaction: OriginalHandwritingLanguagePreferenceTransaction;

  constructor(context: common.Context) {
    this.transaction = new OriginalHandwritingLanguagePreferenceTransaction(
      new HarmonyOriginalHandwritingLanguagePreferenceStorage(context));
  }

  async getRecognitionLanguageId(): Promise<string | null> {
    return OriginalHandwritingLanguagePreferenceStore.mutex.runExclusive(
      async (): Promise<string | null> => this.transaction.getRecognitionLanguageId());
  }

  async saveRecognitionLanguageId(value: string): Promise<void> {
    return OriginalHandwritingLanguagePreferenceStore.mutex.runExclusive(
      async (): Promise<void> => this.transaction.saveRecognitionLanguageId(value));
  }
}
