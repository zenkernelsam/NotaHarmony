# Phase 700：「YouTube Transcription」联网转录导入 fail-closed 登记

日期：2026-09-24
接续：Phase 699（文字色最近色行）

## 背景

P1 图片/工具面审计扫尾时定位到最后一个未登记的联网功能面：原版
编辑器工具行的 YouTube 转录条目（`feature_note__youtube_transcription`）。
与 Add GIF（Phase 659/ADR-0626）同型——旗标门控 + 外部服务依赖。

## 原版依据（decompiled_1.0.3）

- `ac4.O0` = `NOTE_YOUTUBE_TRANSCRIPTION` 旗标（序号 57）；
  `x90:10562` `lc4.a(ac4.O0)` 为真才渲染条目（`ke1(16)` 图标 +
  标签），回调 `function5`。
- `vdg`/`tzi` 对话框：`youtube_link_title` 标题、
  `youtube_url_placeholder` 输入框、`img.youtube.com/vi/{id}/
  hqdefault.jpg` 16:9 缩略图预览、`xai.b`/`n32(3)` Import 按钮。
- `ege` 确认：`dqb.I` 正则（`youtube.com/{watch?v=,/v/,/embed/}
  + youtu.be/` → 11 位 videoId）校验；失败 → `youtube_invalid_url`
  内联错误；成功 → `re0(vdg, videoId)` 协程。
- `udg`：`rdg.a` 经 `youtube.com/oembed` 公共端点取标题 →
  `id7.q` 将笔记改名为视频标题。
- `j55`：Apollo GraphQL `GetYoutubeTranscript(videoId,
  preferredLanguages)` → `track{languageCode,isGenerated,
  segments{text,start,duration}}` —— 走原版**私有 GraphQL 后端**。
- 转录分段物化为 `cz0.TEXT` 元素链（`cz0` 仅 TEXT/IMAGE/MATH）。
- `pw8` = WebView YouTube 播放器辅助面。
- 详见 `docs/migration/evidence/original-youtube-transcript-jadx-2026-09-24.md`。

## 决定（ADR-0651）

- **不实现 YouTube 转录导入**，登记结构性 fail-closed：核心转录
  `getYoutubeTranscript` 是原版私有后端的服务端解析器，非公开
  API；公开 YouTube Data API 需自有凭证且 captions 语义与原版
  自建转录管线不等价。
- 工具行不渲染条目 —— 等价原版旗标关闭态。
- 可移植子集（URL 正则/oembed 标题/缩略图）不单独落地：没有
  转录来源的对话框只剩空壳。
- 文档模型零影响：`cz0` 仅 TEXT/IMAGE/MATH，转录产物本是 TEXT
  元素链，导入路径不受影响。

## 验证

- 桌面回放：`d05-original-youtube-transcript-fail-closed.mjs`
  15 断言绿（原版旗标/对话框/正则/oembed/GraphQL/物化链路 +
  Harmony 无 youtube 表面）；
  全量套件见提交信息。
- HAP：`note@ohosTest` / `note@default` clean 构建通过
  （见提交信息）。

## 工具行外部依赖面最终状态

| 原版项 | 服务依赖 | Harmony 状态 |
|--------|----------|--------------|
| Add GIF（ac4.k0） | Klipy SaaS + 厂商密钥 | fail-closed（Phase 659） |
| YouTube 转录（ac4.O0） | 私有 GraphQL 后端 | **fail-closed（本阶段）** |
| POINTER/presence | 协作会话后端 | fail-closed（ADR-0644） |
| 其余工具行项 | — | 已对齐 |
