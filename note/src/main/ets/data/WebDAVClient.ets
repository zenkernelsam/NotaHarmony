// T-029 WebDAV 客户端（@ohos.net.http 实现，无第三方库）
// 协议操作：PROPFIND/PUT/GET/DELETE/MKCOL + Basic Auth + XML 正则解析
import { http } from '@kit.NetworkKit';
import { buffer } from '@kit.ArkTS';

export interface WebDAVConfig {
  serverUrl: string;      // 如 "https://dav.example.com"
  username: string;
  password: string;
  backupPath: string;     // 默认 "/nota-backup/"
}

export interface WebDAVFileInfo {
  name: string;
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
}

const REQUEST_TIMEOUT_MS: number = 30000;  // 30 秒

export class WebDAVClient {
  private config: WebDAVConfig;

  constructor(config: WebDAVConfig) {
    this.config = config;
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

  // 确保备份目录存在（MKCOL；405=已存在视为成功）
  async ensureBackupDir(): Promise<boolean> {
    try {
      const resp = await this.request('MKCOL', this.backupUrl(''), undefined);
      return resp.responseCode === 201 || resp.responseCode === 405;
    } catch (e) {
      return false;
    }
  }

  // 上传文件（PUT）；成功返回 true
  // 注：ArkTS 头字段无法携带连字符（Content-Type），WebDAV 服务器按内容/扩展名处理，MVP 不传
  async upload(remotePath: string, data: Uint8Array): Promise<boolean> {
    try {
      const resp = await this.request('PUT', remotePath, data.buffer as ArrayBuffer);
      return resp.responseCode >= 200 && resp.responseCode < 300;
    } catch (e) {
      return false;
    }
  }

  // 下载文件（GET）；失败返回 null
  async download(remotePath: string): Promise<Uint8Array | null> {
    try {
      const resp = await this.request('GET', remotePath, undefined);
      if (resp.responseCode !== 200 || resp.result === null) {
        return null;
      }
      const arr = resp.result as ArrayBuffer;
      return new Uint8Array(arr);
    } catch (e) {
      return null;
    }
  }

  // 列出目录内容（PROPFIND Depth:1）；失败返回空数组
  async listDir(remotePath: string): Promise<WebDAVFileInfo[]> {
    try {
      const resp = await this.request('PROPFIND', remotePath, undefined,
        { 'Depth': '1' });
      if (resp.responseCode !== 207 && resp.responseCode !== 200) {
        return [];
      }
      const xml: string = resp.result as string;
      return this.parsePropfind(xml);
    } catch (e) {
      return [];
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
    return this.backupUrl(`${noteId}.note`);
  }

  // === 内部 ===

  private rootUrl(): string {
    let url: string = this.config.serverUrl.trim();
    while (url.endsWith('/')) {
      url = url.slice(0, url.length - 1);
    }
    return url + '/';
  }

  private backupUrl(path: string): string {
    let base: string = this.rootUrl();
    let bp: string = this.config.backupPath.trim();
    if (!bp.startsWith('/')) {
      bp = '/' + bp;
    }
    if (!bp.endsWith('/')) {
      bp = bp + '/';
    }
    return base.replace(/\/+$/, '') + bp + path;
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
    extraHeaders?: WebDAVHeaders): Promise<http.HttpResponse> {
    const client: http.HttpRequest = http.createHttp();
    try {
      const headers: WebDAVHeaders = { Authorization: this.authHeader() };
      if (extraHeaders !== undefined && extraHeaders.Depth !== undefined) {
        headers.Depth = extraHeaders.Depth;
      }
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
      return resp;
    } catch (e) {
      throw new Error('webdav request failed: ' + JSON.stringify(e));
    } finally {
      client.destroy();
    }
  }

  // PROPFIND XML 解析（正则提取，不引入 XML 库）
  private parsePropfind(xml: string): WebDAVFileInfo[] {
    const files: WebDAVFileInfo[] = [];
    const responseRe = /<d:response[\s>][\s\S]*?<\/d:response>/gi;
    const hrefRe = /<d:href>([\s\S]*?)<\/d:href>/i;
    const nameRe = /<d:displayname>([\s\S]*?)<\/d:displayname>/i;
    const sizeRe = /<d:getcontentlength>([\s\S]*?)<\/d:getcontentlength>/i;
    const timeRe = /<d:getlastmodified>([\s\S]*?)<\/d:getlastmodified>/i;
    let match = responseRe.exec(xml);
    while (match !== null) {
      const block: string = match[0];
      const hrefMatch = hrefRe.exec(block);
      const nameMatch = nameRe.exec(block);
      const sizeMatch = sizeRe.exec(block);
      const timeMatch = timeRe.exec(block);
      if (hrefMatch !== null) {
        const path: string = hrefMatch[1].trim();
        const name: string = nameMatch !== null ? nameMatch[1].trim() : path.split('/').pop() ?? path;
        const size: number = sizeMatch !== null ? Number(sizeMatch[1].trim()) : 0;
        let lastModified: number = 0;
        if (timeMatch !== null) {
          const t: number = Date.parse(timeMatch[1].trim());
          lastModified = Number.isNaN(t) ? 0 : t;
        }
        files.push({ name: name, path: path, size: size, lastModified: lastModified });
      }
      match = responseRe.exec(xml);
    }
    return files;
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
