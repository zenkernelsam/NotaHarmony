# Phase 1102 证据 — via/wia/uia/tia/xia 实体-map 构建管线

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `via` = 抽象因果-map builder

```java
abstract class via {
  wia J;                    // 目标 store
  fm8 L;                    // mutex
  LinkedHashMap K;          // pending 写入
  vz a() {                  // 物化
    for (e : K) wia.b(longKey(e), b(e.value));
    return h(wia.a());
  }
  abstract Object b(Object v);  // 值变换
}
```

写挂 LinkedHashMap → `a()` 折进 `wia` → `h(snapshot)`。mutex 护并发物化。

## `wia` = 实体 store

```java
class wia {
  sia a;      // 空间索引（Phase 1081）
  er6 b; igf c;  // igf = long→vnd map
  Object a() → sia;         // 取索引快照
  Object b(long, obj);      // packed-long 键写入
}
```

## `uia extends vz implements Map,ik6` = 只读快照 Map

`vz` = mega-merge 只读 Map 基类；uia = v69 的实体 map 快照。
`tia extends via` = 具体 builder（`b(obj)` 直通值）。

## `xia extends fr5` = 游标 `{wia, long M, int N}`

## `lia extends w4 implements Collection,jk6` = 集合视图 `{kia,f16,lgf}`

## Harmony 决策

- builder = pending-LinkedHashMap + mutex + fold→store→snapshot。
- store = `sia` 索引 + `igf` packed-long map。
- 快照只读（bridge mutator 抛错）。

## 产出

- fixture `d02-mapbuilder.mjs`（10 断言）。
- ADR-1046；中文报告。
