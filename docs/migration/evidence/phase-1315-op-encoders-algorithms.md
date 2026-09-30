# Phase 1315 证据 — op-payload 编码器 + 算法层

来源：`data/Original*PayloadEncoder` + `core/algorithm/`。

## `data/Original*PayloadEncoder` = 逐 op 线编码器

```
OriginalCreateBlockPayloadEncoder
OriginalCreateInkPayloadEncoder
OriginalCreatePagePayloadEncoder
OriginalCreateShapePayloadEncoder
OriginalDeleteEntitiesPayloadEncoder
OriginalAddPathElementsPayloadEncoder
OriginalClipboardPasteMutationCodec
NoteBackgroundMutationCodec /
NoteMetadataMutationCodec / NoteTitleMutationCodec
```

→ **每个原版 `haa` op 的 FlatBuffer payload 编码器**
—— 本地编辑→原版 op 线格式（与 `OriginalSynced
OperationFlatBuffer` 配套）—— 编码保真。

## `core/algorithm/` = 笔画算法

```
CubicFitter          贝塞尔拟合（stroke→cubic path）
ForceSmoother        压力平滑
PencilSplatGenerator 铅笔 splat 生成（mea/lea）
ShapeDetector        形状检测（直线/圆/…）
WidthOutlineBuilder  宽度轮廓（variable-width ink）
```

## 其他 data/

`NSKeyedArchiverDecoder`（iOS 归档）、`NoteExporter`/
`NotePackageSpec`、文件夹修复、Note/Folder 仓储、深链/
相机/剪贴板/拖放 ingress、各 `*MutationCodec`、
`OnboardingTooltipStore` 等 —— 数据层 157 文件。

## 语义

数据层 = **逐 op FlatBuffer 编码器**（本地编辑→原版
op）+ **笔画算法**（拟合/平滑/形状检测/轮廓）+ 仓储/
导入导出/ingress —— CRDT 编码+几何算法保真。

## Harmony 决策

逐 op payload 编码器保真线格式；笔画算法自实现
（CubicFitter/ForceSmoother/ShapeDetector）—— 编码+
算法语义保真。

## 产出

- fixture `d02-op-encoders.mjs`（10 断言）。
- ADR-1259；中文报告。
