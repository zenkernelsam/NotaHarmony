# ADR-0611：分享面板页范围选择 — v6d.l 页集合的 Harmony 子集

- 阶段：Phase 644
- 状态：已实现（二选子集）；~~任意子集勾选登记为差异~~——已被
  Phase 670（`7a0bc882` 原版分享面板任意页子集选择）取代，
  `buildSharePagePicker` 缩略图栅格 + `sharePageIndexes` 集合落地。

## 背景

原版分享面板 VM `v6d` 持有 `Set l`（页选择集合）与 `int m`（总页数），
`b7d` 以 `set.size() != v6dVar2.m` 判定部分页导出 —— 上游
PDF/JPG/PNG 均支持任选页子集。Phase 642/643 落地栅格化导出时
（JPG/PNG 恒当前页、PDF 恒整册），页选择集合是最后一个未对齐的
面板能力。

## 决策

1. **二选子集**：面板顶部加「全部页面 / 当前页」切换
   （`@State shareAllPages`，默认 true 对齐上游全选默认），作用于
   PDF/JPG/PNG 行；NOTE 恒整册（.note 包语义不含页子集）、LINK
   置灰不参与。任意子集勾选需缩略图栅格面（`qd2`/`tfh` 那套
   多选 UI），属于已登记的大跨度差异，不在本 Phase。
2. **整册 JPG/PNG 打包 zip**：`DocumentViewPicker.save` 只回单个
   URI，无法对齐上游多文件 Intent 分发；逐页栅格打入
   `${title}_pages_*.zip`（`page_001.<ext>` STORE——JPEG/PNG 已编码，
   压缩无收益）是对用户最可用的单文件交付。
3. **PDF 当前页**：`allPages=false` 时页列表解析为
   `[pages[currentPageIndex]]`，得到合法单页 PDF，复用 Phase 643
   组装器零改动。
4. **单页图像路径不变**：`pages.length===1` 仍走
   `exportPageImage` 直存，不为 zip 包一层。

## 登记差异

1. ~~任意子集勾选（缩略图栅格面）未实现~~——已被 Phase 670 取代
   （缩略图栅格 + 任选页勾选，`share_range_selected` 计数文案）。
2. 多页图像交付为 zip 单文件，非多 URI Intent 分发。
3. LINK 行仍 fail-closed（账号后端）。

## 验证

- 新 fixture `d05-original-share-page-range.mjs`：23 断言（v6d.l/m、
  b7d 部分页判定证据 + 切换态/派发/zip 管线 pin）。
- `d05-original-share-page-image.mjs`、`d05-original-share-pdf.mjs`、
  `d05-original-editor-share.mjs` pin 更新（签名带 allPages）。
- 全量 Desktop Replay 529/529 绿；`note@ohosTest`/`note@default`
  clean 构建通过。
