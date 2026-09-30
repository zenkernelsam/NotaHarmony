# ADR-1170：ML Kit 客户端/AIDL 层

## 状态

已接受（Phase 1226）。

## 决策

- `o23` DecoupledTextDelegate（dynamite→bundled 回退
  latin OCR）→ Harmony `@kit.VisionKit`（无 GMS 委托）。
- `mc1` GmsDocumentScannerImpl（GMS 包 `ACTION_SCAN_DOCUMENT`
  Intent 委托）→ **fail-closed**（GMS 专属通道）或
  相机+OCR 自研。

## 理由

`o23` `DecoupledTextDelegate` log 实名 + thick/thin
模块回退 + `optional-module-text-latin`；`mc1` GMS 包
Intent + `resolveActivity` 门 + `re`/`p4h`/`hhj`/`qyg`
AIDL stubs + `ztg` VKP options —— 强 GMS 绑定。

## 后果

OCR 换 VisionKit 可行；文档扫描 GMS 委托 = 不可迁
边界（ADR-1169 收口）。
