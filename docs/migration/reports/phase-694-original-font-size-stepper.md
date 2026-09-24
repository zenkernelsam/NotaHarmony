# Phase 694 — 原版字号步进（kre/pte → zyd.f clamp [4,72]）移植

## 范围

`cve` 分发中最后一个字号通道：直接字号步进。原版
`kre` FontSizeTextToolbarItem = 字号显示 + ±1pt 增减 +
onClick 开 `qse.M` 面板；`pte(float)` → `cve.l(f)` →
`zyd.f = clamp(f,4,72)`。

## 原版行为（证据见 phase-694 evidence）

- `ave.java`：increase=`l(f+1.0f)`、decrease=`l(f-1.0f)`——±1pt 步进。
- `cve.l(f)`：`zyd.f=Float(rh8.u(f,4,72))`——clamp [4,72] 区间写。
- `i31` case 20 发 `pte(float)`；`ure.r` 为 fontSizeState。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `stepFontSize(delta)`：`current`（选区=`fontSizeAt`；折叠=
    `pending ?? fontSizeNearCaret() ?? element.fontSize`）±delta →
    `clamp[4,72]` → 选区 `applyFontSize`+normalize、折叠写 pending。
  - `fontSizeAt(s,e)`：选区首个携 `fontSize` run 的值，回落
    `element.fontSize`。
  - `fontSizeNearCaret()`：光标处 run 的 `fontSize`
    （`start<caret<=end`，与插入落点语义一致）。
  - `caretCharFontSize` 态随 `refreshCaretCharStyles` 两分支刷新，
    `Text` 显示当前字号（kre.a 等价）。
  - `−`/`+` 两钮（语言中性符号，原版亦为图标钮）置 Style 与
    Font 之间，对齐原版字体簇 q→r→s 次序。
- 无新增字符串（图标等价 + 数字显示）。

## 验证

- Replay：`d02-original-font-size-stepper.mjs` 16 项全绿；
  lease-bound enabled 计数 27→29。
- 构建：`note@default`/`note@ohosTest` clean assembleHap 成功
  （见提交记录）。
- 真机/模拟器：未验证（约束内）。

## 限制

- 原版 `kre.onClick` 打开 `qse.M` 字号面板（含直接数值输入等更多
  控件）；Harmony 仅移植步进语义，面板弹层差异沿用 ADR-0648/0650
  登记。
- 选区混合字号时显示首个携值 run 的字号（原版 `kre.a` 亦为单值
  折叠态），步进后统一为新值——与原版 ±1 后整选区归一语义一致。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `docs/migration/replays/d02-original-font-size-stepper.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
