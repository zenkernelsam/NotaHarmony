# ADR-0730 — 原版 1.4.2 Finish Notes 管线与配套键面登记

日期：2026-09-29
状态：已登记（fail-closed 主体 + 版本差零散；无源码变更）
证据：`docs/migration/evidence/phase-786-original-finish-notes.md`
Replay：`docs/migration/replays/d02-original-finish-notes.mjs`

## 背景

`feature_note__*` 差集 +53，主体为 Finish Notes AI 管线
（上传→转写→生成补全，配额门控），配套页管理器 a11y 八键、
封面入口、GIF 插入、粘贴图项、手机标题编辑。

## 决策

1. **Finish Notes**：后端 AI 服务 + 订阅配额——fail-closed，
   不虚构。
2. **GIF 插入**：媒体源面登记版本差（源端待评审）。
3. **页管理器 a11y/标题编辑/菜单项**：键级版本差登记。
4. 本阶段不实现。

## 后果

- `feature_note__` 差集 +53 全部归属完毕。
- Finish Notes 状态机语义入 T-042。
