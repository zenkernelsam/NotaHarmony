import assert from 'node:assert/strict';
import fs from 'node:fs';

const page=fs.readFileSync('note/src/main/ets/ui/settings/BackupPage.ets','utf8').replaceAll('\r\n','\n');
const cases=[
 ['export', body('  private async exportAllLocal(): Promise<void> {','  // === 本地：从 .note 导入 ==='), "console.error(`exportAllLocal failed:`,"],
];
function body(startMarker,endMarker){const start=page.indexOf(startMarker);const end=page.indexOf(endMarker,start);assert.ok(start!==-1&&end>start,startMarker);return page.slice(start,end);}

function assertGuarded(name,text,label){
 const logIndex=text.indexOf(label);const catchIndex=logIndex>=0?text.indexOf('catch (e) {',Math.max(0,logIndex-200)):text.indexOf('catch (e) {');
 assert.ok(catchIndex>=0,name+': catch');
 const alertIndex=text.indexOf('this.showAlert(',catchIndex);
 const guardIndex=text.indexOf('if (this.isStale(lifecycleGeneration)) {',catchIndex);
 const returnIndex=text.indexOf('return;',guardIndex);
 assert.ok(alertIndex>guardIndex&&guardIndex>catchIndex&&returnIndex>guardIndex,name+': stale guard precedes alert');
}
assertGuarded('export',body('  private async exportAllLocal(): Promise<void> {','  // === 本地：从 .note 导入 ==='),'exportAllLocal failed');
assertGuarded('import',body('  private async importLocal(): Promise<void> {','  // === WebDAV：备份全部笔记 ==='),'importLocal failed');
assertGuarded('backup',body('  private async backupAll(): Promise<void> {','  // === WebDAV：从云端恢复最近一次已发布的完整批次 ==='),'backupAll failed');
assertGuarded('restore',body('  private async restoreFromCloud(): Promise<void> {','  private async loadLatestBackupBatch('),'restoreFromCloud failed');

console.log('D02_BACKUP_FAILURES_DISPOSAL_BOUND_REPLAY_OK TOTAL=5 FAILED=0');
