# ADR-0597: 荧光笔 underlay z 带探针（u5j.g 对齐）

- 状态：accepted（2026-09-28，Phase 628）
- 证据：`docs/migration/evidence/original-highlighter-underlay-z-2026-09-28.md`

## 背景

原版 CreateInk 统一生产者 `u5j.g` 在调用方未指定 zIndex 且
InkTool 为 HIGHLIGHTER（u16=2）时探测笔迹起点：起点落在所有存活
内容边界之外 → zIndex 钉为 999999（远低于 clientTime 默认值的
衬底带）；起点落在既有内容之内 → 保持 null → 解码端回退
clientTime（顶层）。`u5j.j`（CreateShape）携带同一探针；`g1f`
生成式高亮矩形无条件钉 999999。

Harmony 侧 `writeOriginalCreateInk` 调
`encodeOriginalLocalCreateInk(page, stroke)` 不传 zIndex ——
荧光笔笔迹一律取 clientTime 顶层序，空白处起笔的荧光笔不会被
压到衬底带，与原版分叉。

## 决定

1. `StrokePersistence.ets` 新增 `originalHighlighterUnderlayZIndex`：
   `isHighlighter` 门 + `transform * pathPoints[0]` 起点对
   `current`（提交前存活元素快照）逐项闭区间边界测试；未命中 →
   `'999999'`，命中/非荧光笔/空路径 → `undefined`；
2. `writeOriginalCreateInk` 把探针结果传给
   `encodeOriginalLocalCreateInk` 的既有 `zIndex` 形参 —— 编码器
   与解码器（`clientTime` 兜底）零改动；
3. 形状侧（`u5j.j`）不引入探针：原版探针求值时源 Ink 仍在文档，
   形状原点必被源 Ink 边界覆盖 → 恒 clientTime，与 Harmony 现状
   同结果；
4. `g1f` 生成式高亮矩形无 Harmony 入端，仅登记差异。

## 后果

- 荧光笔在空白处起笔的笔迹落在 z=999999，之后所有常规内容
  （clientTime ~1.7e12）与既有内容都压在其上 —— 与原版一致；
- 显式 zIndex 路径（局部擦除残余段 '1'/sourceZIndex、剪贴板
  Paste op）不经过探针，不受影响；
- 探针只读 `current` 快照，不解锁额外的 RDB 查询；
- 约束：探针只看起点（原版同样只看起点——起笔在空白、笔迹扫过
  内容的荧光笔仍钉 999999，这是原版语义而非缺陷）。
