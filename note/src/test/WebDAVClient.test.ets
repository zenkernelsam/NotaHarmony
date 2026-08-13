import { describe, it, expect } from '@ohos/hypium';
import {
  WebDAVClient, WebDAVConfig, WebDAVFileInfo, normalizeWebDAVConfig, webDAVBackupPathForDisplay,
} from '../main/ets/data/WebDAVClient';
import { webDAVBackupTargetIdentity } from '../main/ets/data/WebDAVConfigStore';

function createClient(): WebDAVClient {
  const config: WebDAVConfig = {
    serverUrl: 'https://dav.example.com/remote.php/dav/files/user',
    username: 'user',
    password: 'secret',
    backupPath: '/nota backup/',
  };
  return new WebDAVClient(config);
}

function throws(operation: () => void): boolean {
  try {
    operation();
    return false;
  } catch (_error) {
    return true;
  }
}

export default function webDAVClientTest() {
  describe('WebDAVClient PROPFIND', () => {
    it('normalizes one shared server root and backup path identity', 0, () => {
      const normalized: WebDAVConfig = normalizeWebDAVConfig({
        serverUrl: '  HTTPS://dav.example.com/remote.php/dav/files/user///  ',
        username: 'user',
        password: 'secret',
        backupPath: '团队%20备份/Nota',
      });
      expect(normalized.serverUrl).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user');
      expect(normalized.backupPath).assertEqual(
        '/%E5%9B%A2%E9%98%9F%20%E5%A4%87%E4%BB%BD/Nota/');
      expect(webDAVBackupPathForDisplay(normalized.backupPath)).assertEqual('/团队 备份/Nota/');
      const client = new WebDAVClient(normalized);
      expect(client.backupDirectoryUrl()).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/' +
        '%E5%9B%A2%E9%98%9F%20%E5%A4%87%E4%BB%BD/Nota/');
    });

    it('keeps canonical backup paths idempotent across save and UI round trips', 0, () => {
      const first: WebDAVConfig = normalizeWebDAVConfig({
        serverUrl: 'https://dav.example.com/root',
        username: '',
        password: '',
        backupPath: '/100%25 ready/%252F-literal/',
      });
      const second: WebDAVConfig = normalizeWebDAVConfig(first);
      expect(second.backupPath).assertEqual(first.backupPath);
      const display: string = webDAVBackupPathForDisplay(first.backupPath);
      expect(display).assertEqual('/100%25 ready/%252F-literal/');
      const fromDisplay: WebDAVConfig = normalizeWebDAVConfig({
        serverUrl: first.serverUrl,
        username: '',
        password: '',
        backupPath: display,
      });
      expect(fromDisplay.backupPath).assertEqual(first.backupPath);
    });

    it('binds last-backup identity to server user and path but not the rotated password', 0, () => {
      const first: WebDAVConfig = {
        serverUrl: 'HTTPS://dav.example.com/root/', username: 'user', password: 'old',
        backupPath: '/team%20notes/',
      };
      const rotated: WebDAVConfig = {
        serverUrl: 'https://dav.example.com/root', username: 'user', password: 'new',
        backupPath: '/team notes/',
      };
      const firstIdentity: string = webDAVBackupTargetIdentity(first);
      expect(firstIdentity).assertEqual(webDAVBackupTargetIdentity(rotated));
      expect(firstIdentity === webDAVBackupTargetIdentity({
        serverUrl: rotated.serverUrl, username: 'other', password: rotated.password,
        backupPath: rotated.backupPath,
      })).assertFalse();
      expect(firstIdentity === webDAVBackupTargetIdentity({
        serverUrl: 'https://other.example.com/root', username: rotated.username,
        password: rotated.password, backupPath: rotated.backupPath,
      })).assertFalse();
      expect(firstIdentity === webDAVBackupTargetIdentity({
        serverUrl: rotated.serverUrl, username: rotated.username, password: rotated.password,
        backupPath: '/another/',
      })).assertFalse();
      expect(webDAVBackupTargetIdentity({
        serverUrl: '', username: '', password: '', backupPath: '/backup/',
      })).assertEqual('');
    });

    it('rejects ambiguous server and backup path configurations', 0, () => {
      const invalidServers: string[] = [
        'ftp://dav.example.com/root',
        'https://dav.example.com/root?share=1',
        'https://dav.example.com/root#fragment',
        'https://user:secret@dav.example.com/root',
        'https://dav.example.com/root\\child',
        "https://dav.example.com/root\nchild",
        'https://dav.example.com/root/%2E%2E/child',
        'https://dav.example.com/root/%2Fchild',
      ];
      for (const serverUrl of invalidServers) {
        expect(throws(() => normalizeWebDAVConfig({
          serverUrl: serverUrl,
          username: '',
          password: '',
          backupPath: '/backup/',
        }))).assertTrue();
      }
      const invalidPaths: string[] = [
        '/', '/backup//notes/', '/backup/../notes/', '/backup/%2e/notes/',
        '/backup/%2Fnotes/', '/backup/%5cnotes/', '/backup\\notes/', '/backup/%zz/',
        "/backup/notes\n/",
      ];
      for (const backupPath of invalidPaths) {
        expect(throws(() => normalizeWebDAVConfig({
          serverUrl: 'https://dav.example.com/root',
          username: '',
          password: '',
          backupPath: backupPath,
        }))).assertTrue();
      }
      expect(throws(() => normalizeWebDAVConfig({
        serverUrl: 'https://dav.example.com/root',
        username: 'user:name',
        password: 'secret',
        backupPath: '/backup/',
      }))).assertTrue();
    });

    it('requires explicit consent for HTTP and never retains it for HTTPS', 0, () => {
      expect(throws(() => normalizeWebDAVConfig({
        serverUrl: 'http://dav.example.com/root',
        username: '',
        password: '',
        backupPath: '/backup/',
      }))).assertTrue();
      const httpConfig: WebDAVConfig = normalizeWebDAVConfig({
        serverUrl: 'http://dav.example.com/root',
        username: '',
        password: '',
        backupPath: '/backup/',
        allowInsecureHttp: true,
      });
      expect(httpConfig.allowInsecureHttp).assertTrue();
      const httpsConfig: WebDAVConfig = normalizeWebDAVConfig({
        serverUrl: 'https://dav.example.com/root',
        username: '',
        password: '',
        backupPath: '/backup/',
        allowInsecureHttp: true,
      });
      expect(httpsConfig.allowInsecureHttp).assertFalse();
    });

    it('uses a collection URL instead of manufacturing an empty note name', 0, () => {
      const client: WebDAVClient = createClient();
      expect(client.backupDirectoryUrl()).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/nota%20backup/');
      expect(client.remoteNotePath('note-1')).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/nota%20backup/note-1.note');
    });

    it('rejects generated object names that can change path hierarchy', 0, () => {
      const client: WebDAVClient = createClient();
      expect(throws(() => client.remoteNotePath('../note'))).assertTrue();
      expect(throws(() => client.remoteNotePath('folder/note'))).assertTrue();
      expect(throws(() => client.backupBatchObjectUrl('batch-0001', '../note.note'))).assertTrue();
    });

    it('does not send credentials to a cross-origin or root-escaping URL', 0, async () => {
      const client: WebDAVClient = createClient();
      expect((await client.download('https://attacker.example/steal.note')) === null).assertTrue();
      expect((await client.download('https://dav.example.com/outside/steal.note')) === null).assertTrue();
      expect((await client.download(
        'https://dav.example.com/remote.php/dav/files/user/%2e%2e/steal.note')) === null).assertTrue();
      expect((await client.download(
        'https://dav.example.com/remote.php/dav/files/user/steal.note?redirect=1')) === null).assertTrue();
      expect((await client.download(
        'https://dav.example.com/remote.php/dav/files/user/steal.note#fragment')) === null).assertTrue();
    });

    it('accepts arbitrary DAV prefixes and only successful propstats', 0, () => {
      const client: WebDAVClient = createClient();
      const directory: string = client.backupDirectoryUrl();
      const source: string = `<?xml version="1.0"?>
        <x:multistatus xmlns:x="DAV:">
          <x:response><x:href>/remote.php/dav/files/user/nota%20backup/</x:href>
            <x:propstat><x:prop><x:displayname>nota backup</x:displayname></x:prop>
              <x:status>HTTP/1.1 200 OK</x:status></x:propstat></x:response>
          <x:response><x:href>alpha.note</x:href>
            <x:propstat><x:prop><x:displayname>wrong.note</x:displayname>
              <x:getcontentlength>999</x:getcontentlength></x:prop>
              <x:status>HTTP/1.1 404 Not Found</x:status></x:propstat>
            <x:propstat><x:prop><x:displayname>Alpha &amp; Beta.note</x:displayname>
              <x:getcontentlength>42</x:getcontentlength>
              <x:getlastmodified>Sun, 09 Aug 2026 01:02:03 GMT</x:getlastmodified></x:prop>
              <x:status>HTTP/1.1 200 OK</x:status></x:propstat></x:response>
        </x:multistatus>`;
      const files: WebDAVFileInfo[] = client.parsePropfindResponse(source, directory);
      expect(files.length).assertEqual(1);
      expect(files[0].name).assertEqual('alpha.note');
      expect(files[0].displayName).assertEqual('Alpha & Beta.note');
      expect(files[0].size).assertEqual(42);
      expect(files[0].path).assertEqual(directory + 'alpha.note');
    });

    it('resolves absolute hrefs and rejects non-DAV response documents', 0, () => {
      const client: WebDAVClient = createClient();
      const directory: string = client.backupDirectoryUrl();
      const valid: string = `<multistatus xmlns="DAV:"><response>
        <href>https://dav.example.com/remote.php/dav/files/user/nota%20backup/beta.note</href>
        <propstat><prop><displayname>beta.note</displayname></prop>
        <status>HTTP/1.1 200 OK</status></propstat></response></multistatus>`;
      const files: WebDAVFileInfo[] = client.parsePropfindResponse(valid, directory);
      expect(files.length).assertEqual(1);
      expect(files[0].name).assertEqual('beta.note');
      expect(files[0].displayName).assertEqual('beta.note');
      expect(files[0].path).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/nota%20backup/beta.note');
      expect(throws(() => client.parsePropfindResponse(
        '<multistatus xmlns="urn:not-dav"><response/></multistatus>', directory))).assertTrue();
      const crossOrigin: string = `<multistatus xmlns="DAV:"><response>
        <href>https://attacker.example/steal.note</href><propstat><prop/>
        <status>HTTP/1.1 200 OK</status></propstat></response></multistatus>`;
      expect(throws(() => client.parsePropfindResponse(crossOrigin, directory))).assertTrue();
    });

    it('keeps an encoded slash inside one href path segment', 0, () => {
      const client: WebDAVClient = createClient();
      const directory: string = client.backupDirectoryUrl();
      const source: string = `<multistatus xmlns="DAV:"><response>
        <href>folder%2Fname.note</href><propstat><prop/>
        <status>HTTP/1.1 200 OK</status></propstat></response></multistatus>`;
      const files: WebDAVFileInfo[] = client.parsePropfindResponse(source, directory);
      expect(files.length).assertEqual(1);
      expect(files[0].path).assertEqual(directory + 'folder%2Fname.note');
      expect(files[0].name).assertEqual('folder/name.note');
    });

    it('rejects hrefs outside the requested Depth:1 collection', 0, () => {
      const client: WebDAVClient = createClient();
      const directory: string = client.backupDirectoryUrl();
      const outside: string = `<multistatus xmlns="DAV:"><response>
        <href>/remote.php/dav/files/user/other/batch-evil.manifest.json</href>
        <propstat><prop/><status>HTTP/1.1 200 OK</status></propstat>
        </response></multistatus>`;
      expect(throws(() => client.parsePropfindResponse(outside, directory))).assertTrue();
      const parent: string = `<multistatus xmlns="DAV:"><response>
        <href>../batch-evil.manifest.json</href>
        <propstat><prop/><status>HTTP/1.1 200 OK</status></propstat>
        </response></multistatus>`;
      expect(throws(() => client.parsePropfindResponse(parent, directory))).assertTrue();
      const nested: string = `<multistatus xmlns="DAV:"><response>
        <href>nested/batch-evil.manifest.json</href>
        <propstat><prop/><status>HTTP/1.1 200 OK</status></propstat>
        </response></multistatus>`;
      expect(throws(() => client.parsePropfindResponse(nested, directory))).assertTrue();
    });
  });
}
