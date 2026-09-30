# Phase 1201 证据 — vle 编辑器依赖（pdf/ype/joe/wj8/yme）

来源：`defpackage/{pdf,ype,joe,wj8,yme,w7d,t76}.java`。

## `vle` 构造注入的 4 类依赖

```java
vle(pdf, ype, joe, a46, bool, nn6, in6, bool, wj8, el8)
```

## `pdf` = 文档/编辑会话服务

`{qoe a(undo 会话，Phase 1191), ps3 c, ov1 d, na3 e,f,
p6a g(MutableState)}` —— 编辑会话+状态。

## `ype`/`yme` = 工具/状态 MutableState 持有

```java
ype{yme a,b, p6a c/d/e/f, q21 g}
yme implements wrd,nsd:
  p6a I=new p6a(null,xme.f)   // 初值
  p6a J=new p6a(null,wme.g)
  c(xme,wme)→wpe; getValue/d()/e(psd)/f(psd)
```

`yme` = **Compose 可观测态持有者**（`p6a` 快照态封装，
`xme.f`/`wme.g` 默认值 —— 工具/颜色选择态）。

## `joe` = 编辑器态聚合

`{pdf a, ype b, k6f e, hi2 f, yla g, p6a r,s}` —— 聚合
document+tool+服务为编辑器态。

## `wj8` = 编辑事件 drop-oldest 通道

```java
wj8:
  v7d a = w7d.b(0, 16, w41.J, 1)   // Channel(0, extra16,
                                   //   DROP_OLDEST)
  a(t76,ef2) suspend / b(t76)→bool  // send/trySend
```

`w7d` = **kotlinx Channel 工厂**（`w41` BufferOverflow
SUSPEND/DROP_OLDEST，`v7d` channel impl，`ai1` conflate）
—— `wj8` = **背压丢弃编辑事件队列**（0 replay + 16
extra + DropOldest —— 输入事件合并/丢弃旧值）。

## 判定

编辑器依赖注入：`pdf`（文档会话+undo）+ `ype`/`yme`
（Compose 工具态）+ `joe`（聚合）+ `wj8`（drop-oldest
编辑通道 `t76`）—— 输入事件经 drop-oldest 背压合并
进编辑通道。

## Harmony 决策

- `p6a`/`yme` Compose 态 → Harmony `@Observed`/`@State`。
- `w7d`/`v7d` Channel+DropOldest → Harmony 事件队列
  （`@kit` 无 Channel —— 自研 drop-oldest 缓冲或
  `taskpool`/`Emitter`）。
- `wj8`/`t76` 编辑事件 → Harmony 编辑事件 sink。

## 产出

- fixture `d02-editor-deps.mjs`（10 断言）。
- ADR-1145；中文报告。
