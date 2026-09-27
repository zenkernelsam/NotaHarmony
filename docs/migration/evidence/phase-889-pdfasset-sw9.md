# Phase 889 证据 — `sw9` = `PDFAsset` 布局表 + `zwd` 结构派发

## 目的

实名 `sw9`（nz9 字段1 的 PDF 布局）全部字段语义——
toString 实证（`decompiled_1.0.3`）。

## `sw9` = `PDFAsset`（toString 实证）

`PDFAsset(metadata=, layoutBehavior=, totalPageCount=,
pagesConsumed=, pageOffset=, cropBoxes=)`——`j7j.c` 写侧
`C(6)`：

| 字段 | 访问器 | 类型/默认 | 语义 |
|------|--------|-----------|------|
| 0 | `m()` | `wa0` 经 `k1j.c` | 资产元数据（PDF 字段表） |
| 1 | `l()` | `xw9.I` byte，默认 2 | **layoutBehavior**——缩放模式枚举（867：MAX_BOX/CROP_BOX/FIT 三值） |
| 2 | `p()` | int 默认 1（`mmf` 包装） | **totalPageCount** |
| 3 | `o()` | int 默认 1（`mmf` 包装） | **pagesConsumed** |
| 4 | `n()` | int 默认 0（`mmf` 包装） | **pageOffset** |
| 5 | `k()`/`j(qed,i)` | `D(8,iK,4)` 8B 结构向量 | **cropBoxes**：qed 裁切框数组（zwd.a 元素写器；负长→`Got negative length`+null） |

- `aVar.z(iN2,4)`+`z(iN2,14)` = 两槽必填标记。
- `mmf` 三处复用 = 页数/页序值类（与 ln2.pageCount 同型）。

## `zwd.a(xwd, a)` = 结构序列化派发

惰性注册表 `a.getValue()`：`npb.b(cls)` 取类键 → `wx4`
调用；未注册 → `rgc.b` 日志 + 抛（fail-closed，与 861
`ree` 表派发同构）。

## `lv2.v(sw9)` = cropBoxes 向量物化器（同 U 模式）。

## Harmony 侧

- `encodeOriginalPageBackgroundTableBlob`/PDF 布局槽 ↔
  PDFAsset 六字段；`xw9` 缩放模式 ↔ Harmony PDF 适配
  模式枚举（868 已对齐三值）。
- cropBoxes qed 向量 ↔ Harmony 裁切框编码；
  totalPageCount/pagesConsumed/pageOffset ↔ PDF 页面
  范围状态。

## 结论

PDFAsset 六字段全实名（资产+行为+页数×3+裁切框向量）；
zwd.a 结构派发 fail-closed 登记；sw9 是 nz9 内嵌子表
闭环的关键件。纯文档+fixture 阶段。
