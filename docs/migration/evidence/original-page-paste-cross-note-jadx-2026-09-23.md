# 原版页粘贴跨笔记资产链接 — jadx 证据（2026-09-23）

阶段：Phase 639。结论：原版页剪贴板 op 流无笔记绑定，跨笔记粘贴为原版
语义；Harmony 侧资产链接写入已存在于 CREATE_BLOCK / CREATE_PAGE 应用器，
Phase 636 的 fail-closed 闸门系过度保守，本 Phase 移除。

## 原版证据（decompiled_1.0.3）

### 剪贴板记录无笔记绑定

`defpackage/mg2.java`（全文）：

```java
public final class mg2 {
    public cg2 a;
    public dg2 b;   // 页剪贴板槽位
}
```

`defpackage/dg2.java`：

```java
public final class dg2 {
    public final ArrayList a;   // ops
    public final int b;         // pageCount
    // toString: CopiedPagesData(ops=..., pageCount=...)
}
```

`dg2` 只携带 op 流与页数——没有 noteId、没有文档句柄。`ae2` 变体 2
（Copy）把 `u5j.e(x09, list)` 序列化结果写入 `mg2Var.b`；Paste 经
`lg2`/`m1d.c0` 把该 op 流应用到**当前打开笔记**的 x09 文档。op 流中的
CREATE_BLOCK/CROUP/CreatePage 身份在应用时经转码重发，资产以哈希引用。

### Paste 菜单门控

`de2.java:54`：`bsd.a(...)` 读取 `mg2Var.b != null` —— 唯一门控是
剪贴板非空，无"同笔记"条件。

## Harmony 侧链接写入证据

| 资产种类 | 写入点 | 行为 |
|----------|--------|------|
| 图片元素 | `OriginalCreateBlockOperation.ets` `applyPayload` → `mergeImageAssetReference` | 既有资产行 `mergeNoteIds(row.noteIds, [noteId])`，保留 `local_path`；无行则插 PENDING 行 |
| PDF 背景 | `OriginalCreatePageOperation.ets` `mergePdfAsset` → `mergeOriginalAssetReference` | 同上，合并 `note_ids` 入目标笔记 |
| 资产字节 | `ImageAssetPackageStore` `filesRoot/assets/final/<sha512>` | 全局内容寻址，不按笔记分桶 |

计划校验 `validateOriginalDuplicatePageContentPlan` 仅校验身份格式与
可编码性；`readOriginalClipboardSourceZIndex` 对目标笔记查无此元素返回
`undefined`，空页 `maximumZIndex === null` 守卫放行。

## 结论

跨笔记粘贴含图页 / 含 PDF 背景页在 Harmony 按构造即可一致完成；
`paste_page_unsupported` 闸门与字符串移除，`canPasteCopiedPage` 回到
原版单一门控（剪贴板非空）。
