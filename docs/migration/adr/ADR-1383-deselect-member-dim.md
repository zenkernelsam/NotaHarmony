# ADR-1383: deselectMode 点除成员 0.2 灰显（hak/oo7 paint-alpha 乘法）

## 状态

已接受（2026-08，Phase 1448）

## 背景

1.4.2 页面渲染协程 `kgi→hak` 在 `isf.h`（deselectMode）时将点除集
`isf.i` 注入元素渲染（`hak.o0`），经 `y2g.f0` 并集装配成 `linkedHashSetF0`
流入 `oo7.c`/`oo7.d` 笔画与形状渲染工。命中成员获得灰显标志：

- 笔画：`x1h.i`（`set.contains(id)`）→ `o() ? 0.2f : 1.0f` 透明度乘子；
  `u1h` 同构。
- 通用 paint：`oo7.x` 的 `z` 分支 → `paint.alpha *= 0.2`（乘法语义）。
- 形状 `f5g`：`jo7` 的 `zContains*` → `v1h`/`oo7.b` 灰显标志。
- 图片 `l97`：hak 分支同款 `contains(getId())` 过滤。

Harmony 侧 `SelectionTool.deselectedIds` 早已随 deselectMode 维护，但
**渲染路径零消费**——点除成员与保留成员视觉无差异，缺"淡出待删"反馈。

## 决策

1. **`AlphaScaledDrawingContext`**（Canvas2DStrokeRenderer.ets）：
   `Canvas2DDrawingContext` 委托实现——全部方法直通内层上下文，仅
   `setGlobalAlpha(a)` → `inner.setGlobalAlpha(a * factor)`。渲染器内部
   绝对覆写（笔画 `s.opacity`、音频 `playback.alpha`）同样被乘上，
   严格等效原版 `paint.alpha *= 0.2` 乘法语义。比外层
   save/setGlobalAlpha 包装更忠实——后者会被内部绝对覆写完全抵消。
2. **`renderOrderedElements`**：`deselectedIds` 非空时对
   `element.elementId ∈ deselected` 的元素换用缩放上下文（factor=0.2，
   `DESELECT_MEMBER_ALPHA` 常量），五类元素分支全经 `rc` 分发；缩放
   上下文每渲染趟惰性分配一次复用。
3. **覆盖面**：`renderOrderedContentLayer`（主层）、直接
   `renderCtx` 路径、zoom 面板 `renderZoomPanelContent` 均走
   `renderOrderedElements` → 全表面一致灰显（原版页渲染协程不分
   表面，同构）。

## 已知限制

- `n0`（f0 并集的另一集）语义未完全解码（kgi 协程体 jadx
  StackOverflow）——它并入灰显集但不改变"点除成员 → 0.2"的映射。
  若 n0 = 页内隐藏/位移预览集等其它灰显类别，Harmony 无对应需求，
  仅补点除集即可。
- 音频播放高亮（`playback.alpha`）与 deselectMode 并发时，灰显经
  乘法正确叠加（原版同理乘在 paint alpha 上）——语义一致。

## 验证

- fixture `d02-original-deselect-member-dim.mjs`：19/19（委托完整性、
  0.2 常量、elementId 命中、五类分发、生命周期清空、renderFrame 链）。
- 全量 Replay 基线、note@default / clean note@ohosTest 构建。
