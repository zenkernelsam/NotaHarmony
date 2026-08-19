# ADR-0254：原版手写 Convert-to-Text 的纯逻辑计划边界

## 状态

Accepted - Phase 276（2026-08-19）

> 后续更正：Phase 277 已通过 ADR-0255 增加专用原子 persistence/HWC1 history path。本文以下关于
> “当前持久层尚不能承载混合 mutation”的描述保留为 Phase 276 当时的决策现场；真实 OCR、Locale adapter、
> SelectionOverlay 入口和生产 page/frame/fingerprint 采集仍未接入。

## 背景

Phase 274 固定了原版识别语言/provider contract，Phase 275 固定了选区 Ink 到 pointer stroke 的
适配，但仍缺少“识别结果如何回到原选区”的安全边界。原版 1.0.3 的 `xsc`/`bt1` 显示这不是
简单地把一段字符串塞进新 Text：选区必须属于同一 page，bounds 要按每轴至少 8 扩展，Text origin
要减去 page frame origin，并且删除 Ink、创建 Block、插入字符串必须在同一个 `xq9` transaction
内按固定顺序执行。

当前 Harmony persistence 能分别应用 type-25 visibility、type-22 CREATE_BLOCK 与 INSERT_TEXT，
但 `writePreparedLocked()` 还不能可靠地把“多删除 + 单新增”映射成同一原版 operation/history
单元。若现在加 UI 入口，迟到 OCR 或中途失败会留下删除已落盘、Text 未创建，或者 UI 快照与 original
register 分叉的状态。

## 决策

### 1. 先落纯逻辑 planner，不接入口

新增 `OriginalHandwritingConversionPlanner.ets`。它只接收已解析的可见页面 stroke candidates、
page frame、generation 与 source fingerprint，输出不可变语义上的 conversion plan；不修改
SelectionTool、UI、RDB 或 provider。

### 2. 严格复现原版几何和门禁

- selected ID 必须非空、唯一、无歧义、可见，并且全部属于 page frame 的同一 page；
- bounds 必须有限且方向有效；union 的 width/height 小于 8 时居中补到 8；
- `textOrigin = selectionTopLeft - pageOrigin`；`textTransform` 为 identity，因为原版 `bt1`
  通过 bitmask 省略了 `u5j.f` 的 optional transform；
- plan 固定记录 source IDs、page generation 和 source fingerprint。

### 3. OCR 迟到结果 fail closed

只有 page ID、generation、source fingerprint 与 plan 完全相等，且结果非空、未超过上限时才可
materialize mutation。任何页面切换、重新加载、选区变化、保存后 revision 变化都必须让调用方
生成新的 fingerprint；旧 Promise 不能覆写当前文档。

### 4. 显式描述原版三步顺序

`materializeOriginalHandwritingTextMutation()` 只生成：

```text
DELETE_ENTITIES(selected Ink IDs)
CREATE_BLOCK(Text, relative origin, 8+ bounds, identity transform)
INSERT_STRING(recognized text)
```

它要求 caller 已取得不与 source Ink 冲突的新 Text ID；不声称这些步骤已经持久化或可 Undo。

## 后果

正面：

- 原版单页、8×8、page-origin 与 transaction order 不会被未来 UI 接线遗忘；
- 页面切换/选区变化后的 OCR 结果不会删除新页面上的 Ink；
- 在持久层尚未支持混合 mutation 前，不会引入半原子或假 history。

代价与开放项：

- 当前没有“转文字”菜单、真实 OCR、结果写回、Undo/Redo 或搜索索引；
- source fingerprint 的生成仍由页面/persistence caller 负责；
- 设备正确率、延迟、内存和多语言体验仍需运行态验收。

## 验证

- 原版 `xsc/bt1/jc5/u5j/bmb/fqa/qed` hash 与行号见对应 evidence；
- ArkTS fixture 覆盖 8-unit bounds、page-relative origin、跨页/隐藏/坏输入、迟到结果和三步顺序；
- 专项 Replay、相关 Replay、全量 Replay、clean 后双 HAP 与 `git diff --check` 必须通过；
- 不启动模拟器、虚拟机、真机或 Hypium。
