# 原版 Partial Erase Group member replacement 证据（2026-08-15）

## 证据文件

- `decompiled_1.0.3/sources/defpackage/au1.java`
  - SHA-256 `B4DA5DB3C578DD38D308B38DCFCD87E12BB5CDE42CE3A875708825E2CA950E5B`
- `decompiled_1.0.3/sources/defpackage/fg2.java`
  - SHA-256 `058705B93D5610C83ACCA860166E4AA9350EC330836911A46BD156177D80001D`
- `decompiled_1.0.3/sources/defpackage/ss8.java`
  - SHA-256 `30898824A57C18F2BA217F7CE71D135DFE8E87616DD6149181F20E149428E92C`
- `decompiled_1.0.3/sources/defpackage/so5.java`
  - SHA-256 `BA88BD05E24494B42D1DF413DB22BBEAE9B96C609AD8518717666BA5C9737E96`
- JADX 无法直接恢复的 `wc.invoke()` fallback：`%TEMP%/nota-wc-fallback-20260815.java`
  - SHA-256 `17A0E86702415B5A4181F8F2B1E81E147AD23D3B6DA1DEDB3C60B58B97679895`

## 多父冲突取 operation identity 最大者

`wc` mode 3 扫描每个有效 Group 的 member。若同一 member 已有 parent，会用 `so5.a()` 比较
`timestamp`，相同再比较 unsigned `siteId`；仅当新 Group identity 更大时覆盖映射。因此 partial erase
只修改与 `OriginalGroupLayering` 相同的有效 parent：

```java
qo5 previous = (qo5) parentByMember.get(member);
if (previous == null || so5.a(previous, group.getId()) <= 0) {
    parentByMember.put(member, group.getId());
}
```

## member 顺序是 remove 后 append，并非原位替换

`fg2(..., 1)` 对与 source ID 相等的 member 返回 `true`。`au1.Y0(list, predicate, true)` 的实现会
原地压缩并删除所有 predicate 为 `true` 的条目；之后 `au1.O0(collection, iterable)` 直接执行
`addAll()`：

```java
au1.Y0(members, new fg2(sourceId, 1), true); // removeAll(sourceId)
au1.O0(members, remnantIds);                 // append all remnants
```

所以 `[A, source, B]` 替换为两个残片时，原版结果是 `[A, B, remnant0, remnant1]`，不是
`[A, remnant0, remnant1, B]`。页面 z-order 仍由每个新 Ink 继承 source z-index 处理，两种顺序不能混用。

## 空 Group 递归删除

`wc` 反复从受影响 Group map 中寻找第一个空 member list：

1. 从待发 `MODIFY_GROUP` map 移除该 Group；
2. 将 Group ID 加入额外删除列表；
3. 查找它的有效 parent；
4. 用 `ss8(entry, 18)` 从 parent members 删除空 Group ID；
5. parent 也变空时继续向上循环。

```java
entry = first affected entry whose members.isEmpty();
affected.remove(entry.getKey());
emptyGroups.add(entry.getKey());
parent = parentByMember.get(entry.getKey());
...
au1.Y0(parentMembers, new ss8(entry, 18), true);
```

剩余非空 affected Groups 才逐个通过 `u5j.p(...)` 发 `MODIFY_GROUP`；最后 `u5j.l(...)` 在一个
DELETE_ENTITIES 中删除 `sources + emptyGroups`。因此被删除空 Group 的 stored member register 不会先被
写成空数组，Undo 只需恢复其 visibility；仍存活的 affected Group 才需要在 Undo/Redo 时反向写
`MODIFY_GROUP`。

## 原版提交顺序

`wc` mode 3 的可观察顺序为：

1. 为每个几何残片发 `CREATE_INK` 并取得真实 operation ID；
2. 以真实 remnant IDs 计算并发出非空 Group 的 `MODIFY_GROUP`；
3. 一次删除 sources 与递归产生的 empty Groups；
4. `oqi.a(...)` 结束 transient interaction。

Harmony Phase 238 依此保持 `CREATE_INK → MODIFY_GROUP → DELETE_ENTITIES`，同时把 before/after
Group 状态加入专用 partial-erase history，以便本地与持久 Undo/Redo 对称恢复。
