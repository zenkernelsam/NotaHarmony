# ADR-0658 `ac4` 远程旗标尾项 fail-closed 总登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：710
- 接续：ADR-0644（旗标域 fail-closed 判据）、ADR-0652（Learn
  旗标族）、ADR-0656/0657（外部依赖面）；本 ADR 为 `ac4` 70
  旗标注册表系统审计的收官登记。
- 证据：`docs/migration/evidence/original-remote-flag-tail-jadx-2026-09-25.md`

## 背景

对原版 `ac4` 70 项远程旗标完成全量消费方审计后，除已单独
登记/实现者外，剩余旗标分三类：

### A. 远程门控的可选行/项（旗标关闭 = 不出现 = Harmony 现状）

| 旗标 | 序号 | 消费方 | 门控内容 |
|---|---|---|---|
| NOTE_TOOLBOX_SECONDARY_TOOLS | 22 | `ch2:94`/`ys2:1099` | 已连接手写笔的二级工具条（含笔状态槽位 +48dp）——同 SPen 手写笔远程面 |
| SETTINGS_NAV_PAGES | 59 | `s3d.a` | 新版设置导航结构（增 connected_services，AI 行转 Learn 门控）；关闭=旧平铺列表=Harmony 现状 |
| SETTINGS_MANAGE_SUBSCRIPTION | 28 | `s3d`/`x97` | manage_subscription 行（订阅域外） |
| SETTINGS_NOTE_EDITOR | 61 | `od:83` | 笔记内 ⋮ 菜单的笔记编辑器设置链接 |
| DOCUMENT_DEFAULT_SETTINGS | 52 | `od:64` | 同上菜单的文档默认设置链接/分区 |
| SETTINGS_HANDWRITING_DRAWING | 58 | `ks:109` | 手写/绘图设置附加行（`pb5`/`sih.f`/`ob5` case6） |
| HANDWRITING_RECOGNITION_TOGGLE | 33 | `ks:118`/`x90:10556` | 手写识别开关行 + 工具行识别图标 |
| SETTINGS_NEWSLETTER_LINK | 60 | `q0:51` | 设置表 newsletter 链接行 |
| SETTINGS_SUPPORT_DIAGNOSTICS | 63 | `q0:51` | 支持诊断行（`jeh.f`） |
| SETTINGS_PRO_INFO | 62 | `x22:344` | pro info 设置行 |
| NOTE_NIGHT_MODE(变体) | 56 | `q0:164` | 设置页内 `j60` case6 行——Harmony 已在设置主列表实现 `note_view_night_mode` 行（旗标开态语义已覆盖） |
| TEMPLATE_SECTION_PICKER | 64 | `fdi:210` | 模板分区标签页选择器变体；关闭=单列表=Harmony 现状 |
| LIBRARY_ADD_NOTE_MENU_ITEMS | 53 | `cd:58` | 库"新建笔记"菜单的 Templates 项 |
| NOTE_CONTENT_MANAGER_CREATE_TEMPLATE | 38 | `n9j:2055` | 内容管理器"Create template"项 |
| COPY_NOTE_ID | 32 | `d5j:242` | 库笔记菜单"Copy note ID"项 |
| NOTE_DEBUG_FEATURES_MENU | 34 | `x90:10391` | 调试功能菜单（内部） |

### B. 订阅/后端/私有 API 依赖（结构性 fail-closed）

| 旗标 | 序号 | 消费方 | 依赖 |
|---|---|---|---|
| NOTE_LIMIT | 26 | `en9:21` | 订阅档位 `vsf`/`v2e` + `z5c`/`v6` 账户态 → 免费层 ≥5 篇限制 |
| REQUIRE_UNLOCKED_DEVICE | 27 | `gti:25` | Android `KeyguardManager` 设备解锁态检查（无 Harmony 等价 API） |
| SIX_MONTHS_PLUS_ONBOARDING | 24 | `rt8:24` | 订阅时长 `i0eVar.e()==y3e.M` + 档位 `vsf.N` 的引导流 |
| ROOM_SEARCH_ENGINE | 50 | `m60:160` | DI 在 Room 搜索引擎 vs 旧实现间切换——Harmony 已有自有 SQLite 搜索 |
| LAUNCH_PAYWALL_PROMO | 30 | `tt8:214` | 付费墙推广流（订阅域外） |
| COLLAB_RTL_TEXT | 12 | `kr8:250`/`rs3:200` | 协作文本 CRDT（`bt3`/`eke`/`uub`/`jtc`）RTL 传播——协作面已 fail-closed（ADR-0513） |

### C. 1.0.3 内死旗标（无消费方）

`g0` HANDWRITING_TO_TEXT(21)、`G0` SINGULAR_ATTRIBUTION(48)、
`U` DESELECT_MODE(9)、`v0` LIVE_TRANSCRIPTION(37)、
PLAY_LAUNCH_PROMO(29，未分配字段)——声明后未接线；旗标
关闭=Harmony 现状（自动取消选择橡皮等对应功能已实现，
识别转写由 Learn 族统一登记）。

## 决定

1. A 类全部呈现旗标关闭态：Harmony 无对应行/项/变体——不
   新增实现。
2. B 类登记结构性 fail-closed：依赖订阅系统/KeyguardManager/
   Room DI 选型/协作层——均无 Harmony 等价物或超出独立笔记
   应用范围。
3. C 类死旗标按"无行为差异"记录，不产生实现义务。
4. 已实现的旗标开态（ENTITY_GROUPS `V`、NOTE_TOOLBOX_
   STROKE_STYLE `W`、NOTE_NIGHT_MODE 设置行）与既有
   fail-closed 登记不冲突——`ac4` 旗标审计至此闭合。

## 后果

- `ac4` 全部 70 旗标均有实现/覆盖/登记结论；
- 若 Harmony 引入设置分区导航或模板分区选择器设计，可重审
  A 类对应行。
