# 原版页面元素身份与 Z-order 身份空间证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/vnd.java`：
  `06B9601160515A05EE55C8903C9F0A72E94CDBB742D5B239D8A3D353E46747CB`
- `sources/defpackage/zh9.java`：
  `A530078FADA4CBA2689A7FC5782282EC6D7FD4967704E246CDC993FAFD86FCB2`
- `sources/defpackage/ssc.java`：
  `5BA2C3546736E8B175B78475BB433FA57E43D070767506E53148BF484E3E0B04`

## 1. 元素包装对象的 equality/hashCode 只使用实体 ID

`vnd.java:80-91`：

```java
public final boolean equals(Object obj) {
    if (this == obj) {
        return true;
    }
    if (obj instanceof vnd) {
        return this.I.getId().equals(((vnd) obj).I.getId());
    }
    return false;
}

public final int hashCode() {
    return this.I.getId().hashCode();
}
```

`I` 可以承载 Ink、Block、Shape 等不同实体实现，但 equality 没有加入实体 kind、页面或 payload 类型。原版因此把
`getId()` 视为实体身份；kind 只决定如何解释 payload，不能让同一个 ID 在另一种实体类型上再次合法出现。

## 2. Z-order 收集同样用一个共享 ID key

`zh9.java:329-343` 从 selection/Group 可达实体收集 `vnd`，以 Group ID 或叶实体 `getId()` 作为同一个
`LinkedHashMap` key：

```java
LinkedHashMap linkedHashMap = new LinkedHashMap(iC0);
for (Object obj2 : arrayList) {
    vnd vndVar = (vnd) obj2;
    und undVar = vndVar.O;
    if (undVar == null || (id = undVar.a) == null) {
        id = vndVar.I.getId();
    }
    linkedHashMap.put(id, obj2);
}
```

这里没有 `(kind,id)` 或 `(page,id)` 复合 key。若两个页面实体共享 ID，后写实体会覆盖前一个 map entry，使层序、
selection 和 Group 物化失去一一对应。因此 Harmony 不能把数据库复合主键可容纳的行误认为两个合法实体。

## 3. ZIndexUnit 不携带 payload kind 身份

`ssc.java:4-13`：

```java
public final class ssc {
    public final qo5 a;    // id
    public final long b;   // z-index
    public final boolean c; // isGroup
}
```

`ssc` 只保留 ID、z-index 和 Group 标志；payload kind 不参与 identity。`isGroup` 是层序单元形态，不是允许
Group 与叶实体复用同一 ID 的命名空间。

## 移植结论

1. 一篇 note 内所有 live 页面元素共用一个 ID 身份空间；pageId 与 kind 都不是 identity 的组成部分。
2. 显式 element order 必须完整、连续、每个 ID 恰好出现一次，并且 order kind 与 payload kind 匹配。
3. 数据库 row 的 `element_id/kind` 必须与 payload 内嵌 ID/判别类型一致；损坏行不能静默跳过。
4. 旧数据库可能已经存在跨页/跨 kind 重复 ID，不能直接增加 note-wide UNIQUE index 令数据库初始化失败。
5. v64 采用 insert/update trigger 阻止所有未来 SQL 写入制造新冲突；普通保存和历史组在同一事务内提前查询其它
   live 页面，以更清晰地 fail closed；自有包和 Notability 导入在创建 note 前完成整包 note-wide ID 预检。
6. 已存在的损坏库保持可打开和诊断；读取整篇 note 或写入冲突页面会明确拒绝，不再把两个实体合并或丢弃其中一个。

## 验证边界

桌面 replay 可证明原版 ID-only equality/map key、v64 trigger 行为、旧损坏库安装 trigger、事务回滚、导入预检和
主要 repository 接线。保存重启、跨页 Undo/Redo、导出导入以及真实混合 Stroke/Text/Shape/Image/Math 层序像素仍需
设备/Hypium 验收。
