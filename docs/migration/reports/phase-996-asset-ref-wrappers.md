# Phase 996 报告 — `pa0` 资产引用包装族

## 范围

pa0/cba/cp5/zjb/u0j.d/kaj.a + sw9/dp5/akb 访问器。
纯审计。

## 原版发现

- `pa0` = `{wa0 a()}` 统一资产引用接口。
- 三包装：cba=PdfAsset(sw9)、cp5=ImageAsset(dp5)、
  zjb=RecordingAsset(akb)——value class。
- 提取链：ModifyPage→u0j.d→cba；CreateRecording→
  kaj.a→zjb；背景/建页→nz9.l()→sw9→cba。
- `wa0.j()` = ua0 AssetHash（清单键）。

## 产出

- 证据：`phase-996-asset-ref-wrappers.md`
- Fixture：`d02-asset-ref-wrappers.mjs`（12/12）
- ADR-0940；全量 Replay 见本提交。
