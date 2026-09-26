# Phase 833 — Receiver/Widget 代码语义

## 范围

`com/gingerlabs/notability/app/` 下 receiver 与 widgets 包的
方法体审计（补 829 manifest 属性层的语义细节）。

## 原版发现

### AppUpgradeReceiver

MY_PACKAGE_REPLACED → `goAsync` + `zv` case 1 → `tid.b`
（androidx.profileinstaller）**重写 Baseline Profile**；
OverlappingFileLockException 跳过重写；AtomicBoolean 保证
PendingResult 恰好 finish 一次。语义更正：非缓存失效。

### Widget Provider（`aub` 接口族）

`RecentNotesWidgetProvider.g()` 产出 `hng` 模型：label +
`CREATE_NOTE` action + `VIEW`+`show_recent=true` target +
`f49Var.d.values()` 绑定集合。`show_recent` extra 的产生端
= widget 点击路由（827 清单闭环）。两 config activity
（Folder/Thumbnail）对应配置流。

### WidgetImageProvider

`openFile` 双路径类：`thumbnail/<noteId>`（`?f=` 自定义文件
校验属主后回退缩略图，48dp 圆角渲染）与 `text/<name>`；
未命中 FileNotFoundException fail-closed。

## Harmony 侧

formBindingData + openFormEditAbility 双配置页已等价；
图片授权 provider 由数据通道替代（模式差登记）；
baseline-profile 刷新无义务（系统 AOT）。

## 验证

- 新 Replay `d02-widget-receiver-code.mjs`：**15/15**（接收器
  5 断言、widget 模型 4、图片 provider 5、Harmony 编辑能力 1）。
- ADR-0777。
