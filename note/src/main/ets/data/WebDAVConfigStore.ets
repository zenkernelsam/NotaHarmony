import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { asset } from '@kit.AssetStoreKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { AsyncMutex } from './AsyncMutex';
import {
  DEFAULT_WEBDAV_BACKUP_PATH, WebDAVConfig, normalizeWebDAVConfig,
} from './WebDAVClient';
import {
  LEGACY_WEBDAV_PASSWORD_ALIAS, SecretReadResult, SecretReadState, WebDAVConfigSaveResult, WebDAVConfigStorage,
  WebDAVConfigTransaction,
} from './WebDAVConfigTransaction';

const PREF_NAME: string = 'webdav_config';
const KEY_SERVER_URL: string = 'webdav_server_url';
const KEY_USERNAME: string = 'webdav_username';
const KEY_PASSWORD: string = 'webdav_password';
const KEY_BACKUP_PATH: string = 'webdav_backup_path';
const KEY_LAST_BACKUP: string = 'webdav_last_backup';
const KEY_ALLOW_INSECURE_HTTP: string = 'webdav_allow_insecure_http';
const KEY_CONFIG_RECORD: string = 'webdav_config_record_v1';
const ASSET_NOT_FOUND: number = 24000002;

class LegacyWebDAVConfigResult {
  config: WebDAVConfig;
  present: boolean;

  constructor(config: WebDAVConfig, present: boolean) {
    this.config = config;
    this.present = present;
  }
}

class HarmonyWebDAVConfigStorage implements WebDAVConfigStorage {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async readRecord(): Promise<string | null> {
    const pref = await preferences.getPreferences(this.context, PREF_NAME);
    const raw: string = pref.getSync(KEY_CONFIG_RECORD, '') as string;
    return raw.length > 0 ? raw : null;
  }

  async writeRecord(record: string): Promise<void> {
    const pref = await preferences.getPreferences(this.context, PREF_NAME);
    const oldRecord: string = pref.getSync(KEY_CONFIG_RECORD, '') as string;
    const oldLegacyPassword: string = pref.getSync(KEY_PASSWORD, '') as string;
    pref.putSync(KEY_CONFIG_RECORD, record);
    pref.deleteSync(KEY_PASSWORD);
    try {
      await pref.flush();
    } catch (e) {
      if (oldRecord.length > 0) {
        pref.putSync(KEY_CONFIG_RECORD, oldRecord);
      } else {
        pref.deleteSync(KEY_CONFIG_RECORD);
      }
      if (oldLegacyPassword.length > 0) {
        pref.putSync(KEY_PASSWORD, oldLegacyPassword);
      } else {
        pref.deleteSync(KEY_PASSWORD);
      }
      try {
        await pref.flush();
      } catch (rollbackError) {
        throw new Error(`preferences commit and rollback failed: ${JSON.stringify(e)}; ` +
          `${JSON.stringify(rollbackError)}`);
      }
      throw new Error(`preferences commit failed: ${JSON.stringify(e)}`);
    }
  }

  async readSecret(alias: string): Promise<SecretReadResult> {
    const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    query.set(asset.Tag.ALIAS, encode(alias));
    query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
    try {
      const results: asset.AssetMap[] = await asset.query(query);
      if (results.length === 0) {
        return new SecretReadResult(SecretReadState.NOT_FOUND);
      }
      const secret: asset.Value | undefined = results[0].get(asset.Tag.SECRET);
      if (!(secret instanceof Uint8Array)) {
        throw new Error(`AssetStore credential ${alias} has no byte secret`);
      }
      return new SecretReadResult(SecretReadState.FOUND,
        util.TextDecoder.create('utf-8').decodeToString(secret));
    } catch (e) {
      if ((e as BusinessError).code === ASSET_NOT_FOUND) {
        return new SecretReadResult(SecretReadState.NOT_FOUND);
      }
      throw new Error(`AssetStore query failed: ${JSON.stringify(e)}`);
    }
  }

  async writeSecret(alias: string, secret: string): Promise<void> {
    const attributes: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    attributes.set(asset.Tag.ALIAS, encode(alias));
    attributes.set(asset.Tag.SECRET, encode(secret));
    attributes.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_FIRST_UNLOCKED);
    attributes.set(asset.Tag.AUTH_TYPE, asset.AuthType.NONE);
    attributes.set(asset.Tag.SYNC_TYPE, asset.SyncType.NEVER);
    await asset.add(attributes);
  }

  async removeSecret(alias: string): Promise<void> {
    const query: asset.AssetMap = new Map<asset.Tag, asset.Value>();
    query.set(asset.Tag.ALIAS, encode(alias));
    try {
      await asset.remove(query);
    } catch (e) {
      if ((e as BusinessError).code !== ASSET_NOT_FOUND) {
        throw new Error(`AssetStore remove failed: ${JSON.stringify(e)}`);
      }
    }
  }
}

export class WebDAVConfigStore {
  private static mutex: AsyncMutex = new AsyncMutex();

  static async load(context: common.UIAbilityContext): Promise<WebDAVConfig> {
    return WebDAVConfigStore.mutex.runExclusive(async (): Promise<WebDAVConfig> => {
      const storage = new HarmonyWebDAVConfigStorage(context);
      const transaction = new WebDAVConfigTransaction(storage, WebDAVConfigStore.newGeneration);
      const config: WebDAVConfig | null = await transaction.load();
      if (config !== null) {
        return config;
      }
      const legacy: LegacyWebDAVConfigResult = await WebDAVConfigStore.loadLegacy(context, storage);
      if (!legacy.present) {
        return normalizeWebDAVConfig(legacy.config);
      }
      const normalized: WebDAVConfig = normalizeWebDAVConfig(legacy.config);
      const migrated: WebDAVConfigSaveResult =
        await transaction.save(normalized, [LEGACY_WEBDAV_PASSWORD_ALIAS]);
      if (!migrated.committed) {
        throw new Error(`legacy WebDAV configuration migration failed: ${migrated.message}`);
      }
      return normalized;
    });
  }

  static async save(context: common.UIAbilityContext, config: WebDAVConfig): Promise<WebDAVConfigSaveResult> {
    return WebDAVConfigStore.mutex.runExclusive(async (): Promise<WebDAVConfigSaveResult> => {
      const storage = new HarmonyWebDAVConfigStorage(context);
      const transaction = new WebDAVConfigTransaction(storage, WebDAVConfigStore.newGeneration);
      return transaction.save(config, [LEGACY_WEBDAV_PASSWORD_ALIAS]);
    });
  }

  static async getLastBackup(context: common.UIAbilityContext): Promise<number> {
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      const value: number = pref.getSync(KEY_LAST_BACKUP, 0) as number;
      if (!Number.isFinite(value) || value < 0) {
        throw new Error('invalid last backup timestamp');
      }
      return value;
    } catch (e) {
      throw new Error(`WebDAVConfigStore.getLastBackup failed: ${JSON.stringify(e)}`);
    }
  }

  static async setLastBackup(context: common.UIAbilityContext, time: number): Promise<void> {
    if (!Number.isFinite(time) || time <= 0) {
      throw new Error('WebDAVConfigStore.setLastBackup requires a positive timestamp');
    }
    try {
      const pref = await preferences.getPreferences(context, PREF_NAME);
      pref.putSync(KEY_LAST_BACKUP, time);
      await pref.flush();
    } catch (e) {
      throw new Error(`WebDAVConfigStore.setLastBackup failed: ${JSON.stringify(e)}`);
    }
  }

  private static async loadLegacy(context: common.UIAbilityContext,
    storage: HarmonyWebDAVConfigStorage): Promise<LegacyWebDAVConfigResult> {
    const pref = await preferences.getPreferences(context, PREF_NAME);
    const legacySecret: SecretReadResult = await storage.readSecret(LEGACY_WEBDAV_PASSWORD_ALIAS);
    const plainPassword: string = pref.getSync(KEY_PASSWORD, '') as string;
    const password: string = legacySecret.state === SecretReadState.FOUND ? legacySecret.value : plainPassword;
    const serverUrl: string = pref.getSync(KEY_SERVER_URL, '') as string;
    const username: string = pref.getSync(KEY_USERNAME, '') as string;
    const backupPath: string = pref.getSync(KEY_BACKUP_PATH, DEFAULT_WEBDAV_BACKUP_PATH) as string;
    const allowInsecureHttp: boolean = pref.getSync(KEY_ALLOW_INSECURE_HTTP, false) as boolean;
    const config: WebDAVConfig = {
      serverUrl: serverUrl,
      username: username,
      password: password,
      backupPath: backupPath,
      allowInsecureHttp: allowInsecureHttp,
    };
    const present: boolean = serverUrl.length > 0 || username.length > 0 || password.length > 0 ||
      backupPath !== DEFAULT_WEBDAV_BACKUP_PATH || allowInsecureHttp;
    return new LegacyWebDAVConfigResult(config, present);
  }

  private static newGeneration(): string {
    return `${Date.now().toString(36)}-${Math.floor(Math.random() * 0x100000000).toString(36)}`;
  }
}

function encode(value: string): Uint8Array {
  return new util.TextEncoder().encodeInto(value);
}
