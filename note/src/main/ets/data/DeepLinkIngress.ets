// 原版 AndroidManifest：VIEW(autoVerify, BROWSABLE) intent-filter 声明
// http/https + host notability.com/*.notability.com + pathPrefix
// /app/note（另有 /authlink、/gallery(1.4.2新增) 与
// /event/learn-from-home、/event/plus25、/event/planner2627(1.4.2新增)）。
// hv7.i 判定 py2.d(data) 置 Q.j 后 kx 协程消费；py2.a 校验路径
// 段为 ["app","note",id]，py2.b 经 wtf.f→m18.r0 把恰好 32 个
// 十六进制位解析成 ttf 笔记 ID。
// Harmony 等价：module.json5 skills 增挂 entity.system.browsable +
// ohos.want.action.viewData + uris(http/https, host notability.com,
// pathStartWith app/note)；want.uri 在此按 py2.f/py2.a/m18.r0 同规则
// 解析出笔记 ID 入进程内队列；LibraryPage 显示时 drain，按
// note_meta.id 直查、未命中再查 note_sync_metadata.legacy_id
// （导入时改号副本保留原 ID），命中即打开 NotePage。
// fail-closed：*.notability.com 子域（Harmony uris host 不支持通配）、
// domainVerify 域名验证（需在 notability.com 托管关联文件）、
// /authlink VerifyLink（yy2 后端校验）与 /event/* 营销事件 —— 均登记。
import { Want } from '@kit.AbilityKit';

const ACTION_VIEW_DATA: string = 'ohos.want.action.viewData';
const DEEP_LINK_HOST: string = 'notability.com';
const DEEP_LINK_HOST_SUFFIX: string = '.notability.com';
const DEEP_LINK_ID_LENGTH: number = 32;
const DEEP_LINK_UUID_LENGTH: number = 36;

const pendingDeepLinkNoteIds: string[] = [];

// py2.f：scheme http/https + host notability.com 或以 .notability.com 结尾。
function isNotabilityHost(scheme: string, host: string): boolean {
  if (scheme !== 'http' && scheme !== 'https') {
    return false;
  }
  return host === DEEP_LINK_HOST || host.endsWith(DEEP_LINK_HOST_SUFFIX);
}

function isHexDigit(code: number): boolean {
  return (code >= 0x30 && code <= 0x39) ||
    (code >= 0x61 && code <= 0x66) || (code >= 0x41 && code <= 0x46);
}

// m18.r0：恰 32 个十六进制位，或 36 位标准带连字符 UUID
// （ttf.toString() 的 8-4-4-4-12 形式，连字符在 8/13/18/23）。
// 返回规范化后的小写 32 位十六进制（导入笔记以此形式入库），
// 否则 null。
export function normalizeDeepLinkNoteId(raw: string): string | null {
  if (raw.length === DEEP_LINK_ID_LENGTH) {
    for (let i = 0; i < DEEP_LINK_ID_LENGTH; i++) {
      if (!isHexDigit(raw.charCodeAt(i))) {
        return null;
      }
    }
    return raw.toLowerCase();
  }
  if (raw.length === DEEP_LINK_UUID_LENGTH) {
    let hex: string = '';
    for (let i = 0; i < DEEP_LINK_UUID_LENGTH; i++) {
      if (i === 8 || i === 13 || i === 18 || i === 23) {
        if (raw.charAt(i) !== '-') {
          return null;
        }
        continue;
      }
      if (!isHexDigit(raw.charCodeAt(i))) {
        return null;
      }
      hex += raw.charAt(i);
    }
    return hex.toLowerCase();
  }
  return null;
}

// py2.a：路径段恰为 ["app","note",<id>]。host 校验沿用 py2.f
// （uris 只放行已声明 host，子域走到这里依旧按原版语义接收）。
export function parseDeepLinkNoteId(uri: string): string | null {
  const match: RegExpMatchArray | null =
    uri.match(/^([A-Za-z][A-Za-z0-9+.-]*):\/\/([^/?#]+)([^?#]*)/);
  if (match === null || match.length < 4) {
    return null;
  }
  const scheme: string = match[1].toLowerCase();
  const hostPort: string = match[2].toLowerCase();
  const host: string = hostPort.split(':')[0];
  if (!isNotabilityHost(scheme, host)) {
    return null;
  }
  const path: string = match[3];
  const segments: string[] = path.split('/').filter((s: string) => s.length > 0);
  if (segments.length !== 3 || segments[0] !== 'app' || segments[1] !== 'note') {
    return null;
  }
  return normalizeDeepLinkNoteId(segments[2]);
}

export function enqueueDeepLinkWant(want: Want): void {
  if (want.action !== ACTION_VIEW_DATA || typeof want.uri !== 'string') {
    return;
  }
  const noteId: string | null = parseDeepLinkNoteId(want.uri);
  if (noteId !== null) {
    pendingDeepLinkNoteIds.push(noteId);
  }
}

export function drainDeepLinkNoteIds(): string[] {
  if (pendingDeepLinkNoteIds.length === 0) {
    return [];
  }
  return pendingDeepLinkNoteIds.splice(0, pendingDeepLinkNoteIds.length);
}
