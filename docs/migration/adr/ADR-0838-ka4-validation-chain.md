# ADR-0838 — `ka4` 校验契约 + `ddg` 校验链

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`）

- `ka4` = `String a()`：null=合法，非 null=错误消息
  （857 `ybg.c` 驱动 → ValidationException）。
- `ln2.a()`：pageCount≠0；nz9→ddg.g；PDF 时
  pageCount=sw9.pagesConsumed。
- `ddg.f(sw9)`：totalPageCount>0、pagesConsumed>0、
  cropBoxes 数=pagesConsumed、offset+consumed≤total、
  逐 cropBox k() 检查 → wa0 级联。
- `wa0.a()`：fileSize>0（无符号）、mimeType/fileName 非空。
- `ddg.g(nz9)`：PDF 需显式 size、边距≤页面、基向旋转
  {0,π/2,π,3π/2}、qed/k3a 级联。

## Harmony 决策

编码侧 throw 门 + 页面/PDF 创建检查逐条对齐规则集；
PDF 页数/裁切框一致性与资产非空校验保持。

## Parity 状态

等价（校验规则全链实名对齐）。

## 验证

- `d02-ka4-validation-chain.mjs`：19/19 通过。
- 全量 Replay 767 文件绿，见 Phase 894 提交。
