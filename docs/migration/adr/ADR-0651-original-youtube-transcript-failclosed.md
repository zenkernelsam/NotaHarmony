# ADR-0651 「YouTube Transcription」联网转录导入 fail-closed 登记

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：700
- 接续：ADR-0626（Add GIF/Klipy fail-closed）、ADR-0644（POINTER/
  ZOOM/view-only 旗标域 fail-closed）
- 证据：`docs/migration/evidence/original-youtube-transcript-jadx-2026-09-24.md`

## 背景

原版编辑器工具行在 `lc4.a(ac4.O0)`（`NOTE_YOUTUBE_TRANSCRIPTION`
旗标，ac4 序号 57）为真时渲染 YouTube 转录条目（`x90:10562` →
`ke1(16)` 图标 + `youtube_transcription` 标签）。完整链路：

`vdg`/`tzi` 对话框（URL 输入 + `img.youtube.com` 缩略图预览 +
Import 按钮）→ `ege` 以 `dqb.I` 正则校验并提取 videoId（不匹配
→ `youtube_invalid_url` 内联错误）→ `re0` 协程：`rdg` 经
YouTube oembed 公共端点取视频标题并 `id7.q` 改名笔记；`j55`
Apollo GraphQL `GetYoutubeTranscript` 经原版**私有后端**取转录
分段 → 物化为 `cz0.TEXT` 元素链。

## 决定

1. **不实现 YouTube 转录导入**，登记结构性 fail-closed：
   - 核心转录 `getYoutubeTranscript` 是原版私有 GraphQL 后端的
     服务端解析器，非公开 API，无法在本工程等价复制；
   - 公开 YouTube Data API 需要自有 OAuth/API key，且官方
     captions 接口与原版自建转录管线语义不等价（语言回退、
     自动生成轨道、分段 start/duration 对齐均不同）；
   - `pw8` WebView 播放器为转录预览辅助，不构成独立可移植功能。
2. **工具行不渲染条目**：原版本身以 `ac4.O0` 旗标控制显隐，
   Harmony 侧等价于「旗标关闭」状态——与其余工具行项无交互。
3. **可移植子集不单独落地**：URL 正则校验、oembed 标题、
   `img.youtube.com` 缩略图虽是公开端点，但没有转录来源的
   对话框只剩空壳，按 fail-closed 原则不渲染半残入口。
4. **文档模型零影响**：`cz0` 元素集仅 TEXT/IMAGE/MATH，转录产物
   本就是普通 TEXT 元素链——外部包/导入路径中的转录文本不受
   本登记影响。

## 后果

- 编辑器工具行不暴露 YouTube 条目（与原版旗标关闭态一致）。
- 若未来获得自有转录服务（或对齐公开 captions API 语义），可按
  `vdg → ege(dqb.I) → re0 → cz0.TEXT` 链路补实现——文档模型
  与插入端无需改动。
