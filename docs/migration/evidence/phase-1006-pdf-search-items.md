# Phase 1006 证据 — PDF/资产搜索项生产（kw1 case 6）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `kw1`（wx4 合并 lambda，`I=5` 主判别符）

case 6 = **PDF 资产搜索项生成器**（kw1:361-397）：

```java
Map<Integer,?> map; List list; ttf noteId; ua0 assetHash;
Set set; Integer pageIdx; bx9 pdfText; LinkedHashMap<Integer,tz9>
cxc pagePos = map.get(pageIdx)?.a;              // 页面定位
String strE0 = aa6.E0(bx9, 50000) ?: "";         // PDF 文本截 5 万
String str5  = map.get(pageIdx) ?: "";           // 另一文本源（图片?）
合并规则：
  str6 空     → lvd.b1(50000, strE0)
  strE0 空    → lvd.b1(50000, str5)
  两者皆非空  → lvd.b1(50000, strE0) + "\n\n" +
               lvd.b1(49998-len, str5)
list.add(new wkc(ttfVar, me2.P /* PDF */,
                 ua0Var + "_" + pageIdx,          // subId
                 mergedText, z5c.Z(cxcVar), 32)); // pageId
```

- **subId = `{assetHash}_{pageIndex}`**（每资产分页）。
- **pageId = `z5c.Z(cxc)`** —— cxc 12B 定位 ID 的
  字符串形式。
- 文本合并：PDF 提取文本优先，另一源（OCR/图片
  文本）以 `\n\n` 追加并二次截断至 50000。
- `aa6.E0(bx9, 50000)` = bx9→String 提取+截断。
- `lvd.b1(n, s)` = 前 n 字符截断（`b1(length,...)`）。
- `tz9{a:cxc}` = 页位置表条目。

## me2.P 确认 = PDF

`new me2("PDF", 6)` → 字段序 I..P：P=6=PDF。

## 其余 kw1 case

case 0-5/7+ = Compose UI lambda（密码保存/测验解锁
字符串等）——合并类多用途，与搜索无关。

## HarmonyOS 决策

- PDF 文本提取平移 `@ohos.multimedia`/`hms` 或自带
  解析；`subId`/`pageId` 键格式、50000 上限、
  `\n\n` 合并规则等价保留。
- 截断语义：`lvd.b1` 前缀截断（UTF-16 code unit 计）。

## 产出

- fixture `d02-pdf-search-items.mjs`（10 断言）。
- ADR-0950；中文报告。
