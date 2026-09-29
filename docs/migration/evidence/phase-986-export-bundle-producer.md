# Phase 986 — `yk9` 导出/分享 NoteBundle 生产者 + `fsi.P` 过滤 + `haa` 全枚举

来源：`decompiled_1.0.3/sources/defpackage/{yk9,fsi,haa}.java`

## 1. `haa` = op 类型全枚举（0–31）

```text
0 NONE            8 INSERT_STRING   16 ADD_PATH_ELEMENTS   24 MODIFY_POSITIONS
1 SET_METADATA    9 REMOVE_CHAR     17 MODIFY_INK          25 DELETE_ENTITIES
2 ASSET_CLOUD_    10 REMOVE_CHARS   18 CREATE_SHAPE         26 TRANSIENT_INTERACTION_ENDED
  PERSISTED       11 REVIVE_CHARS   19 MODIFY_SHAPE         27 MODIFY_PDF_FIELD
3 CREATE_PAGE     12 MODIFY_STYLE   20 CREATE_GROUP        28 UPDATE_CHECKBOX
4 MODIFY_PAGE     13 MODIFY_PARA-   21 MODIFY_GROUP        29 PEER_INTERACTION
5 CREATE_RECORDING   GRAPH_STYLE    22 CREATE_BLOCK        30 CREATE_COMMENT
6 MODIFY_RECORDING 14 CLEAR_STYLE   23 MODIFY_BLOCK        31 MODIFY_COMMENT
7 INSERT_CHAR     15 CREATE_INK
```

## 2. `fsi.P(uq9)` = 导出过滤谓词

排除条件（返回 true=不导出）：
- `uq9.o() != null`（带 transientInteraction 字段的 op）
- `m().ordinal() == 26` TRANSIENT_INTERACTION_ENDED
- `m().ordinal() == 29` PEER_INTERACTION

其余序数 0–25,27,28,30,31 全部放行（default→o14.t）。

## 3. `yk9` = 导出生产者（merged wx4 某 case）

```java
ops = mia.filter(!fsi.P)                       // 去 transient
listK1 = au1.K1(ops, G1(k79(3),k79(4)))        // 双键排序
ny6 = 元素 provider(listK1.get)
a = dk4.a(c8d)                                  // 池化 builder
utf noteId = wtf.c(ttf);  utf legacyId? = wtf.c(ttfF)
a.p(q4j.c(a, noteId, legacyId, siteId s, userId B.toString(),
          createdAt jA, creatorId E.toString(), count, ny6))
ByteBuffer.wrap(a.A()).order(LE) → r29.d 复读 → ybg.c 校验
byte[] out = ree.b(r29)   // ★二次序列化为最终字节
```

**build→finish→复读→validate→ree.b 重序列化**双写模式。

## 4. 资产清单收集（同函数第二段）

逐 op 抽取资产引用建立 `ua0→asset` 映射 `mx7`：

| haa | 载荷路径 | 资产类型 |
|-----|---------|---------|
| 1 SET_METADATA | l2d→m2d SetPageBackground→nz9.l()→sw9 | `cba`(PDFAsset) |
| 3 CREATE_PAGE | ln2.j()→nz9.l()→sw9 | `cba`(PDFAsset) |
| 4 MODIFY_PAGE | ge8→u0j.d | `pa0` |
| 5 CREATE_RECORDING | yn2→kaj.a | `pa0`（条件 `z\|\|m!=CREATE_RECORDING`） |
| 22 CREATE_BLOCK | rl2.m()→dp5 | `cp5`(ImageAsset) |

`uq9.r(sdfVar)` 非空的 op 跳过——transient ops 不参与
资产收集。`O`（boolean 参数）控制是否含录音。

## 5. 语义

**分享/导出 `.note` 包**：生成 NoteBundle 字节 +
被引用资产清单（导出时打包 PDF/图片/录音资产）。

## 6. Harmony 对齐

等价：过滤 transient op、双键排序、写后复读校验、
资产清单随包导出。

## 7. 验证

`d02-export-bundle.mjs` 静态断言。
