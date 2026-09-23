# Phase 628 — 荧光笔 underlay z 带探针（u5j.g 对齐）

## 原版证据

- `u5j.java:557-663`：CreateInk（`dm2`）统一生产者在
  `xgbVar == null`（zIndex 缺省）且 `u16Var2 == HIGHLIGHTER`
  （u16.java:20，序 2）时探针笔迹起点——换算文档坐标后顺序遍历
  存活 Ink（`qjaVar.I` 中 `xy0`）与元素表（`uiaVar`，跳过
  `ba6.K` 标记项），对每个 `ba6.k` 边界做闭区间包含测试；
  **未命中（起点在所有内容之外）→ `xgb(999999L)`**（:651-653），
  命中则保留 null → 解码端回退 `clientTime`；
- `u5j.java:720-824`：CreateShape（`ao2`）生产者携带同一探针
  （`!z4 → 999999`，:820-822）；
- `g1f.java:132`：`khd` 高亮事件生成的荧光笔矩形显式传
  `xgb(999999L)` —— 999999 为规范衬底带值；
- `cfc.java` case8/9：TO_BACK 自 min、TO_FRONT 自 max+1 递增 ——
  z 越大越靠前，999999 恒低于 clientTime（~1.7e12）。

## Harmony 缺口

`writeOriginalCreateInk` 编码 CreateInk 时不携带 zIndex ——
荧光笔笔迹一律按 `clientTime` 落顶层；原版中空白处起笔的
荧光笔应钉 999999 衬底带（低于所有常规内容）。

## 决策与实现

- `StrokePersistence.ets` 新增 `originalHighlighterUnderlayZIndex`
  （:6697）：`isHighlighter` 门 + `transform * pathPoints[0]`
  起点对 `current`（提交前存活快照）逐项闭区间边界测试；
  未命中 → `'999999'`，否则 `undefined`（编码端不写字段）；
- `writeOriginalCreateInk`（:3510）把探针结果传入
  `encodeOriginalLocalCreateInk` 既有 `zIndex` 形参；
- 形状侧不引入探针：原版探针求值时源 Ink 仍在文档，形状原点
  必被覆盖 → 恒 clientTime，Harmony 现状同结果；
- `g1f` 生成式高亮矩形无 Harmony 入端，登记差异。

## 验证

- `d04-original-highlighter-underlay-z.mjs`：29/29
  （原版结构断言 + Harmony 挂接断言 + 探针语义仿真：
  空白→'999999'、界内/边界→undefined、非荧光笔→undefined、
  非单位变换起点投影、显式 zIndex 路径不受探针影响）；
- 全量 Desktop Replay：516/516；
- `note@ohosTest`、`note@default` 双 HAP clean 构建成功。

## 关联文档

- evidence：`original-highlighter-underlay-z-2026-09-28.md`
- ADR-0597
