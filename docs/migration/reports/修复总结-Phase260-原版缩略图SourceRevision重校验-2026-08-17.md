# Phase 260 修复总结：原版缩略图 Source Revision 重校验

## 基线与目标

- 基线提交：`87fa003 fix(viewport): restore original zoom range`
- 目标：重放 `修复总纲2.md` 的 M2-R-06，严格参考原版 1.0.3 的 bitmap/onDiskOpId 配对和新鲜度门禁，
  修复 Library 在缩略图异步渲染期间把变化后的页面内容错配到旧 revision，以及失败时继续展示已知过期图的问题。
- 本阶段不启动设备、模拟器、虚拟机、真机或 Hypium。

## 现场重放结论

M2-R-06 的旧现场已经大幅过时，当前实现早已有：

- 主画布/缩略图共享 stroke、text、shape、image、math、tape、paper 与 PDF renderer；
- 3 个 worker 的并发限制和 64 项缓存上限；
- thumbnail generation、页面 lifecycle、renderer identity 门禁和 mutex 退役；
- page content/background/theme/asset generation cache identity；
- 被替换、页面退出和 renderer 内部临时 PixelMap 的释放路径。

本阶段没有重复实现这些结构，而是发现四个仍成立的竞态/所有权缺口：

1. Library 读取首页 revision 后，另一次异步加载元素/资产并渲染，发布前不重新读取 source。
2. 页面、首页或资产在渲染期间变化时，可能把混合内容 PixelMap 与旧 revision 成对缓存。
3. 渲染失败时旧代码无条件保留旧 bitmap，即使旧 revision 已落后于当前页面。
4. 若 `PixelMap.release()` 自身异步失败，部分未发布/被替换清理路径没有集中捕获。

## 原版证据

- `cn7` 的 `LocalThumbnailState` 同时持有 `bitmaps` 与 `onDiskOpIds` 两个 map。
- `if9` 是单篇笔记的 `NoteThumbnailData(bitmap, onDiskOpId)`。
- `h59` 用同一个 note identity 从两个 map 取值后构造同一个 `if9`。
- `m6j` 的 simple control-flow 证明 produced `onDiskOpId` 为空时无效；expected 非空且 produced 落后时无效；
  只有 validity 成立后才读取 bitmap，否则向 UI 传 null/占位。

原版普通 JADX 在 `m6j` 的 Compose 重复分支中产生了坏 null 表达式，因此本阶段没有照抄反编译出来的 Java
条件，而是结合 simple 跳转、字段读取与 `so5.a()` 比较调用恢复真实控制流。完整证据与 SHA-256 见
`docs/migration/evidence/original-thumbnail-source-revision-jadx-2026-08-17.md`。

## 实际修改

### 完整 source identity

`ThumbnailRenderPolicy.ets` 新增 `isThumbnailSourceUnchanged()`：要求 pageId 非空、pageId 相同且完整
thumbnail revision 精确相同。Harmony revision 已包含页面内容/纸张、主题颜色和 asset generation，不能对该拼接
字符串伪造原版 qo5 的大小比较。

### 两次有界 source attempt

Library 每次渲染现在执行：

```text
读取 source -> 渲染 -> 重读 source/asset generation -> 相同才发布
```

第一次发现 source 变化时，先释放未发布 PixelMap，再用最新 source 重试一次；第二次仍变化则不发布，等待后续
正常 refresh。这样既不会展示旧图，也不会在持续写入页面时形成无限 rerender loop。

### 失败与 lifecycle 门禁

每个 render/verification 后继续核对 thumbnail generation、lifecycle generation、pageActive 与 renderer identity。
异常时再次读取当前 source；只有旧 PixelMap revision 被证明仍与当前 source 完全相同才允许保留，否则从新缓存
省略该项并显示占位。旧的“只要有图就保留”行为已删除。

### PixelMap 所有权

新增集中异步 release helper，覆盖：

- generation/lifecycle 过期的未发布图；
- source 变化后准备重试的图；
- render/verification 异常路径；
- 整代结果被丢弃、cache replacement 与页面退出。

release 自身错误记录 warning，但不会阻止其余 cache/renderer 收口。

## Fixture / replay

- `ThumbnailRenderPolicy.test.ets` 新增相同 source、revision 变化、首页变化与空 page identity fixture。
- 新增 `d02-original-thumbnail-source-revalidation.mjs`，固定原版配对证据、两次 source 读取、有界重试、
  过期释放、失败隐藏和异步 release，结果 `TOTAL=18 FAILED=0`。
- `d02-thumbnail-cache-pair.mjs` 升级为 cache hit、新渲染 revalidation、source-change release 和失败保留门禁，
  结果 `TOTAL=5 FAILED=0`。
- `d02-image-thumbnail.mjs` 更新为新的 `sourceState.page` 调用契约；Library query/mutation、Paper、Image、PDF
  相关专项均通过。
- 全量桌面 replay：`REPLAY_FILES=245 FAILED=0`。

## 最终验证

- 修改中增量 `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 488 ms`。
- `hvigorw --no-daemon clean`：`BUILD SUCCESSFUL in 1 s 723 ms`。
- 同一次 clean 后 `note@ohosTest`：`BUILD SUCCESSFUL in 6 s 888 ms`。
- 同一次 clean 后 `note@default`：`BUILD SUCCESSFUL in 33 s 72 ms`。
- `git diff --check` 通过；构建仅有项目既有 ArkTS/deprecation 与未配置 signing warning。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## M2-R-06 状态与设备验收

M2-R-06 的共享 renderer、cache identity、并发、generation/lifecycle、source revalidation 与静态 PixelMap
所有权现已闭环；不再按旧总纲重复实现串行 renderer 或无 generation 的现场。仍需设备验证：

- 编辑首页后立即返回资料库，旧图不得闪回；
- 快速切 folder/search、同步和资产落地时占位/重试/最终图片稳定；
- 100 篇笔记滚动后的 PixelMap 数量、native/JS 内存峰值和 release 日志；
- 主画布与缩略图在 Paper/PDF/Image/Math/Tape/文本/形状组合下的像素一致性。

## Goal 纪律

T-042 APK 版本追踪仍严格留到整个 Goal 最后。本阶段只登记延后约束，不创建版本追踪目录、不重新反编译整包；
最终必须另写中文 Report，明确自行建立的追踪文档/工具、功能、入口和用法，再把新版 APK decompile/diff
流程归纳进 Wiki、技术文档、API 文档与新手入门。
