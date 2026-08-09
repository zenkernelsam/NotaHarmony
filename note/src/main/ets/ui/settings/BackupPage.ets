// T-030 备份/导入导出页面（本地文件 + WebDAV 云备份）
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { StrokePersistence } from '../../data/StrokePersistence';
import { NoteExporter } from '../../data/NoteExporter';
import { NoteImporter, ImportReport, ImportResult } from '../../data/NoteImporter';
import { WebDAVClient, WebDAVConfig, WebDAVFileInfo, WebDAVListResult } from '../../data/WebDAVClient';
import { WebDAVConfigStore } from '../../data/WebDAVConfigStore';
import {
  BACKUP_MANIFEST_SUFFIX, BackupBatchManifest, BackupSourcePackage,
  parseBackupBatch,
} from '../../data/BackupBatchSpec';
import {
  BackupBatchPublisher, BackupPublishResult, BackupPublishStage, CryptoBackupBatchHasher,
} from '../../data/BackupBatchPublisher';
import {
  BackupBatchRestorer, BackupFetchResult, VerifiedBackupObject,
} from '../../data/BackupBatchRestorer';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Entry
@Component
struct BackupPage {
  @State isLoading: boolean = false;
  @State isBusy: boolean = false;
  @State serverText: string = '';
  @State lastBackupText: string = '';
  @State hasLastBackup: boolean = false;
  @State hasConfig: boolean = false;
  @State statusText: ResourceStr = '';

  private db: DatabaseManager = DatabaseManager.getInstance();
  private persistence: StrokePersistence = new StrokePersistence();
  private config: WebDAVConfig = { serverUrl: '', username: '', password: '', backupPath: '/nota-backup/' };
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.init();
  }

  private async init(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.db.initialize(context);
      this.persistence.initialize(this.db);
      this.config = await WebDAVConfigStore.load(context);
      this.hasConfig = this.config.serverUrl.trim().length > 0;
      this.serverText = this.hasConfig ? this.config.serverUrl : '';
      const lastBackup: number = await WebDAVConfigStore.getLastBackup(context);
      this.hasLastBackup = lastBackup > 0;
      this.lastBackupText = this.hasLastBackup ? this.formatTime(lastBackup) : '';
    } catch (e) {
      console.error(`BackupPage init failed: ${JSON.stringify(e)}`);
    }
  }

  // === 本地：导出全部笔记 ===
  private async exportAllLocal(): Promise<void> {
    if (this.isBusy) {
      return;
    }
    this.isBusy = true;
    this.statusText = $r('app.string.exporting');
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const exporter = new NoteExporter(this.db, this.persistence);
      const noteRepo = new NoteRepositoryImpl(this.db);
      const notes: NoteMeta[] = await noteRepo.getAllNotes();
      if (notes.length === 0) {
        this.statusText = '';
        this.showToast($r('app.string.no_notes_to_export'));
        return;
      }
      let exported: number = 0;
      for (const note of notes) {
        const ok: boolean = await exporter.exportToFile(context, note.id, note.title);
        if (ok) {
          exported++;
        }
      }
      this.showToast($r('app.string.exported_notes_count', exported, notes.length));
    } catch (e) {
      console.error(`exportAllLocal failed: ${JSON.stringify(e)}`);
      this.showAlert($r('app.string.export_failed'), $r('app.string.export_failed_message'));
    } finally {
      this.isBusy = false;
      this.statusText = '';
    }
  }

  // === 本地：从 .note 导入 ===
  private async importLocal(): Promise<void> {
    if (this.isBusy) {
      return;
    }
    this.isBusy = true;
    this.statusText = $r('app.string.importing');
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const importer = new NoteImporter(this.db, this.persistence);
      const report: ImportReport = await importer.importFromFile(context);
      if (report.result === ImportResult.SUCCESS) {
        this.showToast(report.message);
      } else if (report.result === ImportResult.PARTIAL) {
        this.showAlert($r('app.string.partial_import'), report.message);
      } else if (report.result === ImportResult.CORRUPTED) {
        this.showAlert($r('app.string.import_failed'), report.message);
      } else {
        this.showAlert($r('app.string.unsupported_format'), report.message);
      }
    } catch (e) {
      console.error(`importLocal failed: ${JSON.stringify(e)}`);
      this.showAlert($r('app.string.import_failed'), $r('app.string.import_read_failed'));
    } finally {
      this.isBusy = false;
      this.statusText = '';
    }
  }

  // === WebDAV：备份全部笔记 ===
  private async backupAll(): Promise<void> {
    if (this.isBusy || !this.hasConfig) {
      return;
    }
    this.isBusy = true;
    this.statusText = $r('app.string.backing_up_cloud');
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const client = new WebDAVClient(this.config);
      const exporter = new NoteExporter(this.db, this.persistence);
      const backups: BackupSourcePackage[] = await exporter.exportAllNotes();
      if (backups.length === 0) {
        this.showToast($r('app.string.no_notes_to_backup'));
        return;
      }
      const batchId: string = this.generateBatchId();
      const completedAt: number = Date.now();
      const publisher = new BackupBatchPublisher(client, new CryptoBackupBatchHasher());
      const result: BackupPublishResult = await publisher.publish(backups, batchId, completedAt);
      if (!result.success) {
        if (result.stage === BackupPublishStage.DIRECTORY) {
          this.showAlert($r('app.string.backup_failed'), $r('app.string.backup_directory_failed'));
        } else if (result.stage === BackupPublishStage.OBJECT_UPLOAD) {
          this.showAlert($r('app.string.backup_failed'),
            $r('app.string.cloud_backup_incomplete', result.verified, result.total));
        } else if (result.stage === BackupPublishStage.OBJECT_VERIFY) {
          this.showAlert($r('app.string.backup_failed'), $r('app.string.cloud_backup_verify_failed'));
        } else {
          this.showAlert($r('app.string.backup_failed'), $r('app.string.cloud_backup_publish_failed'));
        }
        return;
      }
      await WebDAVConfigStore.setLastBackup(context, completedAt);
      this.hasLastBackup = true;
      this.lastBackupText = this.formatTime(completedAt);
      this.showToast($r('app.string.cloud_backup_count', result.verified, result.total));
    } catch (e) {
      console.error(`backupAll failed: ${JSON.stringify(e)}`);
      this.showAlert($r('app.string.backup_failed'), $r('app.string.network_server_unreachable'));
    } finally {
      this.isBusy = false;
      this.statusText = '';
    }
  }

  // === WebDAV：从云端恢复最近一次已发布的完整批次 ===
  private async restoreFromCloud(): Promise<void> {
    if (this.isBusy || !this.hasConfig) {
      return;
    }
    this.isBusy = true;
    this.statusText = $r('app.string.restoring_cloud');
    try {
      const client = new WebDAVClient(this.config);
      const listResult: WebDAVListResult = await client.listDir(client.backupDirectoryUrl());
      if (!listResult.success) {
        console.error(`WebDAV list failed: HTTP ${listResult.responseCode}: ${listResult.message}`);
        this.showAlert($r('app.string.restore_failed'), $r('app.string.cloud_backup_list_failed'));
        return;
      }
      const manifest: BackupBatchManifest | null = await this.loadLatestBackupBatch(
        client, listResult.files);
      if (manifest === null) {
        this.showToast($r('app.string.no_cloud_backup'));
        return;
      }
      const importer = new NoteImporter(this.db, this.persistence);
      let restored: number = 0;
      let degraded: number = 0;
      const restorer = new BackupBatchRestorer(client, new CryptoBackupBatchHasher());
      const fetched: BackupFetchResult = await restorer.fetch(manifest);
      let failed: number = fetched.failedNoteIds.length;
      for (let i: number = 0; i < fetched.verified.length; i++) {
        const object: VerifiedBackupObject = fetched.verified[i];
        const report: ImportReport = await importer.importFromData(object.data);
        if (report.result === ImportResult.SUCCESS) {
          restored++;
        } else if (report.result === ImportResult.PARTIAL) {
          restored++;
          degraded++;
        } else {
          failed++;
        }
      }
      if (failed > 0 || degraded > 0) {
        this.showAlert($r('app.string.restore_result'),
          $r('app.string.cloud_restore_partial', restored, manifest.entries.length, failed, degraded));
      } else {
        this.showToast($r('app.string.cloud_restore_complete', restored));
      }
    } catch (e) {
      console.error(`restoreFromCloud failed: ${JSON.stringify(e)}`);
      this.showAlert($r('app.string.restore_failed'), $r('app.string.network_server_unreachable'));
    } finally {
      this.isBusy = false;
      this.statusText = '';
    }
  }

  private async loadLatestBackupBatch(client: WebDAVClient,
    files: WebDAVFileInfo[]): Promise<BackupBatchManifest | null> {
    const candidates: WebDAVFileInfo[] = files.filter((file: WebDAVFileInfo) =>
      file.name.startsWith('batch-') && file.name.endsWith(BACKUP_MANIFEST_SUFFIX));
    candidates.sort((left: WebDAVFileInfo, right: WebDAVFileInfo) =>
      right.lastModified - left.lastModified);
    let latest: BackupBatchManifest | null = null;
    const limit: number = Math.min(candidates.length, 100);
    for (let i: number = 0; i < limit; i++) {
      const bytes: Uint8Array | null = await client.download(candidates[i].path);
      if (bytes === null || bytes.length === 0 || bytes.length > 1024 * 1024) {
        continue;
      }
      try {
        const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
        const parsed: BackupBatchManifest | null = parseBackupBatch(text);
        if (parsed !== null && (latest === null || parsed.createdAt > latest.createdAt)) {
          latest = parsed;
        }
      } catch (e) {
        console.warn(`Backup manifest parse failed: ${JSON.stringify(e)}`);
      }
    }
    return latest;
  }

  private generateBatchId(): string {
    return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 12)}`;
  }

  private navigateToSettings(): void {
    router.pushUrl({ url: 'ui/settings/WebDAVSettingsPage' }).catch((e: Error) => {
      console.error(`pushUrl failed: ${JSON.stringify(e)}`);
    });
  }

  // === UI ===
  private showToast(message: ResourceStr): void {
    try {
      promptAction.showToast({ message: message, duration: 2500 });
    } catch (e) {
      console.error(`showToast failed: ${JSON.stringify(e)}`);
    }
  }

  private showAlert(title: ResourceStr, message: ResourceStr): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: message,
      confirm: { value: $r('app.string.confirm'), action: () => {
      } },
    });
  }

  private formatTime(ms: number): string {
    const d = new Date(ms);
    const pad = (n: number): string => (n < 10 ? '0' + n : '' + n);
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
  }

  build() {
    Column() {
      Text($r('app.string.backup_and_sync'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 24, bottom: 16 })

      Scroll() {
        Column() {
          // === 本地文件区 ===
          Text($r('app.string.local_files')).fontSize(18).fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary).margin({ bottom: 8 })
          Button($r('app.string.export_all_notes'))
            .width('90%')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.exportAllLocal();
            })
          Button($r('app.string.import_note_file'))
            .width('90%')
            .margin({ bottom: 16 })
            .onClick(() => {
              this.importLocal();
            })

          Divider().margin({ bottom: 16 })

          // === WebDAV 区 ===
          Text($r('app.string.webdav_cloud_backup')).fontSize(18).fontWeight(FontWeight.Medium)
            .fontColor(this.resolveTokens().textPrimary).margin({ bottom: 8 })
          Text(this.hasConfig ? $r('app.string.server_value', this.serverText) :
            $r('app.string.server_not_configured')).fontSize(14)
            .fontColor(this.resolveTokens().textPrimary).margin({ bottom: 4 })
          Text(this.hasLastBackup ? $r('app.string.last_backup_value', this.lastBackupText) :
            $r('app.string.last_backup_never')).fontSize(14)
            .fontColor(this.resolveTokens().textPrimary).margin({ bottom: 8 })

          Button($r('app.string.configure_webdav'))
            .width('90%')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.navigateToSettings();
            })
          Button($r('app.string.backup_all_to_cloud'))
            .width('90%')
            .enabled(this.hasConfig && !this.isBusy)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.backupAll();
            })
          Button($r('app.string.restore_latest_cloud_backup'))
            .width('90%')
            .enabled(this.hasConfig && !this.isBusy)
            .onClick(() => {
              this.restoreFromCloud();
            })

          if (!this.hasConfig) {
            Text($r('app.string.configure_webdav_hint')).fontSize(12)
              .fontColor(this.resolveTokens().textSecondary).margin({ top: 8 })
          }

          if (this.isBusy) {
            Row() {
              LoadingProgress().width(24).height(24)
              Text(this.statusText)
                .fontSize(14)
                .fontColor(this.resolveTokens().textPrimary)
                .margin({ left: 8 })
            }
            .margin({ top: 16 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }
}
