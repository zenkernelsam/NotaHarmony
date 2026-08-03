# T-032 真实 Notability .note 格式解析（iPad 导出）

## 目标

解析原版 iPad Notability 导出的 .note 文件（Apple binary plist + NSKeyedArchiver），提取笔记元数据和笔画数据，转为内部模型并渲染。

## 已确认的原版格式结构

测试文件：`test_notes/OP-AMP.note`（603KB）

```
ZIP 容器
└── OP-AMP/                      （顶层文件夹 = 笔记标题）
    ├── metadata.plist           （binary plist，NSKeyedArchiver，955B）
    │   字段: uuidKey, noteName, noteCreationDateKey, noteModifiedDateKey,
    │         noteHasRecordingKey, noteTags, notePackagePath, associatedProductsKey
    ├── Session.plist            （binary plist，NSKeyedArchiver，558KB）
    │   → 包含全部笔画/页面数据（核心解析目标）
    ├── thumb12x.png             （缩略图 31KB）
    ├── HandwritingIndex/
    │   └── index.plist          （手写搜索索引）
    ├── Assets/                  （空）
    ├── Images/                  （空）
    ├── PDFs/                    （空）
    └── Recordings/
        └── library.plist        （XML plist，录音元数据）
```

## 实现要求

### 第一步：Binary Plist 解析器

创建 `note/src/main/ets/data/BinaryPlistParser.ets`

Binary plist 格式（Apple CFBinaryPlist）：
- Magic: `bplist00`（8 字节）
- 对象表：序列化对象（dict/array/string/data/int/real/date/uid/bool/null）
- 偏移表：每个对象的文件偏移
- Trailer：最后 32 字节（偏移表位置、对象数、根对象索引）

需要实现的类型解码：
- `0x0` null/bool/fill
- `0x1` int
- `0x2` real
- `0x3` date
- `0x4` data (byte array)
- `0x5` ASCII string
- `0x6` UTF-16 string
- `0x8` UID
- `0xA` array
- `0xD` dict

### 第二步：NSKeyedArchiver 解码器

创建 `note/src/main/ets/data/NSKeyedArchiverDecoder.ets`

NSKeyedArchiver 在 plist 中编码对象图：
- 根对象是 `$archiver` = "NSKeyedArchiver" + `$top` + `$objects` 数组
- `$objects[0]` = "$null"
- 其余对象通过索引引用
- 自定义类有 `$class` 指向类名
- 需要按类名分发解码

### 第三步：Session.plist 结构探测

创建 `note/src/main/ets/data/NotabilitySessionParser.ets`

Session.plist 内部结构需要通过探测确认：
1. 先解码顶层 dict，打印所有 key
2. 找到包含页面/笔画数据的字段
3. 逐步深入分析笔画编码方式（点坐标、压感、工具、颜色）
4. 建立 Notability 数据模型 → 内部 NoteElement 的映射

**探测策略**：由于 Session.plist 结构未知，先实现一个"结构打印器"，输出对象图的层级和类名，再根据输出设计解析逻辑。

### 第四步：集成到 NoteImporter

修改 `note/src/main/ets/data/NoteImporter.ets` 的 `importExternalFormat()` 方法：
1. 检测 ZIP 内是否有 `metadata.plist` + `Session.plist` → Notability 格式
2. 解析 metadata.plist → 提取标题/UUID/日期
3. 解析 Session.plist → 提取笔画数据
4. 转为内部模型 → 写入数据库

### 文件清单

1. `note/src/main/ets/data/BinaryPlistParser.ets` — bplist00 格式解析
2. `note/src/main/ets/data/NSKeyedArchiverDecoder.ets` — 对象图解码
3. `note/src/main/ets/data/NotabilitySessionParser.ets` — Session.plist 结构解析
4. 修改 `note/src/main/ets/data/NoteImporter.ets` — 集成 Notability 格式检测

## 验收标准

- [ ] `check_ets_files` + `build_project` 通过
- [ ] BinaryPlistParser 能正确解析 metadata.plist（提取 noteName="OP-AMP"）
- [ ] NSKeyedArchiverDecoder 能解码 Session.plist 顶层结构
- [ ] 从 OP-AMP.note 中提取出至少笔记标题和页面数
- [ ] 如果能解析笔画数据 → 导入后画布可见
- [ ] 如果笔画数据结构无法完全确认 → 输出结构日志，标注已解析/未解析部分
- [ ] 导入过程不崩溃
- [ ] 不修改 Phase 1 契约文件

## 测试文件

`test_notes/OP-AMP.note` — iPad Notability 导出的真实文件

## 风险与降级

- Session.plist 的笔画编码可能是 Notability 私有格式，无公开文档
- 如果无法完全解析笔画数据，至少做到：提取标题 + 缩略图 + 页面数，标注"内容解析待完善"
- 如果二进制解析过于复杂，可先用结构打印器输出对象图，人工分析后再写解析逻辑

## 完成报告

`docs/migration/reports/T-032-完成.md`（包含 Session.plist 结构分析结果）
