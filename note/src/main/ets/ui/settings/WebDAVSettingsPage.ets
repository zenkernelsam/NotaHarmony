// T-030 WebDAV 配置页面（服务器/用户名/密码/备份路径 + 测试连接 + 保存）
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { WebDAVClient, WebDAVConfig, ConnectionResult } from '../../data/WebDAVClient';
import { WebDAVConfigStore } from '../../data/WebDAVConfigStore';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';

@Entry
@Component
struct WebDAVSettingsPage {
  @State serverUrl: string = '';
  @State username: string = '';
  @State password: string = '';
  @State backupPath: string = '/nota-backup/';
  @State isTesting: boolean = false;
  @State testResult: string = '';
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
      this.backupPath = config.backupPath;
    } catch (e) {
      console.error(`loadConfig failed: ${JSON.stringify(e)}`);
    }
  }

  private async testConnection(): Promise<void> {
    if (this.isTesting) {
      return;
    }
    if (this.serverUrl.trim().length === 0) {
      this.testResult = '请先填写服务器 URL';
      return;
    }
    this.isTesting = true;
    this.testResult = '正在测试连接...';
    try {
      const config: WebDAVConfig = {
        serverUrl: this.serverUrl,
        username: this.username,
        password: this.password,
        backupPath: this.backupPath,
      };
      const client = new WebDAVClient(config);
      const result: ConnectionResult = await client.testConnection();
      this.testResult = result.message;
    } catch (e) {
      console.error(`testConnection failed: ${JSON.stringify(e)}`);
      this.testResult = '网络请求失败：无法连接服务器或超时（30s）';
    } finally {
      this.isTesting = false;
    }
  }

  private async saveConfig(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const config: WebDAVConfig = {
        serverUrl: this.serverUrl.trim(),
        username: this.username,
        password: this.password,
        backupPath: this.backupPath.trim().length > 0 ? this.backupPath.trim() : '/nota-backup/',
      };
      const ok: boolean = await WebDAVConfigStore.save(context, config);
      if (ok) {
        this.safeToast('配置已保存');
      } else {
        this.safeToast('保存失败');
      }
    } catch (e) {
      console.error(`saveConfig failed: ${JSON.stringify(e)}`);
      this.safeToast('保存失败');
    }
  }

  private safeToast(message: string): void {
    try {
      promptAction.showToast({ message: message, duration: 2000 });
    } catch (e) {
      console.error(`showToast failed: ${JSON.stringify(e)}`);
    }
  }

  build() {
    Column() {
      Text('WebDAV 配置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.resolveTokens().textPrimary)
        .margin({ top: 24, bottom: 16 })

      TextInput({ placeholder: 'https://dav.example.com', text: this.serverUrl })
        .width('90%')
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.serverUrl = value;
        })
      TextInput({ placeholder: '用户名', text: this.username })
        .width('90%')
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.username = value;
        })
      TextInput({ placeholder: '密码', text: this.password })
        .width('90%')
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.password = value;
        })
      TextInput({ placeholder: '/nota-backup/', text: this.backupPath })
        .width('90%')
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.backupPath = value;
        })

      Button('测试连接')
        .width('90%')
        .margin({ bottom: 8 })
        .enabled(!this.isTesting)
        .onClick(() => {
          this.testConnection();
        })

      if (this.testResult.length > 0) {
        Text(this.testResult)
          .fontSize(14)
          .fontColor(this.testResult.startsWith('连接成功') ? '#00B42A' : '#E84026')
          .margin({ bottom: 12, top: 4 })
      }

      Button('保存配置')
        .width('90%')
        .onClick(() => {
          this.saveConfig();
        })

      Text('密码明文存储于本地 Preferences（MVP，后续可加密）')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.resolveTokens().background)
  }
}
