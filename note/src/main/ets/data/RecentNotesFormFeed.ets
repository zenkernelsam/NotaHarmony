// 原版 RecentNotesWidgetProvider（qk9.java + app_widgets__widget_notes.xml）：
// 头部"Recent Notes"位图 → PendingIntent(VIEW+show_recent)；创建按钮 →
// PendingIntent(CREATE_NOTE)；行 = 48dp 缩略图(WidgetImageProvider
// content://.../thumbnail/<ttf>?f=<fp>) 或占位图标 + 标题位图 + 分隔线；
// 行点击 fillInIntent = nbnote:<ttf> + note_id extra；空态
// app_widgets__widget_recent_notes_empty；数据 = au1.N1(10) 最近列表。
// 原版 FolderNotesWidgetProvider 同为 qk9 子类 —— 本文件的
// pushNoteListForms 是两张卡共用的通用列表推送引擎（items + formImages）。
// Harmony 等价：卡片 + 本 feed。实例 formId 由各注册器登记进 filesDir
// JSON（Harmony 无活动实例枚举 API —— getFormsInfo 只返回声明态，文档化
// 适配）；扩展侧仅推标题（FormExtensionAbility 无 UIAbilityContext 且仅
// ~5s 后台预算），缩略图由 UIAbility 侧补齐——等价原版
// WidgetImageProvider 懒加载路径：标题先行、缩略图随后到达。
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

export interface NoteListFormExtras {
  folderId: string;
  folderName: string;
  configured: boolean;
}

export interface NoteListFormPush {
  formId: string;
  notes: NoteMeta[];
  extras: NoteListFormExtras;
}

interface RecentFormBindingPayload {
  items: RecentCardItem[];
  itemCount: number;
  formImages: Record<string, number>;
  folderId: string;
  folderName: string;
  configured: boolean;
}

function formIdsPath(context: common.Context): string {
  return `${context.filesDir}/${FORM_IDS_FILE}`;
}

export async function readJsonFile(path: string): Promise<string> {
  try {
    if (!fileIo.accessSync(path)) {
      return '';
    }
    return fileIo.readTextSync(path);
  } catch (e) {
    console.error(`json file read failed: ${JSON.stringify(e)}`);
    return '';
  }
}

export async function writeJsonFile(path: string, content: string): Promise<void> {
  try {
    const file: fileIo.File = fileIo.openSync(path,
      fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      fileIo.writeSync(file.fd, content);
    } finally {
      fileIo.closeSync(file);
    }
  } catch (e) {
    console.error(`json file write failed: ${JSON.stringify(e)}`);
  }
}

async function readFormIds(context: common.Context): Promise<string[]> {
  const content: string = await readJsonFile(formIdsPath(context));
  if (content.length === 0) {
    return [];
  }
  try {
    const parsed: string[] = JSON.parse(content) as string[];
    return Array.isArray(parsed) ? parsed.filter((id: string) => id.length > 0) : [];
  } catch (e) {
    console.error(`recent form ids parse failed: ${JSON.stringify(e)}`);
    return [];
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
    await writeJsonFile(formIdsPath(context), JSON.stringify(ids));
  }
}

export async function unregisterRecentNotesForm(context: common.Context,
  formId: string): Promise<void> {
  const ids: string[] = await readFormIds(context);
  const next: string[] = ids.filter((id: string) => id !== formId);
  if (next.length !== ids.length) {
    await writeJsonFile(formIdsPath(context), JSON.stringify(next));
  }
}

export function buildNoteCardItems(notes: NoteMeta[],
  thumbKeys: Map<string, string>): RecentCardItem[] {
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

async function updateNoteListForm(formId: string, items: RecentCardItem[],
  formImages: Record<string, number>, extras: NoteListFormExtras): Promise<void> {
  const data: RecentFormBindingPayload = {
    items: items,
    itemCount: items.length,
    formImages: formImages,
    folderId: extras.folderId,
    folderName: extras.folderName,
    configured: extras.configured
  };
  try {
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
  } catch (e) {
    console.error(`note list form update failed for ${formId}: ${JSON.stringify(e)}`);
  }
}

export interface ThumbBatchResult {
  keys: Map<string, string>;
  images: Record<string, number>;
  fds: number[];
}

// 渲染一批笔记的缩略图并打包成 formImages（fd 键值对）。调用方负责在
// updateForm 完成后用 closeFormImageFds 关闭返回的 fds。
export async function renderFormThumbImages(context: common.UIAbilityContext,
  theme: ThemeTokens, notes: NoteMeta[], db: DatabaseManager,
  renderer: ThumbnailRenderer): Promise<ThumbBatchResult> {
  const keys: Map<string, string> = new Map<string, string>();
  const images: Record<string, number> = {};
  const fds: number[] = [];
  const thumbDir: string = `${context.filesDir}/${FORM_THUMB_DIR}`;
  if (!fileIo.accessSync(thumbDir)) {
    fileIo.mkdirSync(thumbDir, true);
  }
  const persistence: StrokePersistence = new StrokePersistence();
  const packer: image.ImagePacker = image.createImagePacker();
  for (const note of notes) {
    const state: FirstPageThumbnailState | null =
      await persistence.getFirstPageThumbnailState(note.id);
    if (state === null) {
      continue;
    }
    let pixelMap: image.PixelMap | null = null;
    try {
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
      images[key] = readFd.fd;
      fds.push(readFd.fd);
      keys.set(note.id, key);
    } catch (e) {
      console.error(`form thumb render failed for ${note.id}: ${JSON.stringify(e)}`);
    } finally {
      if (pixelMap !== null) {
        await pixelMap.release();
      }
    }
  }
  return { keys: keys, images: images, fds: fds };
}

export function closeFormImageFds(fds: number[]): void {
  for (const fd of fds) {
    try {
      fileIo.closeSync(fd);
    } catch (e) {
      console.error(`form image fd close failed: ${JSON.stringify(e)}`);
    }
  }
}

// 通用列表推送引擎：向每个目标 formId 推 items（+可选缩略图）。
// theme === null → 标题-only（扩展进程路径）；theme 非空 → 附缩略图
// formImages（UIAbility 进程路径）。缩略图在所有目标间按 noteId 去重渲染。
export async function pushNoteListForms(context: common.Context,
  theme: ThemeTokens | null, pushes: NoteListFormPush[]): Promise<void> {
  if (pushes.length === 0) {
    return;
  }
  if (theme === null) {
    for (const push of pushes) {
      const items: RecentCardItem[] =
        buildNoteCardItems(push.notes, new Map<string, string>());
      await updateNoteListForm(push.formId, items, {}, push.extras);
    }
    return;
  }
  const uiContext: common.UIAbilityContext = context as common.UIAbilityContext;
  let renderer: ThumbnailRenderer | null = null;
  let batch: ThumbBatchResult = { keys: new Map<string, string>(),
    images: {}, fds: [] };
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(uiContext);
    const seen: Set<string> = new Set<string>();
    const thumbed: NoteMeta[] = [];
    for (const push of pushes) {
      for (const note of push.notes.slice(0, MAX_FORM_THUMBS)) {
        if (!seen.has(note.id)) {
          seen.add(note.id);
          thumbed.push(note);
        }
      }
    }
    if (thumbed.length > 0) {
      renderer = new ThumbnailRenderer();
      await renderer.initialize(uiContext);
      batch = await renderFormThumbImages(uiContext, theme, thumbed, db, renderer);
    }
    for (const push of pushes) {
      const items: RecentCardItem[] = buildNoteCardItems(push.notes, batch.keys);
      await updateNoteListForm(push.formId, items, batch.images, push.extras);
    }
  } catch (e) {
    console.error(`pushNoteListForms failed: ${JSON.stringify(e)}`);
  } finally {
    closeFormImageFds(batch.fds);
    if (renderer !== null) {
      await renderer.dispose();
    }
  }
}

export function noteListExtrasEmpty(): NoteListFormExtras {
  return { folderId: '', folderName: '', configured: true };
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
    const ids: string[] = targetFormId !== undefined ? [targetFormId] :
      await readFormIds(context);
    const pushes: NoteListFormPush[] = [];
    for (const formId of ids) {
      pushes.push({ formId: formId, notes: notes,
        extras: noteListExtrasEmpty() });
    }
    await pushNoteListForms(context, null, pushes);
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
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const notes: NoteMeta[] = await repo.getRecentNotes();
    const pushes: NoteListFormPush[] = [];
    for (const formId of ids) {
      pushes.push({ formId: formId, notes: notes,
        extras: noteListExtrasEmpty() });
    }
    await pushNoteListForms(context, theme, pushes);
  } catch (e) {
    console.error(`refreshRecentNotesForms failed: ${JSON.stringify(e)}`);
  }
}
