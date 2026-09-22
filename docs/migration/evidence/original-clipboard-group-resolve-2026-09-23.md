# 原版证据：复制/剪切的 Group 成员闭包解析（lg2.c）— Phase 614

来源：`decompiled_1.0.3/sources/defpackage/`（Notability 1.0.3 反编译，只读证据树）。

## lg2.g（lg2.java:107-168）— 复制负载组装

```java
Set setH = ktcVar.h();                       // 扁平元素 id 集
if (lc4.a(ac4.Q)) { ... jrh.a 过滤 → set }   // 剔除 positionLocked
else { set = setH; }
cmb cmbVarA = a(x09Var, set);                // 过滤后集合求 bounds
// iterableL0 = 选中的 cqc 组列表：
//   ftc → au1.T1(ftc.m)；gtc → 自身包 cqc；itc/etc → 空
for (cqc : iterableL0) arrayList2.add(cqc.b());   // 组 id 列表
for (groupId : arrayList2)
    c(set, linkedHashSet2, linkedHashSet3, x09, arrayList3, groupId);  // 递归解析
ArrayList ops = u5j.c(x09, T1(set) + arrayList3, …);  // 负载 = 过滤 id + 成功组 id
Set setX1 = X1(arrayList3);
for (cqc : iterableL0) if (setX1.contains(cqc.b())) arrayList5.add(cqc);
return new gg2(new cg2(ops, bounds, ktcVar, arrayList5), set);
```

- `h()` 扁平集天然包含组成员（`gtc.h()` 返回成员集 `b`，
  `gtc.f()` 返回 `qw3` 空集、`itc.f()/h()` 返回单元素集——
  `itc.java:19,35,45`、`gtc.java:56,90,105`）。
- `arrayList3` 只收**解析成功**的组 id；`arrayList5`（进 `cg2` 的
  组清单）随之只含成功组 → 粘贴时恢复组。

## lg2.c（lg2.java:51-105）— 递归组解析

```java
c(set, resolved, failed, x09, out, id):
  if (set.contains(id) || resolved.contains(id)) return true;
  if (failed.contains(id)) return false;
  h85 group = tl7.v(id, x09);
  if (group != null) {
      for (member : group.M())
          if (!c(set, resolved, failed, x09, out, member)) { z = false; break; }
      if (z) { resolved.add(id); out.add(id); return true; }
      failed.add(id); return false;          // 任—成员失败 → 整组失败
  } else if (tl7.I(x09, id, 6) == null) {
      log "member is neither a group nor a positionable";
  }
  return false;
```

语义：一个 `positionLocked` 成员被 `jrh.a` 从 `set` 剔除后，
`set.contains(member)` 为 false、该成员又不是组 → 返回 false →
**整组解析失败、组 id 不进 `arrayList3`/`arrayList5`**；但其余
未锁定成员仍在 `set` 中 → 作为散件照常复制/剪切，粘贴后不再成组。
嵌套子组经 `group.M()` 递归，同理传染失败。

## Harmony 差异与修复

旧实现：`clipboardSelectionWithoutLocked` 只过滤扁平 id；
`state.selectedGroupIds` 原样进 `prepareCopy`，
`copyOriginalGroupGraph` 对成员不在 `copiedLeafIds` 的组返回
null → `prepareCopy` 整个返回 null → COPY 不写剪贴板、
CUT 整单不执行。

Phase 614：`ClipboardSelectionIdSet` 增 `groupIds`；
`copyResolvableGroupIds` 按 `lg2.c` 语义递归（kept/resolved → true，
failed/visiting/非组/空成员 → false，成员全过 → resolved）；
COPY/CUT 改用 `kept.groupIds`。结果：含锁定成员的组仅弃组记录，
散件照常进负载，整单不再失败——与 `arrayList5` 语义一致。
DUPLICATE 仍走 `dhb` case4 原始 `ftc.q/m` 路径，不经此过滤。
