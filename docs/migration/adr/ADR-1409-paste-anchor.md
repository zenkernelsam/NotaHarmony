# ADR-1409: Ctrl+V 粘贴锚点 = 负载原界中心 + 10% 偏移

- **状态**: 已接受
- **日期**: 2026-08-10
- **阶段**: Phase 1474
- **关联**: evidence/phase-1474-paste-anchor.md
  （`f2:182-211`/`ot2.b,d,e`/`pt2.a`/`m86 byte20` 解码）

## 背景

原版 Ctrl+V 粘贴锚点并非视口中心：`ot2.b()` 返回 `pt2.a` ——
最近一次 copy/cut/duplicate 构建 `lt2` 负载时记录的**负载原界
`jt2.b`**；锚点 = 该界中心 + `min(宽*0.1, 30)` 页面单位双轴偏移；
屏坐标半开视口检查越界则回退视口中心；负载缺失/剪贴板描述符
不兼容 → `qc8` 空事件不粘贴。语义 = "粘贴回原文附近略偏移"。

Harmony 此前：UP+clipboardAvailable → 视口中心（或选区中心经
`selectionPasteTarget`）——丢失"原位粘贴"语义。

## 决策

- `StrokeClipboard` 新增 `payloadBounds()`：`hasContent` 门 +
  `unionBounds` → 负载原界（`pt2.a` 等价物）。
- Ctrl+V/PASTE 键支：负载非空 → `界中心 + min(w*0.1,30)`；
  `canvasToScreen` 半开视口检查，越界回退视口中心；
  **直达 `pasteClipboard(target)`**——不再经
  `onSelectionMenuAction(PASTE)`/`selectionPasteTarget`
  （其选区中心优先级与原版负载锚语义冲突）。
- 菜单/长按粘贴路径不改（原版菜单锚=触摸点，另案登记）。

## 等价性论证

| 原版 | Harmony | 一致性 |
|------|---------|--------|
| `ot2.b()` 负载界 + 描述符门 | `payloadBounds()` + `clipboardAvailable`/`hasContent` | ✓ |
| `u64.b(sbe)` 中心+`min(w*0.1,30)` | 同式双轴等值 | ✓ |
| `zx7.z` 半开视口检查→`exj.c()` | `canvasToScreen`+[0,w)×[0,h)→视口中心 | ✓ |
| `jt2==null`→`qc8` no-op | null→视口锚但 `pasteClipboard` 空负载 no-op | ≈ |
| `m86(bde.F)` 直锚 | `pasteClipboard(target)` 直达 | ✓ |

## 边界

- 外部系统剪贴板内容（无 `pt2.a`）：原版 `ot2.b` null→qc8；
  Harmony 走视口中心锚 + `hasContent` 内部门，纯系统图片由
  `startOriginalClipboardImagePaste` 路径处理（菜单支）。
- `exj.c` 视口矩形含 insets，Harmony 画布矩形近似。

## 验证

- `d02-original-paste-anchor.mjs`：18 checks。
- 基线与 `note@default`/`note@ohosTest` 构建全绿。
