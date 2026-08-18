# 原版 Convert-to-Text 计划器证据（2026-08-19）

## 1. 范围与只读基准

本阶段只补齐原版手写选区“转文字”动作的纯逻辑计划边界：单页门禁、选区包围盒、最小尺寸、
page-origin 相对坐标、异步 OCR 迟到结果门禁，以及三步原子 mutation 的顺序描述。没有接入真实
OCR provider、SelectionOverlay 菜单或 RDB 写回。Desktop 目录仍只作为原版 APK/JADX 只读证据源；
实现、fixture、Replay、ADR 与本证据均写入 `C:\HarmonyProject\NotaHarmony`。

原版源码根目录：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

| 文件 | SHA-256 | 关键位置 | 证明 |
|---|---|---:|---|
| `xsc.java` | `41C4BD1D24F50E04C095B319BA4B1F37CD04ACD9B43B744DF67D78F89FFF5BB8` | 122-167, 192-210 | `j()` 合并世界 bounds、每轴最小 8、读取 page frame origin；`v()` 拒绝跨页选区 |
| `bt1.java` | `A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA` | 51-64 | 共享 `xq9` transaction 中依次 DELETE_ENTITIES、CREATE TEXT、INSERT_STRING |
| `jc5.java` | `A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405` | 25-39 | 选区实体解析、隐藏/缺失/page-frame 过滤与排序入口 |
| `u5j.java` | `F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC` | 538-551 | `f()` 接收 page、相对 origin、可选 transform 与 size；未知 page 直接失败 |
| `bmb.java` | `A21F305746F2D7BC968D70B5DCC99AB479D880A85D83C66F437A8BB650B9B695` | 14-20, 47-49 | page frame 的 origin 与 size 是独立寄存器 |
| `fqa.java` | `E6C6AB86AB4CD8F7047F41AC9DB57800A0EDC5AB293E9CFAFAF94C64D1B98F04` | 10-16 | origin x/y 读取 |
| `qed.java` | `466944792556C7E9A2661993A72B3B93B27698ACECE3C99D64CA52A4CBEB3FBF` | 10-20, 39-41 | width/height size 读取 |

## 2. 原版行为

### 2.1 单页与 bounds

`xsc.v()` 先取第一条选区实体的 page identity，再逐项比较；任何实体属于不同 page 都调用失败回调
并返回 `null`。`xsc.j()` 对可解析实体的 world bounds 求 union：

```text
left   = min(entity.left)
top    = min(entity.top)
right  = max(entity.right)
bottom = max(entity.bottom)
```

宽或高小于 `8.0f` 时，沿对应轴两侧均匀扩展到 8；没有有效 bounds 或没有当前 page frame 时拒绝。
page frame origin 作为返回 pair 的第二项，后续由 `bt1` 减去它得到 Text Block 的相对 origin。

### 2.2 原子顺序

`bt1` case 2 在同一个 `xq9` transaction 内按以下顺序发出：

1. `u5j.l(...)`：删除选中的 Ink；
2. `u5j.f(..., cz0.TEXT, ..., relativeOrigin, ..., size, ...)`：创建 Text Block；
3. `s5j.i(...)`：向新 Block 插入识别字符串。

调用的 optional transform 位被 bitmask 省略，故本计划器为新 Text 保留 identity transform；page、
relative origin 与 size 仍作为显式字段保存。

## 3. Harmony 当前安全边界

已有 `OriginalHandwritingSelectionAdapter` 只负责把已解析当前页面的 Ink 转成 provider pointer
stroke 序列；已有 `OriginalDeleteEntitiesOperationApplier`、`OriginalCreateBlockOperationApplier`
与 `OriginalInsertTextOperationApplier` 各自可以在 RDB transaction 中应用对应 original operation。
但 `StrokePersistence.writePreparedLocked()` 的特殊路径目前只可靠处理：

- 单独 visibility mutation；或
- 当前快照新增一个 reserved Text Block（CREATE_BLOCK + INSERT_STRING）。

它不能安全表达“删除多笔 Ink，同时新增 Text，并把 DELETE_ENTITIES、CREATE_BLOCK、INSERT_STRING
三个原版 operation identity 作为一个可恢复 history 单元”。因此本阶段不把计划器接到 UI 或
`queueSaveElements()`，不伪造半原子实现。

## 4. 本阶段实现

新增 `OriginalHandwritingConversionPlanner.ets`：

- 要求 selected IDs 非空、唯一、可解析、可见且属于同一 page；重复/歧义/缺失/隐藏/坏 bounds
  返回结构化 reject reason；
- 复现 union bounds 与每轴 8-unit 最小扩展；输出 page-relative `textOrigin`、width、height；
- 记录 page generation 与 source fingerprint；OCR 结果回到不同 page、generation 或 source 时
  fail closed；空结果和超大结果也拒绝；
- 只有 caller 已取得新 Text identity 且结果仍新鲜时，才生成纯逻辑
  `DELETE_ENTITIES → CREATE_BLOCK → INSERT_STRING` mutation plan；文本内容（包括前后空白）原样保留。

该模块不触碰数据库、UI、SelectionTool 或 provider；真实 provider、入口和 persistence 写回均**尚未接入**，
没有“功能已上线”的含义。

## 5. 待后续闭环

- 真实 OCR provider、Locale/global preference adapter 与错误提示；
- SelectionOverlay 的“转文字”入口与页面 generation/source fingerprint 采集；
- 能在一个 transaction/history 单元中表达三类 original operation 的持久层 mutation；
- Text Block 的 original identity、Undo/Redo、搜索索引和重启恢复；
- 真机正确率、延迟、内存与多语言体验。
