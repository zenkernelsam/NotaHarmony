import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import {
  OriginalDefaultTemplateSelection, originalFallbackDefaultTemplate,
} from '../core/model/OriginalDefaultTemplate';
import {
  NOTE_TITLE_POSITION_NONE, NOTE_TITLE_POSITION_PREFIX,
  NOTE_TITLE_POSITION_SUFFIX,
} from '../core/model/OriginalNoteTitlePolicy';
import { AsyncMutex } from './AsyncMutex';
import {
  decodeOriginalDefaultTemplate, encodeOriginalDefaultTemplate,
} from './OriginalDefaultTemplateCodec';

const STORE_NAME: string = 'noteEditorSettings';
const SHAPE_DETECTION_KEY: string = 'shapeDetectionEnabled';
const SELECTED_DEFAULT_TEMPLATE_KEY: string = 'selectedDefaultTemplate';
const KEEP_DEVICE_AWAKE_KEY: string = 'keepDeviceAwake';
const HIDE_STATUS_BAR_KEY: string = 'hideStatusBar';
const HIDE_NAVIGATION_BAR_KEY: string = 'hideNavigationBar';
const NOTE_VIEW_NIGHT_MODE_KEY: string = 'noteViewNightMode';
const AUTO_DESELECT_ERASER_KEY: string = 'autoDeselectEraser';
const PALM_DETECTION_KEY: string = 'palmDetectionEnabled';
const STRAIGHT_LINES_KEY: string = 'straightLinesEnabled';
export const DEFAULT_SHAPE_DETECTION_ENABLED: boolean = true;
// 原版 o59.c 真值表：keepAwake/noteNightView/autoDeselectEraser 缺省 false；
// hideStatusBar/hideNavigationBar 缺省 true（opt-out，证据修正 Phase 561）。
export const DEFAULT_KEEP_DEVICE_AWAKE: boolean = false;
export const DEFAULT_HIDE_STATUS_BAR: boolean = true;
export const DEFAULT_HIDE_NAVIGATION_BAR: boolean = true;
export const DEFAULT_NOTE_VIEW_NIGHT_MODE: boolean = false;
export const DEFAULT_AUTO_DESELECT_ERASER: boolean = false;
// 原版 o59.c：palmDetectionEnabled 缺省 true（书写时忽略手掌触摸）。
export const DEFAULT_PALM_DETECTION: boolean = true;
// 原版 o59.c：straightLinesEnabled 缺省 true（按住自动拉直线条）。
export const DEFAULT_STRAIGHT_LINES: boolean = true;
const LASER_SHOW_TAIL_KEY: string = 'laserShowTail';
// 原版 cu6.i / bu6(true)：laser_preferences.show_tail 缺省 true。
export const DEFAULT_LASER_SHOW_TAIL: boolean = true;
// 原版 o59.n = eua("rulerUnits")；取值序列化为 oof.I（"Imperial"/"Metric"），
// ub5() 默认 oof.IMPERIAL（x22 case 4 / n94 选择器 / ss8 case 8 写入）。
const RULER_UNITS_KEY: string = 'rulerUnits';
export const RULER_UNITS_IMPERIAL: string = 'Imperial';
export const RULER_UNITS_METRIC: string = 'Metric';
export const DEFAULT_RULER_UNITS: string = RULER_UNITS_IMPERIAL;
// 原版 o59.r = eua("zoomViewAdvanceRegionWidthDp")：Zoom 面板自动前进区宽。
// g0j advance_tab 拖拽 → setAdvanceRegionWidth → n27 case 2 tk8.g 持久化；
// lgg/ggg.e 默认 180dp（Harmony 以 vp 承载，vp≈dp 语义等价）。
const ZOOM_ADVANCE_WIDTH_KEY: string = 'zoomViewAdvanceRegionWidthDp';
export const DEFAULT_ZOOM_ADVANCE_WIDTH_DP: number = 180;
// 原版 o8b.P = dcd("undoRedoTapsEnabled")；o8b.f/g 解码缺省 true（bool6 null→true）。
const UNDO_REDO_TAPS_KEY: string = 'undoRedoTapsEnabled';
export const DEFAULT_UNDO_REDO_TAPS: boolean = true;
// 原版 o8b.M/N/O = dcd("defaultNoteTitle")/dcd("includeDatePosition")/
// dcd("includeTimePosition")（yob/ibb 笔记标题设置页；mcn.g 组装新笔记标题）。
// 解码缺省：defaultNoteTitle→null（从未设置才落回 "Note" fallback）；
// includeDatePosition→hmi.SUFFIX；includeTimePosition→hmi.NONE。
// hmi 按名称序列化（"None"/"Prefix"/"Suffix"，pp7.l 解析失败→缺省）。
const DEFAULT_NOTE_TITLE_KEY: string = 'defaultNoteTitle';
const INCLUDE_DATE_POSITION_KEY: string = 'includeDatePosition';
const INCLUDE_TIME_POSITION_KEY: string = 'includeTimePosition';
// hmi 名常量（None/Prefix/Suffix）由 core/model/OriginalNoteTitlePolicy 导出。
export const DEFAULT_INCLUDE_DATE_POSITION: string = NOTE_TITLE_POSITION_SUFFIX;
export const DEFAULT_INCLUDE_TIME_POSITION: string = NOTE_TITLE_POSITION_NONE;

export interface EditorSettingsRepository {
  getShapeDetectionEnabled(): Promise<boolean>;
  saveShapeDetectionEnabled(enabled: boolean): Promise<void>;
  getKeepDeviceAwake(): Promise<boolean>;
  saveKeepDeviceAwake(enabled: boolean): Promise<void>;
  getHideStatusBar(): Promise<boolean>;
  saveHideStatusBar(enabled: boolean): Promise<void>;
  getHideNavigationBar(): Promise<boolean>;
  saveHideNavigationBar(enabled: boolean): Promise<void>;
  getNoteViewNightMode(): Promise<boolean>;
  saveNoteViewNightMode(enabled: boolean): Promise<void>;
  getAutoDeselectEraser(): Promise<boolean>;
  saveAutoDeselectEraser(enabled: boolean): Promise<void>;
  getPalmDetectionEnabled(): Promise<boolean>;
  savePalmDetectionEnabled(enabled: boolean): Promise<void>;
  getStraightLinesEnabled(): Promise<boolean>;
  saveStraightLinesEnabled(enabled: boolean): Promise<void>;
  getRulerUnits(): Promise<string>;
  saveRulerUnits(units: string): Promise<void>;
  getLaserShowTail(): Promise<boolean>;
  saveLaserShowTail(enabled: boolean): Promise<void>;
  getZoomAdvanceWidthDp(): Promise<number>;
  saveZoomAdvanceWidthDp(widthDp: number): Promise<void>;
  getUndoRedoTapsEnabled(): Promise<boolean>;
  saveUndoRedoTapsEnabled(enabled: boolean): Promise<void>;
  // 原版 dpb.a：缺省 null 表示从未设置（o8b.f 落回
  // ui_notedefaults__default_note_title_fallback）；空串表示用户清空。
  getDefaultNoteTitle(): Promise<string | null>;
  saveDefaultNoteTitle(title: string): Promise<void>;
  getIncludeDatePosition(): Promise<string>;
  saveIncludeDatePosition(position: string): Promise<void>;
  getIncludeTimePosition(): Promise<string>;
  saveIncludeTimePosition(position: string): Promise<void>;
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

  private async getBooleanPref(key: string, fallback: boolean): Promise<boolean> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(this.context, STORE_NAME);
        const value = store.getSync(key, fallback);
        return typeof value === 'boolean' ? value : fallback;
      } catch (e) {
        throw new Error(`getBooleanPref(${key}) failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async saveBooleanPref(key: string, enabled: boolean,
    fallback: boolean, tag: string): Promise<void> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<void> => {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const hadPrevious: boolean = store.hasSync(key);
      const previous = store.getSync(key, fallback);
      store.putSync(key, enabled);
      try {
        await store.flush();
      } catch (e) {
        if (hadPrevious) {
          store.putSync(key, previous);
        } else {
          store.deleteSync(key);
        }
        try {
          await store.flush();
        } catch (rollbackError) {
          throw new Error(`${tag} commit and rollback failed: ${JSON.stringify(e)}; ` +
            `${JSON.stringify(rollbackError)}`);
        }
        throw new Error(`${tag} failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async getNumberPref(key: string, fallback: number): Promise<number> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<number> => {
      try {
        const store = await preferences.getPreferences(this.context, STORE_NAME);
        const value = store.getSync(key, fallback);
        return typeof value === 'number' ? value : fallback;
      } catch (e) {
        throw new Error(`getNumberPref(${key}) failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async saveNumberPref(key: string, value: number,
    fallback: number, tag: string): Promise<void> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<void> => {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const hadPrevious: boolean = store.hasSync(key);
      const previous = store.getSync(key, fallback);
      store.putSync(key, value);
      try {
        await store.flush();
      } catch (e) {
        if (hadPrevious) {
          store.putSync(key, previous);
        } else {
          store.deleteSync(key);
        }
        try {
          await store.flush();
        } catch (rollbackError) {
          throw new Error(`${tag} commit and rollback failed: ${JSON.stringify(e)}; ` +
            `${JSON.stringify(rollbackError)}`);
        }
        throw new Error(`${tag} failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async getStringPref(key: string, fallback: string): Promise<string> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<string> => {
      try {
        const store = await preferences.getPreferences(this.context, STORE_NAME);
        const value = store.getSync(key, fallback);
        return typeof value === 'string' ? value : fallback;
      } catch (e) {
        throw new Error(`getStringPref(${key}) failed: ${JSON.stringify(e)}`);
      }
    });
  }

  private async saveStringPref(key: string, value: string,
    fallback: string, tag: string): Promise<void> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<void> => {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const hadPrevious: boolean = store.hasSync(key);
      const previous = store.getSync(key, fallback);
      store.putSync(key, value);
      try {
        await store.flush();
      } catch (e) {
        if (hadPrevious) {
          store.putSync(key, previous);
        } else {
          store.deleteSync(key);
        }
        try {
          await store.flush();
        } catch (rollbackError) {
          throw new Error(`${tag} commit and rollback failed: ${JSON.stringify(e)}; ` +
            `${JSON.stringify(rollbackError)}`);
        }
        throw new Error(`${tag} failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // 原版 r22 case 2：note-editor 设置区的 "Keep device awake" 开关；
  // 与 shape detection 同一条 prefs 存取/回滚路径。
  async getKeepDeviceAwake(): Promise<boolean> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<boolean> => {
      try {
        const store = await preferences.getPreferences(this.context, STORE_NAME);
        const value = store.getSync(KEEP_DEVICE_AWAKE_KEY, DEFAULT_KEEP_DEVICE_AWAKE);
        return typeof value === 'boolean' ? value : DEFAULT_KEEP_DEVICE_AWAKE;
      } catch (e) {
        throw new Error(`getKeepDeviceAwake failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async saveKeepDeviceAwake(enabled: boolean): Promise<void> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<void> => {
      const store = await preferences.getPreferences(this.context, STORE_NAME);
      const hadPrevious: boolean = store.hasSync(KEEP_DEVICE_AWAKE_KEY);
      const previous = store.getSync(KEEP_DEVICE_AWAKE_KEY, DEFAULT_KEEP_DEVICE_AWAKE);
      store.putSync(KEEP_DEVICE_AWAKE_KEY, enabled);
      try {
        await store.flush();
      } catch (e) {
        if (hadPrevious) {
          store.putSync(KEEP_DEVICE_AWAKE_KEY, previous);
        } else {
          store.deleteSync(KEEP_DEVICE_AWAKE_KEY);
        }
        try {
          await store.flush();
        } catch (rollbackError) {
          throw new Error(`saveKeepDeviceAwake commit and rollback failed: ${JSON.stringify(e)}; ` +
            `${JSON.stringify(rollbackError)}`);
        }
        throw new Error(`saveKeepDeviceAwake failed: ${JSON.stringify(e)}`);
      }
    });
  }

  // 原版 r22 case 3/4：note view 隐藏状态栏/导航条开关。
  async getHideStatusBar(): Promise<boolean> {
    return this.getBooleanPref(HIDE_STATUS_BAR_KEY, DEFAULT_HIDE_STATUS_BAR);
  }

  async saveHideStatusBar(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(HIDE_STATUS_BAR_KEY, enabled,
      DEFAULT_HIDE_STATUS_BAR, 'saveHideStatusBar');
  }

  async getHideNavigationBar(): Promise<boolean> {
    return this.getBooleanPref(HIDE_NAVIGATION_BAR_KEY, DEFAULT_HIDE_NAVIGATION_BAR);
  }

  async saveHideNavigationBar(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(HIDE_NAVIGATION_BAR_KEY, enabled,
      DEFAULT_HIDE_NAVIGATION_BAR, 'saveHideNavigationBar');
  }

  // 原版 r22 case 1：note view night mode ——纸墨以深色外观渲染。
  async getNoteViewNightMode(): Promise<boolean> {
    return this.getBooleanPref(NOTE_VIEW_NIGHT_MODE_KEY, DEFAULT_NOTE_VIEW_NIGHT_MODE);
  }

  async saveNoteViewNightMode(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(NOTE_VIEW_NIGHT_MODE_KEY, enabled,
      DEFAULT_NOTE_VIEW_NIGHT_MODE, 'saveNoteViewNightMode');
  }

  // 原版 x22 case 3 / o59.m：autoDeselectEraser —— 擦除后工具栏切回上个工具。
  async getAutoDeselectEraser(): Promise<boolean> {
    return this.getBooleanPref(AUTO_DESELECT_ERASER_KEY, DEFAULT_AUTO_DESELECT_ERASER);
  }

  async saveAutoDeselectEraser(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(AUTO_DESELECT_ERASER_KEY, enabled,
      DEFAULT_AUTO_DESELECT_ERASER, 'saveAutoDeselectEraser');
  }

  // 原版 x22 case 2 / o59.l：palmDetectionEnabled —— 书写时可放置手掌。
  async getPalmDetectionEnabled(): Promise<boolean> {
    return this.getBooleanPref(PALM_DETECTION_KEY, DEFAULT_PALM_DETECTION);
  }

  async savePalmDetectionEnabled(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(PALM_DETECTION_KEY, enabled,
      DEFAULT_PALM_DETECTION, 'savePalmDetectionEnabled');
  }

  // 原版 x22 case 0 / o59.j：straightLinesEnabled —— 画线后按住自动拉直。
  async getStraightLinesEnabled(): Promise<boolean> {
    return this.getBooleanPref(STRAIGHT_LINES_KEY, DEFAULT_STRAIGHT_LINES);
  }

  async saveStraightLinesEnabled(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(STRAIGHT_LINES_KEY, enabled,
      DEFAULT_STRAIGHT_LINES, 'saveStraightLinesEnabled');
  }

  // 原版 x22 case 4 / o59.n：rulerUnits —— n94 选择器写 Imperial/Metric，
  // 非法取值回退 ub5() 默认 IMPERIAL（原版尺具本身仍被 s01.a0 隐藏）。
  async getRulerUnits(): Promise<string> {
    const units: string = await this.getStringPref(RULER_UNITS_KEY, DEFAULT_RULER_UNITS);
    return units === RULER_UNITS_IMPERIAL || units === RULER_UNITS_METRIC
      ? units : DEFAULT_RULER_UNITS;
  }

  async saveRulerUnits(units: string): Promise<void> {
    await this.saveStringPref(RULER_UNITS_KEY, units,
      DEFAULT_RULER_UNITS, 'saveRulerUnits');
  }

  // 原版 cu6（laser_preferences/show_tail）：激光笔 tail 开关。
  async getLaserShowTail(): Promise<boolean> {
    return this.getBooleanPref(LASER_SHOW_TAIL_KEY, DEFAULT_LASER_SHOW_TAIL);
  }

  async saveLaserShowTail(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(LASER_SHOW_TAIL_KEY, enabled,
      DEFAULT_LASER_SHOW_TAIL, 'saveLaserShowTail');
  }

  // 原版 o59.r / n27 case 2：zoomViewAdvanceRegionWidthDp（Float）持久化。
  async getZoomAdvanceWidthDp(): Promise<number> {
    return this.getNumberPref(ZOOM_ADVANCE_WIDTH_KEY, DEFAULT_ZOOM_ADVANCE_WIDTH_DP);
  }

  async saveZoomAdvanceWidthDp(widthDp: number): Promise<void> {
    await this.saveNumberPref(ZOOM_ADVANCE_WIDTH_KEY, widthDp,
      DEFAULT_ZOOM_ADVANCE_WIDTH_DP, 'saveZoomAdvanceWidthDp');
  }

  // 原版 o8b.P / nf6(j8b.C)：undoRedoTapsEnabled —— 双指轻点撤销、
  // 三指轻点重做（kd4 case 15 设置行，data_onboarding 首次提示同款文案）。
  async getUndoRedoTapsEnabled(): Promise<boolean> {
    return this.getBooleanPref(UNDO_REDO_TAPS_KEY, DEFAULT_UNDO_REDO_TAPS);
  }

  async saveUndoRedoTapsEnabled(enabled: boolean): Promise<void> {
    await this.saveBooleanPref(UNDO_REDO_TAPS_KEY, enabled,
      DEFAULT_UNDO_REDO_TAPS, 'saveUndoRedoTapsEnabled');
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

  // 原版 j8b.z：键缺失 = null（mcn.g 以 fallback "Note" 组装）；已写入的空串
  // 原样返回（r0h.T0 视为 blank 丢弃，标题只剩日期/时间分量）。
  async getDefaultNoteTitle(): Promise<string | null> {
    return EditorSettingsStore.mutex.runExclusive(async (): Promise<string | null> => {
      try {
        const store = await preferences.getPreferences(this.context, STORE_NAME);
        if (!store.hasSync(DEFAULT_NOTE_TITLE_KEY)) {
          return null;
        }
        const value = store.getSync(DEFAULT_NOTE_TITLE_KEY, '');
        return typeof value === 'string' ? value : null;
      } catch (e) {
        throw new Error(`getDefaultNoteTitle failed: ${JSON.stringify(e)}`);
      }
    });
  }

  async saveDefaultNoteTitle(title: string): Promise<void> {
    await this.saveStringPref(DEFAULT_NOTE_TITLE_KEY, title,
      '', 'saveDefaultNoteTitle');
  }

  // 原版 pp7.l：未知名称 → null → 调用方回落缺省（date=SUFFIX / time=NONE）。
  private sanitizeTitlePosition(value: string, fallback: string): string {
    return value === NOTE_TITLE_POSITION_NONE ||
      value === NOTE_TITLE_POSITION_PREFIX ||
      value === NOTE_TITLE_POSITION_SUFFIX ? value : fallback;
  }

  async getIncludeDatePosition(): Promise<string> {
    const position: string = await this.getStringPref(
      INCLUDE_DATE_POSITION_KEY, DEFAULT_INCLUDE_DATE_POSITION);
    return this.sanitizeTitlePosition(position, DEFAULT_INCLUDE_DATE_POSITION);
  }

  async saveIncludeDatePosition(position: string): Promise<void> {
    await this.saveStringPref(INCLUDE_DATE_POSITION_KEY,
      this.sanitizeTitlePosition(position, DEFAULT_INCLUDE_DATE_POSITION),
      DEFAULT_INCLUDE_DATE_POSITION, 'saveIncludeDatePosition');
  }

  async getIncludeTimePosition(): Promise<string> {
    const position: string = await this.getStringPref(
      INCLUDE_TIME_POSITION_KEY, DEFAULT_INCLUDE_TIME_POSITION);
    return this.sanitizeTitlePosition(position, DEFAULT_INCLUDE_TIME_POSITION);
  }

  async saveIncludeTimePosition(position: string): Promise<void> {
    await this.saveStringPref(INCLUDE_TIME_POSITION_KEY,
      this.sanitizeTitlePosition(position, DEFAULT_INCLUDE_TIME_POSITION),
      DEFAULT_INCLUDE_TIME_POSITION, 'saveIncludeTimePosition');
  }
}
