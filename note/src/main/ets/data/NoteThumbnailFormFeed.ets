// 原版 NoteThumbnailWidgetProvider（extends ec0 +
// NoteThumbnailConfigActivity）：
//   wyi.e(context, i) = widget_bindings["note_"+appWidgetId] → ttf；
//   xf9 渲染该笔记首页 Bitmap 到部件尺寸；有图显 image（contentDesc=
//   标题）否则 page_new_note_fill 占位；点击 = VIEW+note_id（未配置
//   → MAIN+LAUNCHER 纯拉起）；2×2 targetCell + 40–190dp 双向 resize。
//   配置活动标题 "Choose a note"，空态 "No notes yet"。
// Harmony 等价：note_thumbnail_card + 本 feed。formId→noteId 绑定存
// filesDir/note_thumbnail_form_config.json（等价 widget_bindings）；
// 配置 UI = NoteThumbnailFormEditAbility（type=formEdit）+
// NoteThumbnailEditPage；推送经 formProvider.updateForm +
// formImages（缩略图 UIAbility 侧补齐，同两阶段语义）。
import { common } from '@kit.AbilityKit';
import { formProvider, formBindingData } from '@kit.FormKit';
import { image } from '@kit.ImageKit';
import { NoteMeta } from '../core/model/NoteTypes';
import { ThemeTokens } from '../ui/theme/EditorTheme';
import { ThumbnailRenderer } from '../rendering/ThumbnailRenderer';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import {
  renderFormThumbImages,
  closeFormImageFds,
  readJsonFile,
  writeJsonFile
} from './RecentNotesFormFeed';

export const NOTE_THUMBNAIL_FORM_NAME: string = 'note_thumbnail_card';
const THUMB_CONFIG_FILE: string = 'note_thumbnail_form_config.json';

interface ThumbFormConfigEntry {
  formId: string;
  noteId: string;
}

interface ThumbFormBindingPayload {
  noteId: string;
  title: string;
  thumb: string;
  configured: boolean;
  formImages: Record<string, number>;
}

function configPath(context: common.Context): string {
  return `${context.filesDir}/${THUMB_CONFIG_FILE}`;
}

async function readConfig(context: common.Context): Promise<ThumbFormConfigEntry[]> {
  const content: string = await readJsonFile(configPath(context));
  if (content.length === 0) {
    return [];
  }
  try {
    const parsed: ThumbFormConfigEntry[] =
      JSON.parse(content) as ThumbFormConfigEntry[];
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    console.error(`thumb form config parse failed: ${JSON.stringify(e)}`);
    return [];
  }
}

async function writeConfig(context: common.Context,
  entries: ThumbFormConfigEntry[]): Promise<void> {
  await writeJsonFile(configPath(context), JSON.stringify(entries));
}

export async function registerNoteThumbnailForm(context: common.Context,
  formId: string): Promise<void> {
  if (formId.length === 0) {
    return;
  }
  const entries: ThumbFormConfigEntry[] = await readConfig(context);
  if (!entries.some((entry: ThumbFormConfigEntry) => entry.formId === formId)) {
    // 未配置态：空串等价原版 wyi.e 返回 null。
    entries.push({ formId: formId, noteId: '' });
    await writeConfig(context, entries);
  }
}

export async function unregisterNoteThumbnailForm(context: common.Context,
  formId: string): Promise<void> {
  const entries: ThumbFormConfigEntry[] = await readConfig(context);
  const next: ThumbFormConfigEntry[] = entries.filter(
    (entry: ThumbFormConfigEntry) => entry.formId !== formId);
  if (next.length !== entries.length) {
    await writeConfig(context, next);
  }
}

export async function noteThumbnailFormIds(context: common.Context): Promise<string[]> {
  const entries: ThumbFormConfigEntry[] = await readConfig(context);
  const ids: string[] = [];
  for (const entry of entries) {
    ids.push(entry.formId);
  }
  return ids;
}

export async function setNoteThumbnailFormNote(context: common.Context,
  formId: string, noteId: string): Promise<void> {
  const entries: ThumbFormConfigEntry[] = await readConfig(context);
  const hit: ThumbFormConfigEntry | undefined = entries.find(
    (entry: ThumbFormConfigEntry) => entry.formId === formId);
  if (hit === undefined) {
    entries.push({ formId: formId, noteId: noteId });
  } else {
    hit.noteId = noteId;
  }
  await writeConfig(context, entries);
}

async function updateThumbForm(formId: string, noteId: string, title: string,
  thumb: string, configured: boolean,
  formImages: Record<string, number>): Promise<void> {
  const data: ThumbFormBindingPayload = {
    noteId: noteId,
    title: title,
    thumb: thumb,
    configured: configured,
    formImages: formImages
  };
  try {
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
  } catch (e) {
    console.error(`thumb form update failed for ${formId}: ${JSON.stringify(e)}`);
  }
}

interface ThumbPushTarget {
  formId: string;
  noteId: string;
  title: string;
  meta: NoteMeta | null;
}

async function resolveThumbTargets(context: common.Context,
  repo: NoteRepositoryImpl,
  targetFormId?: string): Promise<ThumbPushTarget[]> {
  const entries: ThumbFormConfigEntry[] = await readConfig(context);
  const targets: ThumbPushTarget[] = [];
  for (const entry of entries) {
    if (targetFormId !== undefined && entry.formId !== targetFormId) {
      continue;
    }
    const meta: NoteMeta | null = entry.noteId.length === 0 ? null :
      await repo.getNote(entry.noteId);
    targets.push({ formId: entry.formId, noteId: entry.noteId,
      title: meta?.title ?? '', meta: meta });
  }
  return targets;
}

// 标题-only 推送：FormExtensionAbility 与 UIAbility 两侧均可调用——
// 只读 note_meta，不触碰渲染管线。
export async function pushNoteThumbnailTitles(context: common.Context,
  targetFormId?: string): Promise<void> {
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const targets: ThumbPushTarget[] =
      await resolveThumbTargets(context, repo, targetFormId);
    for (const target of targets) {
      await updateThumbForm(target.formId, target.noteId, target.title,
        '', target.noteId.length > 0, {});
    }
  } catch (e) {
    console.error(`pushNoteThumbnailTitles failed: ${JSON.stringify(e)}`);
  }
}

// 全量推送：标题 + 缩略图 formImages。仅 UIAbility 侧调用。
export async function refreshNoteThumbnailForms(context: common.UIAbilityContext,
  theme: ThemeTokens): Promise<void> {
  let renderer: ThumbnailRenderer | null = null;
  let batchFds: number[] = [];
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const targets: ThumbPushTarget[] = await resolveThumbTargets(context, repo);
    if (targets.length === 0) {
      return;
    }
    const metas: NoteMeta[] = [];
    for (const target of targets) {
      if (target.meta !== null) {
        metas.push(target.meta);
      }
    }
    if (metas.length > 0) {
      renderer = new ThumbnailRenderer();
      await renderer.initialize(context);
      const batch = await renderFormThumbImages(context, theme, metas,
        db, renderer);
      batchFds = batch.fds;
      for (const target of targets) {
        const key: string = target.meta === null ? '' :
          (batch.keys.get(target.meta.id) ?? '');
        const images: Record<string, number> = {};
        if (key.length > 0) {
          images[key] = batch.images[key];
        }
        await updateThumbForm(target.formId, target.noteId, target.title,
          key, target.noteId.length > 0, images);
      }
    } else {
      for (const target of targets) {
        await updateThumbForm(target.formId, target.noteId, target.title,
          '', target.noteId.length > 0, {});
      }
    }
  } catch (e) {
    console.error(`refreshNoteThumbnailForms failed: ${JSON.stringify(e)}`);
  } finally {
    closeFormImageFds(batchFds);
    if (renderer !== null) {
      await renderer.dispose();
    }
  }
}
