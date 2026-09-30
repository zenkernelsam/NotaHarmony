# ADR-1104：全包树架构盘点

## 状态

已接受（Phase 1160 milestone）。

## 决策

`com.gingerlabs.notability` 分层：`app`(入口/widget)、
`core`(CRDT/FB/glmath/network)、`data`(12 Room 仓储)、
`domain`、`feature`(login+note-toolbox-audio)、
`ui`(fileimport/support)。

## 迁移边界

- `data/*` → `@ohos.data.relationalStore` 仓储 +
  后端 fail-closed。
- `feature/login`、`billing`/`subscription` → OAuth/支付
  fail-closed。
- `stylus`/`transcription`/`handwritingrecognition` →
  适配层 / iink fail-closed（ADR-1103）。

## 后果

Harmony 模块图按此分层；core 已映射完，data/feature/
ui 为剩余迁移面。
