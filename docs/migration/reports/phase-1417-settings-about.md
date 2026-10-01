# Phase 1417：设置页 About 区（Blog / Discord 卡 / 社交图标行）移植报告

- 日期：2026-10-01
- 状态：完成（Desktop Replay 21 项本 Phase 检查；`note@default` /
  clean `note@ohosTest` 构建通过）
- 证据：`docs/migration/evidence/phase-1417-settings-about.md`
- 决策：`docs/migration/adr/ADR-1353-settings-about-section.md`
- Replay：`docs/migration/replays/d02-original-settings-about.mjs`

## 目标

补齐原版设置页 About 区。原版 `xpa` 骨架以
`yrm.a(feature_settings__about, v0(1))` 渲出内嵌项列表：
[w8n.b 钮卡（Rate/Newsletter/Blog/flag 项）] + [Discord 卡] +
[五枚社交图标钮]。Harmony `SettingsPage` 此前无 About 区。

## 原版证据链

| 层 | 原版类 | 语义 |
|----|--------|------|
| 区头 | `xpa`/`yrm.a` | title=`feature_settings__about`，content=`v0(bz5,1)` |
| 宿主 | `v0(1)`→`wxm.a`→`ec2.e(s0)` | About 区 = 内嵌 `s0` 项列表 |
| 钮卡 | `w8n.b`+`u0(1)/(2)`+`x8n.b` | Rate→play store；Blog→`j1(0)`=blog.notability.com |
| Discord 卡 | `wxm.b`/`u0(3)` | tee.a 16dp 卡：title/desc + `x6n.a`×2（Accept invite→`j1(1)`=discord.gg/Fw9SsRYU7a；Learn more→`j1(2)`=support 文章） |
| 社交行 | `wxm.c` | `cc3.l`×5 + `cd_*`；`t0(5/6/7/8/0)`→`j1` 二次映射到五品牌 URL |
| URL 分发 | `j1`/`t0` | `k1.z()` 协程 emit URL → `startActivity` |

## Harmony 实现

1. 11 枚字串沿用原版资源名 `feature_settings__*`（en 逐字：
   about/blog/discord_title/discord_description/accept_invite/
   learn_more/cd_instagram/cd_linkedin/cd_threads/cd_tiktok/
   cd_youtube；zh 本地化）。
2. `ToolGlyphs` 新增五枚品牌徽标（instagram/youtube/tiktok/
   threads/linkedin），drawable pathData 逐字（24×24 单 fill）。
3. `SettingsPage` 尾部（backup_and_sync 后）新增 About 区：
   - 区头 "About"（沿用现有区头样式）；
   - Blog 全宽钮 → `openLink(blog.notability.com)`；
   - Discord 卡（标题+描述+Accept-invite 主钮/Learn-more 次钮）；
   - 社交图标行 `ForEach(socialLinks)`：48×48 图标钮、cd_* a11y、
     原版顺序 instagram→youtube→tiktok→threads→linkedin。
4. `openExternalLink`：`context.openLink` + `catch` 日志
   （`k1.z()`→`startActivity` 等价物）。

## Fail-closed（记录不迁移）

- **Rate Notability**：`play.google.com/…com.gingerlabs.notability`
  是 Android 商店页，Harmony 无等价宿主，不伪造 AppGallery 链接。
- **Newsletter 与第四枚 flag 文本钮**：`h35.Y0` flag 门控，无订阅宿主。

## 校验

- 本 Phase Replay：21/21 全绿（含 fail-closed 钉：非注释代码无
  play.google.com / newsletter 引用）。
- 全量 Desktop Replay：1269/1269 全绿（含 d02-original-settings-about
  21 项 + editor-toolbar-glyphs 计数 46→51 重锚）。
- `hvigorw --no-daemon assembleHap -p product=default`：BUILD SUCCESSFUL。
- `hvigorw --no-daemon clean assembleHap -p module=note@ohosTest`：
  BUILD SUCCESSFUL（含 `OhosTestCompileArkTS`）。

## 遗留 / 下一步

- `cd_hide_tools`（工具箱收起钮）、`cd_audio_player_settings`
  （内嵌音频块 ⋯ 钮）原版存在但 Harmony 无宿主表面，继续 fail-closed。
- `media_object_corners` 1.0.3 死 UI 已定案不迁移；
  check_spelling/tap_anywhere 等设置行为项已在 ADR-1347 族归档。
