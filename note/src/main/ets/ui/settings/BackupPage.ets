// T-030 备份/导入导出页面（本地文件 + WebDAV 云备份）
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import { StrokePersistence } from '../../data/StrokePersistence';
import { NoteExporter } from '../../data/NoteExporter';
import { NoteImporter, ImportReport, ImportResult } from '../../data/NoteImporter';
import { WebDAVClient, WebDAVConfig, WebDAVFileInfo } from '../../data/WebDAVClient';
import { WebDAVConfigStore } from '../../data/WebDAVConfigStore';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Entry
@Component
struct BackupPage {
  @State isLoading: boolean = false;
  @State isBusy: boolean = false;
  @State serverText: string = '未配置';
  @State lastBackupText: string = '从未备份';
  @State hasConfig: boolean = false;
  @State statusText: string = '';

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
      this.serverText = this.hasConfig ? this.config.serverUrl : '未配置';
      const lastBackup: number = await WebDAVConfigStore.getLastBackup(context);
      this.lastBackupText = lastBackup > 0 ? this.formatTime(lastBackup) : '从未备份';
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
    this.statusText = '正在导出...';
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const exporter = new NoteExporter(this.db, this.persistence);
      const noteRepo = new NoteRepositoryImpl(this.db);
      const notes: NoteMeta[] = await noteRepo.getAllNotes();
      if (notes.length === 0) {
        this.statusText = '';
        this.showToast('没有可导出的笔记');
        return;
      }
      let exported: number = 0;
      for (const note of notes) {
        const ok: boolean = await exporter.exportToFile(context, note.id, note.title);
        if (ok) {
          exported++;
        }
      }
      this.showToast(`已导出 ${exported}/${notes.length} 个笔记`);
    } catch (e) {
      console.error(`exportAllLocal failed: ${JSON.stringify(e)}`);
      this.showAlert('导出失败', '导出过程中发生错误，请重试');
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
    this.statusText = '正在导入...';
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const importer = new NoteImporter(this.db, this.persistence);
      const report: ImportReport = await importer.importFromFile(context);
      if (report.result === ImportResult.SUCCESS) {
        this.showToast(report.message);
      } else if (report.result === ImportResult.PARTIAL) {
        this.showAlert('部分导入', report.message);
      } else if (report.result === ImportResult.CORRUPTED) {
        this.showAlert('导入失败', report.message);
      } else {
        this.showAlert('不支持的格式', report.message);
      }
    } catch (e) {
      console.error(`importLocal failed: ${JSON.stringify(e)}`);
      this.showAlert('导入失败', '读取或解析文件时发生错误');
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
    this.statusText = '正在备份到云端...';
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const client = new WebDAVClient(this.config);
      const exporter = new NoteExporter(this.db, this.persistence);
      const backups = await exporter.exportAllNotes();
      if (backups.size === 0) {
        this.showToast('没有可备份的笔记');
        return;
      }
      if (!await client.ensureBackupDir()) {
        this.showAlert('备份失败', '无法创建备份目录，请检查服务器配置');
        return;
      }
      let uploaded: number = 0;
      const keys: string[] = Array.from(backups.keys());
      for (const noteId of keys) {
        const data = backups.get(noteId);
        if (data !== undefined && await client.upload(client.remoteNotePath(noteId), data)) {
          uploaded++;
        }
      }
      await WebDAVConfigStore.setLastBackup(context, Date.now());
      this.lastBackupText = this.formatTime(Date.now());
      this.showToast(`云端备份完成：${uploaded}/${keys.length}`);
    } catch (e) {
      console.error(`backupAll failed: ${JSON.stringify(e)}`);
      this.showAlert('备份失败', '网络错误或服务器不可达，请稍后重试');
    } finally {
      this.isBusy = false;
      this.statusText = '';
    }
  }

  // === WebDAV：从云端恢复（恢复最近一次备份）===
  private async restoreFromCloud(): Promise<void> {
    if (this.isBusy || !this.hasConfig) {
      return;
    }
    this.isBusy = true;
    this.statusText = '正在从云端恢复...';
    try {
      const client = new WebDAVClient(this.config);
      const files: WebDAVFileInfo[] = await client.listDir(client.remoteNotePath(''));
      const noteFiles: WebDAVFileInfo[] = files.filter((f: WebDAVFileInfo) => f.name.endsWith('.note'));
      if (noteFiles.length === 0) {
        this.showToast('云端没有可恢复的备份');
        return;
      }
      // 按最后修改时间取最新
      noteFiles.sort((a: WebDAVFileInfo, b: WebDAVFileInfo) => b.lastModified - a.lastModified);
      const target: WebDAVFileInfo = noteFiles[0];
      const data: Uint8Array | null = await client.download(target.path);
      if (data === null) {
        this.showAlert('恢复失败', '下载备份文件失败');
        return;
      }
      const importer = new NoteImporter(this.db, this.persistence);
      const report: ImportReport = await importer.importFromData(data);
      if (report.result === ImportResult.SUCCESS) {
        this.showToast(`已恢复：${report.message}`);
      } else {
        this.showAlert('恢复结果', report.message);
      }
    } catch (e) {
      console.error(`restoreFromCloud failed: ${JSON.stringify(e)}`);
      this.showAlert('恢复失败', '网络错误或服务器不可达，请稍后重试');
    } finally {
      this.isBusy = false;
      this.statusText = '';
    }
  }

  private navigateToSettings(): void {
    router.pushUrl({ url: 'ui/settings/WebDAVSettingsPage' }).catch((e: Error) => {
      console.error(`pushUrl failed: ${JSON.stringify(e)}`);
    });
  }

  // === UI ===
  private showToast(message: string): void {
    try {
      promptAction.showToast({ message: message, duration: 2500 });
    } catch (e) {
      console.error(`showToast failed: ${JSON.stringify(e)}`);
    }
  }

  private showAlert(title: string, message: string): void {
    this.getUIContext().showAlertDialog({
      title: title,
      message: message,
      confirm: { value: '确定', action: () => {
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
      Text('备份与同步')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 24, bottom: 16 })

      Scroll() {
        Column() {
          // === 本地文件区 ===
          Text('本地文件').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
          Button('导出全部笔记为 .note')
            .width('90%')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.exportAllLocal();
            })
          Button('从 .note 文件导入')
            .width('90%')
            .margin({ bottom: 16 })
            .onClick(() => {
              this.importLocal();
            })

          Divider().margin({ bottom: 16 })

          // === WebDAV 区 ===
          Text('WebDAV 云备份').fontSize(18).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
          Text(`服务器: ${this.serverText}`).fontSize(14).margin({ bottom: 4 })
          Text(`上次备份: ${this.lastBackupText}`).fontSize(14).margin({ bottom: 8 })

          Button('配置 WebDAV')
            .width('90%')
            .margin({ bottom: 8 })
            .onClick(() => {
              this.navigateToSettings();
            })
          Button('备份全部笔记到云端')
            .width('90%')
            .enabled(this.hasConfig && !this.isBusy)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.backupAll();
            })
          Button('从云端恢复（最近一次备份）')
            .width('90%')
            .enabled(this.hasConfig && !this.isBusy)
            .onClick(() => {
              this.restoreFromCloud();
            })

          if (!this.hasConfig) {
            Text('提示：请先配置 WebDAV 服务器').fontSize(12).fontColor('#999999').margin({ top: 8 })
          }

          if (this.isBusy) {
            Row() {
              LoadingProgress().width(24).height(24)
              Text(this.statusText.length > 0 ? this.statusText : '处理中...')
                .fontSize(14)
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
