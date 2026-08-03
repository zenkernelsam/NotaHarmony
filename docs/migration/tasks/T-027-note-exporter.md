# T-027 笔记导出器

## 目标

实现 NoteExporter：将内部笔记数据（NoteMeta + PageInfo + 笔画/元素）序列化为 .note ZIP 文件并通过系统文件选择器保存。

## 参考

- 契约：`docs/migration/phase-4-backup-sync.md` §2（ZIP 结构/manifest/pages 格式）
- 依赖：T-026（NotePackageSpec + ZipArchive）、Phase 3 数据层（Repository）
- 鸿蒙 API：@ohos.file.picker（文件保存对话框）、@ohos.file.fs（临时文件写入）

## 实现要求

### 创建文件

`note/src/main/ets/data/NoteExporter.ets`

### 类设计

```typescript
import { ZipWriter } from './ZipArchive';
import { NoteManifest, PageData, serializeManifest, serializePage } from './NotePackageSpec';
import { NoteMeta, PageInfo } from '../core/model/NoteTypes';
import { NoteElement } from '../core/model/ElementTypes';

export class NoteExporter {
  // 导出单个笔记为 .note Uint8Array
  async exportNote(noteId: string): Promise<Uint8Array | null> {
    // 1. 从 Repository 加载 NoteMeta
    // 2. 从 Repository 加载 PageInfo[]
    // 3. 从 StrokePersistence 加载每页元素
    // 4. 构造 manifest JSON
    // 5. 构造每页 PageData JSON
    // 6. ZipWriter: addEntry("manifest.json") + addEntry("pages/page_0.json") ...
    // 7. return zipWriter.build()
  }

  // 导出并保存到文件（通过系统 picker）
  async exportToFile(context: Context, noteId: string, title: string): Promise<boolean> {
    // 1. exportNote() → Uint8Array
    // 2. 写入应用沙箱临时文件
    // 3. 调用 picker.DocumentSaveOptions 让用户选保存位置
    // 4. 复制到用户选择的路径
    // 5. 清理临时文件
  }

  // 导出全部笔记（用于 WebDAV 备份）
  async exportAllNotes(): Promise<Map<string, Uint8Array>> {
    // 返回 noteId → .note 二进制 的映射
  }
}
```

### 鸿蒙特有约束

- 文件操作用 `import { fileIo } from '@kit.CoreFileKit'`
- picker 用 `import { picker } from '@kit.CoreFileKit'`
- 临时文件路径：`context.tempDir + '/export_xxx.note'`
- 导出完成后清理临时文件
- 大笔记（>100 页）考虑内存，逐页写入 ZipWriter

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] exportNote 返回有效 ZIP 二进制
- [ ] ZIP 内含 manifest.json + pages/page_N.json
- [ ] manifest.json 字段完整且值正确
- [ ] exportToFile 触发系统保存对话框
- [ ] 不修改契约文件

## 完成报告

`docs/migration/reports/T-027-完成.md`
