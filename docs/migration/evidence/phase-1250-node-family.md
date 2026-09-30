# Phase 1250 证据（里程碑）— Modifier.Node 编辑器家族全景

来源：`defpackage` 编辑器 Node extends/implements 普查。

## Modifier.Node 能力树

| Node | base | ifaces | 职责 |
|------|------|--------|------|
| `vle` | n73 | lo3,cma,mvc,o65,ara,jm6,q52,rd8,sn9,kv6,mp4 | 主编辑 VM（11） |
| `k2`  | n73 | ara,jm6,mvc,vff,q52,sn9,pz5,b25 | 兄弟编辑（8） |
| `bq4` | n73 | mvc,o65,q52,sn9,vff | focus/事件 relay（5） |
| `gn3` | n73 | ara,pz5,q52,b25 | 手势 Node（4） |
| `eje` | n73 | q52,qie | IME/键盘 Node（2） |
| `u8e` | od8 | bra,r93,ara | pointerInput（3） |
| `ol3` | od8 | vff,pl3,kv6 | 拖拽分发（3） |
| `bk5` | od8 | ara | 触控事件 Node（1） |

## 结构

- **`n73`=DelegatingNode** 多 iface 控制器（vle/k2/bq4/
  eje/gn3 —— 组合多能力）;
- **`od8`=Modifier.Node** 单职责（u8e/ol3/bk5 —— 指针
  /拖拽/触控）;
- **`ara` 共享输入 iface**：`A(iqa,jqa,long)` —— vle/k2/
  gn3/u8e/bk5 都实现（指针输入分发链）;
- `vle`=主编（11 iface 全能力），其余=能力切片（focus/
  drag/gesture/IME/pointerInput/touch-emit）;
- `ty8.e` kind-bitmask → `xp4` 按 iface 遍历分发。

## 语义

编辑器 UI = Compose **Modifier.Node 树**：每 Node 一个
能力切片，`ara` 输入链 + `xp4` 遍历 + `wj8` 事件总线
—— 完整协作管线。

## Harmony 决策

Modifier.Node 树 → Harmony 组件装饰器/自定义 Node +
`onTouch` 链 + Emitter —— 节点树语义保真。

## 产出

- fixture `d02-node-family.mjs`（10 断言）。
- ADR-1194；中文报告。
