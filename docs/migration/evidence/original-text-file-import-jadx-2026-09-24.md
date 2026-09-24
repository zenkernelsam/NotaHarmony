# 原版独立文本文件导入 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「Import File → .txt」链路的静态证据，
支撑 Phase 654。与 Phase 652/653 共用 `i58.c = */*` 选择器与
`yq8.f` 负载路由。

## 选择器与路由

- `i58.java:6`：`new i58("*/*")` —— 任意类型进入后按 MIME/内容分发。
- `nj3.java`：`txt` 是导入类型表中唯一的纯文本类型。
- `yq8.java:32-34`：`uu5Var instanceof tu5 → return dhj.p0`。
- `tu5.java`：仅 `String K`（解码后的文本）；`a()` 为空操作
  （无临时文件需清理 —— 临时文件已在 dv5 读取后立即删除）。

## dv5 默认分支：文本读取

`dv5.java`（约 85–115 行，switch default 分支）：

```java
zu5 zu5VarF2 = jv5.f(jv5Var2, uri2, drfVar2, ttfVarX2, null, 8);  // 复制到临时文件
File file2 = ((xu5) zu5VarF2).a;
String strX0 = tf4.x0(file2, ej1.a);        // UTF-8 全文读出
file2.delete();                              // 立即删临时文件
nj3 nj3Var2 = nj3.txt;
return new nv5(new tu5(
    new o88(ttfVarX2, nj3Var2, nj3Var2, drfVar2.a, 1, 32), strX0));
//                                       ^ 1 页
```

读取失败（IOException）→ 记 `Failed to read text file` 日志走失败路径。

## dhj.p0：空文件跳过 + te0

`dhj.java`（约 705–723 行，switch default 分支）：

```java
tu5 tu5Var = (tu5) uu5Var;
if (tu5Var.K.length() != 0) {
    return new te0(tu5Var, i3);           // 非空 → te0 op
}
a.e(..., "Empty text file, skipping import", null, ...);
return dca.c;                              // 空文件 → 无 op
```

## te0：建页 + INSERT_STRING

`te0.java`（variant a=1）：

```java
cxc cxcVarG = nti.g(xq9Var.a(new wq9(
    haj.a(cxcVar, null, 1, oz9.UNBOOKMARKED, 16), null, false, null, 30)), 0);
xq9Var.a(new wq9(kci.b(null, ((tu5) obj).K, null), null, false, null, 30));
```

1. `haj.a(...)`：与图片导入同一页面构造 —— `m09.b` 默认 Letter
   （612×792pt）页，`oz9.UNBOOKMARKED`。
2. `nti.g(..., 0)`：取寄存器位 0 的 `cxc` 位置。
3. `kci.b(null, text, null)`：构造 `f46` flatbuffer 文本实体
   （字段 6 = 字符串必填，`f46.a()` 校验「Cannot insert empty
   string」；`exc`/`qo5` 均为 null → 默认样式）。
4. `zq9.java:21`：`mx7Var.put(npbVar.b(f46.class), haa.INSERT_STRING)`
   —— f46 实体在 op 日志中为 `haa.INSERT_STRING((byte) 8)`；
   `nti.g(qo5,0)` 即 `INSERT_STRING` 落在 richtext 寄存器位 0
   （页文本流起始处）。

## Harmony 适配决策

1. **选择器**：`fileSuffixFilters` 追加 `.txt`（`nj3.txt` 是唯一
   纯文本类型）。
2. **分发**：`.txt` 后缀 → `importTextFromBytes`；UTF-8
   `TextDecoder` 解码（`tf4.x0(file, ej1.a)` 对齐）。
3. **空文件**：解码为空串 → 返回 `CORRUPTED` + 「空文本文件，未
   导入」（对齐原版 log + `dca.c` 无 op、零写库）。
4. **落库**：`importMutex` 内 `createNoteWithMeta` →
   `addImportedPage`（Letter 612×792pt→mm，PLAIN/PORTRAIT/
   `originalDefaultNoteBackground()`/bookmarked=false）→
   `saveElements`（单 TEXT 元素 zIndex=0）；异常 →
   `removeFailedImport`。
5. **文本块**：`buildImportedTextElement` —— `textOrigin {0,0}`、
   `blockWidth = 612pt`（页宽，页文本寄存器横向占满）、
   `blockHeight = max(40, lines×(fontSize+8)+insets)`（沿用
   `TextBlockTool.updateText` 行高规则）、BlockCommon 内边距
   5/3/5/10、fontSize 17、fontColor 黑、`corner/textWrap=0`、
   `enableCaption=false`、`resizesWidthToFitText=false`，
   bounds 经 `textBlockWorldBounds`。

## 已知差异（fail-closed / 记录项）

- **块几何**：原版 `te0` 不携带显式位置 —— INSERT_STRING 进页
  richtext 寄存器位 0，块几何由 cde 默认寄存器给出；Harmony 以
  「页顶 + 页宽 + 行高测量」物化等价呈现，行高公式沿用既有
  `updateText` 规则（近似原版行距，非逐像素等价）。
- **样式**：原版 `kci.b(null, text, null)` 全部默认样式；
  Harmony 用 BlockCommon 默认（insets 5/3/5/10、font 17、黑），
  与 `originalHandwritingConversionTextDraft` 同源。
- **临时文件**：原版先落临时文件再读再删；Harmony 直接从 picker
  URI 读字节，无临时文件生命周期（等价语义）。
