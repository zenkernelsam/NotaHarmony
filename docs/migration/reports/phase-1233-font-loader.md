# Phase 1233 报告 — 字体加载 + span

## 完成内容

- `lyb`=ResourcesCompat.Font 异步加载（ThreadLocal+
  WeakHashMap+`ifj` FontCallback）；`nlf`=
  ReplacementSpan 读 CharacterStyle Typeface→独立
  Paint 内嵌图像/数学（baseline 对齐）；`mac`=双
  Paint holder —— 字体管线。

## 产出

- evidence `phase-1233-font-loader.md`
- fixture `d02-font-loader.mjs`（10/10）
- ADR-1177
