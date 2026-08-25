# ADR-0420: 损坏历史恢复中文资源补齐

日期：2026-08-26

## 状态

Accepted

## 背景

D-02 第十一阶段为损坏持久化历史提供原生 AlertDialog 与故障 toast，但当时只把六条
恢复文案写入默认 `base` 资源。`zh_CN` 资源表随后持续新增照片、录音等中文文案，
却没有同步这组历史恢复字符串。中文环境下 `$r('app.string.*')` 会回退到英文标题、
正文、按钮和 toast，违背项目已确立的双语 UI 交付口径。

## 决策

在 `zh_CN/element/string.json` 中补齐 `history_recovery_title/message`、
`continue_editing/reset_undo_history` 和 needed/complete/failed 三类结果 toast。
中文语义逐句对应默认英文：明确笔记内容安全、仅重置本地撤销栈、操作日志保留，
以及失败时仍可继续编辑。不改生产逻辑、按钮顺序或 reset 入口串行化。

## 结果

默认英文与 `zh_CN` 资源形成一一对应的可验证契约；专项 Replay 锁定双语键值。
真实中文环境下的对话框视觉排版仍留待后续设备验收，本阶段不做无证据的运行态断言。
