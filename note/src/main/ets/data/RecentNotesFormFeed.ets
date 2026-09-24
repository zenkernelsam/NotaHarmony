// 原版 RecentNotesWidgetProvider（qk9.java + app_widgets__widget_notes.xml）：
// 头部"Recent Notes"位图 → PendingIntent(VIEW+show_recent)；创建按钮 →
// PendingIntent(CREATE_NOTE)；行 = 48dp 缩略图(WidgetImageProvider
// content://.../thumbnail/<ttf>?f=<fp>) 或占位图标 + 标题位图 + 分隔线；
// 行点击 fillInIntent = nbnote:<ttf> + note_id extra；空态
// app_widgets__widget_recent_notes_empty；数据 = au1.N1(10) 最近列表。
// Harmony 等价：recent_notes_card ArkTS 卡片 + 本 feed。实例 formId 由
// NoteFormAbility.onAddForm/onRemoveForm 登记进 filesDir JSON（Harmony 无
// 活动实例枚举 API —— getFormsInfo 只返回声明态，文档化适配）；onAddForm /
// onUpdateForm 用 pushRecentNotesTitles 推标题（FormExtensionAbility 仅有
// ~5s 后台预算且无 UIAbilityContext，无法跑 ThumbnailRenderer —— 缩略图仅
// 由 refreshRecentNotesForms 在 UIAbility 侧补齐，行为等价于原版
// WidgetImageProvider 懒加载路径：标题先行、缩略图随后到达）。
import { common } from '@kit.AbilityKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { NoteMeta } from '../core/model/NoteTypes';
import { ThemeTokens } from '../ui/theme/EditorTheme';
import { ThumbnailRenderer } from '../rendering/ThumbnailRenderer';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { StrokePersistence, FirstPageThumbnailState } from './StrokePersistence';

export const RECENT_NOTES_FORM_NAME: string = 'recent_notes_card';
const FORM_IDS_FILE: string = 'recent_notes_form_ids.json';
const FORM_THUMB_DIR: string = 'form_recent_thumbs';
// API <=19 单次刷新图片上限 5 张（API >=20 才放宽到 20）——保守取 5。
const MAX_FORM_THUMBS: number = 5;
const THUMB_QUALITY: number = 80;

export interface RecentCardItem {
  id: string;
  title: string;
  thumb: string;
  folder: string;
}

interface RecentFormBindingPayload {
  items: RecentCardItem[];
  itemCount: number;
  formImages: Record<string, number>;
}

function formIdsPath(context: common.Context): string {
  return `${context.filesDir}/${FORM_IDS_FILE}`;
}

async function readFormIds(context: common.Context): Promise<string[]> {
  const path: string = formIdsPath(context);
  try {
    if (!fileIo.accessSync(path)) {
      return [];
    }
    const content: string = fileIo.readTextSync(path);
    const parsed: string[] = JSON.parse(content) as string[];
    return Array.isArray(parsed) ? parsed.filter((id: string) => id.length > 0) : [];
  } catch (e) {
    console.error(`recent form ids read failed: ${JSON.stringify(e)}`);
    return [];
  }
}

async function writeFormIds(context: common.Context, ids: string[]): Promise<void> {
  const path: string = formIdsPath(context);
  try {
    const file: fileIo.File = fileIo.openSync(path,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, JSON.stringify(ids));
    } finally {
      fileIo.closeSync(file);
    }
  } catch (e) {
    console.error(`recent form ids write failed: ${JSON.stringify(e)}`);
  }
}

export async function registerRecentNotesForm(context: common.Context,
  formId: string): Promise<void> {
  if (formId.length === 0) {
    return;
  }
  const ids: string[] = await readFormIds(context);
  if (!ids.includes(formId)) {
    ids.push(formId);
    await writeFormIds(context, ids);
  }
}

export async function unregisterRecentNotesForm(context: common.Context,
  formId: string): Promise<void> {
  const ids: string[] = await readFormIds(context);
  const next: string[] = ids.filter((id: string) => id !== formId);
  if (next.length !== ids.length) {
    await writeFormIds(context, next);
  }
}

function cardItems(notes: NoteMeta[], thumbKeys: Map<string, string>): RecentCardItem[] {
  const items: RecentCardItem[] = [];
  for (const note of notes) {
    items.push({
      id: note.id,
      title: note.title,
      thumb: thumbKeys.get(note.id) ?? '',
      folder: note.folderName ?? ''
    });
  }
  return items;
}

async function updateRecentForm(formId: string, items: RecentCardItem[],
  formImages: Record<string, number>): Promise<void> {
  const data: RecentFormBindingPayload = {
    items: items,
    itemCount: items.length,
    formImages: formImages
  };
  try {
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
  } catch (e) {
    console.error(`recent form update failed for ${formId}: ${JSON.stringify(e)}`);
  }
}

// 标题-only 推送：FormExtensionAbility（onAddForm/onUpdateForm）与 UIAbility
// 两侧均可调用——只读 note_meta，不触碰渲染管线。
export async function pushRecentNotesTitles(context: common.Context,
  targetFormId?: string): Promise<void> {
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const notes: NoteMeta[] = await repo.getRecentNotes();
    const items: RecentCardItem[] = cardItems(notes, new Map<string, string>());
    const ids: string[] = targetFormId !== undefined ? [targetFormId] :
      await readFormIds(context);
    for (const formId of ids) {
      await updateRecentForm(formId, items, {});
    }
  } catch (e) {
    console.error(`pushRecentNotesTitles failed: ${JSON.stringify(e)}`);
  }
}

// 全量推送：标题 + 缩略图 formImages。仅 UIAbility 侧调用（需要
// UIAbilityContext 初始化 ThumbnailRenderer 的铅笔纹理/数学引擎）。
export async function refreshRecentNotesForms(context: common.UIAbilityContext,
  theme: ThemeTokens): Promise<void> {
  const ids: string[] = await readFormIds(context);
  if (ids.length === 0) {
    return;
  }
  let renderer: ThumbnailRenderer | null = null;
  const openedFds: number[] = [];
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const notes: NoteMeta[] = await repo.getRecentNotes();
    const thumbKeys: Map<string, string> = new Map<string, string>();
    const formImages: Record<string, number> = {};
    const thumbDir: string = `${context.filesDir}/${FORM_THUMB_DIR}`;
    if (!fileIo.accessSync(thumbDir)) {
      fileIo.mkdirSync(thumbDir, true);
    }
    const persistence: StrokePersistence = new StrokePersistence();
    const packer: image.ImagePacker = image.createImagePacker();
    const thumbed: NoteMeta[] = notes.slice(0, MAX_FORM_THUMBS);
    if (thumbed.length > 0) {
      renderer = new ThumbnailRenderer();
      await renderer.initialize(context);
    }
    for (const note of thumbed) {
      const state: FirstPageThumbnailState | null =
        await persistence.getFirstPageThumbnailState(note.id);
      if (state === null) {
        continue;
      }
      let pixelMap: image.PixelMap | null = null;
      try {
        if (renderer === null) {
          continue;
        }
        pixelMap = await renderer.renderThumbnail(note.id, persistence,
          state.page, theme, db);
        const packed: ArrayBuffer = await packer.packing(pixelMap,
          { format: 'image/webp', quality: THUMB_QUALITY });
        const key: string = `thumb_${note.id}_${note.updatedAt}`;
        const filePath: string = `${thumbDir}/${key}.webp`;
        const file: fileIo.File = fileIo.openSync(filePath,
          fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE |
          fileIo.OpenMode.TRUNC);
        try {
          fileIo.writeSync(file.fd, packed);
        } finally {
          fileIo.closeSync(file);
        }
        const readFd: fileIo.File = fileIo.openSync(filePath,
          fileIo.OpenMode.READ_ONLY);
        formImages[key] = readFd.fd;
        openedFds.push(readFd.fd);
        thumbKeys.set(note.id, key);
      } catch (e) {
        console.error(`form thumb render failed for ${note.id}: ${JSON.stringify(e)}`);
      } finally {
        if (pixelMap !== null) {
          await pixelMap.release();
        }
      }
    }
    const items: RecentCardItem[] = cardItems(notes, thumbKeys);
    for (const formId of ids) {
      await updateRecentForm(formId, items, formImages);
    }
  } catch (e) {
    console.error(`refreshRecentNotesForms failed: ${JSON.stringify(e)}`);
  } finally {
    for (const fd of openedFds) {
      try {
        fileIo.closeSync(fd);
      } catch (e) {
        console.error(`form image fd close failed: ${JSON.stringify(e)}`);
      }
    }
    if (renderer !== null) {
      await renderer.dispose();
    }
  }
}
