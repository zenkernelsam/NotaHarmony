# 原版手写选区到 OCR pointer 序列适配证据（2026-08-18）

## 1. 范围与只读基准

本阶段只把已经解析到 Harmony `StrokeElementData` 的当前页面选区，转换为
Phase 274 定义的 `OriginalHandwritingRecognitionStroke[]`。Desktop 目录仍然只作为
原版 APK/JADX 只读证据源；本阶段所有实现、fixture、Replay、ADR 和报告均写入
`C:\HarmonyProject\NotaHarmony`。

原版源码根目录：
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage`

| 文件 | SHA-256 | 关键位置 | 证明 |
|---|---|---:|---|
| `jc5.java` | `A015153C5590755E79C2436BA9210430222187DDCBF226FC284FD1BD2233B405` | 25-39 | 由选中实体 ID 解析 `s06`，排除缺失/隐藏/无 page frame/高亮笔，再排序 |
| `rn2.java` | `C788B6C5BBED0ACEC45D6217A151701E859EBB5157DF69AE46F4A9047BF1E414` | 73-75 | case 15 委托 `so5.a` |
| `so5.java` | `BA88BD05E24494B42D1DF413DB22BBEAE9B96C609AD8518717666BA5C9737E96` | 9-13 | unsigned timestamp，随后 unsigned 16-bit site ID |
| `wqh.java` | `E5D214E59B17ACECC265DF543C544ED3F88ED918EC2E654347DAD0685D8623EB` | 144-147 | text recognition 只排除 `HIGHLIGHTER` |
| `pm8.java` | `96DCE90733FCD3137EC49B31552AC7D85153425D735EDCD308B9536E58778064` | 89-199 | page origin、逐笔 pointer 生命周期、force、单笔 cancel |
| `bmb.java` | `A21F305746F2D7BC968D70B5DCC99AB479D880A85D83C66F437A8BB650B9B695` | 14-20, 47-49 | page frame 的 origin 位于前两个 float |
| `fqa.java` | `E6C6AB86AB4CD8F7047F41AC9DB57800A0EDC5AB293E9CFAFAF94C64D1B98F04` | 10-16 | origin 的 x/y 读取方式 |
| `s06.java` | `A6E7B7F3D0EEAE1B898CEE66E5AD56C55DEC50681CC3D3DB6E059CF5E7CADC19` | 467-470, 518-524 | highlighter 判定与 page identity 访问 |

## 2. 原版行为重放

### 2.1 选区解析、过滤和顺序

`jc5.a()` 对传入的实体 ID 逐个从 `a79.F` 取 `s06`。以下任一条件会丢弃该实体：

1. ID 不存在；
2. `aa6.V()` 判定为隐藏/不可见；
3. 当前页面没有对应 `tz9(s06.i())` page frame；
4. text recognition 分支传入 `z=true` 时，`wqh.e(s06)` 为 false。

然后调用 `au1.K1(..., new rn2(15))`。`rn2` 的 case 15 调用 `so5.a`，而 `so5.a` 先以
`Integer.compareUnsigned(timestamp)` 比较，再以 `site & 0xFFFF` 比较。因此 OCR 输入的
Ink 顺序不是 UI 选择数组的偶然顺序，而是原版 operation identity 顺序。

### 2.2 page frame、局部坐标和 pointer 生命周期

`pm8.a()` 对每个 `s06`：

1. 从 page-frame buffer 读取 origin（`bmb`/`fqa` 的 x、y）；
2. 读取 center path 的每个终点/采样，并把 origin 加到局部坐标；
3. 第一采样发送 `pointerDown`，后续发送 `pointerMove`，最后一采样发送 `pointerUp`；
4. 每次事件都保留 `po4.f` force；
5. 当前 center path 可恢复解码失败时，若已经 down，则发送 `pointerCancel`，然后继续下一条 Ink。

`pm8.c()` 是 suspend/coroutine 调用，Phase 274 已把 Harmony provider 改为 Promise，
本阶段只负责在调用前生成等价的有序 stroke 数组。

## 3. Harmony 现场与适配决定

### 3.1 坐标

Harmony `StrokeElementData.pathPoints` 是已经解码的 page-local center samples；
`NotabilitySessionParser.pushCurve()` 对导入笔画使用 `transform = identity`，并生成
`nb-<uuid>` 或 `nb-<page>-<index>` ID。原版 page-frame origin 在导入/当前页面模型中已经
折叠到 page-local 坐标，不能再次添加一个凭空的 frame offset。

当前编辑器的 SelectionTool 只把选区变换累计到 `stroke.transform`，不改写
`pathPoints`。因此 adapter 对每个 sample 应用完整行主序 3×3 affine：

```text
x' = m0*x + m1*y + m2
y' = m3*x + m4*y + m5
```

不是只使用平移、AABB 或单一 scale。输出 sample 深拷贝 position，`force = pressure`，
包括原版无压感约定的 `-1`，不 clamp、不把 widthFactor 冒充 force。

### 3.2 选择和排序

新增 `adaptOriginalHandwritingSelection(selectedStrokeIds, pageStrokes)`：

- `isFinished=false`、partial-eraser preview、highlighter、空 path 不进入 provider；
- 非有限 transform、奇异 affine、非有限 position/pressure 只跳过当前 stroke；
- 缺失 ID、重复/歧义 page ID、重复 selection 都返回结构化 skipped reason；
- canonical `op:<timestamp>:<site>` ID 的槽位按原版 `so5` 排序；
- `nb-*` 等无法解码的导入 ID 不猜造 timestamp/site，而保留其输入槽位；
- 一个坏 stroke 不会丢弃其他合法 stroke，适配结果为空时由 Phase 274 provider boundary 继续
  fail closed。

“canonical 槽位排序”保证混合页面仍确定：先收集 canonical 候选并排序，再把排序结果放回
它们原来的槽位，非 canonical 槽位原样保留。全 canonical 页面与原版完全一致，全 imported
页面则稳定保持输入顺序。

## 4. 明确边界

- 当前页面数组的可见性和 page-frame 归属由调用者负责；adapter 不重新猜隐藏实体或跨页 frame。
- 本阶段没有创建 MyScript/Harmony OCR provider，没有增加 SelectionOverlay 菜单，没有结果写回、
  Undo/Redo、搜索索引或设备入口。
- provider 尚不存在时仍由 `OriginalHandwritingRecognition` 返回 null；本阶段不把纯逻辑转换
  冒充“手写转文字已上线”。
