# Phase 821 — public.xml 公共资源差分与字符串删除审计

## 范围

`res/values/public.xml`（resources.arsc 公共 API 声明面）1.0.3→1.4.2 差分；
107 个被删字符串逐键归因；Harmony 反向核验。

## 原版证据

### 总量

5,222 → 4,292（−1,844/+914）。删除按类型：attr 1,200、style 215、
dimen 153、string 107、drawable 55、color 45、layout 51、杂项零星——
vendor 框架裁剪为主体（1,199 个 attr 真删）。

### 107 个删除字符串三分解

- **17 重键名**：`feature_learn__chat_error_*`→`ui_learn__*`（第 784 之后
  又一处 re-key 证据）、`sign_out*`→`ui_account`、`clear_search`→designsystem。
- **~62 vendor**：`abc_*`（appcompat）、`exo_track_*`×14（ExoPlayer 音轨
  选择字符串族整组删除）、`mtrl_*`/Material 组件、`default_web_client_id`、
  `google_crash_reporting_api_key`。
- **~28 应用级真删**：logout 同步警告族 ~9 键、主题标签 2 键、
  工具栏 a11y 描述 6 键、`youtube_transcription`、`ui_templates__browse`、
  `card_completed_score`、`error_format` 等。

### drawable 删除的正确判读

55 个 drawable 删除中含 `convert_to_math`/`fit_to_page`/`youtube`/
`insert_math`/`chevron_right`/`record_option`/`docscan`/`hamburger` 等
应用级图标——但同名字符串在 1.4.2 仍存。结论：图标从 XML drawable 迁往
Compose 代码内联向量（与 812 app_mark_path 字符串化、791 drawable 清理
同一趋势），**不是功能下线**。

## Harmony 侧核验

12 个代表性删除键反向检索全部正确缺席（Harmony 按 1.4.2 表面构建）；
主题标签以自有键保留等价语义。

## 交付物

- 证据：`docs/migration/evidence/phase-821-public-xml-removals.md`
- ADR：`docs/migration/adr/ADR-0765-public-xml-diff.md`
- Replay：`docs/migration/replays/d02-public-xml-diff.mjs`（11 项断言）

## 验证

- 新增 Replay：11/11 通过。
- 全量 Desktop Replay、双 HAP 构建随本 Phase 完成。

## 下一步

资源声明面闭合。候选轴：baseline.prof 热点方法级抽样、
obfuscated 字符串常量池残留、或 Room schema JSON（如有导出）。
