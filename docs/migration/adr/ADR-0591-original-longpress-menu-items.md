# ADR-0591 — 空白处长按菜单项集 {PASTE, SELECT_ALL}

- 状态：Accepted
- Phase 622；对齐 `yqa.f`（yqa.java:180-215）+ `tqe` 枚举 +
  `eh5.b` 门（decompiled_1.0.3）。

## 背景

原版空白处长按菜单为固定两项 `{PASTE, SELECT_ALL}`：
PASTE 受 `hasPrimaryClip` 门（剪贴板有内容即产出）；SELECT_ALL
在 {PASTE,SELECT_ALL} 项集中**无门**——`eh5.b` 过滤门的是
ordinal6=REMOVE_HIGHLIGHT（文本菜单项，不在本项集）。两项均可
被 `g39.b()` 200ms 交互窗抑制。

Harmony 旧实现只有「系统剪贴板图片粘贴」一项，且仅在元素
剪贴板为空时产出——元素剪贴板粘贴经长按不可达，SELECT_ALL
完全缺失。

## 决策

1. `ClipboardPasteContextMenu` 在 200ms 门内按 `m18.m0` 顺序
   产出两项：
   - **PASTE**：`canPasteClipboardNow() ||
     canUseOriginalClipboardImage()`——`hasPrimaryClip` 等价
     （Harmony 两种粘贴源分列，任一可用即产出）。点击时元素
     剪贴板优先（`pasteClipboard(clipboardPasteTarget)`，长按
     锚点），否则系统图片粘贴——原版 PASTE 读系统剪贴板自有
     载荷优先的等价。
   - **SELECT_ALL**：无门固定产出（过滤循环对 ordinal3 放行；
     空页点击产生空选=no-op，与原版一致）。
2. `selectAllPageElements()`：全部实体 id 经
   `resolveOriginalGroupSelection(allIds, allIds, groups)` 归并
   ——未分组实体平铺 + 顶层组整体入选 → `selectElementIds` →
   ftc 多选 → `updateSelectionOverlay()` + `renderFrame()`。
3. `select_all` 字符串双语（"Select All"/"全选"）。

## 边界 / fail-closed

- 原版 `z3` 分支（剪贴板动态项）与 `tqe.a()` 全量项集属更广
  载荷模型，Harmony 无对应类型——对齐常态两项集。
- 选区存在时的长按菜单由选区壳事件体系处理；Harmony 选区动作
  为常驻浮层（已注册适配）。

## 证据

- `docs/migration/evidence/original-longpress-menu-items-2026-09-28.md`
- Replay：`d02-original-longpress-menu-items.mjs`（18 断言）
