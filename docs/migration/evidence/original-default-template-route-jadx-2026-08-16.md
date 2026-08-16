# 原版默认模板入口与编辑器纸张职责：JADX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- 日期：2026-08-16

本证据用于纠正 Phase 246 对默认纸张 UI 入口的初步理解，并区分设置页 `rge` 与编辑器模板弹窗 `vge`
各自可以修改的状态。

## 1. 默认模板是设置页的独立 `TemplateRoute`

`jge.java:16` 为 `kge` serializer 固定完整路由名：

```text
com.gingerlabs.notability.feature.settings.selectedcontent.noteeditor.navigation.TemplateRoute
```

`kge.toString()` 返回 `TemplateRoute`。`x90.java:344-345` 把 `kge.class` 注册进设置导航图；对应内容
`a1.java:41-46` 使用 `feature_settings__template` 标题并把 `vnh.a` 作为页面内容。`vnh.a` 最终经
`z22 case 23` 调用 `fcj.a()`。

因此原版入口是“Settings → Template”的独立设置内容，不是编辑器纸张弹窗中的“设为默认纸张”按钮。

## 2. `rge/fcj` 拥有默认模板偏好

`rge` 构造时从 `o3d.b.f()` 订阅 `noteEditorSettings.selectedDefaultTemplate`，再把结果与收藏集合、纸张
尺寸、方向、颜色及四类线型状态合成 `mge UiState`。`fcj` 暴露：

- `onSelectBackground`；
- `onFavoriteBackground`；
- `onUnfavoriteBackground`；
- `onUpdateSpacing`；
- 纸张尺寸、方向、纸张颜色及最大预览尺寸更新。

其中 `onSelectBackground → v43 case 0 → nge(..., case 1)` 会用当前草稿 `s3a` 与所选 `gq0` 组成
`l3a`，随后执行：

```java
o59Var.d(new ss8(o59Var, l3aVar2), continuation)
```

`ss8 case 7` 再把 `l3a.a(mask=7)` 编码为 root `nz9` 字节并写入 `o59.s`。这是默认模板唯一明确的 UI
保存链路。

## 3. `vge/xyd` 只修改当前笔记

编辑器模板弹窗使用另一套 `vge`。`xyd.java:128-195` 暴露与默认页平行的尺寸、方向、颜色、选择、收藏和
spacing 回调，但 `vge` 本身没有 `o59` 或 `selectedDefaultTemplate` 依赖。

`v43 case 5 → s49 case 15` 只把所选纸张组合写入 `vge.R`；`uge` 随后通过当前 note update flow 生成
背景 mutation。换言之，编辑器入口修改当前笔记背景，不拥有“更改以后新笔记默认纸张”的权限。

## 4. 尺寸和方向先暂存，选择模板卡才提交

设置页 `o1 case 11/12` 只修改 `rge.P` 中的 size/orientation；编辑器 `htd case 6/7` 同样只修改
`vge.S`。这两组回调都不会直接写偏好或 note operation。

真正提交发生在 `onSelectBackground`：它把草稿 paper state 与用户点选的 Plain/Lines/Grid/Dots 卡片组合。
所以原版交互不是“点尺寸后立即关闭弹窗并写入”，而是：

```text
选择尺寸/方向（草稿） → 点选模板卡 → 写默认偏好或当前笔记
```

Phase 247 因而为 Harmony 增加纯 picker state，并让设置页与编辑器共用该暂存语义。

## 5. 收藏与 spacing 是设置页和编辑器共享的数据库状态

`rge` 与 `vge` 都依赖 `rs0/dq0`，收藏/取消收藏分别经 `nge/tge → hge → ige` 访问 `BackgroundInfo`
数据库。`hge` 会避免重复插入，并按完整 `l3a` 比较收藏项。每类非 Plain 线型的 spacing 也由 `rs0`
独立维护。

Harmony 当前尚无这套 `BackgroundInfo` 收藏库，也没有四类线型各自的持久 spacing/完整颜色选择器。本阶段
只修正入口所有权、草稿提交顺序，并在同线型尺寸/方向变化时保留现有颜色、spacing 与 legacy index；跨线型
spacing 暂用原版内建 36 pt，收藏和颜色 UI 留作后续独立闭环，不能把它们误报为已经完成。

## 文件 SHA-256

- `jge.java`：`DF7634E59F4C93B6C0A00A0F16F7E191FF0D9956249ABE9AFDCBD01D19F89A7C`
- `kge.java`：`8AF9128DA3BF69A48B7F62B46A9518C9AA8D54348F6B0F66D21B1B3F911F9E2A`
- `x90.java`：`EF671A8F87957E4B332497A9E74DF7235FC50E910D7F4866559FE447948E1C91`
- `a1.java`：`43D450CCF9C4BBA95B25CC7EF4A0CEFE742796BCBC5827C7AC808B17B08AB670`
- `z22.java`：`A4D2DF6C2BAAD6A82D28A7CA445C21ACFC38111258988A805E9E2A3A53EE865C`
- `fcj.java`：`4A70AFF309E3DCF1C86ACF1203E0AF747D02005CEBC2F7505BDDD27D87055450`
- `rge.java`：`32669419AE3C1F2E1C111163BF98FB3FEEE8A6F2466C97E05EA8E7598C9FC942`
- `nge.java`：`83A8129E677BEF4D2B519947A5762D8E4B0D19A8C01108FE045F00DCB8785F5F`
- `vge.java`：`01B9B57DCC6FD5715BFBB4349DA484B4DAC1F2138208961DA593E607AF32A3BD`
- `xyd.java`：`7579A68E1C55B1DC94A9663FF0031E9EE75C600A8EC2E012A6308E0632CD8701`
- `hge.java`：`19E85AACBB4FC05E1F42142036010ADA0AD7A22A1DC35E13CD564E8E91291E95`
- `ige.java`：`2998094B3ABD04C2E36999E88C3BFEED4577B59F10AA46D9726C6F5F66A94960`
- `ss8.java`：`30898824A57C18F2BA217F7CE71D135DFE8E87616DD6149181F20E149428E92C`

## 设备边界

本阶段未启动设备、模拟器、虚拟机或 Hypium。真机仍需验证设置入口、返回/重进、尺寸方向暂存、模板卡提交、
保存失败回滚、编辑器弹窗不污染默认值，以及新建笔记确实消费刚保存的默认模板。
