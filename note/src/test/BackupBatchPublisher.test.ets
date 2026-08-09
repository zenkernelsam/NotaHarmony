import { describe, it, expect } from '@ohos/hypium';
import {
  BackupBatchHasher, BackupBatchPublisher, BackupBatchTransport,
  BackupPublishResult, BackupPublishStage,
} from '../main/ets/data/BackupBatchPublisher';
import { BackupSourcePackage } from '../main/ets/data/BackupBatchSpec';
import { BackupBatchRestorer, BackupFetchResult } from '../main/ets/data/BackupBatchRestorer';

class FakeHasher implements BackupBatchHasher {
  async hash(data: Uint8Array): Promise<string> {
    let value: number = 0;
    for (let i: number = 0; i < data.length; i++) {
      value = (value + data[i]) % 16;
    }
    return value.toString(16).repeat(64);
  }
}

class FakeTransport implements BackupBatchTransport {
  uploads: string[] = [];
  objects: Map<string, Uint8Array> = new Map<string, Uint8Array>();
  failUploadNumber: number = -1;
  corruptDownloadPath: string = '';

  async ensureBackupDir(): Promise<boolean> { return true; }
  async ensureBackupBatchDir(_batchId: string): Promise<boolean> { return true; }
  backupBatchObjectUrl(batchId: string, fileName: string): string {
    return `root/.pending-${batchId}/${fileName}`;
  }
  backupBatchManifestUrl(batchId: string): string { return `root/batch-${batchId}.manifest.json`; }
  async upload(path: string, data: Uint8Array): Promise<boolean> {
    this.uploads.push(path);
    if (this.uploads.length === this.failUploadNumber) {
      return false;
    }
    this.objects.set(path, data.slice());
    return true;
  }
  async download(path: string): Promise<Uint8Array | null> {
    const value: Uint8Array | undefined = this.objects.get(path);
    if (value === undefined) {
      return null;
    }
    if (path === this.corruptDownloadPath) {
      return new Uint8Array([255]);
    }
    return value.slice();
  }
}

function packages(): BackupSourcePackage[] {
  return [
    { noteId: 'a', updatedAt: 10, revision: '1:1:1', data: new Uint8Array([1, 2]) },
    { noteId: 'b', updatedAt: 11, revision: '1:2:2', data: new Uint8Array([3, 4]) },
    { noteId: 'c', updatedAt: 12, revision: '1:3:3', data: new Uint8Array([5, 6]) },
  ];
}

export default function backupBatchPublisherTest() {
  describe('BackupBatchPublisher', () => {
    it('publishes the completion manifest only after every object verifies', 0, async () => {
      const transport = new FakeTransport();
      const publisher = new BackupBatchPublisher(transport, new FakeHasher());
      const result: BackupPublishResult = await publisher.publish(
        packages(), 'm4f9z120-abcd1234', 100);
      expect(result.success).assertTrue();
      expect(result.verified).assertEqual(3);
      expect(transport.uploads.length).assertEqual(4);
      expect(transport.uploads[3]).assertContain('.manifest.json');
      expect(result.manifest?.entries.length).assertEqual(3);
    });

    it('does not expose a manifest when the second object upload fails', 0, async () => {
      const transport = new FakeTransport();
      transport.failUploadNumber = 2;
      const publisher = new BackupBatchPublisher(transport, new FakeHasher());
      const result: BackupPublishResult = await publisher.publish(
        packages(), 'm4f9z120-abcd1234', 100);
      expect(result.success).assertFalse();
      expect(result.stage).assertEqual(BackupPublishStage.OBJECT_UPLOAD);
      expect(result.verified).assertEqual(1);
      expect(transport.uploads.length).assertEqual(2);
      expect(transport.uploads[1].endsWith('.manifest.json')).assertFalse();
    });

    it('does not publish after object verification detects corruption', 0, async () => {
      const transport = new FakeTransport();
      transport.corruptDownloadPath = 'root/.pending-m4f9z120-abcd1234/0-a.note';
      const publisher = new BackupBatchPublisher(transport, new FakeHasher());
      const result: BackupPublishResult = await publisher.publish(
        packages(), 'm4f9z120-abcd1234', 100);
      expect(result.stage).assertEqual(BackupPublishStage.OBJECT_VERIFY);
      expect(result.verified).assertEqual(0);
      expect(transport.uploads.length).assertEqual(1);
    });

    it('isolates one tampered object while preserving the rest of a complete batch', 0, async () => {
      const transport = new FakeTransport();
      const hasher = new FakeHasher();
      const publisher = new BackupBatchPublisher(transport, hasher);
      const published: BackupPublishResult = await publisher.publish(
        packages(), 'm4f9z120-abcd1234', 100);
      expect(published.success).assertTrue();
      expect(published.manifest === null).assertFalse();
      if (published.manifest === null) {
        return;
      }
      transport.corruptDownloadPath = 'root/.pending-m4f9z120-abcd1234/1-b.note';
      const restorer = new BackupBatchRestorer(transport, hasher);
      const fetched: BackupFetchResult = await restorer.fetch(published.manifest);
      expect(fetched.verified.length).assertEqual(2);
      expect(fetched.failedNoteIds.length).assertEqual(1);
      expect(fetched.failedNoteIds[0]).assertEqual('b');
    });
  });
}
