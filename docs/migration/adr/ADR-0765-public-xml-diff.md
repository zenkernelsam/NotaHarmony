# ADR-0765 — public.xml 公共资源差分登记

## 状态

已接受。

## 背景

`res/values/public.xml` 反映 resources.arsc 的公共资源 ID 声明面。
1.0.3→1.4.2 总量 5,222→4,292，删 1,844 / 增 914。

删除项经逐键回验 strings.xml/attrs.xml/styles.xml 确认为真实移除而非私有化：

- attr 1,200（1,199 真删）、style 215、dimen 153、color 45、layout 51、
  anim/animator/integer/font/xml 零星——vendor 框架裁剪主体。
- string 107 = **17 重键名**（`feature_learn__chat_error_*`→`ui_learn__*`、
  `feature_settings__sign_out*`→`ui_account__*`、`feature_library__clear_search`
  →`ui_designsystem__clear_search` 等）+ ~62 vendor（`abc_*`/`exo_track_*`×14/
  `mtrl_*`/`material_*`/Firebase 配置遗留）+ ~28 应用级真删。
- drawable 55 中含应用级图标（`convert_to_math`/`fit_to_page`/`youtube`/
  `insert_math`/`chevron_right`/`docscan` 等），但同名字符串仍在——
  图标迁往 Compose 代码向量，非功能下线。

## 决定

1. 107 个删除字符串按"重键名/vendor/应用真删"三分解登记（证据文档）。
2. 应用级真删语义：logout 同步警告族精简（仅 3 键存活至 `ui_account`）、
   主题标签迁移 `ui_designsystem__theme_*`、六条工具栏 a11y 描述删除、
   `youtube_transcription`/`ui_templates__browse`/`card_completed_score` 等清理。
3. drawable 图标删除登记为 Compose ImageVector 迁移证据，不判功能移除。
4. Harmony 反向核验：已删键在 `string.json`/`ets/` 中正确缺席；
   主题标签以自有键保留等价语义。

## 后果

- 公共资源 API 面闭合；字符串删除画像登记完成。
- 新增 `d02-public-xml-diff.mjs` 回归：差分总量、类型分解、
  三分解计数、drawable-迁移判定、Harmony 缺席核验。

## 已验证

- `d02-public-xml-diff.mjs`：11/11。
- 全量 Desktop Replay + clean/default、`note@ohosTest` HAP 构建（随 Phase 821 提交）。
