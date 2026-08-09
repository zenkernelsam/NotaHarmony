import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const STORE_NAME: string = 'noteEditorSettings';
const SHAPE_DETECTION_KEY: string = 'shapeDetectionEnabled';

export interface EditorSettingsRepository {
  getShapeDetectionEnabled(): Promise<boolean>;
  saveShapeDetectionEnabled(enabled: boolean): Promise<void>;
}

export class EditorSettingsStore implements EditorSettingsRepository {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  async getShapeDetectionEnabled(): Promise<boolean> {
    try {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      return store.getSync(SHAPE_DETECTION_KEY, true) as boolean;
    } catch (e) {
      throw new Error(`getShapeDetectionEnabled failed: ${JSON.stringify(e)}`);
    }
  }

  async saveShapeDetectionEnabled(enabled: boolean): Promise<void> {
    try {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      store.putSync(SHAPE_DETECTION_KEY, enabled);
      await store.flush();
    } catch (e) {
      throw new Error(`saveShapeDetectionEnabled failed: ${JSON.stringify(e)}`);
    }
  }
}
