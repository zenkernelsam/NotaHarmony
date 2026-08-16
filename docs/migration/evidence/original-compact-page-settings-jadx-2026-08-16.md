# 原版模板弹层与窄屏页面设置证据（2026-08-16）

## 范围

本证据用于 Phase 250（M2-U-02）的静态闭环。基准为
`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`，重点核对模板卡/纸张设置的
Compose 结构，以及 Harmony 移植侧在手机和窄平板上的可达性修补。

## 原版硬证据

- `sources/defpackage/fci.java` 构造模板卡组时先建立纵向容器；模板卡区域使用 `48.0f` 的触控行高，
  分区之间使用 `8.0f` 间距。`f2j.java`/`zci.java` 负责把卡组作为模板设置弹层内容组合起来。
- 原版状态明确分开纸张尺寸、方向、颜色/legacy、模板和 spacing（`sge/cge/bge`）；因此本阶段只改变
  容器布局，不改变 Phase 247–249 已恢复的 staged picker 与“点击模板卡才提交”语义。
- JADX 结果没有提供 Harmony 所需的手机断点数值；`720vp` compact 阈值和 `560vp` popup 最大高度是
  移植侧适配决策，证据等级为 🟡/⚠️，必须在设备截图中继续验收，不能伪称为原版常数。

## 移植侧修补

- `PageSettingsPanel` 新增 `popupMode`。编辑器页管理栏的 popup 使用独立纵向 `Scroll`，最大高度
  `560vp`；Settings 默认模板页继续使用自己的外层 `Scroll`，避免嵌套滚动争抢手势。
- 面板外宽下限从 `320vp` 降为 `280vp`，尺寸卡、legacy 色卡、模板卡和 spacing 子面板改为流式宽度/
  `layoutWeight`，不再用 `340vp`/固定卡宽把 280–320vp 手机内容推出屏幕。
- `PageManagerBar` 在 `<720vp` 进入 compact：设置改为 44vp 齿轮按钮，新增页和 overflow 均为 44vp
  触控区；前后移动、删除动作继续通过原生 `bindMenu` 可达。popup 调用显式传入 `popupMode: true`。

## 边界

本证据只证明静态结构与宽度预算；真实 ArkUI popup 定位、字体度量、滚动手感、横竖屏切换和
`360×800`/`600×960`/`1280×800` 截图仍需设备/Hypium 验收。
