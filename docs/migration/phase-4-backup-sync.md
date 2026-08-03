# Phase 4 — 备份、导入导出与 WebDAV 同步

> 版本: v1.0 | 日期: 2026-08-02 | 状态: 待工人执行
> 前置: Phase 3 通过 + T-AUDIT 通过

---

## 1. 阶段目标

实现三大差异化能力：
- **4A** 兼容导入原版 Notability 导出的 .note 文件
- **4B** 将内部笔记导出为 .note ZIP 包
- **4C~4E** WebDAV 云备份/恢复/增量同步

**完成标准**：
- 我们导出的 .note 文件可在另一台设备导入还原
- 导入外部 .note 文件时能解析元数据+尽力恢复内容
- WebDAV 配置→备份→恢复流程可演示

---

## 2. .note 包格式设计（自定义，结构兼容原版概念）

### 2.1 ZIP 内部结构

```
note_export_<title>_<timestamp>.note  （ZIP 容器）
├── manifest.json           元数据（必须）
├── pages.json              页面列表（必须）
├── strokes/                笔画数据
│   ├── page_0.json         第 0 页的笔画/元素 JSON
│   ├── page_1.json         第 1 页
│   └── ...
└── assets/                 资源文件（图片等）
    ├── <sha256_hash_1>
    ├── <sha256_hash_2>
    └── ...
```

### 2.2 manifest.json 格式

```json
{
  "format": "nota.note",
  "version": 1,
  "title": "笔记标题",
  "noteId": "uuid",
  "createdAt": 1722614400000,
  "updatedAt": 1722614400000,
  "pageCount": 3,
  "appVersion": "1.0.0",
  "source": "NotaHarmony"
}
```

### 2.3 pages/<pageId>.json 格式

```json
{
  "pageId": "uuid",
  "pageIndex": 0,
  "paperSize": 1,
  "paperTemplate": 0,
  "orientation": 0,
  "elements": [
    // StrokeElementData / TextBlockElement / EllipseElement / PolygonElement
  ]
}
```

### 2.4 兼容导入策略

对于非我方格式的 .note 文件（原版 Notability 导出）：
1. 读取 ZIP → 扫描内部文件列表
2. 查找 `manifest.json` → 有则按我方格式解析
3. 无 manifest → 尝试查找 FlatBuffers BLOB（`*.fbs` / `*.bin`）→ 尽力解析
4. 完全无法识别 → 提示"不支持的格式"，记录 ZIP 内部文件列表供调试

---

## 3. WebDAV 同步设计

### 3.1 协议操作

| 操作 | HTTP 方法 | 用途 |
|------|-----------|------|
| 测试连接 | PROPFIND / | 验证 URL + 凭证 |
| 上传备份 | PUT /backup/<noteId>.note | 上传 .note 文件 |
| 列出备份 | PROPFIND /backup/ | 获取远端文件列表 |
| 下载恢复 | GET /backup/<noteId>.note | 下载 .note 文件 |
| 删除远端 | DELETE /backup/<noteId>.note | 删除远端备份 |
| 创建目录 | MKCOL /backup/ | 首次初始化 |

### 3.2 同步策略

- **手动备份**：用户点击"备份"→ 导出全部笔记 → 逐个 PUT
- **手动恢复**：用户点击"恢复"→ PROPFIND 列表 → 选择 → GET → 导入
- **增量标记**：manifest.json 中 `updatedAt` 与本地对比，只上传有变化的

### 3.3 设置存储

WebDAV 配置存 Preferences（@ohos.data.preferences）：
- serverUrl: string
- username: string
- password: string（加密存储或明文 MVP）
- lastBackupTime: number
- autoBackup: boolean

---

## 4. 涉及鸿蒙 API

| API | 起始版本 | 用途 |
|-----|----------|------|
| @ohos.net.http | 7 | WebDAV 请求 |
| @ohos.file.fs | 9 | 文件读写（临时导出文件） |
| @ohos.file.picker | 9 | 文件选择/保存对话框 |
| @ohos.zlib | 9 | deflate/inflate（ZIP 内压缩） |
| @ohos.data.preferences | 9 | WebDAV 配置存储 |
| @ohos.backgroundTaskManager | 9 | 后台备份任务（可选） |

**权限需求**：
- `ohos.permission.INTERNET`（网络请求）
- `ohos.permission.READ_MEDIA`/`ohos.permission.WRITE_MEDIA`（文件操作，如需）

---

## 5. 模块边界与文件规划

```
note/src/main/ets/data/
├── NotePackageSpec.ets        // .note 格式定义（manifest/pages 结构）
├── NoteExporter.ets           // 导出：内部模型 → .note ZIP
├── NoteImporter.ets           // 导入：.note ZIP → 内部模型
├── ZipArchive.ets             // 最小 ZIP 读写器（STORE + DEFLATE）
└── WebDAVClient.ets           // WebDAV 协议封装

note/src/main/ets/ui/settings/
├── BackupPage.ets             // 备份/恢复/导入导出 UI
└── WebDAVSettingsPage.ets     // WebDAV 配置页面
```

---

## 6. 任务卡拆分

| 卡号 | 名称 | 依赖 | 产出 |
|------|------|------|------|
| T-026 | .note 格式规格 + ZIP 读写器 | Phase 3 | NotePackageSpec.ets + ZipArchive.ets |
| T-027 | 笔记导出器 | T-026 | NoteExporter.ets（内部→ZIP→文件） |
| T-028 | 笔记导入器 | T-026 | NoteImporter.ets（ZIP→内部模型） |
| T-029 | WebDAV 客户端 | T-027 | WebDAVClient.ets（PUT/GET/PROPFIND/MKCOL） |
| T-030 | 备份 UI 与设置 | T-027~T-029 | BackupPage + WebDAVSettings + 配置存储 |
| T-031 | 集成联调 | T-026~T-030 | 全流程验证 |

### 依赖图

```
T-026 (格式+ZIP) ─┬→ T-027 (导出) ─┬→ T-029 (WebDAV) ─→ T-030 (UI) ─→ T-031 (集成)
                  └→ T-028 (导入) ─┘
```

**建议执行顺序**：T-026 → T-027 + T-028（可并行）→ T-029 → T-030 → T-031

---

## 7. 验收基准

| 项 | 标准 | 验证方式 |
|----|------|----------|
| 导出 | 笔记→.note 文件生成，ZIP 可解压，manifest.json 内容正确 | 模拟器 + 文件检查 |
| 导入 | .note→笔记恢复，笔画/页面/元数据完整 | 模拟器操作 |
| 往返 | 导出→删除笔记→导入→内容一致 | 手动测试 |
| WebDAV | 配置→测试连接→备份→清除本地→恢复 | 需 WebDAV 服务器 |
| 格式兼容 | 非我方 ZIP → 不崩溃，给出友好提示 | 手动测试 |
| 无崩溃 | 全流程操作无异常 | hilog |

---

## 8. 约束提醒

- ZIP 实现用纯 ArkTS（不引入第三方库），STORE 模式为主，DEFLATE 可选。
- WebDAV 密码 MVP 明文存 Preferences（后续可加密）。
- 文件选择用 `@ohos.file.picker`（系统对话框），不自绘文件浏览器。
- 网络请求用 `@ohos.net.http`，不用 fetch（ArkTS 无原生 fetch）。
- 导入时做格式校验，损坏/不支持的文件给友好错误提示，不崩溃。
- 大文件（>10MB）导入/导出在后台线程（taskpool）执行，不阻塞 UI。
