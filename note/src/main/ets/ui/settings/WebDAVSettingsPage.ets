// T-030 WebDAV 配置页面（服务器/用户名/密码/备份路径 + 测试连接 + 保存）
import { promptAction, router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import {
  DEFAULT_WEBDAV_BACKUP_PATH, WebDAVClient, WebDAVConfig, ConnectionResult, normalizeWebDAVConfig,
  webDAVBackupPathForDisplay,
} from '../../data/WebDAVClient';
import { WebDAVConfigStore } from '../../data/WebDAVConfigStore';
import { WebDAVConfigSaveResult } from '../../data/WebDAVConfigTransaction';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Entry
@Component
struct WebDAVSettingsPage {
  @State serverUrl: string = '';
  @State username: string = '';
  @State password: string = '';
  @State backupPath: string = DEFAULT_WEBDAV_BACKUP_PATH;
  @State allowInsecureHttp: boolean = false;
  @State isTesting: boolean = false;
  @State testResult: ResourceStr = '';
  @State hasTestResult: boolean = false;
  @State testSucceeded: boolean = false;
  // T-038：主题状态
  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;

  // 注意：ArkTS 编译器会丢弃 @Component struct 中的自定义 getter，必须用普通方法
  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    this.loadConfig();
  }

  private async loadConfig(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const config: WebDAVConfig = await WebDAVConfigStore.load(context);
      this.serverUrl = config.serverUrl;
      this.username = config.username;
      this.password = config.password;
      this.backupPath = webDAVBackupPathForDisplay(config.backupPath);
      this.allowInsecureHttp = config.allowInsecureHttp === true;
    } catch (e) {
      console.error(`loadConfig failed: ${JSON.stringify(e)}`);
    }
  }

  private async testConnection(): Promise<void> {
    if (this.isTesting) {
      return;
    }
    if (this.serverUrl.trim().length === 0) {
      this.testSucceeded = false;
      this.testResult = $r('app.string.enter_server_url');
      this.hasTestResult = true;
      return;
    }
    let allowInsecureHttp: boolean;
    try {
      allowInsecureHttp = await this.confirmInsecureHttp();
    } catch (e) {
      console.error(`insecure HTTP confirmation failed: ${JSON.stringify(e)}`);
      this.testSucceeded = false;
      this.testResult = $r('app.string.connection_request_failed');
      this.hasTestResult = true;
      return;
    }
    if (this.isInsecureHttp() && !allowInsecureHttp) {
      this.testSucceeded = false;
      this.testResult = $r('app.string.insecure_connection_cancelled');
      this.hasTestResult = true;
      return;
    }
    let config: WebDAVConfig;
    try {
      config = this.normalizedDraft(allowInsecureHttp);
      this.applyNormalizedDraft(config);
    } catch (e) {
      console.error(`invalid WebDAV test configuration: ${JSON.stringify(e)}`);
      this.testSucceeded = false;
      this.testResult = $r('app.string.invalid_webdav_config');
      this.hasTestResult = true;
      return;
    }
    this.isTesting = true;
    this.testSucceeded = false;
    this.testResult = $r('app.string.testing_connection_status');
    this.hasTestResult = true;
    try {
      const client = new WebDAVClient(config);
      const result: ConnectionResult = await client.testConnection();
      this.testSucceeded = result.success;
      this.testResult = result.message;
      this.hasTestResult = true;
    } catch (e) {
      console.error(`testConnection failed: ${JSON.stringify(e)}`);
      this.testSucceeded = false;
      this.testResult = $r('app.string.connection_request_failed');
      this.hasTestResult = true;
    } finally {
      this.isTesting = false;
    }
  }

  private async saveConfig(): Promise<void> {
    let allowInsecureHttp: boolean;
    try {
      allowInsecureHttp = await this.confirmInsecureHttp();
    } catch (e) {
      console.error(`insecure HTTP confirmation failed: ${JSON.stringify(e)}`);
      this.safeToast($r('app.string.save_failed'));
      return;
    }
    if (this.isInsecureHttp() && !allowInsecureHttp) {
      this.safeToast($r('app.string.insecure_save_cancelled'));
      return;
    }
    let config: WebDAVConfig;
    try {
      config = this.normalizedDraft(allowInsecureHttp);
    } catch (e) {
      console.error(`invalid WebDAV save configuration: ${JSON.stringify(e)}`);
      this.safeToast($r('app.string.invalid_webdav_config'));
      return;
    }
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const result: WebDAVConfigSaveResult = await WebDAVConfigStore.save(context, config);
      if (result.committed) {
        this.applyNormalizedDraft(config);
        this.safeToast(result.cleanupPending ? $r('app.string.settings_saved_cleanup_pending') :
          $r('app.string.settings_saved'));
      } else {
        console.error(`WebDAV config commit failed: ${result.message}`);
        this.safeToast($r('app.string.save_failed'));
      }
    } catch (e) {
      console.error(`saveConfig failed: ${JSON.stringify(e)}`);
      this.safeToast($r('app.string.save_failed'));
    }
  }

  private normalizedDraft(allowInsecureHttp: boolean): WebDAVConfig {
    return normalizeWebDAVConfig({
      serverUrl: this.serverUrl,
      username: this.username,
      password: this.password,
      backupPath: this.backupPath,
      allowInsecureHttp: allowInsecureHttp,
    });
  }

  private applyNormalizedDraft(config: WebDAVConfig): void {
    this.serverUrl = config.serverUrl;
    this.username = config.username;
    this.password = config.password;
    this.backupPath = webDAVBackupPathForDisplay(config.backupPath);
    this.allowInsecureHttp = config.allowInsecureHttp === true;
  }

  private safeToast(message: ResourceStr): void {
    try {
      promptAction.showToast({ message: message, duration: 2000 });
    } catch (e) {
      console.error(`showToast failed: ${JSON.stringify(e)}`);
    }
  }

  private isInsecureHttp(): boolean {
    return this.serverUrl.trim().toLowerCase().startsWith('http://');
  }

  private async confirmInsecureHttp(): Promise<boolean> {
    if (!this.isInsecureHttp()) {
      return false;
    }
    if (this.allowInsecureHttp) {
      return true;
    }
    const response: promptAction.ShowDialogSuccessResponse = await promptAction.showDialog({
      title: $r('app.string.insecure_webdav_title'),
      message: $r('app.string.insecure_webdav_message'),
      buttons: [
        { text: $r('app.string.cancel'), color: this.resolveTokens().textSecondary },
        { text: $r('app.string.continue_anyway'), color: this.resolveTokens().danger },
      ],
    });
    return response.index === 1;
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
        Text($r('app.string.webdav_settings'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.resolveTokens().textPrimary)
          .margin({ left: 12 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 12, right: 16 })

      TextInput({ placeholder: 'https://dav.example.com', text: this.serverUrl })
        .width('90%')
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().surface)
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.serverUrl = value;
          this.allowInsecureHttp = false;
        })
      TextInput({ placeholder: $r('app.string.username'), text: this.username })
        .width('90%')
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().surface)
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.username = value;
        })
      TextInput({ placeholder: $r('app.string.password'), text: this.password })
        .width('90%')
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().surface)
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.password = value;
        })
      TextInput({ placeholder: '/nota-backup/', text: this.backupPath })
        .width('90%')
        .fontColor(this.resolveTokens().textPrimary)
        .placeholderColor(this.resolveTokens().textSecondary)
        .backgroundColor(this.resolveTokens().surface)
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.backupPath = value;
        })

      Button($r('app.string.test_connection'))
        .width('90%')
        .margin({ bottom: 8 })
        .enabled(!this.isTesting)
        .onClick(() => {
          this.testConnection();
        })

      if (this.hasTestResult) {
        Text(this.testResult)
          .fontSize(14)
          .fontColor(this.testSucceeded ? this.resolveTokens().success :
            this.resolveTokens().danger)
          .margin({ bottom: 12, top: 4 })
      }

      Button($r('app.string.save_settings'))
        .width('90%')
        .onClick(() => {
          this.saveConfig();
        })

      if (this.isInsecureHttp()) {
        Text($r('app.string.insecure_webdav_warning'))
          .fontSize(12)
          .fontColor(this.resolveTokens().danger)
          .margin({ top: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }
}
