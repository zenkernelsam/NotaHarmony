# Phase 812 — 同名资源内容差(键值编辑层)

## 目的

此前各阶段的资源对比以"文件名/键名"为粒度(增删集)。本阶段补完
更深一层:**同名资源的内容差异** —— 同键不同值的文案编辑、
同路径不同字节的可绘制/配置文件。文件名级别的 diff 无法发现
这一层。

## 取证路径

- `decompiled_{1.0.3,1.4.2}/resources/res/` 全树 SHA-256 对比
- `values/strings.xml` 同键值对比

## 文件级内容差(同名文件,551 个共享路径)

20 个文件内容变化:

| 文件 | 性质 |
|---|---|
| `drawable{,-watch}/common_google_signin_btn_*` ×9 | GMS 登录按钮矢量(厂商,按钮样式微调) |
| `drawable/ic_launcher_monochrome.xml` | **单色主题图标重构**:840B 内联 pathData → 引用共享字符串 `ui_designsystem__app_mark_path`(349B)—— app 徽标路径收敛为单一事实源,同时驱动图标与其他界面 |
| `values/strings.xml` | 见下表 |
| `values/plurals.xml` | Phase 809 已登记 |
| `values/{attrs,colors,dimens,drawables,integers,public,styles}.xml` | Phase 809/810 已登记(裁剪) |
| `xml/core_remoteconfig__remote_config_defaults.xml` | Phase 802 已登记 |

## 键值级文案差(1396 个共享 string 键)

11 个键值变化:

| 键 | 1.0.3 → 1.4.2 | 性质 |
|---|---|---|
| `crashlytics.mapping_file_id` | 构建指纹 → 新指纹 | 构建元数据 |
| `crashlytics.version_control_info` | 构建信息 | 构建元数据 |
| `feature_library__copy_note_id` | "Copy note ID" → "Copy Note ID" | **文案:标题式大小写** |
| `feature_library__show_in_folder` | "Show in folder" → "Show in Folder" | **文案:标题式大小写** |
| `feature_note_toolbox__add_files` | "Add Files" → "From your files" | **文案:来源标注** |
| `feature_note_toolbox__add_gif` | "Add GIF" → "Giphy" | **文案:Giphy 署名**(GIF 选择器来源) |
| `feature_note_toolbox__add_photo` | "Add Photo" → "From your photos" | **文案:来源标注** |
| `feature_note_toolbox__insert_math` | "Insert Math" → "Math (LaTeX)" | **文案:格式消歧** |
| `feature_note_toolbox__take_photo` | "Take Photo" → "Take a photo" | **文案:句式** |
| `feature_paywall__error_purchase_billing_unavailable` | "Billing isn't available..." → "Google Play billing isn't available... 更详细说明 | **文案:错误详情**(GMS 面) |
| `ui_designsystem__theme_match_system` | "Match system" → "System" | **文案:精简** |

## Harmony 文案对齐(本阶段修复)

Harmony 移植了原版 1.0.3 时代文案的 3 个键,与 1.4.2 现值不一致,
已对齐:

| Harmony 键 | 旧值(1.0.3) | 新值(1.4.2) |
|---|---|---|
| `show_in_folder` | "Show in folder" | "Show in Folder" |
| `copy_note_id` | "Copy note ID" | "Copy Note ID" |
| `take_photo` | "Take Photo" | "Take a photo" |
| `insert_math` | "Math" | "Math (LaTeX)"(zh_CN "公式"→"公式 (LaTeX)") |

(注:`insert_math` 的 Harmony 旧值 "Math" 与两版原文案均不同;
按 1.4.2 消歧意图对齐为 "Math (LaTeX)"。)

## 登记差异(不修复)

- `add_files`/`insert_photo`/`insert_math` 菜单标签:Harmony 使用
  紧凑标签("Files"/"Photo"),原版的 "From your files/photos" 为
  来源标注式长文案 —— 登记为紧凑菜单适配(布局差异而非缺漏)。
- `add_gif` → "Giphy":GIF 选择器/Giphy 集成在 Harmony 未实现,
  fail-closed(Phase 789 已登记 GIF picker 面)。
- `theme_match_system`:Harmony 使用自有的更完整文案
  "Match system appearance",非同一表面字面移植 —— 登记差异。
- `billing_unavailable`:Google Play 计费文案,GMS 依赖 fail-closed。
- 2 个 crashlytics 构建元数据键:非用户可见,登记为构建指纹差异。

## 结论

同名资源内容差层闭合:20 个文件级变化中 19 个为厂商/已登记面,
1 个为单色图标单源重构;1396 个共享键中 11 个值变化(2 构建元数据
+9 文案编辑)。Harmony 侧 4 个文案已对齐 1.4.2,其余差异登记为
紧凑适配或 fail-closed。
