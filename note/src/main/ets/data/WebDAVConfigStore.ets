// T-030 WebDAV 配置存储（@ohos.data.preferences，MVP 密码明文）
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WebDAVConfig } from './WebDAVClient';

const PREF_NAME: string = 'webdav_config';
const KEY_SERVER_URL: string = 'webdav_server_url';
const KEY_USERNAME: string = 'webdav_username';
const KEY_PASSWORD: string = 'webdav_password';
const KEY_BACKUP_PATH: string = 'webdav_backup_path';
const KEY_LAST_BACKUP: string = 'webdav_last_backup';

export class WebDAVConfigStore {
  // 读取配置（无配置时返回默认值）
  static async load(context: common.UIAbilityContext): Promise<WebDAVConfig> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      const config: WebDAVConfig = {
        serverUrl: pref.getSync(KEY_SERVER_URL, '') as string,
        username: pref.getSync(KEY_USERNAME, '') as string,
        password: pref.getSync(KEY_PASSWORD, '') as string,
        backupPath: pref.getSync(KEY_BACKUP_PATH, '/nota-backup/') as string,
      };
      return config;
    } catch (e) {
      console.error(`WebDAVConfigStore.load failed: ${JSON.stringify(e)}`);
      return { serverUrl: '', username: '', password: '', backupPath: '/nota-backup/' };
    }
  }

  // 保存配置
  static async save(context: common.UIAbilityContext, config: WebDAVConfig): Promise<boolean> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      pref.putSync(KEY_SERVER_URL, config.serverUrl);
      pref.putSync(KEY_USERNAME, config.username);
      pref.putSync(KEY_PASSWORD, config.password);
      pref.putSync(KEY_BACKUP_PATH, config.backupPath.length > 0 ? config.backupPath : '/nota-backup/');
      await pref.flush();
      return true;
    } catch (e) {
      console.error(`WebDAVConfigStore.save failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // 读取上次备份时间（毫秒；0 = 从未备份）
  static async getLastBackup(context: common.UIAbilityContext): Promise<number> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      return pref.getSync(KEY_LAST_BACKUP, 0) as number;
    } catch (e) {
      return 0;
    }
  }

  // 记录上次备份时间
  static async setLastBackup(context: common.UIAbilityContext, time: number): Promise<void> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      pref.putSync(KEY_LAST_BACKUP, time);
      await pref.flush();
    } catch (e) {
      console.error(`WebDAVConfigStore.setLastBackup failed: ${JSON.stringify(e)}`);
    }
  }
}
