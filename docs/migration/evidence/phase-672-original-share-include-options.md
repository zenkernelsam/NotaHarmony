# Phase 672 证据 — 原版分享面板结构重排 + v6d.i/v6d.j 包含开关

日期：2026-09-24
前置：Phase 671（`59918648`）

## 原版证据（decompiled_1.0.3）

### 面板结构（dih.java / r6d.java / s6d.java）

- `dih` 是分享面板 Compose UI；主屏 `r6d.MAIN` 渲染
  **格式 chip 行 + 按格式切换的选项区 + Cancel/Share 动作行**，
  而非"点行即导出"。
- `s6d` 枚举五种格式：LINK / PDF / NOTE / JPG / PNG；
  chip 标签复用 `ui_share__chip_*` 键，Share 按钮用
  `ui_share__action_*`（`action_pdf`/`action_note`/…），
  Cancel 用 `ui_share__cancel`。
- 选项区按 `v6d.c`（选中格式 ordinal）分派：
  - `dih.h`（PDF）：`j6d` 双开关行（background + recording）
    + Page range 行 + Password 行（On/Off）。
  - `dih.d`（NOTE）：`j6d` recording 开关行。
  - `dih.a`（JPG/PNG）：`j6d` background 开关行 + Page range 行。
  - `dih.b`（LINK）：账号域权限开关（含
    `ui_share__link_*` 标签），无背景/录音开关。

### 包含开关（v6d.java / b7d.java / j6d.java / fw2.java / pj.java）

- `v6d.i` = `includeBackground`；`v6d.j` = `includeRecording`
  （`v6d.toString` 字段序确认）。
- 初值：`includeBackground=false`、`includeRecording=true`。
- `j6d` 把两个 Switch 分别经 `ix4` 回调绑到 `v6d.i`/`v6d.j`；
  `fw2` 渲染行图标与标签（模板图标→`ui_share__include_background`；
  麦克风图标→`ui_share__include_recording`）。
- `b7d.p(boolean)` 写入开关；导出侧消费 `v6d` 整体
  （`b7d.i` → `ml4.m`/`ya9.m` 操作流；zh9 协程不可完全反编译）。
- `pj` 导出分析事件字段确认语义：`includesRecordings` /
  `includesBackground` / `includesPageRange`。

### 字符串（strings.xml）

```
ui_share__chip_link / chip_pdf / chip_note / chip_jpg / chip_png
ui_share__action_pdf / action_note / action_jpg / action_png / action_link
ui_share__cancel
ui_share__include_background / include_recording
```

（多选分享另有 `chip_*_multi`/`action_*_multi` 变体，属多笔记分享
面，本期不涉及。）

## Harmony 落点

- `EditorToolbar.ets`：`shareFormat`（v6d.c 对应）+
  `shareIncludeBackground`（v6d.i，默认 false）+
  `shareIncludeRecording`（v6d.j，默认 true）；chip 行
  （link 置灰吞点）→ 按格式选项区 → Cancel/Share 动作行；
  `dispatchShare()` 统一分发。
- `ThumbnailRenderer.renderPageExport` 新增
  `exportBackground` 形参（'paper'|'white'|'transparent'）：
  includeBackground=false 时跳过纸面/PDF 背景，PDF 导出填白底
  （JPEG 无 alpha），JPG/PNG 导出填透明底（PNG 保留 alpha，
  JPEG packer 内部无 alpha 信息由 packer 填白）。
- `NoteExporter.exportToFile` 新增 `includeRecordings` 形参
  （默认 true）：false 时 .note 归档不写入录音资产，
  对应 `zk9.a->yk9.O` 原版旗标语义。
- `NotePage` 三回调签名带新旗标：
  `onShareNote(includeRecording)` /
  `onShareImage(format, pageIndexes, includeBackground)` /
  `onSharePdf(pageIndexes, password, includeBackground)`。

## 适配差异（fail-closed）

- LINK chip 置灰不可选（账号域链接分享无 Harmony 对应物，
  `dih.b` 权限行未迁移）。
- 原版 `includeBackground=false` 的 JPG 语义为"无页面背景"，
  Harmony 侧经 `exportBackground='transparent'/'white'` 实现；
  PDF 恒填白（内嵌 JPEG 无 alpha 通道）。
- 背景模式只作用于分享导出路径；页内缩略图与画布渲染不受影响。

## 验证

- `d05-original-share-include-options.mjs` 30/30。
- 全量 Desktop Replay 556/556。
- `note@ohosTest` + `note@default` clean 构建成功。
