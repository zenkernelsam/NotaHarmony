# Phase 632 报告：Canvas2DStrokeRenderer c5g 面审计收口

- 日期：2026-09-28
- 证据：`docs/migration/evidence/original-stroke-renderer-c5g-audit-2026-09-28.md`
- 性质：审计收口（验证既有 parity + 修正错误基准引用），无行为变更

## 背景

`审计缺口清单.md` 一.1 将 `Canvas2DStrokeRenderer.ets` 列为
完全未审的最大缺口，附两条待对照线索：dash 参数基准与
highlighter 混合模式。

## 复核结论

两条线索经 1.0.3 decompiled 复核均为**已实现 parity**：

- dash/DOTS 参数真源为 `c5g.g`（原线索引的 `pzf` 是
  AutoCloseable 资源池，与渲染无关）：DASH `{2f,1f}`+BUTT、
  DOTS `{0.001f,2f}`+ROUND/MITER、相位 0——Harmony 逐条一致，
  Phase 574 fixture 持续回归。
- highlighter 原版即 alpha 覆盖 `zx1.e(color,107)`（=0.42），
  全部画笔 SRC_OVER——Harmony `isHighlighter ? 107` 一致，
  并非"近似替代混合模式"。
- `l96.l0` clipOut+fill 与 Harmony evenodd clip+fill 同构。

## 变更

- `Canvas2DStrokeRenderer.ets`：两处注释 `pzf.g` → `c5g.g`
  （错误基准引用修正，无行为变化）。
- `审计缺口清单.md`：一.1 改写为"核心面已对齐"，完全未审
  文件数 12→11，主干覆盖 6→7；残余 splat/tape/边界分支降级
  为间接覆盖档。

## 验证

- `d02-original-dash-phase-zero` 等相关 fixture 回归绿。
- 全量回放套件与双 HAP 构建见本节验收记录。
