import {
  DEFAULT_WEBDAV_BACKUP_PATH, WebDAVConfig, normalizeWebDAVConfig,
} from './WebDAVClient';

export const WEBDAV_CONFIG_FORMAT: string = 'nota.webdav-config';
export const WEBDAV_CONFIG_VERSION: number = 1;
export const LEGACY_WEBDAV_PASSWORD_ALIAS: string = 'nota.webdav.password';

export enum SecretReadState {
  FOUND = 'found',
  NOT_FOUND = 'not_found',
}

export class SecretReadResult {
  state: SecretReadState;
  value: string;

  constructor(state: SecretReadState, value: string = '') {
    this.state = state;
    this.value = value;
  }
}

export interface WebDAVConfigStorage {
  readRecord(): Promise<string | null>;
  writeRecord(record: string): Promise<void>;
  readSecret(alias: string): Promise<SecretReadResult>;
  writeSecret(alias: string, secret: string): Promise<void>;
  removeSecret(alias: string): Promise<void>;
}

export interface StoredWebDAVConfig {
  format: string;
  version: number;
  generation: string;
  serverUrl: string;
  username: string;
  backupPath: string;
  allowInsecureHttp: boolean;
  secretAlias: string;
  cleanupAliases: string[];
}

export class WebDAVConfigSaveResult {
  committed: boolean;
  cleanupPending: boolean;
  message: string;

  constructor(committed: boolean, cleanupPending: boolean, message: string = '') {
    this.committed = committed;
    this.cleanupPending = cleanupPending;
    this.message = message;
  }
}

export type WebDAVGenerationFactory = () => string;

export class WebDAVConfigTransaction {
  private storage: WebDAVConfigStorage;
  private generationFactory: WebDAVGenerationFactory;

  constructor(storage: WebDAVConfigStorage, generationFactory: WebDAVGenerationFactory) {
    this.storage = storage;
    this.generationFactory = generationFactory;
  }

  async load(): Promise<WebDAVConfig | null> {
    const raw: string | null = await this.storage.readRecord();
    if (raw === null) {
      return null;
    }
    const record: StoredWebDAVConfig | null = parseStoredWebDAVConfig(raw);
    if (record === null) {
      throw new Error('WebDAV configuration record is corrupted');
    }
    let password: string = '';
    if (record.secretAlias.length > 0) {
      const secret: SecretReadResult = await this.storage.readSecret(record.secretAlias);
      if (secret.state !== SecretReadState.FOUND) {
        throw new Error(`WebDAV credential is missing for generation ${record.generation}`);
      }
      password = secret.value;
    }
    return normalizeWebDAVConfig({
      serverUrl: record.serverUrl,
      username: record.username,
      password: password,
      backupPath: record.backupPath,
      allowInsecureHttp: record.allowInsecureHttp,
    });
  }

  async save(config: WebDAVConfig, extraCleanupAliases: string[] = []): Promise<WebDAVConfigSaveResult> {
    let normalized: WebDAVConfig;
    try {
      normalized = normalizeWebDAVConfig(config);
    } catch (e) {
      return new WebDAVConfigSaveResult(false, false,
        `invalid WebDAV configuration: ${JSON.stringify(e)}`);
    }
    const oldRaw: string | null = await this.storage.readRecord();
    let oldRecord: StoredWebDAVConfig | null = null;
    if (oldRaw !== null) {
      oldRecord = parseStoredWebDAVConfig(oldRaw);
      if (oldRecord === null) {
        oldRecord = parseStoredWebDAVConfigForReplacement(oldRaw);
        if (oldRecord === null) {
          return new WebDAVConfigSaveResult(false, false, 'existing configuration record is corrupted');
        }
      }
    }

    const generation: string = this.generationFactory();
    if (!isValidGeneration(generation)) {
      return new WebDAVConfigSaveResult(false, false, 'invalid configuration generation');
    }
    const secretAlias: string = normalized.password.length > 0 ? passwordAlias(generation) : '';
    const cleanupAliases: string[] = collectCleanupAliases(oldRecord, secretAlias, extraCleanupAliases);
    const nextRecord: StoredWebDAVConfig = {
      format: WEBDAV_CONFIG_FORMAT,
      version: WEBDAV_CONFIG_VERSION,
      generation: generation,
      serverUrl: normalized.serverUrl,
      username: normalized.username,
      backupPath: normalized.backupPath,
      allowInsecureHttp: normalized.allowInsecureHttp === true,
      secretAlias: secretAlias,
      cleanupAliases: cleanupAliases,
    };

    let secretWritten: boolean = false;
    try {
      if (secretAlias.length > 0) {
        await this.storage.writeSecret(secretAlias, normalized.password);
        secretWritten = true;
      }
      await this.storage.writeRecord(JSON.stringify(nextRecord));
    } catch (e) {
      if (secretWritten) {
        try {
          await this.storage.removeSecret(secretAlias);
        } catch (cleanupError) {
          return new WebDAVConfigSaveResult(false, true,
            `commit failed: ${JSON.stringify(e)}; compensation failed: ${JSON.stringify(cleanupError)}`);
        }
      }
      return new WebDAVConfigSaveResult(false, false, `commit failed: ${JSON.stringify(e)}`);
    }

    const failedCleanup: string[] = [];
    for (let i: number = 0; i < cleanupAliases.length; i++) {
      try {
        await this.storage.removeSecret(cleanupAliases[i]);
      } catch (e) {
        failedCleanup.push(cleanupAliases[i]);
      }
    }
    if (failedCleanup.length > 0) {
      return new WebDAVConfigSaveResult(true, true,
        `configuration committed; ${failedCleanup.length} old credential(s) still require cleanup`);
    }

    if (cleanupAliases.length > 0) {
      nextRecord.cleanupAliases = [];
      try {
        await this.storage.writeRecord(JSON.stringify(nextRecord));
      } catch (e) {
        // The committed record still points to the complete new generation. Its stale cleanup list is safe to retry.
        return new WebDAVConfigSaveResult(true, true,
          `configuration committed; cleanup marker update failed: ${JSON.stringify(e)}`);
      }
    }
    return new WebDAVConfigSaveResult(true, false);
  }
}

export function parseStoredWebDAVConfig(raw: string): StoredWebDAVConfig | null {
  try {
    const parsed: StoredWebDAVConfig | null = parseStoredWebDAVConfigForReplacement(raw);
    if (parsed === null) {
      return null;
    }
    const normalized: WebDAVConfig = normalizeWebDAVConfig({
      serverUrl: parsed.serverUrl,
      username: parsed.username,
      password: '',
      backupPath: parsed.backupPath.length > 0 ? parsed.backupPath : DEFAULT_WEBDAV_BACKUP_PATH,
      allowInsecureHttp: parsed.allowInsecureHttp,
    });
    parsed.serverUrl = normalized.serverUrl;
    parsed.backupPath = normalized.backupPath;
    parsed.allowInsecureHttp = normalized.allowInsecureHttp === true;
    if (parsed.serverUrl.length === 0 && parsed.secretAlias.length > 0) {
      return null;
    }
    return parsed;
  } catch (_error) {
    return null;
  }
}

// Replacement may proceed when the record envelope and credential aliases are trustworthy even if
// a legacy URL/path value no longer passes the current canonicalization rules. Loading remains strict.
function parseStoredWebDAVConfigForReplacement(raw: string): StoredWebDAVConfig | null {
  try {
    const parsed = JSON.parse(raw) as StoredWebDAVConfig;
    if (parsed === null || typeof parsed !== 'object' || parsed.format !== WEBDAV_CONFIG_FORMAT ||
      parsed.version !== WEBDAV_CONFIG_VERSION || !isValidGeneration(parsed.generation) ||
      typeof parsed.serverUrl !== 'string' || typeof parsed.username !== 'string' ||
      typeof parsed.backupPath !== 'string' ||
      typeof parsed.allowInsecureHttp !== 'boolean' || typeof parsed.secretAlias !== 'string' ||
      (parsed.secretAlias.length > 0 && parsed.secretAlias !== passwordAlias(parsed.generation)) ||
      !Array.isArray(parsed.cleanupAliases) || parsed.cleanupAliases.length > 32) {
      return null;
    }
    const aliases: Set<string> = new Set<string>();
    for (let i: number = 0; i < parsed.cleanupAliases.length; i++) {
      const alias: string = parsed.cleanupAliases[i];
      if (typeof alias !== 'string' || !isValidPasswordAlias(alias) ||
        alias === parsed.secretAlias || aliases.has(alias)) {
        return null;
      }
      aliases.add(alias);
    }
    return parsed;
  } catch (_error) {
    return null;
  }
}

export function passwordAlias(generation: string): string {
  return `nota.webdav.password.${generation}`;
}

function isValidGeneration(generation: string): boolean {
  return /^[a-z0-9-]{8,80}$/.test(generation);
}

function isValidPasswordAlias(alias: string): boolean {
  return alias === LEGACY_WEBDAV_PASSWORD_ALIAS || /^nota\.webdav\.password\.[a-z0-9-]{8,80}$/.test(alias);
}

function collectCleanupAliases(oldRecord: StoredWebDAVConfig | null, nextAlias: string,
  extraCleanupAliases: string[]): string[] {
  const result: string[] = [];
  const seen: Set<string> = new Set<string>();
  const candidates: string[] = extraCleanupAliases.slice();
  if (oldRecord !== null) {
    candidates.push(...oldRecord.cleanupAliases);
    if (oldRecord.secretAlias.length > 0) {
      candidates.push(oldRecord.secretAlias);
    }
  }
  for (let i: number = 0; i < candidates.length && result.length < 32; i++) {
    const alias: string = candidates[i];
    if (isValidPasswordAlias(alias) && alias !== nextAlias && !seen.has(alias)) {
      seen.add(alias);
      result.push(alias);
    }
  }
  return result;
}
