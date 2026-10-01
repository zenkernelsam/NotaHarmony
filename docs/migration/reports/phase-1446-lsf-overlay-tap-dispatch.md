# Phase 1446 报告 — lsf 点选型单元素选区界内命中分发（zf3 case1 / ch1 case8-9）

## 目标

按 1.4.2 `zf3` case1 点按分发器对齐 Harmony 覆盖层内/外点按语义，重点是 lsf（点选型单元素）支的命中分发与 `ch1` case8/9 终局。

## 原版取证

- `zf3` case1 分支结构：`ksf`（isf/jsf）界内为拖拽域——`isf` 界内一律 `ctf`（**含套索单文本，不进编辑**）；`jsf` 命中 vvh/非组成员 → `ctf`，非 vvh 组成员 → `zsf`。`lsf` 支**无界内判定**，直接 `dtfVar.a(jE)` 命中分发：落空 → `xsf`、异元素/组 → `btf`、同元素 `vvh` → `zsf`、同非 vvh → `ctf`。
- 终局映射：`xsf`→`rv0`（清选）；`btf`→`ch1` case8（`hmb.g(new lsf/jsf)` 重选 + `e.c(tap,msf)` 起移动会话）；`ctf`→`usf` case0（r3b 拖拽）；`zsf`→`ch1` case9（`zyh` 进编辑 + `w8d.d` 落 caret）；`wsf`→`e8f`（取消点除，P1445）；`atf`→null。
- 编辑会话激活（`r3eVar.F≠null`）且 `z2`：同块点按 → `atf`；编辑中点选区外 → `vsf` 早退。`!z3`（裸笔）压制 `xsf`/`btf` 落空支。

## 缺口与修复

**缺口 A（lsf 支）**：Harmony `insideOverlayElementTap` 旧实现界内非自身命中/落空一律拖拽旧选区，且 `singleText` 门不区分来源使套索单文本误入编辑。

- `insideOverlayElementTap` 重构：`lsfLike = !supportsDeselectMode && groupIds==0 && 总数==1`（复用 P1439 来源标记）。
  - 界内落空 → `clearSelectionWithRegisterReset()`（xsf→rv0）。
  - 界内异命中 → `applyTapSelect` + `beginSelectionDragSession`（btf→case8 `e.c`）。
  - 同文本块 → 链接探/`beginTextEditingAt`（zsf→case9，caret-at-tap 已有）。
  - 同非文本 → `false` → 拖拽（ctf）。
  - 非 lsfLike（isf/jsf/多元素）保持界内拖拽域——isf 单文本界内点按改为拖拽（原版语义修正）。
- 签名增 `screenP` 参数（异命中拖拽会话需屏幕坐标），两调用点同步。

**缺口 B（e.c 移动会话）**：`ch1` case8 尾部 `e.c(tap, msf)` 无条件起同手势移动会话。Harmony 两处选区外重选点（DEFAULT 面、SELECTION 面各一）仅 `applyTapSelect` 缺拖拽会话——补齐后换选元素可同手势直接拖动。

## 复核一致项（无改动）

编辑态先行门（3596-3608 `textEditing` 块内 return/块外提交或挂起）↔ `z2` 会话激活 `atf`/`vsf`；裸笔压制 `stylusSuppress` ↔ `!z3`；jsf 非文本成员消费不拖拽 ↔ `zsf`→`zyh(非文本)` no-op；链接探测先行（`uw2` case4/`qke` 既有裁决）。

## 验证

- 新 fixture `d02-original-lsf-overlay-tap.mjs` 13/13。
- 更新 fixture `d02-original-selected-element-tap.mjs` 15/15、`d02-original-text-surface-selection-dispatch.mjs` 15/15（新签名）。
- `d02-original-tap-caret-place.mjs` 12/12（序断言仍成立）。

## 后续候选

- `hsf` 进行中套索的第二指按下：原版恒 `xsf`→`rv0`（弃手势）；Harmony 当前按无选区路径命中分发——多点触控边角，暂登记。
- `sen.t`/`gsf.d` 选区轮廓渲染：原版 isf 轮廓=实线 2dp 界 + 32% 透明套索路径 + 蚂蚁线动画（600ms 相位循环），deselectMode 下界色降 32% 透明——渲染层 parity 待定 Phase。
