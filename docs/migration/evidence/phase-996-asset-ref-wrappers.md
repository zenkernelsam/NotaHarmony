# Phase 996 — `pa0` 资产引用族（cba/cp5/zjb）+ 提取器

来源：`decompiled_1.0.3/sources/defpackage/{pa0,cba,cp5,zjb,u0j,kaj,sw9,dp5,akb}.java`

## 1. `pa0` 接口

```java
interface pa0 { wa0 a(); }   // → AssetMetadata
```

## 2. 三个 value-class 包装

| 包装 | 内层 | a() | 语义 |
|------|------|-----|------|
| `cba` | sw9 | `sw9.m()` | **PdfAsset**（背景 PDF） |
| `cp5` | dp5 | `dp5.j()` | **ImageAsset**（块图片） |
| `zjb` | akb | `akb.j()` | **RecordingAsset**（录音） |

toString 实证名："PdfAsset(asset=…)"/"ImageAsset(…)"。

## 3. 提取器（yk9 清单链）

| op | 提取器 | 链 |
|----|--------|-----|
| SET_METADATA/CREATE_PAGE | 直链 | →m2d/l2d.j()→nz9.l()→sw9→`cba` |
| MODIFY_PAGE | `u0j.d(ge8)` | ge8.j()→nz9.j()...l()→sw9→`cba` |
| CREATE_BLOCK | 直链 | rl2.m()→dp5→`cp5` |
| CREATE_RECORDING | `kaj.a(yn2)` | yn2.l()→akb→`zjb` |

`yk9` 以 `pa0.a().j()`（=AssetMetadata.j()→ua0 hash）
作 `mx7` 清单键去重。

## 4. `kaj.b` = kotlinx MissingFieldException 构造器

（同文件混入的 kotlinx 序列化 helper——位掩码
diff→缺字段异常消息；与资产无关，记录防混淆。）

## 5. Harmony 对齐

等价：资产引用包装 + ua0 键清单。

## 6. 验证

`d02-asset-ref-wrappers.mjs` 静态断言。
