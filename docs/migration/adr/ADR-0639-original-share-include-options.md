# ADR-0639 — 原版分享面板格式 chip + 分格式选项 + v6d.i/v6d.j 包含开关

日期：2026-09-24
状态：已实施（含 3 项文档化适配；多笔记分享/LINK 继续登记）

## 决策

把分享面板从"格式行点选即导出"重排为原版的三段式结构
（`dih`）：格式 chip 行（`shareFormat`，对应 `v6d.c`）→
按选中格式渲染选项区（`dih.h`/`d`/`a`/`b` 分派）→
Cancel/Share 动作行；`dispatchShare()` 按 `shareFormat`
统一分发。选项区携带原版包含开关：
`shareIncludeBackground`（v6d.i，默认 false）与
`shareIncludeRecording`（v6d.j，默认 true）。

分格式选项矩阵（对齐 `dih` 分派）：

- PDF：Page range + Include background + Include recording
  + Password（`dih.h` 全集）。
- NOTE：Include recording（`dih.d`）。
- JPG/PNG：Page range + Include background（`dih.a`）。
- LINK：chip 置灰不可选（`dih.b` 账号域权限行不迁移）。

导出侧：`onShareNote(includeRecording)`、
`onShareImage(format, pageIndexes, includeBackground)`、
`onSharePdf(pageIndexes, password, includeBackground)`；
`ThumbnailRenderer.renderPageExport` 增 `exportBackground`
（'paper'|'white'|'transparent'）；`NoteExporter.exportToFile`
增 `includeRecordings`（默认 true，Library/Backup 调用点
行为不变）。

## 证据锚点

`dih.java`（h=PDF 选项/d=NOTE/a=JPG·PNG/b=LINK 分派 +
chip 行 + Cancel/Share 动作）、`s6d.java`（五格式枚举 +
action/chip 标签键）、`v6d.java`（`i`/`j` 字段 +
toString 字段序 + 初值 false/true）、`j6d.java`（Switch↔
`v6d.i`/`v6d.j` 绑定）、`fw2.java`（include 行图标+标签）、
`pj.java`（includesRecordings/includesBackground/
includesPageRange 分析字段）、`strings.xml`
（ui_share__chip_*/action_*/cancel/include_*）。
详见 `docs/migration/evidence/phase-672-original-share-include-options.md`。

## 适配差异（fail-closed / 文档化）

1. LINK 格式 chip 置灰吞点——账号域链接分享在 Harmony 无
   对应物，`dih.b` 权限开关组不迁移。
2. `includeBackground=false` 的落地：PDF 填白底（内嵌 JPEG
   无 alpha）；JPG/PNG 走 `exportBackground='transparent'`
   （PNG 保 alpha；JPEG packer 输出无透明通道）。
3. `includeRecordings=false` 时 .note 归档不含录音资产——
   原版 `zk9.a->yk9.O` 旗标等价；默认 true 保持既有导出
   调用点（Library/Backup）语义。

## 验证

- `d05-original-share-include-options.mjs` 30/30；
  六份存量分享 fixture 全部更新通过。
- 全量 Desktop Replay 556/556。
- `note@ohosTest` + `note@default` clean 构建成功。
