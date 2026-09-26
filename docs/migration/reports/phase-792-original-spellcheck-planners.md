# Phase 792 — 原版 1.4.2 内置拼写检查 + planner 资产

日期：2026-09-29
状态：完成（证据 + ADR + Replay；无 Harmony 源码变更）
证据：`docs/migration/evidence/phase-792-original-spellcheck-planners.md`
ADR：`ADR-0736-original-spellcheck-planners.md`
Replay：`d02-original-spellcheck-planners.mjs`（7/7）

## 本阶段做了什么

assets/ 目录收尾登记：拼写检查词库 + planner PDF +
conf-lite 移除。

## 发现

- **内置拼写检查**（1.4.2 全新，纯本地）：
  `spellcheck/en_words.dat` gzip 词表（解压 1.2MB，
  126,036 词条）→ `bc1` 加载器（BreakIterator 分词 +
  HashSet 判定 + fail-soft 回退）→ `fal` 批量 API →
  `cji` Flow 文本装饰管线。配套新设置开关
  `feature_settings__check_spelling`（1.0.3 无）。
- **planners/**：monday/sunday 双起始日学术计划本 PDF，
  与 782 的 ui_planners__ 周起始切换构成闭环。
- conf-lite/ 移除佐证 MyScript lite 远端化（760/768）。

## 验收

- Replay 7/7 绿；assets/ 面全量归属完毕；
  全量套件与双 HAP 随本阶段执行。
