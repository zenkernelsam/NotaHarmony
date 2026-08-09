import { describe, it, expect } from '@ohos/hypium';
import { WebDAVConfig } from '../main/ets/data/WebDAVClient';
import {
  SecretReadResult, SecretReadState, WebDAVConfigSaveResult, WebDAVConfigStorage,
  WebDAVConfigTransaction,
} from '../main/ets/data/WebDAVConfigTransaction';

class FakeConfigStorage implements WebDAVConfigStorage {
  record: string | null = null;
  secrets: Map<string, string> = new Map<string, string>();
  failReadRecord: boolean = false;
  failReadSecret: boolean = false;
  failWriteSecret: boolean = false;
  failWriteRecordAt: number = 0;
  failRemoveAt: number = 0;
  writeRecordCount: number = 0;
  removeCount: number = 0;

  async readRecord(): Promise<string | null> {
    if (this.failReadRecord) {
      throw new Error('injected record read failure');
    }
    return this.record;
  }

  async writeRecord(record: string): Promise<void> {
    this.writeRecordCount++;
    if (this.failWriteRecordAt === this.writeRecordCount) {
      throw new Error('injected record commit failure');
    }
    this.record = record;
  }

  async readSecret(alias: string): Promise<SecretReadResult> {
    if (this.failReadSecret) {
      throw new Error('injected secret query failure');
    }
    const value: string | undefined = this.secrets.get(alias);
    return value === undefined ? new SecretReadResult(SecretReadState.NOT_FOUND) :
      new SecretReadResult(SecretReadState.FOUND, value);
  }

  async writeSecret(alias: string, secret: string): Promise<void> {
    if (this.failWriteSecret) {
      throw new Error('injected secret add failure');
    }
    this.secrets.set(alias, secret);
  }

  async removeSecret(alias: string): Promise<void> {
    this.removeCount++;
    if (this.failRemoveAt === this.removeCount) {
      throw new Error('injected secret remove failure');
    }
    this.secrets.delete(alias);
  }
}

function config(serverUrl: string, password: string): WebDAVConfig {
  return {
    serverUrl: serverUrl,
    username: 'user',
    password: password,
    backupPath: '/backup/',
    allowInsecureHttp: false,
  };
}

function transaction(storage: FakeConfigStorage, generation: string): WebDAVConfigTransaction {
  return new WebDAVConfigTransaction(storage, (): string => generation);
}

export default function webDAVConfigTransactionTest() {
  describe('WebDAVConfigTransaction', () => {
    it('publishes the record only after the generation credential exists', 0, async () => {
      const storage = new FakeConfigStorage();
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0001')
        .save(config('https://old.example', 'secret-1'));
      expect(result.committed).assertTrue();
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.serverUrl).assertEqual('https://old.example');
      expect(loaded?.password).assertEqual('secret-1');
    });

    it('keeps the old generation when secret add fails', 0, async () => {
      const storage = new FakeConfigStorage();
      await transaction(storage, 'generation-0001').save(config('https://old.example', 'secret-1'));
      storage.failWriteSecret = true;
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0002')
        .save(config('https://new.example', 'secret-2'));
      expect(result.committed).assertFalse();
      storage.failWriteSecret = false;
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.serverUrl).assertEqual('https://old.example');
      expect(loaded?.password).assertEqual('secret-1');
    });

    it('compensates a new credential when record commit fails', 0, async () => {
      const storage = new FakeConfigStorage();
      await transaction(storage, 'generation-0001').save(config('https://old.example', 'secret-1'));
      storage.failWriteRecordAt = storage.writeRecordCount + 1;
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0002')
        .save(config('https://new.example', 'secret-2'));
      expect(result.committed).assertFalse();
      expect(storage.secrets.has('nota.webdav.password.generation-0002')).assertFalse();
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.serverUrl).assertEqual('https://old.example');
      expect(loaded?.password).assertEqual('secret-1');
    });

    it('reports compensation remove failure without exposing a mixed generation', 0, async () => {
      const storage = new FakeConfigStorage();
      await transaction(storage, 'generation-0001').save(config('https://old.example', 'secret-1'));
      storage.failWriteRecordAt = storage.writeRecordCount + 1;
      storage.failRemoveAt = storage.removeCount + 1;
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0002')
        .save(config('https://new.example', 'secret-2'));
      expect(result.committed).assertFalse();
      expect(result.cleanupPending).assertTrue();
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.serverUrl).assertEqual('https://old.example');
      expect(loaded?.password).assertEqual('secret-1');
    });

    it('commits password clearing before removing the previous credential', 0, async () => {
      const storage = new FakeConfigStorage();
      await transaction(storage, 'generation-0001').save(config('https://old.example', 'secret-1'));
      storage.failRemoveAt = storage.removeCount + 1;
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0002')
        .save(config('https://new.example', ''));
      expect(result.committed).assertTrue();
      expect(result.cleanupPending).assertTrue();
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.serverUrl).assertEqual('https://new.example');
      expect(loaded?.password).assertEqual('');
    });

    it('does not turn secret query failure into an empty password', 0, async () => {
      const storage = new FakeConfigStorage();
      await transaction(storage, 'generation-0001').save(config('https://old.example', 'secret-1'));
      storage.failReadSecret = true;
      let failed: boolean = false;
      try {
        await transaction(storage, 'unused-0001').load();
      } catch (_error) {
        failed = true;
      }
      expect(failed).assertTrue();
    });

    it('keeps the committed generation when cleanup marker flush fails', 0, async () => {
      const storage = new FakeConfigStorage();
      await transaction(storage, 'generation-0001').save(config('https://old.example', 'secret-1'));
      storage.failWriteRecordAt = storage.writeRecordCount + 2;
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0002')
        .save(config('https://new.example', 'secret-2'));
      expect(result.committed).assertTrue();
      expect(result.cleanupPending).assertTrue();
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.serverUrl).assertEqual('https://new.example');
      expect(loaded?.password).assertEqual('secret-2');
    });

    it('moves a legacy credential to a generation alias after commit', 0, async () => {
      const storage = new FakeConfigStorage();
      storage.secrets.set('nota.webdav.password', 'legacy-secret');
      const result: WebDAVConfigSaveResult = await transaction(storage, 'generation-0001')
        .save(config('https://legacy.example', 'legacy-secret'), ['nota.webdav.password']);
      expect(result.committed).assertTrue();
      expect(result.cleanupPending).assertFalse();
      expect(storage.secrets.has('nota.webdav.password')).assertFalse();
      expect(storage.secrets.get('nota.webdav.password.generation-0001')).assertEqual('legacy-secret');
      const loaded: WebDAVConfig | null = await transaction(storage, 'unused-0001').load();
      expect(loaded?.password).assertEqual('legacy-secret');
    });
  });
}
