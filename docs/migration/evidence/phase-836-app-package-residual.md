# Phase 836 — `app/` 包残余面闭合

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/app/`
（initializers/ + demo/ + widgets config）

## 一、androidx.startup Initializer 链（1.0.3 已存在，非新增）

```
LoggingInitializer
  dependencies() = [UserDataStoreInitializer,
                    ThemeDataStoreInitializer,
                    NoteEditorSettingsInitializer,
                    HapticPreferencesInitializer]   // 4 个 proto DataStore（819 清单）
AppStartupInitializer
  dependencies() = [LoggingInitializer]
```

`LoggingInitializer.create()` 装设自定义
`Thread.UncaughtExceptionHandler`：**吞掉 GMS 证书
SecurityException**（"Swallowed Play Services certificate
SecurityException" 带 thread.name 维度）——Google Play 证书
校验 bug 的已知规避；其余异常透传默认 handler。

## 二、Widget 配置 Activity（`a2k` 基类）

`a2k`（abstract，`le2` 子类）：`abstract int h()` 返回
**登录要求提示字符串 id**；`onCreate` 内登录门控（未登录
`finish()`）。

| 子类 | h() 返回 | 配置对象 |
|------|---------|---------|
| `FolderNotesConfigActivity`（15 行纯壳） | `widget_folder_picker_login_required` | 文件夹选择 |
| `NoteThumbnailConfigActivity`（309 行） | `widget_note_picker_login_required` | 笔记缩略图选择 |

`NoteThumbnailConfigActivity` 内含完整 picker sheet：
`widget_note_thumbnail_picker_title` / `widget_note_picker_search_hint` /
`widget_picker_no_notes` / `ui_folder__unfiled` 字符串面。

## 三、`app/demo/DemoResetWorker`

零售演示重置 Worker（823 已登记 worker 清单；本相位确认其
位于 `app/demo` 应用级包）。

## 四、Harmony 侧

- androidx.startup Initializer 依赖图：无等价物——Harmony
  初始化走 ability onCreate 顺序调用（828 已登记形态差）；
- LoggingInitializer 的 GMS 证书吞异常：GMS 不存在，
  无移植义务，登记；
- 登录门控 `a2k.h()`：Harmony 卡片配置页（openFormEditAbility）
  自行鉴权——模式差登记；
- picker sheet 字符串面：Harmony 卡片配置页已有等价文案
  （note/folder 选择器）。

## 五、结论

`app/` 包全面闭合：MainActivity（832）、NbApplication（828）、
ApiGated/AppUpgradeReceiver（829/833）、MissingNativeLibrary
Activity（800）、initializers×2 + demo worker + widget config
基类（本相位）全部归因。
