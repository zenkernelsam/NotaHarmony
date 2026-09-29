# ADR-1015：实体/页 id 联合 + 页 id 合成

## 状态

已接受（Phase 1071）。

## 决策

- `u09` = sealed id 联合：`o09`(qo5 实体) | `r09`(cxc 页)。
- 页 id = `nti.g(opId,i)` = `{site,logicalTime,seq}` —— 由
  CREATE_PAGE opId 确定性派生。
- `yq9.a` 序位门类表门控 DELETE 枚举。

## 依据

`nti.g` → `f(c(),d(),i)`；`yq9.a[25]=1`。

## 后果

Harmony 页 id 按 opId+seq 派生（非随机 UUID）——保证
同 op 多页因果同根、回放一致。
