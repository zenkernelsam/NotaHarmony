import { describe, it, expect } from '@ohos/hypium';
import { WebDAVClient, WebDAVConfig, WebDAVFileInfo } from '../main/ets/data/WebDAVClient';

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
    it('uses a collection URL instead of manufacturing an empty note name', 0, () => {
      const client: WebDAVClient = createClient();
      expect(client.backupDirectoryUrl()).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/nota%20backup/');
      expect(client.remoteNotePath('note-1')).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/nota%20backup/note-1.note');
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
      expect(files[0].name).assertEqual('Alpha & Beta.note');
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
      expect(files[0].path).assertEqual(
        'https://dav.example.com/remote.php/dav/files/user/nota%20backup/beta.note');
      expect(throws(() => client.parsePropfindResponse(
        '<multistatus xmlns="urn:not-dav"><response/></multistatus>', directory))).assertTrue();
      const crossOrigin: string = `<multistatus xmlns="DAV:"><response>
        <href>https://attacker.example/steal.note</href><propstat><prop/>
        <status>HTTP/1.1 200 OK</status></propstat></response></multistatus>`;
      expect(throws(() => client.parsePropfindResponse(crossOrigin, directory))).assertTrue();
    });
  });
}
