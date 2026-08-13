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
import {
  DEFAULT_WEBDAV_BACKUP_PATH, WebDAVClient, WebDAVConfig, WebDAVFileInfo, WebDAVListResult,
} from '../../data/WebDAVClient';
import { WebDAVConfigStore } from '../../data/WebDAVConfigStore';
import {
  BACKUP_MANIFEST_SUFFIX, BackupBatchManifest, BackupSourcePackage,
  backupManifestFileName, parseBackupBatch,
} from '../../data/BackupBatchSpec';
import {
  BackupBatchPublisher, BackupPublishResult, BackupPublishStage, CryptoBackupBatchHasher,
} from '../../data/BackupBatchPublisher';
import {
  BackupBatchRestorer, BackupFetchResult,
} from '../../data/BackupBatchRestorer';
import {
  BackupBatchApplier, BackupBatchApplyResult, BackupBatchApplyStatus, BackupObjectImporter,
  ImportedNoteRemover,
} from '../../data/BackupBatchApplier';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

enum BackupLoadState {
  LOADING = 'loading',
  ERROR = 'error',
  READY = 'ready',
}

class NoteImporterBackupAdapter implements BackupObjectImporter, ImportedNoteRemover {
  private importer: NoteImporter;

  constructor(importer: NoteImporter) {
    this.importer = importer;
  }

  async importFromData(data: Uint8Array): Promise<ImportReport> {
    return await this.importer.importFromData(data);
  }

  async removeImportedNote(noteId: string): Promise<boolean> {
    return await this.importer.removeImportedNote(noteId);
  }
}

@Entry
@Component
struct BackupPage {
  @State loadState: BackupLoadState = BackupLoadState.LOADING;
  @State isBusy: boolean = false;
  @State serverText: string = '';
  @State lastBackupText: string = '';
  @State hasLastBackup: boolean = false;
  @State hasConfig: boolean = false;
  @State statusText: ResourceStr = '';

  private db: DatabaseManager = DatabaseManager.getInstance();
  private persistence: StrokePersistence = new StrokePersistence();
  private config: WebDAVConfig = {
    serverUrl: '', username: '', password: '', backupPath: DEFAULT_WEBDAV_BACKUP_PATH,
  };
  private initialized: boolean = false;
  private loadGeneration: number = 0;
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.reloadPage();
  }

  onPageShow(): void {
    if (this.initialized) {
      this.reloadPage();
    }
  }

  private async reloadPage(): Promise<void> {
    const generation: number = ++this.loadGeneration;
    this.loadState = BackupLoadState.LOADING;
    this.hasConfig = false;
    this.hasLastBackup = false;
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await this.db.initialize(context);
      this.persistence.initialize(this.db);
      const config: WebDAVConfig = await WebDAVConfigStore.load(context);
      const lastBackup: number = await WebDAVConfigStore.getLastBackup(context);
      if (generation !== this.loadGeneration) {
        return;
      }
      this.config = config;
      this.hasConfig = config.serverUrl.trim().length > 0;
      this.serverText = this.hasConfig ? config.serverUrl : '';
      this.hasLastBackup = lastBackup > 0;
      this.lastBackupText = this.hasLastBackup ? this.formatTime(lastBackup) : '';
      this.loadState = BackupLoadState.READY;
    } catch (e) {
      if (generation === this.loadGeneration) {
        this.config = {
          serverUrl: '', username: '', password: '', backupPath: DEFAULT_WEBDAV_BACKUP_PATH,
        };
        this.serverText = '';
        this.lastBackupText = '';
        this.loadState = BackupLoadState.ERROR;
      }
      console.error(`BackupPage reload failed: ${JSON.stringify(e)}`);
    } finally {
      if (generation === this.loadGeneration) {
        this.initialized = true;
      }
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
      const restorer = new BackupBatchRestorer(client, new CryptoBackupBatchHasher());
      const fetched: BackupFetchResult = await restorer.fetch(manifest);
      const verificationFailures: number = fetched.failedNoteIds.length;
      if (fetched.verified.length === 0) {
        this.showAlert($r('app.string.restore_result'),
          $r('app.string.cloud_restore_partial', 0, manifest.entries.length, verificationFailures, 0));
        return;
      }
      const adapter: NoteImporterBackupAdapter = new NoteImporterBackupAdapter(importer);
      const applier = new BackupBatchApplier(adapter, adapter);
      const applied: BackupBatchApplyResult = await applier.apply(fetched.verified);
      if (applied.status === BackupBatchApplyStatus.ROLLED_BACK) {
        console.error(`cloud restore import failed for ${applied.failedSourceNoteId}; ` +
          `rolled back ${applied.rolledBack} note(s)`);
        this.showAlert($r('app.string.restore_failed'),
          $r('app.string.cloud_restore_rolled_back', applied.rolledBack, verificationFailures));
        return;
      }
      if (applied.status === BackupBatchApplyStatus.ROLLBACK_INCOMPLETE) {
        console.error(`cloud restore rollback incomplete for ${applied.failedSourceNoteId}: ` +
          `${applied.rollbackFailedNoteIds.join(',')}`);
        this.showAlert($r('app.string.restore_failed'),
          $r('app.string.cloud_restore_rollback_incomplete', applied.unresolvedRollbackCount));
        return;
      }
      if (verificationFailures > 0 || applied.degraded > 0) {
        this.showAlert($r('app.string.restore_result'),
          $r('app.string.cloud_restore_partial', applied.restored, manifest.entries.length,
            verificationFailures, applied.degraded));
      } else {
        this.showToast($r('app.string.cloud_restore_complete', applied.restored));
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
        if (parsed !== null && candidates[i].name === backupManifestFileName(parsed.batchId) &&
          (latest === null || parsed.createdAt > latest.createdAt)) {
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
      Row() {
        Button('<')
          .width(48)
          .height(40)
          .fontSize(20)
          .accessibilityText($r('app.string.back'))
          .onClick(() => {
            router.back();
          })
        Text($r('app.string.backup_and_sync'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 12, right: 16 })

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

          if (this.loadState === BackupLoadState.LOADING) {
            Row() {
              LoadingProgress().width(20).height(20)
              Text($r('app.string.backup_settings_loading'))
                .fontSize(14)
                .fontColor(this.resolveTokens().textSecondary)
                .margin({ left: 8 })
            }
            .margin({ bottom: 12 })
          } else if (this.loadState === BackupLoadState.ERROR) {
            Text($r('app.string.backup_settings_load_failed'))
              .fontSize(14)
              .fontColor(this.resolveTokens().danger)
              .margin({ bottom: 8 })
            Button($r('app.string.retry'))
              .width('90%')
              .margin({ bottom: 12 })
              .enabled(!this.isBusy)
              .onClick(() => {
                this.reloadPage();
              })
          } else {
            Text(this.hasConfig ? $r('app.string.server_value', this.serverText) :
              $r('app.string.server_not_configured')).fontSize(14)
              .fontColor(this.resolveTokens().textPrimary).margin({ bottom: 4 })
            Text(this.hasLastBackup ? $r('app.string.last_backup_value', this.lastBackupText) :
              $r('app.string.last_backup_never')).fontSize(14)
              .fontColor(this.resolveTokens().textPrimary).margin({ bottom: 8 })
          }

          Button($r('app.string.configure_webdav'))
            .width('90%')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.navigateToSettings();
            })
          Button($r('app.string.backup_all_to_cloud'))
            .width('90%')
            .enabled(this.loadState === BackupLoadState.READY && this.hasConfig && !this.isBusy)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.backupAll();
            })
          Button($r('app.string.restore_latest_cloud_backup'))
            .width('90%')
            .enabled(this.loadState === BackupLoadState.READY && this.hasConfig && !this.isBusy)
            .onClick(() => {
              this.restoreFromCloud();
            })

          if (this.loadState === BackupLoadState.READY && !this.hasConfig) {
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
