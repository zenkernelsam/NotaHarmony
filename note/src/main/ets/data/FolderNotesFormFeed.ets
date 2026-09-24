// 原版 FolderNotesWidgetProvider（extends qk9 + FolderNotesConfigActivity）：
// 与 RecentNotes 共用 qk9 RemoteViews 集合，差异 = 数据作用域：
//   wyi.c(context, i) = SharedPreferences "widget_bindings" →
//   "folder_"+appWidgetId —— 每个实例绑定一个 folderId（配置活动写入）。
//   g() 返回 xld(title=文件夹名, createIntent=CREATE_NOTE+folder_id,
//   headerIntent=VIEW+folder_id, collection=该文件夹笔记)。
//   未配置/文件夹缺失 → g() 返回 null → 加载态；空态
//   app_widgets__widget_folder_no_notes = "No notes in this folder"、
//   未配置态 widget_folder_empty = "Tap to open Notability"。
// Harmony 等价：folder_notes_card + 本 feed。formId→folderId 绑定存
// filesDir/folder_notes_form_config.json（等价 widget_bindings）；
// 配置 UI 由 FolderFormEditAbility（type=formEdit，对应原版配置活动）
// 写入；推送复用 pushNoteListForms 通用引擎。
import { common } from '@kit.AbilityKit';
import { NoteMeta } from '../core/model/NoteTypes';
import { ThemeTokens } from '../ui/theme/EditorTheme';
import { DatabaseManager } from './DatabaseManager';
import { NoteRepositoryImpl } from './NoteRepositoryImpl';
import { FolderRepositoryImpl, NoteFolder } from './FolderRepositoryImpl';
import {
  NoteListFormExtras,
  NoteListFormPush,
  pushNoteListForms,
  readJsonFile,
  writeJsonFile
} from './RecentNotesFormFeed';

export const FOLDER_NOTES_FORM_NAME: string = 'folder_notes_card';
const FOLDER_CONFIG_FILE: string = 'folder_notes_form_config.json';

interface FolderFormConfigEntry {
  formId: string;
  folderId: string;
}

function configPath(context: common.Context): string {
  return `${context.filesDir}/${FOLDER_CONFIG_FILE}`;
}

async function readConfig(context: common.Context): Promise<FolderFormConfigEntry[]> {
  const content: string = await readJsonFile(configPath(context));
  if (content.length === 0) {
    return [];
  }
  try {
    const parsed: FolderFormConfigEntry[] =
      JSON.parse(content) as FolderFormConfigEntry[];
    return Array.isArray(parsed) ? parsed : [];
  } catch (e) {
    console.error(`folder form config parse failed: ${JSON.stringify(e)}`);
    return [];
  }
}

async function writeConfig(context: common.Context,
  entries: FolderFormConfigEntry[]): Promise<void> {
  await writeJsonFile(configPath(context), JSON.stringify(entries));
}

export async function registerFolderNotesForm(context: common.Context,
  formId: string): Promise<void> {
  if (formId.length === 0) {
    return;
  }
  const entries: FolderFormConfigEntry[] = await readConfig(context);
  if (!entries.some((entry: FolderFormConfigEntry) => entry.formId === formId)) {
    // 未配置态：空串等价原版 wyi.c 返回 null（g() 返回 null → 加载态）。
    entries.push({ formId: formId, folderId: '' });
    await writeConfig(context, entries);
  }
}

export async function unregisterFolderNotesForm(context: common.Context,
  formId: string): Promise<void> {
  const entries: FolderFormConfigEntry[] = await readConfig(context);
  const next: FolderFormConfigEntry[] = entries.filter(
    (entry: FolderFormConfigEntry) => entry.formId !== formId);
  if (next.length !== entries.length) {
    await writeConfig(context, next);
  }
}

export async function setFolderNotesFormFolder(context: common.Context,
  formId: string, folderId: string): Promise<void> {
  const entries: FolderFormConfigEntry[] = await readConfig(context);
  const hit: FolderFormConfigEntry | undefined = entries.find(
    (entry: FolderFormConfigEntry) => entry.formId === formId);
  if (hit === undefined) {
    entries.push({ formId: formId, folderId: folderId });
  } else {
    hit.folderId = folderId;
  }
  await writeConfig(context, entries);
}

export async function folderNotesFormIds(context: common.Context): Promise<string[]> {
  const entries: FolderFormConfigEntry[] = await readConfig(context);
  const ids: string[] = [];
  for (const entry of entries) {
    ids.push(entry.formId);
  }
  return ids;
}

interface FolderPushTarget {
  formId: string;
  folderId: string;
  folderName: string;
  notes: NoteMeta[];
}

async function resolveFolderTargets(context: common.Context,
  repo: NoteRepositoryImpl, folderRepo: FolderRepositoryImpl,
  targetFormId?: string): Promise<FolderPushTarget[]> {
  const entries: FolderFormConfigEntry[] = await readConfig(context);
  const folders: NoteFolder[] = await folderRepo.getAllFolders();
  const nameById: Map<string, string> = new Map<string, string>();
  for (const folder of folders) {
    nameById.set(folder.id, folder.name);
  }
  const targets: FolderPushTarget[] = [];
  for (const entry of entries) {
    if (targetFormId !== undefined && entry.formId !== targetFormId) {
      continue;
    }
    const folderId: string = entry.folderId;
    const folderName: string = nameById.get(folderId) ?? '';
    const notes: NoteMeta[] = folderId.length === 0 ? [] :
      await repo.getNotesByFolder(folderId);
    targets.push({ formId: entry.formId, folderId: folderId,
      folderName: folderName, notes: notes });
  }
  return targets;
}

function folderExtras(target: FolderPushTarget): NoteListFormExtras {
  // configured=false → 卡片显示未配置态（原版 widget_folder_empty）。
  return { folderId: target.folderId, folderName: target.folderName,
    configured: target.folderId.length > 0 };
}

// 标题-only 推送：FormExtensionAbility 与 UIAbility 两侧均可调用。
export async function pushFolderNotesTitles(context: common.Context,
  targetFormId?: string): Promise<void> {
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const folderRepo: FolderRepositoryImpl = new FolderRepositoryImpl(db);
    const targets: FolderPushTarget[] =
      await resolveFolderTargets(context, repo, folderRepo, targetFormId);
    const pushes: NoteListFormPush[] = [];
    for (const target of targets) {
      pushes.push({ formId: target.formId, notes: target.notes,
        extras: folderExtras(target) });
    }
    await pushNoteListForms(context, null, pushes);
  } catch (e) {
    console.error(`pushFolderNotesTitles failed: ${JSON.stringify(e)}`);
  }
}

// 全量推送：标题 + 缩略图 formImages。仅 UIAbility 侧调用。
export async function refreshFolderNotesForms(context: common.UIAbilityContext,
  theme: ThemeTokens): Promise<void> {
  try {
    const db: DatabaseManager = DatabaseManager.getInstance();
    await db.initialize(context);
    const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
    const folderRepo: FolderRepositoryImpl = new FolderRepositoryImpl(db);
    const targets: FolderPushTarget[] =
      await resolveFolderTargets(context, repo, folderRepo);
    if (targets.length === 0) {
      return;
    }
    const pushes: NoteListFormPush[] = [];
    for (const target of targets) {
      pushes.push({ formId: target.formId, notes: target.notes,
        extras: folderExtras(target) });
    }
    await pushNoteListForms(context, theme, pushes);
  } catch (e) {
    console.error(`refreshFolderNotesForms failed: ${JSON.stringify(e)}`);
  }
}
