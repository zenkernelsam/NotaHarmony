# Phase 1071 证据 — u09 id 联合 + nti.g 页 id 合成 + yq9.a 门控

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `u09` 实体/页 id 联合接口

```java
interface u09 { n09 a = n09.a; }   // 伴生
o09 implements u09 { qo5 b }       // 实体 id（opId）
r09 implements u09 { cxc b }       // 页 id（cxc）
```

- `o09` = 实体引用（包 `qo5`）；`r09` = 页引用（包 `cxc`）。
- `fsi.F` 返回 `List<u09>`（统一实体/页）。

## `nti.g(qo5, int i) → cxc`

```java
return f(qo5.c(), qo5.d(), i);
// = cxc{site, logicalTime, pageSeq:i}
```

**页 id = CREATE_PAGE opId 的 (site,logicalTime) + 页序号** ——
确定性派生：同 op 的多页共享因果根、按 i 区分。

## `yq9.a` = op 序位→门类 int 表

```java
int[] a = new int[haa.values().length];
a[25] = 1;   // DELETE_ENTITIES → 门类 1（G/H 门控）
a[0] = 2; a[6] = 3; ...
```

标准 `when` 序位表：`fsi.G/H` 仅在 `a[ordinal]==1` 生效。

## Harmony 决策

- `u09` = sealed {entity:qo5 | page:cxc} 联合 id。
- 页 id = `(site,logicalTime,seq)` 三元合成。

## 产出

- fixture `d02-id-wrappers.mjs`（10 断言）。
- ADR-1015；中文报告。
