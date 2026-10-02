# Phase 1474 报告：Ctrl+V 粘贴锚点 = 负载原界中心 + min(w*0.1,30)

## 原版行为（1.4.2 证据）

`f2.java:182-211`（`!pa8.W` 块内、Ctrl+V 支，`pa8.H`=ofk.e(50)=V）：

- **UP + Ctrl+V** → `jt2 = bd8.K.b()` = `ot2.b()` = `pt2.d.a`
  ——**剪贴板负载原界**（`ot2.d` copy / `ot2.a` duplicate /
  `ot2.e` cut 构建 `lt2` 负载时 `this.d.a = lt2VarH.b()` 记录），
  且过 `gqf` 剪贴板描述符兼容检查。
- 负载界 null → `ea1.p(qc8.a)` 空事件 no-op。
- 非空 → 锚点 `bde.F` = `u64.b(sbe)` **负载界中心** +
  `min((sbe.c−sbe.a)*0.1, 30)` 双轴等值页面单位偏移。
- 屏坐标半开视口检查（`zx7.z`，`ku7`=`exj.c` 视口矩形）：x/y 越界
  → `bde.F = exj.c()` **视口中心回退**。
- → `m86(bd8, bde, jt2, byte20)` 粘贴事件——**锚定负载原位**，
  与当前选区无关（copy/cut 后 `ome.a()` 已清选）。

## Harmony 缺口

此前 Ctrl+V：UP+`clipboardAvailable` → `clipboardPasteTarget`=
视口中心 → `onSelectionMenuAction(PASTE)` → `selectionPasteTarget`
（有选区时甚至取**选区中心**）——丢失"负载原位+偏移"语义。

## 实现

- `StrokeClipboard.payloadBounds()` 公开访问器：`hasContent` 门 +
  `unionBounds` 合法性 → `pt2.a` 负载原界等价物。
- Ctrl+V/PASTE 支重写：负载非空 → `界中心+min(w*0.1,30)` →
  `canvasToScreen` 半开视口检查 → 越界/空负载回退视口中心 →
  **直达 `pasteClipboard(target)`**（与 DUPLICATE 支同款直通，
  绕开选区中心优先路径）。

## 验证

- `d02-original-paste-anchor.mjs`：18 checks 全绿（访问器 pin、
  锚点式、半开检查、回退、直达调用、可执行模型 5 例）。
- 剪贴板/键盘相关 fixture 全绿（keyboard-shortcuts 68、
  duplicate-offset 12、transaction-anchor 23、image-ingress 29、
  longpress 18、menu-order 51、duplicate-key 23、alt-well 33、
  delete-key 17、media-keys 20）。
- `note@default` + `note@ohosTest` 构建成功。
- 全量 Replay 基线：见本阶段提交说明。

## 差异

- `gqf` 描述符兼容 → `hasContent`/`canPaste` 内部态近似；系统
  图片剪贴板由 `startOriginalClipboardImagePaste` 路径处理。
- `exj.c` 视口矩形含系统 insets → `canvasCtx` 画布矩形近似
  （≤系统栏像素级差异）。
- 菜单/长按 PASTE 保留 `selectionPasteTarget`（原版菜单锚=触摸
  点，与键盘支不同源——未动）。

## 关联

- evidence/phase-1474-paste-anchor.md
- ADR-1409-paste-anchor
