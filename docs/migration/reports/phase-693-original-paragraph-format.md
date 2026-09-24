# Phase 693 — 原版段落对齐 + 行距（vse/i5a/r4a + wte/j5a/fg7）移植

## 范围

补齐 `cve` 分发中仅剩的两个段落级 authoring op：对齐
（`vse(r4a)`→`i5a` SetAlignment）与行距（`wte(float)`→`j5a`
SetLineSpacing）。两者对应原版格式面板 `qse.P`/`qse.Q` 弹层，
Harmony 以两个 `bindMenu` 钮等价承载。

## 原版行为（证据见 phase-693 evidence）

- `r4a`：LEFT(1)/CENTER(2)/RIGHT(3)；`oue` 工具条 cases 7-9 直发
  `vse(r4a.X)`。
- `fg7`：LineSpacingPopoverState，可选值固定 `[1.0, 1.5, 2.0]`；
  选择经 `i31` case 18 → `wte(f)` → `j5a` op。
- 两 op 均作用于光标段落；`ure` 工具条态显示当前对齐/行距。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `setAlignment(value)`：显式写 `alignment=1/2/3`（1=LEFT 也
    显式落记录，忠实 `vse(LEFT)`）；其余字段拷贝保留。
  - `setLineSpacing(value)`：写字面浮点 `{1.0,1.5,2.0}`。
  - `refreshCaretParagraphExtras()`：caret/seed 时同步
    `caretAlignment`/`caretLineSpacing`（默认 1/1）。
  - `buildAlignmentMenu()`/`buildLineSpacingMenu()`：
    `MenuElement` 菜单；两钮置 Done 之前，
    `.enabled(!photoImportLeaseActive)`。
- 新增字符串 ×5（en/zh）：`text_alignment`/`align_left`/
  `align_center`/`align_right`/`line_spacing`。
- 模型与渲染层此前已兑现两字段，本 Phase 零改动。

## 验证

- Replay：`d02-original-paragraph-format.mjs` 29 项全绿；
  lease-bound enabled 计数 25→27。
- 构建：`note@default`/`note@ohosTest` clean assembleHap 成功
  （见提交记录）。
- 真机/模拟器：未验证（约束内）。

## 限制

- 原版为弹出式分段控件/选项 popover（`kdi.b`/`wsi.a`），Harmony
  用 `bindMenu` 列表等价——交互形态差异沿用 ADR-0648/0650 登记。
- 原版 `oue` case 10（`b40.o()` 浏览器打开链接）属链接交互项，
  未包含于本 Phase（链接打开/长按菜单仍为登记缺口）。

## 涉及文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`
- `docs/migration/replays/d02-original-paragraph-format.mjs`
- `docs/migration/replays/d02-open-text-shared-ingress-lease-bound.mjs`
