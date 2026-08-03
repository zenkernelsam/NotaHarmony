# T-026 .note 格式规格 + ZIP 读写器

## 目标

定义 .note 包格式的类型（manifest/pages JSON 结构）+ 实现最小 ZIP 读写器（支持 STORE 和 DEFLATE 两种模式）。

## 参考

- 契约：`docs/migration/phase-4-backup-sync.md` §2（.note 包格式设计）
- 依赖：Phase 1 模型类型（NoteMeta/PageInfo/StrokeElementData 等）
- 鸿蒙 API：@ohos.zlib（deflate/inflate）

## 实现要求

### 创建文件

1. `note/src/main/ets/data/NotePackageSpec.ets`
2. `note/src/main/ets/data/ZipArchive.ets`

### NotePackageSpec.ets

```typescript
// .note 包的 JSON 结构定义
export interface NoteManifest {
  format: string;        // "nota.note"
  version: number;       // 1
  title: string;
  noteId: string;
  createdAt: number;
  updatedAt: number;
  pageCount: number;
  appVersion: string;
  source: string;        // "NotaHarmony"
}

export interface PageData {
  pageId: string;
  pageIndex: number;
  paperSize: number;
  paperTemplate: number;
  orientation: number;
  elements: object[];    // NoteElement JSON 数组
}

// 序列化/反序列化工具
export function serializeManifest(manifest: NoteManifest): string
export function parseManifest(json: string): NoteManifest | null
export function serializePage(page: PageData): string
export function parsePage(json: string): PageData | null
```

### ZipArchive.ets

实现最小 ZIP 格式读写（纯 ArkTS，不引第三方库）：

```typescript
import { zlib } from '@kit.BasicServicesKit';

export interface ZipEntry {
  name: string;           // 文件路径（如 "manifest.json"）
  data: Uint8Array;       // 文件内容
  compressed: boolean;    // 是否 DEFLATE 压缩
}

export class ZipWriter {
  private entries: ZipEntry[] = [];

  addEntry(name: string, data: Uint8Array, compress?: boolean): void
  // 生成 ZIP 二进制（Local File Header + Central Directory + End Record）
  build(): Uint8Array
}

export class ZipReader {
  // 从 ZIP 二进制解析所有条目
  static parse(data: Uint8Array): ZipEntry[] | null
  // 查找指定名称的条目
  static findEntry(entries: ZipEntry[], name: string): ZipEntry | null
}
```

ZIP 格式要点（工人必须正确实现）：
- Local File Header: signature `0x04034b50` + 版本 + 标志 + 压缩方法 + CRC32 + 大小 + 文件名
- Central Directory: signature `0x02014b50` + 每个条目的元数据
- End of Central Directory: signature `0x06054b50` + 条目数 + CD 偏移
- STORE: compressionMethod = 0（直接存储）
- DEFLATE: compressionMethod = 8（用 zlib.deflateSync/inflateSync）
- CRC32: 手动实现或用 zlib 辅助

### 鸿蒙特有约束

- `import { zlib } from '@kit.BasicServicesKit'`（API 9+）
- CRC32 手动实现（查表法，256 项表）
- Uint8Array 操作注意字节序（ZIP 是 little-endian）
- 文件名用 UTF-8 编码
- MVP 不需要支持 ZIP64 / 加密 / 分卷

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] ZipWriter.build() 产出的二进制可被标准 ZIP 工具解压（结构正确）
- [ ] ZipReader.parse() 能解析 ZipWriter.build() 的输出（往返一致）
- [ ] STORE 和 DEFLATE 两种模式都工作
- [ ] CRC32 校验正确
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-026-完成.md`
