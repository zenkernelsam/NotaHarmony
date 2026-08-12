// T-029 WebDAV 客户端（@ohos.net.http 实现，无第三方库）
// 协议操作：PROPFIND/PUT/GET/DELETE/MKCOL + Basic Auth + XML pull parsing
import { http } from '@kit.NetworkKit';
import { buffer, url, xml } from '@kit.ArkTS';
import { backupManifestFileName, isValidBackupBatchId } from './BackupBatchSpec';
import { BackupBatchTransport } from './BackupBatchPublisher';

export const DEFAULT_WEBDAV_BACKUP_PATH: string = '/nota-backup/';

export interface WebDAVConfig {
  serverUrl: string;      // 如 "https://dav.example.com"
  username: string;
  password: string;
  backupPath: string;     // 默认 "/nota-backup/"
  allowInsecureHttp?: boolean;
}

const CONTROL_CHARACTER_PATTERN: RegExp = /[\u0000-\u001F\u007F]/;

// All persisted, UI-supplied and client-consumed WebDAV configurations pass through this boundary.
// The empty server is retained as the explicit "not configured" state; clients require a server.
export function normalizeWebDAVConfig(config: WebDAVConfig,
  requireServer: boolean = false): WebDAVConfig {
  if (typeof config.serverUrl !== 'string' || typeof config.username !== 'string' ||
    typeof config.password !== 'string' || typeof config.backupPath !== 'string' ||
    (config.allowInsecureHttp !== undefined && typeof config.allowInsecureHttp !== 'boolean')) {
    throw new Error('WebDAV configuration fields have invalid types');
  }
  if (config.username.indexOf(':') >= 0) {
    throw new Error('WebDAV Basic Auth username cannot contain a colon');
  }
  const serverUrl: string = normalizeWebDAVServerUrl(config.serverUrl);
  if (requireServer && serverUrl.length === 0) {
    throw new Error('WebDAV server URL is required');
  }
  if (serverUrl.length === 0 && (config.username.length > 0 || config.password.length > 0)) {
    throw new Error('WebDAV credentials require a server URL');
  }
  const allowInsecureHttp: boolean = serverUrl.startsWith('http://') &&
    config.allowInsecureHttp === true;
  if (serverUrl.startsWith('http://') && !allowInsecureHttp) {
    throw new Error('insecure HTTP WebDAV requires explicit confirmation');
  }
  return {
    serverUrl: serverUrl,
    username: config.username,
    password: config.password,
    backupPath: normalizeWebDAVBackupPath(config.backupPath),
    allowInsecureHttp: allowInsecureHttp,
  };
}

export function webDAVBackupPathForDisplay(path: string): string {
  const canonical: string = normalizeWebDAVBackupPath(path);
  const segments: string[] = canonical.slice(1, canonical.length - 1).split('/');
  const displaySegments: string[] = [];
  for (const segment of segments) {
    // Keep literal percent signs escaped so feeding an unchanged UI value back into the
    // normalizer cannot turn "%252F" into a hierarchy-changing "%2F" on the next save.
    displaySegments.push(decodeURIComponent(segment).replace(/%/g, '%25'));
  }
  return '/' + displaySegments.join('/') + '/';
}

function normalizeWebDAVServerUrl(raw: string): string {
  if (CONTROL_CHARACTER_PATTERN.test(raw)) {
    throw new Error('WebDAV server URL contains a control character');
  }
  const value: string = raw.trim();
  if (value.length === 0) {
    return '';
  }
  if (CONTROL_CHARACTER_PATTERN.test(value) || value.indexOf('\\') >= 0 ||
    value.indexOf('?') >= 0 || value.indexOf('#') >= 0) {
    throw new Error('WebDAV server URL contains a forbidden character or query component');
  }
  const schemeEnd: number = value.indexOf('://');
  if (schemeEnd <= 0) {
    throw new Error('WebDAV server URL must contain an authority');
  }
  const authorityStart: number = schemeEnd + 3;
  const pathStart: number = value.indexOf('/', authorityStart);
  const authority: string = pathStart < 0 ? value.slice(authorityStart) :
    value.slice(authorityStart, pathStart);
  if (authority.length === 0) {
    throw new Error('WebDAV server URL must contain an authority');
  }
  let rawPath: string = pathStart < 0 ? '' : value.slice(pathStart);
  while (rawPath.length > 1 && rawPath.endsWith('/')) {
    rawPath = rawPath.slice(0, rawPath.length - 1);
  }
  assertEncodedHierarchyPath(rawPath, 'WebDAV server URL path', true);

  let parsed: url.URL;
  try {
    parsed = url.URL.parseURL(value);
  } catch (_error) {
    throw new Error('WebDAV server URL is invalid');
  }
  if ((parsed.protocol !== 'https:' && parsed.protocol !== 'http:') || parsed.hostname.length === 0 ||
    parsed.origin === 'null' || parsed.username.length > 0 || parsed.password.length > 0 ||
    parsed.search.length > 0 || parsed.hash.length > 0) {
    throw new Error('WebDAV server URL must be an HTTP(S) origin without credentials, query or fragment');
  }
  let pathname: string = parsed.pathname;
  while (pathname.length > 1 && pathname.endsWith('/')) {
    pathname = pathname.slice(0, pathname.length - 1);
  }
  return parsed.origin + (pathname === '/' ? '' : pathname);
}

function normalizeWebDAVBackupPath(raw: string): string {
  if (CONTROL_CHARACTER_PATTERN.test(raw)) {
    throw new Error('WebDAV backup path contains a control character');
  }
  const value: string = raw.trim().length > 0 ? raw.trim() : DEFAULT_WEBDAV_BACKUP_PATH;
  if (CONTROL_CHARACTER_PATTERN.test(value) || value.indexOf('\\') >= 0) {
    throw new Error('WebDAV backup path contains a forbidden character');
  }
  let body: string = value;
  if (body.startsWith('/')) {
    body = body.slice(1);
  }
  if (body.endsWith('/')) {
    body = body.slice(0, body.length - 1);
  }
  if (body.length === 0) {
    throw new Error('WebDAV backup path must contain at least one segment');
  }
  const rawSegments: string[] = body.split('/');
  const canonicalSegments: string[] = [];
  for (const rawSegment of rawSegments) {
    if (rawSegment.length === 0) {
      throw new Error('WebDAV backup path contains an empty segment');
    }
    const decoded: string = decodeConfiguredPathSegment(rawSegment, 'WebDAV backup path');
    canonicalSegments.push(encodeURIComponent(decoded));
  }
  return '/' + canonicalSegments.join('/') + '/';
}

function assertEncodedHierarchyPath(path: string, label: string, allowEmpty: boolean): void {
  if (path.length === 0) {
    if (allowEmpty) {
      return;
    }
    throw new Error(`${label} is empty`);
  }
  if (!path.startsWith('/')) {
    throw new Error(`${label} must be absolute`);
  }
  if (path === '/') {
    return;
  }
  let body: string = path.slice(1);
  if (body.endsWith('/')) {
    body = body.slice(0, body.length - 1);
  }
  const segments: string[] = body.split('/');
  for (const segment of segments) {
    if (segment.length === 0) {
      throw new Error(`${label} contains an empty segment`);
    }
    decodeConfiguredPathSegment(segment, label);
  }
}

function decodeConfiguredPathSegment(raw: string, label: string): string {
  let decoded: string;
  try {
    decoded = decodeURIComponent(raw);
  } catch (_error) {
    throw new Error(`${label} contains invalid percent-encoding`);
  }
  if (decoded.length === 0 || decoded === '.' || decoded === '..' ||
    decoded.indexOf('/') >= 0 || decoded.indexOf('\\') >= 0 ||
    CONTROL_CHARACTER_PATTERN.test(decoded)) {
    throw new Error(`${label} contains a forbidden path segment`);
  }
  return decoded;
}

export interface WebDAVFileInfo {
  name: string;           // Decoded final DAV:href segment; safe for protocol identity.
  displayName: string;    // Optional server display property; never use as object identity.
  path: string;
  size: number;
  lastModified: number;   // 毫秒时间戳（无则 0）
}

export interface ConnectionResult {
  success: boolean;
  message: string;
}

// HTTP 头（显式 interface，ArkTS 不支持 Record 字面量/带连字符属性）
interface WebDAVHeaders {
  Authorization?: string;
  Depth?: string;
  'Content-Type'?: string;
  'Content-Length'?: string;
}

export interface WebDAVListResult {
  success: boolean;
  files: WebDAVFileInfo[];
  responseCode: number;
  message: string;
}

interface WebDAVResponse {
  responseCode: number;
  textBody: string;
  binaryBody: Uint8Array | null;
}

interface PropstatValues {
  success: boolean;
  displayName: string;
  sizeText: string;
  modifiedText: string;
}

interface DavResponseValues {
  href: string;
  displayName: string;
  sizeText: string;
  modifiedText: string;
  hasSuccessfulPropstat: boolean;
}

const REQUEST_TIMEOUT_MS: number = 30000;  // 30 秒
const MAX_PROPFIND_XML_BYTES: number = 8 * 1024 * 1024;
const DAV_NAMESPACE: string = 'DAV:';

export class WebDAVClient implements BackupBatchTransport {
  private config: WebDAVConfig;

  constructor(config: WebDAVConfig) {
    this.config = normalizeWebDAVConfig(config, true);
  }

  // 测试连接（PROPFIND 服务器根）；成功/失败均返回可读信息
  async testConnection(): Promise<ConnectionResult> {
    try {
      const resp = await this.request('PROPFIND', this.rootUrl(), undefined,
        { Depth: '0' });
      if (resp.responseCode >= 200 && resp.responseCode < 300) {
        return { success: true, message: `连接成功（HTTP ${resp.responseCode}）` };
      }
      return { success: false, message: this.describeError(resp.responseCode) };
    } catch (e) {
      return { success: false, message: this.describeError(-1) };
    }
  }

  // RFC 4918: MKCOL 不会递归创建父集合，因此必须逐级建立。
  async ensureBackupDir(): Promise<boolean> {
    try {
      return await this.ensureDirectorySegments(this.backupPathSegments());
    } catch (e) {
      return false;
    }
  }

  async ensureBackupBatchDir(batchId: string): Promise<boolean> {
    if (!isValidBackupBatchId(batchId)) {
      return false;
    }
    try {
      const segments: string[] = this.backupPathSegments();
      segments.push(`.pending-${batchId}`);
      return await this.ensureDirectorySegments(segments);
    } catch (_error) {
      return false;
    }
  }

  // 上传文件（PUT）；成功返回 true
  async upload(remotePath: string, data: Uint8Array): Promise<boolean> {
    try {
      const body: ArrayBuffer = data.buffer.slice(data.byteOffset,
        data.byteOffset + data.byteLength) as ArrayBuffer;
      const resp = await this.request('PUT', remotePath, body);
      return resp.responseCode >= 200 && resp.responseCode < 300;
    } catch (e) {
      return false;
    }
  }

  // 下载文件（GET）；失败返回 null
  async download(remotePath: string): Promise<Uint8Array | null> {
    try {
      const resp = await this.request('GET', remotePath, undefined);
      if (resp.responseCode !== 200 || resp.binaryBody === null) {
        return null;
      }
      return resp.binaryBody;
    } catch (e) {
      return null;
    }
  }

  // 列出目录内容（PROPFIND Depth:1）；传输/协议失败与合法空目录严格区分。
  async listDir(remotePath: string): Promise<WebDAVListResult> {
    try {
      const resp = await this.request('PROPFIND', remotePath, undefined,
        { 'Depth': '1' });
      if (resp.responseCode !== 207 && resp.responseCode !== 200) {
        return {
          success: false,
          files: [],
          responseCode: resp.responseCode,
          message: this.describeError(resp.responseCode),
        };
      }
      const files: WebDAVFileInfo[] = this.parsePropfindResponse(resp.textBody, remotePath);
      return { success: true, files: files, responseCode: resp.responseCode, message: '' };
    } catch (e) {
      return {
        success: false,
        files: [],
        responseCode: -1,
        message: e instanceof Error ? e.message : this.describeError(-1),
      };
    }
  }

  // 删除文件（DELETE）；204/200 成功
  async delete(remotePath: string): Promise<boolean> {
    try {
      const resp = await this.request('DELETE', remotePath, undefined);
      return resp.responseCode === 204 || resp.responseCode === 200;
    } catch (e) {
      return false;
    }
  }

  // 远端文件名：<backupPath><noteId>.note
  remoteNotePath(noteId: string): string {
    this.assertGeneratedPathSegment(noteId, 'note ID');
    return this.backupUrl(`${noteId}.note`);
  }

  backupDirectoryUrl(): string {
    return this.backupUrl('');
  }

  backupBatchObjectUrl(batchId: string, fileName: string): string {
    if (!isValidBackupBatchId(batchId)) {
      throw new Error('invalid backup batch object path');
    }
    this.assertGeneratedPathSegment(fileName, 'backup batch object name');
    return this.backupUrl(`.pending-${batchId}/${fileName}`);
  }

  backupBatchManifestUrl(batchId: string): string {
    return this.backupUrl(backupManifestFileName(batchId));
  }

  // === 内部 ===

  private rootUrl(): string {
    return this.config.serverUrl + '/';
  }

  private backupUrl(path: string): string {
    const segments: string[] = this.backupPathSegments();
    if (path.length > 0) {
      const suffix: string[] = path.split('/');
      for (const segment of suffix) {
        this.assertGeneratedPathSegment(segment, 'generated WebDAV path');
        segments.push(segment);
      }
    }
    return this.urlUnderRootSegments(segments, path.length === 0);
  }

  private backupPathSegments(): string[] {
    const encoded: string[] = this.config.backupPath.slice(1,
      this.config.backupPath.length - 1).split('/');
    const decoded: string[] = [];
    for (const segment of encoded) {
      decoded.push(decodeURIComponent(segment));
    }
    return decoded;
  }

  private async ensureDirectorySegments(segments: string[]): Promise<boolean> {
    const current: string[] = [];
    for (const segment of segments) {
      current.push(segment);
      const currentUrl: string = this.urlUnderRootSegments(current, false);
      const resp: WebDAVResponse = await this.request('MKCOL', currentUrl, undefined);
      if (resp.responseCode !== 201 && resp.responseCode !== 405) {
        console.error(`MKCOL failed at ${currentUrl}: HTTP ${resp.responseCode}`);
        return false;
      }
    }
    return true;
  }

  private encodePath(path: string): string {
    const parts: string[] = path.split('/');
    const encoded: string[] = [];
    for (const part of parts) {
      let decoded: string = part;
      try {
        decoded = decodeURIComponent(part);
      } catch (e) {
        decoded = part;
      }
      encoded.push(encodeURIComponent(decoded));
    }
    return encoded.join('/');
  }

  private urlForServerPath(path: string): string {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (this.urlOrigin(path) !== this.urlOrigin(this.rootUrl())) {
        throw new Error('WebDAV href points to a different server origin');
      }
      const schemeEnd: number = path.indexOf('://') + 3;
      const pathStart: number = path.indexOf('/', schemeEnd);
      if (pathStart < 0) {
        return path;
      }
      return path.slice(0, pathStart) + this.encodePath(path.slice(pathStart));
    }
    const root: string = this.rootUrl().replace(/\/+$/, '');
    if (path.startsWith('/')) {
      const schemeEnd: number = root.indexOf('://') + 3;
      const rootPath: number = root.indexOf('/', schemeEnd);
      const origin: string = rootPath < 0 ? root : root.slice(0, rootPath);
      return origin + this.encodePath(path);
    }
    return root + '/' + this.encodePath(path);
  }

  private urlOrigin(value: string): string {
    const schemeEnd: number = value.indexOf('://');
    if (schemeEnd <= 0) {
      throw new Error('WebDAV URL has no valid origin');
    }
    const authorityStart: number = schemeEnd + 3;
    const pathStart: number = value.indexOf('/', authorityStart);
    return (pathStart < 0 ? value : value.slice(0, pathStart)).toLowerCase();
  }

  private urlUnderRootSegments(segments: string[], trailingSlash: boolean): string {
    const root: string = this.rootUrl().replace(/\/+$/, '');
    const encoded: string[] = [];
    for (const segment of segments) {
      encoded.push(encodeURIComponent(segment));
    }
    let result: string = root + '/' + encoded.join('/');
    if (trailingSlash) {
      result += '/';
    }
    return result;
  }

  private assertGeneratedPathSegment(value: string, label: string): void {
    if (value.length === 0 || value === '.' || value === '..' ||
      value.indexOf('/') >= 0 || value.indexOf('\\') >= 0 ||
      CONTROL_CHARACTER_PATTERN.test(value)) {
      throw new Error(`${label} is not a safe WebDAV path segment`);
    }
  }

  // Basic Auth header
  private authHeader(): string {
    const cred: string = `${this.config.username}:${this.config.password}`;
    const encoded: string = buffer.from(cred, 'utf-8').toString('base64');
    return `Basic ${encoded}`;
  }

  // 发起 HTTP 请求
  // 注意：RequestMethod 枚举无 PROPFIND/MKCOL，此处强转字符串（底层网络栈接受任意方法字符串）
  private async request(method: string, url: string, body?: ArrayBuffer,
    extraHeaders?: WebDAVHeaders): Promise<WebDAVResponse> {
    this.assertRequestUrlUnderServerRoot(url);
    if (url.toLowerCase().startsWith('http://') && this.config.allowInsecureHttp !== true) {
      throw new Error('insecure HTTP WebDAV requires explicit confirmation');
    }
    const client: http.HttpRequest = http.createHttp();
    try {
      const depth: string | undefined = extraHeaders !== undefined ? extraHeaders.Depth : undefined;
      const contentType: string | undefined = body !== undefined ? 'application/octet-stream' : undefined;
      const contentLength: string | undefined = body !== undefined ? body.byteLength.toString() : undefined;
      const headers: WebDAVHeaders = {
        Authorization: this.authHeader(),
        Depth: depth,
        'Content-Type': contentType,
        'Content-Length': contentLength,
      };
      const options: http.HttpRequestOptions = {
        method: method as http.RequestMethod,
        header: headers,
        connectTimeout: REQUEST_TIMEOUT_MS,
        readTimeout: REQUEST_TIMEOUT_MS,
        // PROPFIND 响应为 XML 文本 → STRING；GET 下载二进制 → ARRAY_BUFFER
        expectDataType: method === 'GET' ? http.HttpDataType.ARRAY_BUFFER : http.HttpDataType.STRING,
      };
      if (body !== undefined) {
        options.extraData = body;
      }
      const resp: http.HttpResponse = await client.request(url, options);
      let textBody: string = '';
      let binaryBody: Uint8Array | null = null;
      if (method === 'GET' && resp.result !== null) {
        const source: Uint8Array = new Uint8Array(resp.result as ArrayBuffer);
        binaryBody = source.slice();
      } else if (resp.result !== null) {
        textBody = resp.result as string;
      }
      return { responseCode: resp.responseCode, textBody: textBody, binaryBody: binaryBody };
    } catch (e) {
      throw new Error('webdav request failed: ' + JSON.stringify(e));
    } finally {
      client.destroy();
    }
  }

  parsePropfindResponse(xmlText: string, requestUrl: string): WebDAVFileInfo[] {
    const source = buffer.from(xmlText, 'utf-8');
    if (source.length > MAX_PROPFIND_XML_BYTES) {
      throw new Error('WebDAV PROPFIND response exceeds the XML size budget');
    }
    const data: ArrayBuffer = source.buffer.slice(source.byteOffset,
      source.byteOffset + source.length) as ArrayBuffer;
    const parser = new xml.XmlPullParser(data, 'utf-8');
    const files: WebDAVFileInfo[] = [];
    let response: DavResponseValues | null = null;
    let responseDepth: number = -1;
    let propstat: PropstatValues | null = null;
    let propstatDepth: number = -1;
    let captureName: string = '';
    let captureDepth: number = -1;
    let captureText: string = '';
    let davResponseCount: number = 0;

    parser.parseXml({
      supportDoctype: false,
      ignoreNameSpace: false,
      tokenValueCallbackFunction: (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
        const namespace: string = info.getNamespace();
        const name: string = info.getName().toLowerCase();
        const depth: number = info.getDepth();
        if (eventType === xml.EventType.START_TAG && namespace === DAV_NAMESPACE) {
          if (name === 'response') {
            response = this.emptyDavResponse();
            responseDepth = depth;
            davResponseCount++;
          } else if (response !== null && name === 'propstat') {
            propstat = this.emptyPropstat();
            propstatDepth = depth;
          } else if (response !== null && (name === 'href' || name === 'displayname' ||
            name === 'getcontentlength' || name === 'getlastmodified' || name === 'status')) {
            captureName = name;
            captureDepth = depth;
            captureText = '';
          }
        } else if ((eventType === xml.EventType.TEXT || eventType === xml.EventType.CDSECT ||
          eventType === xml.EventType.ENTITY_REFERENCE) && captureDepth >= 0) {
          captureText += info.getText();
        } else if (eventType === xml.EventType.END_TAG && namespace === DAV_NAMESPACE) {
          if (captureDepth === depth && captureName === name) {
            this.applyDavText(response, propstat, captureName, captureText.trim());
            captureName = '';
            captureDepth = -1;
            captureText = '';
          }
          if (name === 'propstat' && propstat !== null && propstatDepth === depth) {
            this.mergeSuccessfulPropstat(response, propstat);
            propstat = null;
            propstatDepth = -1;
          } else if (name === 'response' && response !== null && responseDepth === depth) {
            const file: WebDAVFileInfo | null = this.toFileInfo(response, requestUrl);
            if (file !== null) {
              this.assertPropfindMemberUrl(file.path, requestUrl);
              if (!this.sameResourceUrl(file.path, requestUrl)) {
                files.push(file);
              }
            }
            response = null;
            responseDepth = -1;
          }
        }
        return true;
      },
    });
    if (xmlText.trim().length > 0 && davResponseCount === 0) {
      throw new Error('WebDAV PROPFIND response contains no DAV:response element');
    }
    return files;
  }

  private assertRequestUrlUnderServerRoot(value: string): void {
    if (CONTROL_CHARACTER_PATTERN.test(value) || value.indexOf('\\') >= 0 ||
      value.indexOf('?') >= 0 || value.indexOf('#') >= 0) {
      throw new Error('WebDAV request URL contains a forbidden component');
    }
    if (this.urlOrigin(value) !== this.urlOrigin(this.rootUrl())) {
      throw new Error('WebDAV request URL points to a different server origin');
    }
    const requestPath: string = this.urlPath(value);
    const rootPath: string = this.urlPath(this.rootUrl()).replace(/\/+$/, '');
    this.assertCanonicalUrlPath(requestPath);
    this.assertCanonicalUrlPath(rootPath);
    if (requestPath !== rootPath && !requestPath.startsWith(rootPath + '/')) {
      throw new Error('WebDAV request URL escapes the configured server root');
    }
  }

  private emptyDavResponse(): DavResponseValues {
    return { href: '', displayName: '', sizeText: '', modifiedText: '', hasSuccessfulPropstat: false };
  }

  private emptyPropstat(): PropstatValues {
    return { success: false, displayName: '', sizeText: '', modifiedText: '' };
  }

  private applyDavText(response: DavResponseValues | null, propstat: PropstatValues | null,
    name: string, value: string): void {
    if (response === null) {
      return;
    }
    if (name === 'href' && propstat === null) {
      response.href = value;
    } else if (propstat !== null && name === 'status') {
      propstat.success = /\s2\d\d(?:\s|$)/.test(value);
    } else if (propstat !== null && name === 'displayname') {
      propstat.displayName = value;
    } else if (propstat !== null && name === 'getcontentlength') {
      propstat.sizeText = value;
    } else if (propstat !== null && name === 'getlastmodified') {
      propstat.modifiedText = value;
    }
  }

  private mergeSuccessfulPropstat(response: DavResponseValues | null, propstat: PropstatValues): void {
    if (response === null || !propstat.success) {
      return;
    }
    response.hasSuccessfulPropstat = true;
    if (propstat.displayName.length > 0) {
      response.displayName = propstat.displayName;
    }
    if (propstat.sizeText.length > 0) {
      response.sizeText = propstat.sizeText;
    }
    if (propstat.modifiedText.length > 0) {
      response.modifiedText = propstat.modifiedText;
    }
  }

  private toFileInfo(response: DavResponseValues, requestUrl: string): WebDAVFileInfo | null {
    if (!response.hasSuccessfulPropstat || response.href.length === 0) {
      return null;
    }
    const path: string = this.urlForHref(response.href, requestUrl);
    const fallbackName: string = this.resourceNameFromUrl(path);
    const sizeValue: number = response.sizeText.length > 0 ? Number(response.sizeText) : 0;
    const size: number = Number.isFinite(sizeValue) && sizeValue >= 0 ? sizeValue : 0;
    const parsedTime: number = response.modifiedText.length > 0 ? Date.parse(response.modifiedText) : 0;
    return {
      name: fallbackName,
      displayName: response.displayName.length > 0 ? response.displayName : fallbackName,
      path: path,
      size: size,
      lastModified: Number.isNaN(parsedTime) ? 0 : parsedTime,
    };
  }

  private urlForHref(href: string, requestUrl: string): string {
    if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('/')) {
      return this.urlForServerPath(href);
    }
    const base: string = requestUrl.endsWith('/') ? requestUrl : requestUrl + '/';
    return base + this.encodePath(href.replace(/^\.\//, ''));
  }

  private sameResourceUrl(left: string, right: string): boolean {
    return this.urlOrigin(left) === this.urlOrigin(right) &&
      this.urlPath(left).replace(/\/+$/, '') === this.urlPath(right).replace(/\/+$/, '');
  }

  private assertPropfindMemberUrl(resourceUrl: string, requestUrl: string): void {
    if (this.urlOrigin(resourceUrl) !== this.urlOrigin(requestUrl)) {
      throw new Error('WebDAV href points to a different server origin');
    }
    const resourcePath: string = this.urlPath(resourceUrl);
    const requestPath: string = this.urlPath(requestUrl);
    this.assertCanonicalUrlPath(resourcePath);
    this.assertCanonicalUrlPath(requestPath);
    const requestIdentity: string = requestPath.replace(/\/+$/, '');
    const resourceIdentity: string = resourcePath.replace(/\/+$/, '');
    if (resourceIdentity === requestIdentity) {
      return;
    }
    const collectionPrefix: string = requestIdentity + '/';
    if (!resourceIdentity.startsWith(collectionPrefix)) {
      throw new Error('WebDAV href is outside the requested collection');
    }
    const child: string = resourceIdentity.slice(collectionPrefix.length);
    if (child.length === 0 || child.indexOf('/') >= 0) {
      throw new Error('WebDAV Depth:1 response contains a non-child resource');
    }
  }

  private urlPath(value: string): string {
    const authorityStart: number = value.indexOf('://') + 3;
    if (authorityStart < 3) {
      throw new Error('WebDAV URL has no valid origin');
    }
    const pathStart: number = value.indexOf('/', authorityStart);
    if (pathStart < 0) {
      return '/';
    }
    let end: number = value.length;
    const query: number = value.indexOf('?', pathStart);
    const fragment: number = value.indexOf('#', pathStart);
    if (query >= 0 && query < end) {
      end = query;
    }
    if (fragment >= 0 && fragment < end) {
      end = fragment;
    }
    return value.slice(pathStart, end);
  }

  private assertCanonicalUrlPath(path: string): void {
    const segments: string[] = path.split('/');
    for (const segment of segments) {
      let decoded: string;
      try {
        decoded = decodeURIComponent(segment);
      } catch (_error) {
        throw new Error('WebDAV URL path contains invalid percent-encoding');
      }
      if (decoded === '.' || decoded === '..') {
        throw new Error('WebDAV href contains a dot path segment');
      }
    }
  }

  private resourceNameFromUrl(value: string): string {
    let end: number = value.length;
    const query: number = value.indexOf('?');
    const fragment: number = value.indexOf('#');
    if (query >= 0 && query < end) {
      end = query;
    }
    if (fragment >= 0 && fragment < end) {
      end = fragment;
    }
    const path: string = value.slice(0, end).replace(/\/+$/, '');
    const slash: number = path.lastIndexOf('/');
    return this.decodePathSegment(slash >= 0 ? path.slice(slash + 1) : path);
  }

  private decodePathSegment(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch (e) {
      console.warn(`WebDAV path segment is not valid percent-encoding: ${value}`);
      return value;
    }
  }

  // 错误码 → 可读信息
  private describeError(code: number): string {
    if (code === 401) {
      return '认证失败（401）：用户名或密码错误';
    }
    if (code === 403) {
      return '拒绝访问（403）：服务器不允许该操作';
    }
    if (code === 404) {
      return '服务器路径不存在（404）：请检查服务器 URL';
    }
    if (code === 405) {
      return '操作不被允许（405）';
    }
    if (code >= 500) {
      return `服务器错误（HTTP ${code}）`;
    }
    if (code === -1) {
      return '网络请求失败：无法连接服务器或超时（30s）';
    }
    return `请求失败（HTTP ${code}）`;
  }
}
