# Phase 1417 证据：设置页 About 区（Blog 钮 + Discord 卡 + 社交图标行）

- 版本证据基线：`decompiled_1.4.2`
- 接续 Phase 1416：库 chrome 无障碍收尾后，补齐原版设置页缺失的
  About/社区尾部区块。

## 1. 宿主链：About 区

| 原版 | 语义 | 证据 |
|------|------|------|
| `xpa` | 设置骨架逐 case 渲 `yrm.a(title, bz5, false, null, content)`；About 区 title=`feature_settings__about`("About")、content=`v0(bz5,1)` | `xpa.java:348/431/511/592` |
| `v0` case1 | `wxm.a(bz5, nc6Var, 0)` —— About 区内容宿主 | `v0.java:45` |
| `wxm.a` | `lph.a` 建 `k1` VM 后 `ec2.e(null,…,new s0(k1Var, bz5Var, b))` —— 内嵌项列表 | `wxm.java:51` 附近 |
| `s0` case0 | 项表尾部：`w8n.b` 钮卡 + 两个 `aq8.j0` 追加 `wxm.b`(Discord 卡) 与 `wxm.c`(社交行) | `s0.java:62/71` |

## 2. About 钮卡（w8n.b）四项

| 项 | 原版 | 目标 | 处置 |
|----|------|------|------|
| Rate Notability | `u0(1)` → `x8n.b(..., t0(4), ubl.b)` | `t0(4)`→`j1(5)`= `play.google.com/store/apps/details?id=com.gingerlabs.notability` | **fail-closed**：Android 商店页无 Harmony 等价宿主，不伪造 AppGallery 链接 |
| Newsletter | `v0(0)` flag `h35.Y0` 门控 → `x8n.b(..., ubl.c)` | — | **fail-closed**：flag 门控 + 无对应订阅服务 |
| Blog | `u0(2)` → `x8n.b(..., t0(1), ubl.d)` | `t0(1)`→`j1(0)`= `blog.notability.com` | **移植**：`openLink` |
| flag 文本钮 | `jf2(1064842269, ubl.f)` + `t0(8)`→`j1(6)`=threads | flag `h35.Y0` 门控 | **fail-closed**：flag 门控冗余入口（社交行已有 Threads 图标） |

## 3. Discord 卡（wxm.b / u0 case3）

| 原版 | 语义 | 证据 |
|------|------|------|
| `wxm.b` | `tee.a(hx7.K(w8aVarF,16f), …)` —— 16dp 内边距卡片，内容 `u0(k1,3)` | `wxm.java:68` 附近 |
| `u0` case3 | `r92` 列(16 间距)：`d4i.b(discord_title, z5i.I)` + `d4i.b(discord_description, z5i.J)` + `b0f` 行双钮 | `u0.java:61-117` |
| Accept invite | `x6n.a(t0(2), colors=fc1.a(a.d.a), ubl.g)` → `j1(1)` = `discord.gg/Fw9SsRYU7a` | `u0.java:123-128` |
| Learn more | `x6n.a(t0(3), colors=fc1.a(a.b.a), ubl.h)` → `j1(2)` = `support.gingerlabs.com/…/Join-the-Notability-Discord-Server` | `u0.java:130-133` |

`a.d.a`/`a.b.a` = 主/次钮配色组 → Harmony `accent/onAccent` 与
`control/textPrimary`。

## 4. 社交图标行（wxm.c）

| 图标 | cd | t0 | j1 | URL |
|------|----|----|----|----|
| instagram | `cd_instagram`="Open Notability on Instagram" | `t0(5)` | `j1(3)` | instagram.com/notabilityapp |
| youtube | `cd_youtube`="Open Notability on YouTube" | `t0(6)` | `j1(8)` | youtube.com/notability |
| tiktok | `cd_tiktok`="Open Notability on TikTok" | `t0(7)` | `j1(7)` | tiktok.com/@notabilityapp |
| threads | `cd_threads`="Open Notability on Threads" | `t0(8)` | `j1(6)` | threads.com/@notabilityapp |
| linkedin | `cd_linkedin`="Open Notability on LinkedIn" | `t0(0)` | `j1(4)` | linkedin.com/company/ginger-labs |

- `cc3.l(hdc, cd, onClick, null, false, nta.c().a.c.b, 0f)` —— 紧凑图标钮，
  tint=`a.c.b`（内容色）→ Harmony `textPrimary`。
- 五行 `t0`→`j1` 二次映射与图标/文案逐一对应（图标 cd 与 URL 同品牌）。
- drawable：4×`feature_settings__*` + `ui_designsystem__youtube`，
  24×24 单 path fill #000000（linkedin 带 evenOdd fillType、clip-path
  仅视口裁剪）→ `TOOL_GLYPHS` 五枚 f 层逐字 pathData。

## 5. Harmony 实现

- `SettingsPage` 尾部（backup_and_sync 之后）新增 About 区：
  `feature_settings__about` 区头 → Blog 全宽钮 → Discord 卡（标题/描述/
  Accept-invite 主钮/Learn-more 次钮）→ 社交图标行 `ForEach(socialLinks)`。
- `openExternalLink(url)`：`getContext → openLink().catch`（替代
  `k1.z()` 协程 emit → `startActivity`）。
- 11 枚字串沿用原版资源名 `feature_settings__*`；en 逐字、zh 本地化。

## Replay

- `docs/migration/replays/d02-original-settings-about.mjs`（21 项）。
