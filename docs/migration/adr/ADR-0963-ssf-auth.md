# ADR-0963 — ssf 鉴权/会话服务

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `ssf` = nr1 鉴权门：4 ctor deps + `sfb e` 会话
  Flow + `b()→ml4` 状态暴露（ml4=interface）。
- `e`/`f`(String,String) suspend→`xrf.g(str,str,str)`
  鉴权端点；`d` 4-arg；`e`/`f` 反编译失败。

## Harmony 决策

**鉴权整体 fail-closed**（OAuth+服务端 token 不可
复现）；本地保留 `ml4`-形态状态 Flow 等价物。

## Parity 状态

fail-closed（后端依赖）。

## 验证

- `d02-ssf-auth.mjs`：10/10 通过。
