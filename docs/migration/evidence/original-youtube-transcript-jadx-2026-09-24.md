# 原版「YouTube Transcription」联网转录导入 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「工具行 YouTube 转录入口 → URL 校验
对话框 → GraphQL 转录 → TEXT 元素插入 + 笔记改名」链路的静态证据，
支撑 Phase 700 的结构性 fail-closed 登记。

## 入口与旗标

- `x90.java:10562`：`lc4.a(ac4.O0)` 为真才渲染 `cq.c`
  （`o22(new ke1(16))` = `feature_note__youtube` 图标 +
  `feature_note__youtube_transcription` 标签的条目），回调为
  `function5`。
- `ac4.java:203`：`O0 = new ac4("NOTE_YOUTUBE_TRANSCRIPTION", 57,
  zb4Var3, null, gc4.J)` —— **特性旗标门控**，与 `ac4.k0`
  （ANIMATED_IMAGES/Add GIF）同型。

## 对话框与 URL 校验

- `tzi` = 转录对话框 composable：`vdg` ViewModel（`tdg` 状态
  {a=busy, b=videoId, c=errorRes, d} 驱动），标题
  `feature_note__youtube_link_title`，URL 输入框占位
  `feature_note__youtube_url_placeholder`（`l32`），Import 按钮
  `xai.b`/`n32(3)` = `feature_note__youtube_import`。
- 视频已解析时渲染预览：`tzi.d` 拼
  `https://img.youtube.com/vi/{id}/hqdefault.jpg`（16:9 缩略图）。
- `ege` 确认分支：`dqb.I` 正则
  `(?:youtube\.com/(?:[^/]+/.+/|(?:v|e(?:mbed)?)/|.*[?&]v=)|youtu\.be/)([^"&?/\s]{11})`
  提取 videoId；不匹配 → `vdg.i(R.string.feature_note__youtube_invalid_url)`
  内联错误（`tdg.c` 错误资源），匹配 →
  `xj2.A(vdg.h(), null, null, new re0(vdgVar, str3, ...))` 进协程。

## 转录获取（私有后端）

- `udg` case 0：`rdg.a(videoId)` →
  `https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={id}&format=json`
  取视频标题 → `id7.q(ttf, title)` **将笔记改名为视频标题**。
- `j55` = Apollo GraphQL operation（`z6b`/`ft9`）：
  `query GetYoutubeTranscript($videoId: String!, $preferredLanguages:
  [String!])` → `getYoutubeTranscript(youtubeTranscriptParams:{videoId,
  preferredLanguages})` 返回 `track{languageCode,isGenerated,
  segments{text,start,duration}}` —— 走原版**私有 GraphQL 后端**
  （`id7`/`ttf` 传输层），非公开 API。
- `re0(vdg, videoId)` 协程：GraphQL 转录 → 分段物化为 `cz0.TEXT`
  元素链插入笔记（`cz0` 元素集仅 TEXT/IMAGE/MATH，无视频元素）。
- `pw8`：`getWebViewYouTubePlayer` WebView 播放器表面（转录流程
  的预览/回放辅助，不入文档模型）。
- 错误文案：`youtube_insert_failed` / `youtube_empty_transcript` /
  `youtube_error_unknown` / `youtube_invalid_url`。

## Harmony 现状

- `note/src/main/ets` 无任何 youtube/youtu 表面或字符串；
  编辑器工具行无对应条目（等价旗标关闭态）。
- `.note` 导入：`cz0` 仅 TEXT/IMAGE/MATH，外部包若含转录文本按
  普通 TEXT 元素处理，无附加依赖。

## 结论

YouTube Transcription = **旗标门控的联网转录导入**：URL 校验 +
oembed 标题为公开端点可移植，但核心转录依赖原版私有 GraphQL
后端（Notability 服务端 `getYoutubeTranscript` 解析器），
Harmony 侧无法等价复制；公开 YouTube Data API 需要自有 API key
且语义（官方 caption API 与原版自建转录管线）不等价。登记结构性
fail-closed（ADR-0651）。
