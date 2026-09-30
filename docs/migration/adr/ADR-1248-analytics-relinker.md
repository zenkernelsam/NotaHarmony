# ADR-1248：分析 SDK + ReLinker + Wire

## 状态

已接受（Phase 1304）。

## 决策

- ReLinker → Harmony `hilog`+fail-closed（无 ABI 重试）。
- Singular/Mixpanel → 归因/分析等价物或移除。
- Square Wire → ArkTS protobuf。

## 理由

`getkeepsafe/relinker`（MissingLibraryException → 原生
库缺失弹窗）+ `com/singular`（MMP 归因+延迟深链）+
`com/mixpanel`（分析）+ `squareup/wire`（protobuf）+`sso/`
（Google 凭据）—— 多提供商分析栈+原生加载容错。

## 后果

Harmony 分析 = 平台等价物；原生加载 → hilog+fail-
closed；Wire → ArkTS protobuf —— 分析/容错语义映射。
