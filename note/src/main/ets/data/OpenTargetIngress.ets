// 原版打开目标 extras：VIEW intent + note_id（ttf.toString() 的
// 8-4-4-4-12 带连字符 UUID；m18.r0 兼容 32-hex 与 36 位带连字符）
// + nbnote:<id> data URI（qk9 列表小部件行 fillInIntent）+
// show_library / show_recent 布尔 extra。
// 投递方：v50 近期笔记动态快捷项（VIEW+note_id）、qk9 小部件行
// （VIEW+nbnote URI+note_id）、bv7 新窗口目标（VIEW+note_id）、
// RecentNotesWidgetProvider 本体（VIEW+show_recent）。
// 消费端：MainActivity 的 nav-target 队列（xu7(noteId) 打开笔记 /
// wu7.a 资料库落地）。
// Harmony 等价：want.parameters 与 want.uri 在此按原版 extra/URI
// 契约解析 → 进程内队列；LibraryPage 显示时 drain —— note_id/
// nbnote 走 resolveDeepLinkNoteId（与 /app/note 深链同一
// note_meta.id + legacy_id 解析）打开 NotePage；show_library →
// LibrarySection.ALL_NOTES，show_recent → RECENT 区。
// fail-closed：nbnote 为原版内部 URI（未在 manifest 声明），
// Harmony 侧不注册 uris skill —— 仅 want.uri 投递时接收。
import { Want } from '@kit.AbilityKit';
import { normalizeDeepLinkNoteId } from './DeepLinkIngress';

const EXTRA_NOTE_ID: string = 'note_id';
const EXTRA_SHOW_LIBRARY: string = 'show_library';
const EXTRA_SHOW_RECENT: string = 'show_recent';
const NBNOTE_SCHEME: string = 'nbnote:';

export const LANDING_ALL_NOTES: string = 'all_notes';
export const LANDING_RECENT: string = 'recent';

const pendingOpenNoteIds: string[] = [];
const pendingLandings: string[] = [];

export function enqueueOpenTargetWant(want: Want): void {
  if (want.parameters !== undefined) {
    const noteId: Object | undefined = want.parameters[EXTRA_NOTE_ID];
    if (typeof noteId === 'string') {
      const normalized: string | null = normalizeDeepLinkNoteId(noteId);
      if (normalized !== null) {
        pendingOpenNoteIds.push(normalized);
      }
    }
    if (want.parameters[EXTRA_SHOW_LIBRARY] === true) {
      pendingLandings.push(LANDING_ALL_NOTES);
    }
    if (want.parameters[EXTRA_SHOW_RECENT] === true) {
      pendingLandings.push(LANDING_RECENT);
    }
  }
  if (typeof want.uri === 'string' && want.uri.startsWith(NBNOTE_SCHEME)) {
    const normalized: string | null =
      normalizeDeepLinkNoteId(want.uri.slice(NBNOTE_SCHEME.length));
    if (normalized !== null) {
      pendingOpenNoteIds.push(normalized);
    }
  }
}

export function drainOpenNoteIds(): string[] {
  if (pendingOpenNoteIds.length === 0) {
    return [];
  }
  return pendingOpenNoteIds.splice(0, pendingOpenNoteIds.length);
}

export function drainLibraryLandings(): string[] {
  if (pendingLandings.length === 0) {
    return [];
  }
  return pendingLandings.splice(0, pendingLandings.length);
}
