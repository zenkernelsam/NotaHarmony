# ADR-0626 「Add GIF」Klipy 联网挑选 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：659
- 接续：ADR-0624（Add Files 入既有笔记）、ADR-0625（多选导入）
- 证据：`docs/migration/evidence/original-add-gif-klipy-jadx-2026-09-24.md`

## 背景

原版插入菜单第 4 序位是 `add_gif`（`qc` 中 `function4 != null` 才
渲染），由 `ac4.k0 = ANIMATED_IMAGES` 特性旗标门控。选中流程：

`qb5` 打开挑选页 → `f65` 访问 `api.klipy.com`（**URL 内嵌厂商客户
密钥**，"Powered by Klipy"）→ `p55` GifItem 网格 → `re0` 下载
（`gif_*.gif` 临时文件，104857600B=100MB 上限）→ `je4` FileInfo →
`bgj.b` 落 `cz0.IMAGE` 元素（mime=image/gif）。

## 决定

1. **不实现 Klipy 挑选页**，登记结构性 fail-closed：
   - Klipy 是第三方付费 GIF 搜索 SaaS，HarmonyOS 无对应 SDK；
   - 原版密钥为厂商专属凭证，复制到本工程不可取（且服务端可吊销）；
   - 原版没有「本地 GIF 文件插入」替代路径——该菜单项即 Klipy 入口。
2. **菜单不渲染 add_gif**：原版本身以 `function4 != null` + 旗标
   控制显隐，Harmony 侧等价于「旗标关闭」状态——插入菜单其余四项
   序位不受影响。
3. **本地 .gif 文件**经 Add Files（P653/P657/P658）仍按 IMAGE 元素
   导入；GIF 动画帧表现（Harmony `Image` 组件原生支持动图）由渲染层
   后续单独评估，不在本阶段范围。
4. **登记随附差异**：100MB 下载上限、locale/per_page/q 查询参数、
   防重复点击等 Klipy 语义随服务缺失整体失效。

## 后果

- 插入菜单五项中 Files/Photo/TakePhoto/Math 对齐，Add GIF 显式
  关闭（与原版旗标关闭态一致）。
- 若未来获得自有 GIF 源（或 Klipy 推出 Harmony 集成），可按
  `p55 → re0 → bgj.b` 链路补实现——物化端（IMAGE 元素）无需改动。
