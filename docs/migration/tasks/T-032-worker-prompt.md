# T-032 工人启动 Prompt（强工人版）

> 用途：直接复制下方内容作为强工人 Agent 的首条消息。

---

## 你的角色

你是一个**逆向工程 + 实现**工人。这个任务不是"照卡施工"——你需要**自主探索未知格式结构**，多轮试探，逐步建立解析能力。允许试错和迭代。

## 工作区

`C:\HarmonyProject\NotaHarmony`

## 任务目标

解析 iPad Notability 导出的 .note 文件，提取笔记内容（元数据 + 笔画数据），转为内部模型并导入。

## 开工前必读

1. `docs/migration/tasks/T-032-notability-format-import.md` — 任务卡（格式结构 + 验收标准）
2. `test_notes/OP-AMP-extracted/OP-AMP/metadata.plist` — 已解压的元数据文件（binary plist）
3. `test_notes/OP-AMP-extracted/OP-AMP/Session.plist` — 已解压的笔画数据文件（binary plist，558KB）
4. `test_notes/OP-AMP-extracted/OP-AMP/Recordings/library.plist` — XML plist 示例（可参考结构）

## 已知信息（指挥官已确认）

测试文件：`test_notes/OP-AMP.note`（603KB，已解压到 `test_notes/OP-AMP-extracted/`）

**ZIP 内部结构：**
```
OP-AMP/
├── metadata.plist       (955B, binary plist bplist00, NSKeyedArchiver)
│   已知字段: uuidKey, noteName="OP-AMP", noteCreationDateKey, noteModifiedDateKey
├── Session.plist        (558KB, binary plist bplist00, NSKeyedArchiver)
│   → 核心目标：包含全部笔画/页面数据
├── thumb12x.png         (31KB, 缩略图)
├── HandwritingIndex/index.plist (10KB)
├── Recordings/library.plist (332B, XML plist)
└── Assets/ Images/ PDFs/ (空目录)
```

**metadata.plist 是 binary plist**：magic = `bplist00`，Apple NSKeyedArchiver 编码。
**Session.plist 也是 binary plist**：558KB，是笔画数据的载体。

## 你需要实现的

### 1. Binary Plist 解析器

创建 `note/src/main/ets/data/BinaryPlistParser.ets`

Apple CFBinaryPlist 格式规格：
- Header: `bplist00` (8 bytes)
- Objects: 序列化的对象（类型由首字节高4位决定）
- Offset table: 每个对象的文件偏移
- Trailer: 最后 32 字节（6 unused + offsetTableSize[1] + objectRefSize[1] + numObjects[8] + topObject[8] + offsetTableOffset[8]）

对象类型（首字节高4位）：
- 0x0: null/bool/fill (低4位: 0=null, 8=false, 9=true, F=fill)
- 0x1: int (低4位=字节数 2^n)
- 0x2: real (低4位=字节数 2^n)
- 0x3: date (8 bytes, Core Data epoch: seconds since 2001-01-01)
- 0x4: data (低4位=长度，0xF 表示长度跟在后面作为 int 对象)
- 0x5: ASCII string (低4位=长度，0xF 表示长度跟在后面)
- 0x6: UTF-16BE string (低4位=字符数，0xF 表示长度跟在后面)
- 0x8: UID (低4位+1 = 字节数)
- 0xA: array (低4位=元素数，0xF 表示数量跟在后面)
- 0xC: set
- 0xD: dict (低4位=键值对数，0xF 表示数量跟在后面)

**注意**：当低4位为 0xF 时，下一个字节是 int 类型标记（0x1N），后面跟着实际长度/数量。

### 2. NSKeyedArchiver 对象图解码

创建 `note/src/main/ets/data/NSKeyedArchiverDecoder.ets`

NSKeyedArchiver 编码在 plist 的根 dict 中：
```
{
  "$archiver": "NSKeyedArchiver",
  "$version": 100000,
  "$top": { "root": UID(1) },
  "$objects": [
    "$null",                              // index 0 永远是 "$null"
    { "$class": UID(N), "field1": ..., "field2": ... },  // index 1 = root object
    ...
    { "$classname": "SomeClass", ... }   // 类定义对象
  ]
}
```

解码规则：
- `$objects` 是扁平对象数组，通过 UID/索引互相引用
- UID 值 = $objects 数组的索引
- 自定义类的实例有 `$class` 字段指向类定义对象的索引
- 类定义对象有 `$classname` 字段表示类名
- 需要递归解引用：遇到 UID → 查 $objects[uid] → 如果是 dict 且有 $class → 按类名分发

### 3. Session.plist 结构探测（核心挑战）

创建 `note/src/main/ets/data/NotabilitySessionParser.ets`

Session.plist 的内部结构**未知**。你的策略：

**第一步：结构打印**
1. 用 BinaryPlistParser 解码 Session.plist → 得到原始对象数组
2. 用 NSKeyedArchiverDecoder 解码 → 得到对象图
3. 遍历顶层结构，打印所有 key、类型、子对象数量
4. 输出到日志/报告

**第二步：识别数据**
1. 在对象图中找到可能是页面/笔画的字段
2. 线索：大 array（包含多个相似对象）、float 数组（坐标）、dict with "points"/"strokes"/"pages" 等 key
3. 分析类名（$classname）：可能包含 Notability 自定义类名

**第三步：建立映射**
1. 确认笔画点数据格式（x/y 坐标、压感、时间戳）
2. 确认页面结构（多页如何组织）
3. 确认工具/颜色/宽度编码
4. 映射到我们的 StrokeElementData / NoteElement

**如果结构过于复杂无法一次搞定**：
- 先实现"结构打印器"（输出对象树到日志）
- 分析日志后再写精确解析
- 分步骤：先 metadata → 再页面结构 → 再笔画点数据

### 4. 集成到 NoteImporter

修改 `note/src/main/ets/data/NoteImporter.ets` 的 `importExternalFormat()` 方法：
- 检测 ZIP 内是否有 `*/metadata.plist` + `*/Session.plist` → Notability 格式
- 解析 metadata.plist → 提取标题/UUID/日期
- 解析 Session.plist → 提取笔画数据
- 转为内部模型 → 写入数据库

## 文件清单

创建：
- `note/src/main/ets/data/BinaryPlistParser.ets`
- `note/src/main/ets/data/NSKeyedArchiverDecoder.ets`
- `note/src/main/ets/data/NotabilitySessionParser.ets`

修改：
- `note/src/main/ets/data/NoteImporter.ets`

测试数据：
- `test_notes/OP-AMP.note`
- `test_notes/OP-AMP-extracted/OP-AMP/Session.plist`（可直接读取分析）
- `test_notes/OP-AMP-extracted/OP-AMP/metadata.plist`

## 工作方式

- **允许多轮迭代**：先写解析器 → 运行看输出 → 调整 → 再运行
- **允许在代码中加日志**：探测阶段可以 console.log/hilog 结构信息
- **允许分步交付**：先解析 metadata（简单），再攻克 Session（复杂）
- **遇到死胡同可以换方向**：如果某条路走不通，记录为什么，换另一条
- **不确定的标注假设**：不要猜，标注"此处推测，待验证"
- **可以先写一个临时测试页面**来验证解析结果（不需要集成到正式 UI）

## 验收标准（分层）

**必须达成（P0）：**
- [ ] BinaryPlistParser 能解析 metadata.plist → 提取 noteName="OP-AMP"
- [ ] 不崩溃，错误友好提示
- [ ] `check_ets_files` + `build_project` 通过

**尽力达成（P1）：**
- [ ] 解码 Session.plist 顶层结构（输出 key 列表和对象类型）
- [ ] 识别页面数量和页面尺寸
- [ ] 找到笔画点坐标数据的位置

**加分项（P2）：**
- [ ] 完整解析笔画 → 导入后画布可见
- [ ] 颜色/压感/工具类型映射
- [ ] 多页支持

## 完成报告

`docs/migration/reports/T-032-完成.md`：
- Session.plist 结构分析结果（key 列表、对象类型、数据分布）
- 已解析/未解析的部分
- 遗留问题和后续方向
- 如果发现了 Notability 的类名/字段名，列出完整映射表

## 提交

```
git add note/src/main/ets/data/ docs/migration/reports/
git commit -m "impl(T-032): Notability .note 格式解析"
```

## 禁止

- ❌ 不修改 Phase 1 契约文件（core/model/ 和 core/adaptation/ 下的接口）
- ❌ 不修改 docs/migration/ 架构文档
- ❌ 不引入第三方 plist 解析库（纯 ArkTS 实现）
- ❌ 不在未确认的情况下猜测数据结构——不确定就标注假设

## 鸿蒙特有约束

- 纯 ArkTS 实现，不 import @ohos.* 到解析器中（解析器是纯逻辑）
- NoteImporter 修改部分可以 import 平台 API（它已在平台层）
- Uint8Array 操作注意字节序（binary plist 是大端 big-endian）
- ArkTS 不支持 DataView，需手动读字节拼接多字节整数
