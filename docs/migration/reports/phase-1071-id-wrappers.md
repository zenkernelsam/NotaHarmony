# Phase 1071 报告 — id 联合 + 页 id 合成 + 门控

## 完成内容

- `u09` = {`o09`:qo5 实体 | `r09`:cxc 页} id 联合。
- `nti.g(qo5,i)` = `f(site,lt,seq)` → `cxc` —— CREATE_PAGE
  页 id 由 opId 坐标 + 页序确定派生。
- `yq9.a[25]=1` = DELETE_ENTITIES 门类门控。

## 产出

- evidence `phase-1071-id-wrappers.md`
- fixture `d02-id-wrappers.mjs`（10/10）
- ADR-1015
