# 原版本地页面重排 `MODIFY_PAGE` 出站：JADX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- 日期：2026-08-16

本证据回答本地页面拖动应生成什么原版 operation，以及为何不能只改 Harmony `page_index`。

## 1. 拖动结果保留“被拖页面”身份

`q0.java:482-490` 从 `DragPageResult.fromIndex` 取得页面的稳定 `cxc`，把该页面和
`DragPageResult.toIndex` 一并交给 `be2`：

```java
cxc cxcVar2 = ((pd2) ((qd2) ((gl8) obj2).getValue()).c().get(i11)).a;
...
new be2(de2Var, cxcVar2, i12, null, 0)
```

`be2.java:91-99` 等待当前模型后，以 singleton 页面列表调用 `u5j.s()`：

```java
u5j.s((x09) k1aVar.J,
  m18.l0(new tz9((cxc) obj2)), new Integer(this.K), null, null, 12)
```

因此一次单页拖动不是“比较两个最终数组后任选一个差异页”，而是明确携带被拖页面身份。相邻交换从
`before/after` 单独看可解释为移动任一侧页面；Harmony 必须由 UI 继续传递 `selectedPageId/action.pageId`。

## 2. 原版写的是 payload type 4 `MODIFY_PAGE`

`u5j.java:1141-1161` 用目标 index 查当前 sequence 位置，再构造 `SeqMove`，最后调用 `r0j.a()`：

```java
cxc cxcVarB = bfj.b(f1aVar.b, num.intValue(), f1aVar.h);
...
lxcVarA = egh.a(cxcVarB != null ? cxcVarB : null);
return r0j.a(list, lxcVarA, m2dVar, oz9Var);
```

`r0j.java:24-56` 证明 `ge8` 的 FlatBuffer 布局：

- field 0：12-byte `SeqId` 页面 vector；
- field 1：`lxc SeqMove`；
- field 2：可选页面 background；
- field 3：可选 bookmark。

单页拖动只携带 singleton pages 与 move，不应伪造 background/bookmark。

## 3. 移到根时仍必须保留 `SeqMove` table

`egh.java:21-30` 无条件创建一字段的 `lxc` table；只有 `cxcVar == null` 时省略 table 内 field 0：

```java
aVarA.C(1);
if (cxcVar != null) {
  aVarA.j(0, nti.X(cxcVar, aVarA));
}
aVarA.p(aVarA.n());
```

所以“移到根”不是省略 `ge8.field1`，而是 field 1 指向一个存在、但 `toId` 缺省的 `SeqMove` table。
省略整个 field 1 会被 reducer 解释为没有移动语义。

## 4. 移动生成新位置，winner 以页面稳定身份为 key

`v69.java:990-992` 把 `ge8.pages + operation ID + lxc.toId` 转为 `pvb Move`；`ko.java:1089-1103`
再把 move 作为 `twc InsertMany` 写入 sequence，并为每个页面产生新位置。`bl2` 保存
`Insert(opId, key=stablePageIdentity, value=newPosition)`；`al2.java:30-38` 以稳定页面身份为 key，只在新
operation ID 不小于旧 winner 时替换。

因此本地重排必须：

1. 保留被移动页的稳定 Page SeqId；
2. 以本次 operation ID 建立新 position；
3. 锚到当前位置树中的有效 position，而不是只改最终数组下标；
4. 将 losing/旧位置留在树中供后续 operation 继续引用。

Harmony 已有 `OriginalModifyPageOperationApplier` 完成该 reducer。本地 writer 应调用同一生产 reducer，并在
写出前后验证 `page_info` 与 CRDT visible order 精确等于请求顺序。

## 5. Harmony 最终顺序到原版锚点的安全映射

Harmony 当前页面菜单只做相邻移动，Undo/Redo 保存完整 before/after 和明确 `pageId`。本地 planner 先移除
该 `pageId`，要求其余页面顺序完全不变，从而证明请求是一页 relocation。目标页位于最终 index 0 时写
target-null `SeqMove`；否则使用最终顺序中前驱页的**当前 winning position**作为锚点。

该映射符合既有原版位置树物化规则：child move group 在锚点 position 后展开。生产 reducer 应用后还会再次
计算完整树；若结果与请求数组不完全一致，整个 SQLite transaction 回滚，不能降级成 Harmony-only 排序。

## 文件 SHA-256

- `q0.java`：`E5B4B3041CBADA93C9EC06746DB4BD5E05A7D88F5ACAF08ABF17EB072A33EECD`
- `be2.java`：`4A1249960CD0FBFB8BB7AD375D55892E8F0781860C671A13C1F632D85809F462`
- `u5j.java`：`F0A764366252292C01F11A10E7B69E0C3903428E44B7D97F84FC9CA8BF5675AC`
- `r0j.java`：`F1B9FA7027FAB3993965669578DE6E5CB13784399CD89CB7CDFA2E0342BA3CF6`
- `egh.java`：`46CF4E3BBD056A1F87CD74D821E48A2032FA33C71259BCB5E4F3182DB5302A77`
- `ge8.java`：`456A4979B451478648CCBE860AA6EB4C5D69ADE49B9680A970A612B69A79875E`
- `lxc.java`：`01652BDEE01D4ED2F270EE62553F0DE6024F08B7A5CE9A7F0B2C08D25A93A5FA`
- `v69.java`：`69A28ACDF6B65139405E3F22B2EF42AC3DC8FF4E3D8054438EC54B745FE315EF`
- `ko.java`：`06AF8ACADE3FCE3A957AE32D85C38F9E3CCE352EB73FC5B45175CA358B158A7B`
- `al2.java`：`09A0E06759FCB79F98142C7232FC8A46D808A5740AF93C94C19D47DBF435AF47`
- `bl2.java`：`38184C68148240047C4F91CBF415BA5F08EA7ACB03E3448B1A575CDEB7DD9ABC`

## 尚需设备验证

本阶段不启动设备、模拟器、虚拟机或 Hypium。真机需验证首位／末位移动、连续快速 Undo/Redo、同步后重开、
多端并发移动，以及页面缩略图选中态与实际页序一致。
