# ADR-1353 设置页 About 区（Blog / Discord 卡 / 社交图标行）

- 状态：Accepted
- 日期：2026-10-01
- 关联 Phase：1417
- 接续：ADR-1352（库 chrome 无障碍收尾）；同族 fail-closed：ADR-0644/ADR-1347
- 证据：`docs/migration/evidence/phase-1417-settings-about.md`

## 背景

原版 `xpa` 设置骨架在尾部渲 `yrm.a(feature_settings__about, v0(1))`
About 区：`v0(1)` → `wxm.a` 建 `k1` VM 后以 `ec2.e` 内嵌 `s0` 项列表 =
[w8n.b 钮卡] + [Discord 卡 wxm.b] + [社交图标行 wxm.c]。
Harmony `SettingsPage` 此前完全没有 About 区。

## 决策

### 移植

1. **Blog 钮**：`x8n.b + t0(1) → j1(0)` =
   `blog.notability.com` —— 可移植外链，`openLink` 打开。
2. **Discord 卡**：`tee.a` 16dp 卡，标题 `discord_title` +
   描述 `discord_description` + `x6n.a` 双钮：
   Accept invite（`a.d.a` 主配色 → `accent/onAccent`，
   `discord.gg/Fw9SsRYU7a`）与 Learn more（`a.b.a` 次配色 →
   `control/textPrimary`，Ginger Labs support 文章）。
3. **社交图标行**：`wxm.c` 五枚 `cc3.l`（instagram → youtube →
   tiktok → threads → linkedin），cd = `feature_settings__cd_*`，
   URL 经 `t0`→`j1` 二次映射逐字移植；`TOOL_GLYPHS` 新增五枚
   24×24 单 fill 品牌徽标（`feature_settings__instagram` 等
   drawable pathData 逐字，clip-path 视口裁剪不迁移）。
4. `openExternalLink`：`context.openLink` 替代
   `k1.z()` 协程 emit → `startActivity`；失败仅日志
   （沿用 `console.error` 约定）。

### Fail-closed

- **Rate Notability**（`t0(4)`→`j1(5)` =
  `play.google.com/store/apps/details?id=com.gingerlabs.notability`）：
  Android 商店页无 Harmony 等价宿主；不伪造 AppGallery 链接。
- **Newsletter 与第四枚 flag 文本钮**：`h35.Y0` flag 门控，
  无对应订阅宿主。

### 有意差异

- About 区置于 `backup_and_sync` 之后（设置页尾部），与原
  版 About 区在列表尾部的语义一致；Harmony 采用现有区头
  样式（16sp Medium textSecondary）而非重建 `yrm.a` 骨架。

## Replay

- `docs/migration/replays/d02-original-settings-about.mjs`：21 项
  覆盖宿主链、URL 映射、字串、布局顺序与 fail-closed 钉。
