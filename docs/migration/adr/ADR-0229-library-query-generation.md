# ADR-0229：资料库查询状态使用统一 request generation 门禁

## 状态

已采用（2026-08-16）；设备快速输入、切页和真实数据库延迟仍待验收。

## 背景

原版 1.0.3 将搜索索引和资料库观察流分开，Room 查询结果由最新状态组合消费。Harmony 侧此前由多个回调分别
调用 `loadNotes`，只校验页面仍 active 和 ViewModel 引用；搜索、folder 切换、mutation 后 reload、初始化回填之间
没有共享的查询身份，迟到结果可能把旧列表发布到新查询。

## 决策

- 在 `LibraryPage` 内维护单调 `notesRequestGeneration`。
- 每个列表请求捕获 `query`、`folderId` 和 generation；发布、错误提示、缩略图刷新和 drawer 收起均先通过同一
  `isCurrentNotesRequest` 检查。
- 输入 debounce 在排队时即使旧请求失效；页面离开递增 generation，阻断跨生命周期回调。
- mutation 的提交结果仍由 ViewModel/仓储先确定；权威 reload 只是最佳努力观察，不得覆盖已提交的本地快照。

## 原版依据

- `decompiled_1.0.3/sources/defpackage/e47.java:356-360`
- `decompiled_1.0.3/sources/defpackage/sq1.java:51-68`
- `decompiled_1.0.3/sources/defpackage/vf6.java:39-47`
- `decompiled_1.0.3/sources/defpackage/d6c.java:70-123`

## 验证

- `d02-library-query-generation.mjs`：通过，输出 `D02_LIBRARY_QUERY_GENERATION_REPLAY_OK`。
- 原有 `d02-library-mutation-lifecycle.mjs`、`d02-library-note-mutation-order.mjs`、
  `d02-library-folder-commit-boundary.mjs`、`d02-thumbnail-cache-pair.mjs`：均通过。
- 全量桌面回放：`REPLAY_FILES=237 FAILED=0`；`git diff --check` 通过。
- `note@ohosTest` 与 `note@default` 均 `BUILD SUCCESSFUL`。
- 未启动设备、模拟器、虚拟机、真机或 Hypium。

## 后续影响

该 ADR 收敛 M2-U-04/M2-U-08 的页面级迟到查询边界，但不宣称完整搜索体验或设备验收完成；正文/手写 OCR、输入法
时序、长时间数据库故障与跨页面真实触控仍按总纲继续。

T-042 APK 版本追踪仍严格留到整个 Goal 最后一项；最终另写 Report，并将其入口和 decompile/diff 阅读顺序归纳进
Wiki、技术/API 文档与新手入门。
