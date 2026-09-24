# Phase 683 — 原版文本格式工具条列表装饰项移植

## 范围

P681（QUOTE_AND_CODE_BLOCKS）补齐了段落装饰 4/5 的 authoring；本
期把同一行的 fy2 1~3 —— Bullet list/Numbered list/Checkbox list —
— 也补进 `TextBlockOverlay` 底部行，段落装饰面全部落地（字符样式
B/I/U/S 与 link/indent 留待后续期）。

## 原版行为（证据见 phase-683 evidence）

- `fy2` 枚举 NONE=0/BULLET=1/NUMBER=2/CHECK_BOX=3/BLOCK_QUOTE=4/
  CODE_BLOCK=5。
- `h32` case24-26 三图标行；`cve` `yse/xte/zse` → `o(fy2)` →
  `m(m5a)` 段落样式 op，单选互斥、同项再点清除。
- `isChecked` 为独立字段，切换 decorator 不丢失勾选。

## Harmony 实现

- `TextBlockOverlay.ets`：底部行新增三枚切换钮（光标段落粒度，
  激活态按 `caretDecoratorStyle === 1/2/3`），顺序对齐 h32：
  bullet→number→checkbox→quote→code；`toggleDecoratorStyle`
  复用，isChecked 等字段跨切换保留。
- 资源：`bullet_list`/`numbered_list`/`checkbox_list` en+zh。
- 顺带修正 P681 行内注释中“其余项已在既有表面实现”的不实表述。

## 验证

- Replay：`d02-original-list-decorators.mjs` 21 项全绿；
  `d02-open-text-shared-ingress-lease-bound` 的 enabled 计数钉
  5→8 同步更新；P681 fixture 不受影响。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；`note@ohosTest`
  clean 构建见提交记录。
- 真机/模拟器：未验证（约束内）。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`
- `docs/migration/replays/d02-original-list-decorators.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
- `docs/migration/evidence/phase-683-original-list-decorators.md`
- 本报告 + 三份跟踪文档
