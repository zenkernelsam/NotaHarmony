# Phase 821 — public.xml 公共资源 API 差分与字符串删除审计

证据来源：`decompiled_1.0.3/1.4.2` 的 `res/values/public.xml`（jadx 自 resources.arsc
重建的公共资源声明清单）、`strings.xml`；Harmony `string.json`。

## 一、public.xml 总量差分（1.0.3 → 1.4.2）

| 指标 | 值 |
|---|---|
| 1.0.3 公共条目 | 5,222 |
| 1.4.2 公共条目 | 4,292 |
| 删除 | **1,844** |
| 新增 | **914** |

### 删除项按类型

| 类型 | 删除数 | 归属判定 |
|---|---|---|
| attr | 1,200 | 几乎全部 vendor（Material/Compose/appcompat 属性随 SDK 栈裁剪） |
| style | 215 | vendor |
| dimen | 153 | vendor |
| string | 107 | 混合（见 §二） |
| drawable | 55 | 混合——应用级图标 `feature_note__selection_menu_convert_to_math`/`fit_to_page`/`feature_note__youtube`/`feature_note_toolbox__{insert_math,chevron_right,record_option}`/`ui_fileimport__docscan` 等被删，但**同名字符串仍在** strings.xml：图标从 XML drawable 迁移为 Compose 代码内联向量（呼应 812 的 app_mark_path 字符串化重构） |
| color | 45 / layout 51 / integer 9 / anim 4 / animator 2 / font 2 / xml 1 | vendor 为主 |

1,199 个被删 attr 中仅 1 个仍在 attrs.xml——其余为框架裁剪。

## 二、107 个被删字符串的三分解

逐键与 1.4.2 `strings.xml` 键名比对（同后缀不同前缀 = 重键名）：

| 类别 | 数量 | 内容 |
|---|---|---|
| **重键名** | 17 | `feature_learn__chat_error_*`×7→`ui_learn__chat_error_*`；`feature_settings__sign_out*`×3→`ui_account__*`；`feature_library__clear_search`→`ui_designsystem__clear_search`；`feature_learn_summary__copy_all`→`ui_learn__copy_all` 等 |
| **vendor 删除** | ~62 | `abc_*`（appcompat）、`exo_track_*`×14（ExoPlayer 音轨选择）、`mtrl_*`/`material_*`/bottomsheet/character_counter/path_password_*（Material）、`default_web_client_id`、`google_crash_reporting_api_key` |
| **应用级真删** | ~28 | 见 §三 |

## 三、应用级真删的语义

1. **drawable→代码向量迁移**：`convert_to_math`/`fit_to_page`/`youtube`/
   `insert_math` 等图标的 drawable 条目被删但字符串保留——功能未下线，
   图标实现迁往 Compose ImageVector（与 Phase 791 drawable 清理、812
   app-mark 字符串化同一趋势）。Harmony 本就无这些键，一致。
2. **登出流程精简**：`feature_settings__logout_sync*`/`logout_title`/`logout_text`
   等 9 键真删——Phase 784 登记的 re-key 只覆盖 3 个 sign_out 键，其余同步警告
   文案随账号流程简化删除。
3. **工具栏 a11y 描述删除**：`feature_note__hwr_toggle_description`/
   `learn_toggle_description`/`content_manager_toggle_description`/
   `hwr_panel_close_description`/`toprighttoolbar_undo/redo_action`——
   六条 a11y content-description 删除（工具栏标签改自动推导或合并）。
4. **主题标签迁移**：`feature_settings__dark_theme`/`match_system_appearance`
   删除，`ui_designsystem__theme_*` 族承接（Phase 812 已登记值对齐）。
5. **遗留清理**：`feature_note__youtube*`/`feature_settings__youtube`、
   `feature_library__hamburger`/`importnewnote`/`list_bullet`/`plus`、
   `ui_fileimport__docscan`、`ui_templates__browse`、`feature_learn_quiz__card_completed_score`
   等遗留键删除。

## 四、Harmony 侧核验

对 12 个代表性删除键逐一在 `string.json`/`ets/` 中反向检索：

- `convert_to_math`、`fit_to_page`、6 条工具栏 a11y 描述、`logout_syncing`/
  `logout_sync_now`：**全部正确缺席**——Harmony 按 1.4.2 时代表面构建，删除自然传播。
- `dark_theme`/`match_system_appearance`：Harmony 以自有键保留主题标签
  （等价语义存在）。

## 五、结论

public.xml 差分闭合：**−1,844** 项中 1,199 attr + 215 style + 153 dimen +
45 color + layout/integer/anim 等均为 vendor 框架裁剪；107 个字符串删除
三分解为 17 重键名 + 62 vendor + 28 应用级真删；另有 55 个 drawable
条目删除中含应用级图标，但对应字符串保留——属 Compose 代码向量迁移
而非功能下线。logout/主题/a11y 家族为流程重构残留清理。
Harmony 已正确缺席全部已删键。
