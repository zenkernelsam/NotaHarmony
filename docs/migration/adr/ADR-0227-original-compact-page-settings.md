# ADR-0227：原版模板弹层的窄屏适配边界

## 状态

已接受（Phase 250，2026-08-16）。

## 决策

保留原版模板 picker 的状态与提交边界，只在 Harmony UI 适配层增加两项布局能力：

1. 编辑器 popup 使用有界纵向 `Scroll`；Settings 默认模板页继续由页面级 `Scroll` 承载。
2. 页管理栏在 `<720vp` 进入 compact，使用图标化设置入口和原生 overflow 菜单收纳低频页操作；所有
   常用动作保留至少 44vp 触控区。

面板内部使用流式宽度和 `layoutWeight`，最小宽度为 280vp，避免颜色/模板卡在手机上水平溢出。

## 原版依据与适配说明

`fci.java` 的模板卡组是纵向弹层内容，使用 48vp 触控行和 8vp 分区间距；`f2j.java`/`zci.java` 将其
组合为模板设置 UI。JADX 没有暴露本项目所需的 Harmony 手机断点，因此 `720vp`、`560vp` 属移植侧
可验证的布局预算，不是伪造的原版常量。纸张 draft、收藏、spacing 和模板卡提交仍完全复用
Phase 247–249 的原版逻辑。

## 验证

- `node docs/migration/replays/d02-original-compact-page-settings.mjs`：通过。
- `hvigorw --no-daemon assembleHap -p product=default`：`BUILD SUCCESSFUL`。
- 设备截图和 Hypium 尚未执行；真机验收列为 M2-U-02 的剩余门。
