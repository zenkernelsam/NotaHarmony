// 原版 AndroidManifest：VIEW(content/file, application/pdf) +
// SEND(application/pdf) intent-filter → fag.h0(intent) 提取 URI
// （SEND 取 EXTRA_STREAM，VIEW 取 content/file data）→ hv7.i 置
// Q.j 标记后 kx 协程走与内建选择器同一导入管线。
// Harmony 等价：UIAbility onCreate/onNewWant 收 want.uri
// （ohos.want.action.viewData）与 want.parameters['ability.params.stream']
// （sendData/sendMultipleData 的 URI 数组）入进程内队列；
// LibraryPage 显示时 drain 并走同一逐文件导入。
import { Want } from '@kit.AbilityKit';

const ACTION_VIEW_DATA: string = 'ohos.want.action.viewData';
const ACTION_SEND_DATA: string = 'ohos.want.action.sendData';
const ACTION_SEND_MULTIPLE_DATA: string = 'ohos.want.action.sendMultipleData';
const PARAMS_STREAM: string = 'ability.params.stream';

const pendingSharedUris: string[] = [];

function pushUri(uri: string): void {
  if (uri.length > 0) {
    pendingSharedUris.push(uri);
  }
}

export function enqueueSharedWantUris(want: Want): void {
  if (want.action === ACTION_VIEW_DATA && typeof want.uri === 'string') {
    pushUri(want.uri);
    return;
  }
  if (want.action === ACTION_SEND_DATA ||
    want.action === ACTION_SEND_MULTIPLE_DATA) {
    const stream: Object | undefined = want.parameters === undefined ?
      undefined : want.parameters[PARAMS_STREAM];
    if (Array.isArray(stream)) {
      for (const item of stream as Object[]) {
        if (typeof item === 'string') {
          pushUri(item);
        }
      }
    } else if (typeof stream === 'string') {
      pushUri(stream);
    }
    if (typeof want.uri === 'string') {
      pushUri(want.uri);
    }
  }
}

export function drainSharedUris(): string[] {
  if (pendingSharedUris.length === 0) {
    return [];
  }
  return pendingSharedUris.splice(0, pendingSharedUris.length);
}
