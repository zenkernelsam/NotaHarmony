# Phase 622 — 空白处长按菜单项集 {PASTE, SELECT_ALL}（yqa.f）

## 原版证据

- `yqa.java:184-215`：常态菜单 = `m18.m0(tqe.PASTE, tqe.SELECT_ALL)`；
  过滤循环按 `ordinal()` 门控——ordinal2（PASTE）需
  `tr1.a.a().hasPrimaryClip()`（剪贴板有内容），ordinal6
  （REMOVE_HIGHLIGHT，文本菜单项）需 `z4 = eh5.b`——
  **复查修正**：SELECT_ALL（ordinal3）不在门控集，空白处菜单
  中无门固定产出。
- `tqe.java`：菜单项枚举含 PASTE/SELECT_ALL。
- `g39.b()` 200ms 交互窗抑制（Phase 620 已对齐外层门）。

## 排查结论

`ClipboardPasteContextMenu` 仅一项「系统剪贴板图片粘贴」，且
只在元素剪贴板为空时产出——元素剪贴板粘贴经长按不可达；
SELECT_ALL 完全缺失。与原版两项集差距大。

## 修复

- 菜单重构：`recentInteractionGateActive()` 门内按原版顺序产出——
  - PASTE：`canPasteClipboardNow() ||
    canUseOriginalClipboardImage()`（hasPrimaryClip 等价）；点击
    时元素剪贴板优先 `pasteClipboard(clipboardPasteTarget)`，
    否则 `startOriginalClipboardImagePaste()`。
  - SELECT_ALL：无门固定产出（原过滤对 ordinal3 放行；空页
    早退=原版空选等价）→ `selectAllPageElements()`。
- `selectAllPageElements()`：全部实体 id 经
  `resolveOriginalGroupSelection` 归并出顶层组+平铺实体 →
  `selectElementIds` → ftc 多选 → overlay+渲染刷新。
- 字符串：`select_all` = "Select All"/"全选"（base+zh_CN）。

## 验证

- 新增 replay `d02-original-longpress-menu-items.mjs`：18/18 绿。
- `d02-original-recent-interaction-menu-gate.mjs` 更新门结构断言：
  15/15 绿。
- 全量 desktop replay 套件：512/512 绿。
- `note@default` HAP 构建绿；`note@ohosTest` HAP 构建绿。
- ArkTS 静态检查随构建通过，无新增错误。
- 未启动模拟器/真机/Hypium。

## 提交

Phase 622 commit（见 git log）。
