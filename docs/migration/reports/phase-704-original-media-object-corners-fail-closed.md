# Phase 704：原版 media_object_corners 设置 + ROUND 圆角渲染 fail-closed 登记

继续 `feature_settings__*` 扫描：`media_object_corners`（Rounded/
Sharp）为唯一未登记项。JADX 审计后登记 fail-closed（ADR-0653）。

## 原版证据

- 设置项：`z22` 渲染标题，`y22`/`hx1` 渲染 Rounded/Sharp 两选项。
- `corner` 是 BlockCommon 的 LWW register，`ry0` 元数据显示类型为
  flatbuffers `BlockCornerType`——**枚举**（{0,1}，SHARP/ROUND），
  非像素半径；`td8`/`rl2`/`mb` 参与 ModifyBlock op 序列化与比较。

## Harmony 现状

**数据面已完整对齐**（无需改代码）：

- TEXT/IMAGE/MATH 元素均携带 `corner` 字段；
- CreateBlock：`corner` uint8 `normalizeOriginalEnum(...,1)` 读 +
  `create_corner` 列持久化 + 应用三类元素；
- ModifyBlock：`StoredRegister<number>` LWW 合并
  （`registerAccepts`→`updatedElement.corner`）；
- 外部同步/导入携带 `corner=1` 的块忠实存储回写，数据无损。

**登记边界**：

1. `media_object_corners` 设置项不实现——Harmony 插入固定
   `corner: 0`（SHARP），等价原版默认设置。
2. ROUND 圆角视觉渲染不实现——像素半径无静态证据（沿用
   "继续不猜"先例）；SHARP=0 是确定的呈现。

## 产物

- `docs/migration/adr/ADR-0653-original-media-object-corners-failclosed.md`
- `docs/migration/evidence/original-media-object-corners-jadx-2026-09-24.md`
- `docs/migration/replays/d05-original-media-object-corners-fail-closed.mjs`
  （9 断言：原版设置/register 证据 + Harmony 数据面 + 边界）

## 验证

- 专项 9/9；全套件重跑通过后记录于修复总纲；双 HAP 0 错误。
