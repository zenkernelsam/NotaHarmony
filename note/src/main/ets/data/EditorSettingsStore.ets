import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AsyncMutex } from './AsyncMutex';

const STORE_NAME: string = 'noteEditorSettings';
const SHAPE_DETECTION_KEY: string = 'shapeDetectionEnabled';
export const DEFAULT_SHAPE_DETECTION_ENABLED: boolean = true;

export interface EditorSettingsRepository {
  getShapeDetectionEnabled(): Promise<boolean>;
  saveShapeDetectionEnabled(enabled: boolean): Promise<void>;
}

export class EditorSettingsStore implements EditorSettingsRepository {
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
}
