# T-028 笔记导入器

## 目标

实现 NoteImporter：从 .note ZIP 文件解析笔记数据并写入本地数据库。支持我方格式（完整恢复）和外部格式（尽力解析+友好提示）。

## 参考

- 契约：`docs/migration/phase-4-backup-sync.md` §2.4（兼容导入策略）
- 依赖：T-026（ZipArchive + NotePackageSpec）、Phase 3 数据层
- 鸿蒙 API：@ohos.file.picker（文件选择）

## 实现要求

### 创建文件

`note/src/main/ets/data/NoteImporter.ets`

### 类设计

```typescript
import { ZipReader, ZipEntry } from './ZipArchive';
import { NoteManifest, PageData, parseManifest, parsePage } from './NotePackageSpec';

export enum ImportResult {
  SUCCESS = 0,
  UNSUPPORTED_FORMAT = 1,
  CORRUPTED = 2,
  PARTIAL = 3,       // 部分恢复
}

export interface ImportReport {
  result: ImportResult;
  noteId: string | null;    // 成功时返回新 noteId
  title: string | null;
  pageCount: number;
  message: string;          // 用户可读的结果描述
}

export class NoteImporter {
  // 从 Uint8Array 导入（WebDAV 下载后调用）
  async importFromData(data: Uint8Array): Promise<ImportReport> {
    // 1. ZipReader.parse(data) → entries
    //    失败 → CORRUPTED
    // 2. 查找 manifest.json
    //    有 → parseManifest → 我方格式 → importOurFormat()
    //    无 → 尝试外部格式 → importExternalFormat()
  }

  // 从文件导入（用户选择文件）
  async importFromFile(context: Context): Promise<ImportReport> {
    // 1. picker 选择 .note 文件
    // 2. 读取文件内容 → Uint8Array
    // 3. importFromData()
  }

  // 我方格式导入
  private async importOurFormat(entries: ZipEntry[], manifest: NoteManifest): Promise<ImportReport> {
    // 1. 创建新 NoteMeta（用 manifest 中的 title/时间）
    // 2. 逐页读取 pages/page_N.json → parsePage
    // 3. 写入 page_info 表
    // 4. 写入笔画/元素到 client_op（StrokePersistence）
    // 5. 返回 SUCCESS
  }

  // 外部格式（尽力解析）
  private async importExternalFormat(entries: ZipEntry[]): Promise<ImportReport> {
    // 1. 扫描文件列表，查找可能的数据文件
    // 2. 尝试 JSON 解析 / FlatBuffers 检测
    // 3. 能解析多少恢复多少
    // 4. 完全无法识别 → UNSUPPORTED_FORMAT + 文件列表日志
  }
}
```

### 鸿蒙特有约束

- 导入时生成新 noteId（不覆盖已有笔记）
- 文件选择用 `picker.DocumentSelectOptions` + filter `.note` 后缀
- 大文件（>10MB）在 taskpool 中解析，不阻塞主线程
- 损坏的 ZIP / 非 ZIP 文件 → 返回 CORRUPTED，不抛异常
- 导入失败不写入数据库（事务性：全部成功才 commit）

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] 导入我方导出的 .note → 笔记完整恢复（笔画/页面/标题）
- [ ] 导入损坏文件 → 返回 CORRUPTED，不崩溃
- [ ] 导入非 .note 文件 → 返回 UNSUPPORTED_FORMAT
- [ ] 导入后资料库显示新笔记
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-028-完成.md`
