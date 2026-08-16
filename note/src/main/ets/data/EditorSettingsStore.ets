import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  OriginalDefaultTemplateSelection, originalFallbackDefaultTemplate,
} from '../core/model/OriginalDefaultTemplate';
import { AsyncMutex } from './AsyncMutex';
import {
  decodeOriginalDefaultTemplate, encodeOriginalDefaultTemplate,
} from './OriginalDefaultTemplateCodec';

const STORE_NAME: string = 'noteEditorSettings';
const SHAPE_DETECTION_KEY: string = 'shapeDetectionEnabled';
const SELECTED_DEFAULT_TEMPLATE_KEY: string = 'selectedDefaultTemplate';
export const DEFAULT_SHAPE_DETECTION_ENABLED: boolean = true;

export interface EditorSettingsRepository {
  getShapeDetectionEnabled(): Promise<boolean>;
  saveShapeDetectionEnabled(enabled: boolean): Promise<void>;
}

export interface DefaultNoteTemplateRepository {
  getSelectedDefaultTemplate(): Promise<OriginalDefaultTemplateSelection>;
  saveSelectedDefaultTemplate(selection: OriginalDefaultTemplateSelection): Promise<void>;
}

export class EditorSettingsStore implements EditorSettingsRepository, DefaultNoteTemplateRepository {
  private static mutex: AsyncMutex = new AsyncMutex();
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  async getShapeDetectionEnabled(): Promise<boolean> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(this.context, STORE_NAME);
        const value = store.getSync(SHAPE_DETECTION_KEY, DEFAULT_SHAPE_DETECTION_ENABLED);
        return typeof value === 'boolean' ? value : DEFAULT_SHAPE_DETECTION_ENABLED;
      } catch (e) {
        throw new Error(`getShapeDetectionEnabled failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async saveShapeDetectionEnabled(enabled: boolean): Promise<void> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<void> => {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const hadPrevious: boolean = store.hasSync(SHAPE_DETECTION_KEY);
      const previous = store.getSync(SHAPE_DETECTION_KEY, DEFAULT_SHAPE_DETECTION_ENABLED);
      store.putSync(SHAPE_DETECTION_KEY, enabled);
      try {
        await store.flush();
      } catch (e) {
        if (hadPrevious) {
          store.putSync(SHAPE_DETECTION_KEY, previous);
        } else {
          store.deleteSync(SHAPE_DETECTION_KEY);
        }
        try {
          await store.flush();
        } catch (rollbackError) {
          throw new Error(`saveShapeDetectionEnabled commit and rollback failed: ${JSON.stringify(e)}; ` +
            `${JSON.stringify(rollbackError)}`);
        }
        throw new Error(`saveShapeDetectionEnabled failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async getSelectedDefaultTemplate(): Promise<OriginalDefaultTemplateSelection> {
    return EditorSettingsStore.mutex.runExclusive(
      async (): Promise<OriginalDefaultTemplateSelection> => {
        try {
          const store: preferences.Preferences =
            await preferences.getPreferences(this.context, STORE_NAME);
          if (!store.hasSync(SELECTED_DEFAULT_TEMPLATE_KEY)) {
            return originalFallbackDefaultTemplate();
          }
          const raw: preferences.ValueType = store.getSync(
            SELECTED_DEFAULT_TEMPLATE_KEY, new Uint8Array(0));
          if (!(raw instanceof Uint8Array)) {
            await this.clearWrongTypeDefaultTemplate(store);
            return originalFallbackDefaultTemplate();
          }
          const decoded: OriginalDefaultTemplateSelection | null =
            decodeOriginalDefaultTemplate(raw);
          if (decoded === null) {
            return originalFallbackDefaultTemplate();
          }
          return decoded;
        } catch (e) {
          throw new Error(`getSelectedDefaultTemplate failed: ${JSON.stringify(e)}`);
        }
      });
  }

  async saveSelectedDefaultTemplate(selection: OriginalDefaultTemplateSelection): Promise<void> {
    const encoded: Uint8Array = encodeOriginalDefaultTemplate(selection);
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<void> => {
      const store: preferences.Preferences =
        await preferences.getPreferences(this.context, STORE_NAME);
      const hadPrevious: boolean = store.hasSync(SELECTED_DEFAULT_TEMPLATE_KEY);
      const previous: preferences.ValueType = store.getSync(
        SELECTED_DEFAULT_TEMPLATE_KEY, new Uint8Array(0));
      store.putSync(SELECTED_DEFAULT_TEMPLATE_KEY, encoded);
      try {
        await store.flush();
      } catch (e) {
        if (hadPrevious) {
          store.putSync(SELECTED_DEFAULT_TEMPLATE_KEY, previous);
        } else {
          store.deleteSync(SELECTED_DEFAULT_TEMPLATE_KEY);
        }
        try {
          await store.flush();
        } catch (rollbackError) {
          throw new Error(`saveSelectedDefaultTemplate commit and rollback failed: ` +
            `${JSON.stringify(e)}; ${JSON.stringify(rollbackError)}`);
        }
        throw new Error(`saveSelectedDefaultTemplate failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async clearWrongTypeDefaultTemplate(store: preferences.Preferences): Promise<void> {
    if (!store.hasSync(SELECTED_DEFAULT_TEMPLATE_KEY)) {
      return;
    }
    store.deleteSync(SELECTED_DEFAULT_TEMPLATE_KEY);
    try {
      await store.flush();
    } catch (_error) {
      // Corrupt settings must not prevent the original Letter/Plain fallback from loading.
    }
  }
}
