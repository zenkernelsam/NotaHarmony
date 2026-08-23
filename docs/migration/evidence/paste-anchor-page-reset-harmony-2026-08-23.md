# 粘贴锚点跨页重置证据

证据时间：2026-08-23（Asia/Shanghai）

## 原版契约

`original-clipboard-transaction-anchor-jadx-2026-08-17.md` 记录：普通 Paste 的位置来自本次手势/命令的文档
坐标；`w43/v49` 把同一位置传入 Paste source 和 handler；页面边缘只 clamp，不改内部几何。Duplicate 的偏移
不能套用到普通 Paste。

## Harmony 缺口

`clipboardPasteTarget` 在每次 canvas touch down 更新，用于跨越 ArkUI context menu callback 的异步边界。
但页面切换只清理 selection 与系统剪贴板缓存，未清理该锚点。切换后若直接点击 Paste Image，旧页坐标会作为
新页插入中心。

## Phase 306 契约

1. 新页数据成功加载并绑定 `loadedPageId/currentPage` 后清空 `clipboardPasteTarget`；
2. 后续 Paste 必须等待新的长按锚点，或退回当前视口中心；
3. 不使用连续粘贴递增偏移；
4. 锚点生命周期不影响权限门禁、MIME probe、busy 串行化、页面 generation 守卫和失败反馈绑定。

## 边界

真实长按、菜单定位与切页时序仍需设备验收；本阶段仅做静态契约、Desktop Replay 和双 HAP 打包。未启动模拟器、
虚拟机、真机或 Hypium。
