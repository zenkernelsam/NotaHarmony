# Phase 1226 证据 — ML Kit 客户端/AIDL 层

来源：`defpackage/{o23,m40,nqe,ng5,pfi,mc1,re,p4h,hhj,qyg,ztg}.java`。

## OCR 委托层

| 类 | 角色 |
|---|---|
| `o23 implements h38,jwi` | **`DecoupledTextDelegate`**（log 实名）——`Failed to init/run/create text recognizer` MlKitException 包装；`vm9(Context)`+`yhj("optional-module-text-latin","en")` 配置 |
| `o23` 模块加载 | `"Start loading thick OCR module."`/`thin OCR module.` —— **dynamite（GMS 运行时）↔ bundled（内置）双通道回退**；`DynamiteModule$LoadingException` 捕获 |
| `m40`/`nqe`/`ng5`/`pfi` | OCR 备选/错误包装（同 `MlKitException`+`TextRecognizer`） |

## 扫描客户端

| 类 | 角色 |
|---|---|
| `mc1 implements Function0` | **`GmsDocumentScannerImpl`**（log 实名）——`new Intent().setPackage("com.google.android.gms").setAction("com.google.android.gms.mlkit.ACTION_SCAN_DOCUMENT")` + `resolveActivity` 检查 → `GmsDocumentScanningDelegateActivity` 委托 |
| `re implements RemoteCall` | `IDocumentScannerService` AIDL 调用（`writeInterfaceToken("com.google.mlkit.vision.docscan.ui.aidls.IDocumentScannerService")`） |
| `p4h extends kig` | `IDocumentScannerCallbacks` AIDL stub（`attachInterface`） |

## AIDL stubs

- `hhj` = `ITextRecognizer`（`queryLocalInterface`）
- `qyg extends prg implements ryg` = `ITextRecognizerCreator`
  （`newTextRecognizer`/`newTextRecognizerWithOptions`）
- `ztg` = `VkpTextRecognizerOptions{configLabel=…}`（toString 实名）

## 判定

ML Kit 客户端 = **双层委托**：
- OCR：`DecoupledTextDelegate` 按 dynamite→bundled
  回退加载 latin 模型。
- 扫描：`GmsDocumentScannerImpl` 经 GMS 包内
  `ACTION_SCAN_DOCUMENT` Intent 委托给 GMS 扫描
  Activity —— **强 GMS 绑定**。

## Harmony 决策

OCR 可换 `@kit.VisionKit`（不依赖 GMS 委托通道）；
文档扫描的 GMS Intent/委托管线 **不可迁移** ——
fail-closed 或相机+OCR 自研（对齐 ADR-1169）。

## 产出

- fixture `d02-mlkit-clients.mjs`（10 断言）。
- ADR-1170；中文报告。
