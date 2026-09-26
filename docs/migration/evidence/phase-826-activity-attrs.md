# Phase 826 — activity 属性级明细（launchMode/configChanges/软键盘）

证据来源：三版 `AndroidManifest.xml` `<activity>` 逐属性提取；
Harmony `module.json5` NoteAbility/NoteFormAbility 与 `NotePage.ets`
keepScreenOn 实现。

## 一、原版 6 个应用级 activity（三版本零差异）

| Activity | 关键属性 | 语义 |
|---|---|---|
| MainActivity | `configChanges=smallestScreenSize|screenSize|screenLayout|orientation|navigation|keyboardHidden|keyboard` + `windowSoftInputMode=adjustNothing` + `resizeableActivity=true` + `showWhenLocked=true` + `turnScreenOn=true` | 单 Activity Compose 宿主——全 configChanges 自承载旋转/导航/键盘变化；软键盘不做布局 resize（自绘视口）；可锁屏上显示/点亮屏幕（录音续录/课堂场景） |
| MissingNativeLibraryActivity | 无 | 原生库缺失兜底告警（800 登记，HAP 无对应场景） |
| AppleSignInActivity | `configChanges=screenSize|screenLayout|orientation|keyboardHidden` | Apple 登录中转（fail-closed 登录域） |
| MicrosoftSignInActivity | `launchMode=singleTop` + 同 configChanges | MSAL 登录回调去重（fail-closed） |
| NoteThumbnailConfigActivity | 无 | 缩略图 widget 配置页 |
| FolderNotesConfigActivity | 无 | 文件夹 widget 配置页 |

## 二、Harmony 等价判定

| 原版属性 | Harmony 对应 |
|---|---|
| 全量 configChanges | ArkUI 声明式重组合——配置变化天然不重建 Ability，等价成立 |
| `windowSoftInputMode=adjustNothing` | Harmony 默认键盘避让策略 + 笔记画布自绘视口；编辑器对 IME 高度自管理（`NotePage` 保持内容区自绘） |
| `resizeableActivity=true` | Harmony 多窗能力默认支持（分屏/自由窗系统级） |
| `showWhenLocked`/`turnScreenOn` | Harmony 侧**未设置**——原版录音中可锁屏上浮唤醒；登记为次要差异（Harmony 连续任务卡片经系统横幅通知承担锁屏可见性，见下） |
| `singleTop`（MSAL） | 登录域 fail-closed，无需等价 |
| widget ConfigActivity | Harmony `noteformability` 卡片配置页（FolderNotesEditPage/NoteThumbnailEditPage）等价 |
| keepScreenOn | Harmony `NotePage.keepScreenOnApplied` 编程式实现（原版由 FLAG_KEEP_SCREEN_ON/录制流程驱动） |

`showWhenLocked` 说明：原版该属性使录音通知/编辑页可越锁屏直达。
Harmony 连续任务在锁屏态经系统录音横幅可见可控，应用层页面不做
锁屏上显示——属平台交互范式差异而非功能缺失，登记即可。

## 三、skills/深链面（Harmony NoteAbility）

- `entity.system.home` + `ohos.want.action.home`：主入口。
- `viewData`/`sendData`/`sendMultipleData` + `file:`/`application/pdf`：
  PDF 查看/分享入站（对应原版 intent-filter，796 登记）。
- `entity.system.browsable` + notability.com `app/note` http/https 深链。

## 四、结论

activity 属性面闭合：6 个应用级 activity 三版零差；关键属性逐项映射
或登记差异（showWhenLocked 平台范式差异）。widget 配置 activity 与
登录中转 activity 均有等价或 fail-closed 归属。
