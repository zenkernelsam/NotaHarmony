# Phase 1280 报告 — MyScript iink + Play 授权（里程碑）

## 完成内容

- **MyScript iink**（`com/myscript/iink` 94 文件）：
  `Engine`/`Editor`/`OffscreenEditor`/`ContentBlock`/
  `ContentPackage`/`IEditorListener` + graphics/text/
  util —— 手写→文本/数学/图形识别（商业 SDK+原生
  NativeUtils.loadLibrary）；
- **pairip**（`com/pairip` 8 文件）：`LicenseClient`/
  `LicenseActivity`/`LicenseResponseHelper`/
  `LicenseContentProvider`/`ILicenseV2ResultListener`/
  `RepeatedCheckMetadata` —— Play App Licensing/
  Integrity 反盗版。

## 产出

- evidence `phase-1280-vendor-sdks.md`
- fixture `d02-vendor-sdks.mjs`（10/10）
- ADR-1224（fail-closed）
