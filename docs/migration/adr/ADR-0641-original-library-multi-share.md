# ADR-0641 — 原版多笔记分享（v6d.a + _multi 面板 + 多文件交付）

日期：2026-09-24
状态：已实施（5 项文档化适配；LINK 继续 fail-closed）

## 决策

交付 Phase 673 登记的 lc4-gated Share 图标：多选底栏增
Share 按钮 → `MultiShareSheet`（v6d.a=isMultiNote 形态）→
`multiShare()` 逐笔记产出文件 → `systemShare` 系统分享面板
一次交付（`ACTION_SEND_MULTIPLE` 等价物）。

面板（对齐 `dih` 多笔记形态）：

- chip 行：`s6d` 五格式的 `_multi` 标签
  （PDFs/Notes/JPGs/PNGs + LINK 置灰吞点）。
- 选项区按 `v6d.c` 分派且 **不含页范围行**（`dih.a`/`dih.h`
  的 `e()` composable 被 `v6d.a` 短路）：
  - PDF：include_background + include_recording 开关 +
    密码行（On/Off → 内联 draft+confirm+Save/Remove，
    kw1/kv1 语义）。
  - NOTE：include_recording 开关。
  - JPG/PNG：include_background 开关。
  - LINK：unavailable 文案，chip 不可选、Share 禁用。
- 默认格式 PDF（`b7d` 构造器 `list.size()>1 → PDF`）；
  `includeBackground=false`、`includeRecording=true`
  （`v6d` 构造器初值）；`v6d.k` 密码可空。
- Cancel + "Share Xs"（`action_*_multi` 标签）动作行。

分发（`multiShare()`）：

- `.note`：逐笔记 `exportNote(id, includeRecording)`。
- PDF：逐笔记全页 `renderPageExport` → JPEG → `buildPdf`；
  `v6d.k` 非空 → `encryptPdfFile` 逐 PDF 加密。
- JPG/PNG：逐笔记全页图像 → `page_NNN.<ext>` →
  `<title>_pages.zip`。
- `systemShare.SharedData` 多 `SharedRecord`（utd +
  `fileUri` URI + title）→ `getWant` → `startAbility`。

## 适配与差异

1. **交付机制**：FileProvider content URI +
   `ACTION_SEND_MULTIPLE` → `systemShare` 多
   `SharedRecord` + 系统分享面板（语义等价）。
2. **图像扇出**：原版逐页独立文件 → 每笔记整册
   `page_NNN.<ext>` zip（Phase 644 同构适配，避免
   N×M 条记录失控）。
3. **密码逐 PDF 复用**：与原版 `v6d.k` 施加于多 PDF
   的语义一致。
4. **临时文件**：`tempDir/multishare_*` 不主动删除，
   由系统 tempDir 生命周期接管（面板异步消费）。
5. **运行时风险**：`systemShare` 依赖
   `SystemCapability.Collaboration.SystemShare`；未做
   设备验证（按约束），缺失时 `getWant` 抛错 →
   `multi_share_failed` fail-closed。

## 验证

- `d02-original-library-multi-share.mjs`：38/38。
- 全量 Desktop Replay：559/559 绿。
- `note@ohosTest` / `note@default` 双 HAP clean 构建成功。
- 无模拟器/真机/Hypium（按约束）。
