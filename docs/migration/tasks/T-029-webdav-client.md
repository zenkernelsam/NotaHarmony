# T-029 WebDAV 客户端

## 目标

实现 WebDAVClient：封装 WebDAV 协议操作（PROPFIND/PUT/GET/DELETE/MKCOL），支持连接测试、文件上传/下载/列表。

## 参考

- 契约：`docs/migration/phase-4-backup-sync.md` §3（WebDAV 协议操作/同步策略）
- 依赖：T-027（NoteExporter 产出 .note 二进制）
- 鸿蒙 API：@ohos.net.http

## 实现要求

### 创建文件

`note/src/main/ets/data/WebDAVClient.ets`

### 类设计

```typescript
import { http } from '@kit.NetworkKit';

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
  lastModified: number;
}

export class WebDAVClient {
  private config: WebDAVConfig;

  constructor(config: WebDAVConfig)

  // 测试连接（PROPFIND 根目录）
  async testConnection(): Promise<{ success: boolean; message: string }>

  // 确保备份目录存在（MKCOL）
  async ensureBackupDir(): Promise<boolean>

  // 上传文件（PUT）
  async upload(remotePath: string, data: Uint8Array): Promise<boolean>

  // 下载文件（GET）
  async download(remotePath: string): Promise<Uint8Array | null>

  // 列出目录内容（PROPFIND）
  async listDir(remotePath: string): Promise<WebDAVFileInfo[]>

  // 删除文件（DELETE）
  async delete(remotePath: string): Promise<boolean>

  // 内部：构造 Basic Auth header
  private authHeader(): string {
    // "Basic " + base64(username:password)
  }

  // 内部：发起 HTTP 请求
  private async request(method: string, path: string, body?: Uint8Array, headers?: Record<string, string>): Promise<http.HttpResponse>
}
```

### WebDAV 协议要点

- **PROPFIND**：Header `Depth: 1`，响应为 XML（解析 `<d:displayname>` 和 `<d:getcontentlength>`）
- **PUT**：body = 文件二进制，Content-Type: application/octet-stream
- **GET**：响应 body = 文件内容
- **MKCOL**：创建目录，201 = 成功，405 = 已存在
- **DELETE**：204 = 成功
- **认证**：HTTP Basic Auth（`Authorization: Basic base64(user:pass)`）
- **HTTPS**：必须支持（不限制 HTTP 但推荐 HTTPS）

### 鸿蒙特有约束

- `import { http } from '@kit.NetworkKit'`（API 7+）
- 请求超时：30 秒
- 错误处理：网络错误/401/403/404/5xx 分别给出有意义的错误信息
- PROPFIND 响应是 XML，用字符串解析（不引入 XML 库，正则提取关键字段）
- base64 编码用 ArkTS 内置（`buffer.from(...).toString('base64')` 或手动实现）
- 需要在 module.json5 中声明 `ohos.permission.INTERNET` 权限

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] testConnection 对有效 WebDAV 返回 success=true
- [ ] testConnection 对无效 URL/凭证返回 success=false + 错误信息
- [ ] upload + download 往返数据一致
- [ ] listDir 返回文件列表
- [ ] 网络不可达时不崩溃，返回错误信息
- [ ] module.json5 已添加 INTERNET 权限
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-029-完成.md`
