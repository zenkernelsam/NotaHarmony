# ADR-0940 — `pa0` 资产引用包装族

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `pa0` = `{wa0 a()}` 资产→AssetMetadata 接口。
- 三 value-class：`cba(sw9)`PdfAsset、`cp5(dp5)`
  ImageAsset、`zjb(akb)`RecordingAsset。
- 提取器：`u0j.d`(MODIFY_PAGE→cba 链)、
  `kaj.a`(CREATE_RECORDING→zjb)；SET_METADATA/
  CREATE_PAGE 直链→nz9.l()→sw9→cba。
- `yk9` 用 `pa0.a().j()`(ua0 hash) 作清单去重键。
- `kaj.b` = kotlinx MissingFieldException 合并 helper。

## Harmony 决策

等价：包装 + 提取链 + hash 键去重。

## Parity 状态

等价。

## 验证

- `d02-asset-ref-wrappers.mjs`：12/12 通过。
