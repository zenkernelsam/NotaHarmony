# Phase 833 — Receiver/Widget 代码语义

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/app/` 下
`AppUpgradeReceiver.java`、`widgets/` 包

## 一、AppUpgradeReceiver（MY_PACKAGE_REPLACED）

```java
onReceive: if action==MY_PACKAGE_REPLACED
    a.execute(new zv(context, AtomicBoolean, goAsync(), 1))
// zv case 1:
tid.b(context, executor, cjl-callback, false)
// 并发锁守卫日志："Baseline profile write skipped;
// concurrent writer holds the lock"
```

**语义**：`tid.b` 为 androidx.profileinstaller 入口——自升级后
**重写 Baseline Profile**（dexopt 画像刷新），非缓存失效。
goAsync + AtomicBoolean 保证 PendingResult 恰好 finish 一次；
OverlappingFileLockException 时跳过重写。

## 二、Widget Provider（5 个，`aub` 接口统一）

`RecentNotesWidgetProvider.g()` 构建 `hng` 模型：

```java
label  = app_widgets__widget_recent_notes_label
action = ji3.H(context).setAction("android.intent.action.CREATE_NOTE")
target = ji3.H(context).setAction(VIEW).putExtra("show_recent", true)
data   = f49Var.d.values()          // 绑定的笔记集合
```

- `aub` 接口的 `c()/d()/e()` 返回尺寸规格字段（h/f/g）。
- `show_recent` extra 在此**产生**——827 清单的消费端=widget
  点击路由。
- 配套 config activity：`FolderNotesConfigActivity` +
  `NoteThumbnailConfigActivity`（配置页流）。

## 三、WidgetImageProvider（content:// 图片解析器）

`openFile(uri)` 两路径类：

| URI 形态 | 解析 |
|---------|------|
| `thumbnail/<noteId>` | `kom.O` 解析 noteId → `oei.c(id)` 缩略图；
  `?f=` 查询参数可指自定义文件（校验属主后回退缩略图）；最终经
  `kbn.c` 渲染为 **48dp 密度圆角位图**（dimen
  `app_widgets__widget_thumb_corner_radius`） |
| `text/<name>` | `ibn.i` 文本资产文件 |

未命中 → `FileNotFoundException`（fail-closed）。

## 四、Harmony 侧映射

- 升级 profile 重写：Harmony HAP 安装由系统 AOT/ark 编译管理，
  无应用级 profile 刷新义务——登记不移植。
- widget 数据模型：FormExtensionAbility + `formBindingData` 推送；
  `openFormEditAbility`（FOLDER_EDIT_ABILITY/THUMB_EDIT_ABILITY）
  对应原版两个 config activity——**已对齐**。
- WidgetImageProvider content:// 授权：Harmony 卡片图片经
  formProvider 数据通道推送位图，无进程间 URI 授权需求——
  模式差登记（827 已登记其 manifest 面，本相位补语义）。

## 五、结论

Receiver/widget/provider 三类的**代码语义层**闭合：升级接收器
= 基线画像重写（非缓存失效）；widget provider = `hng` 模型
（label+双 intent+绑定集合）；图片 provider = 双路径类
fail-closed 解析器。Harmony 卡片体系（804/本相位）已对齐
模型层。
