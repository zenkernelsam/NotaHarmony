# ADR-1145：编辑器依赖注入（pdf/ype/joe/wj8）

## 状态

已接受（Phase 1201）。

## 决策

- `pdf` 文档会话（含 `qoe` undo）+ `ype`/`yme` Compose
  工具态 `p6a` + `joe` 聚合 + `wj8` `w7d.b(0,16,
  DropOldest)` 编辑事件通道 → Harmony `@Observed`/
  `@State` 态 + drop-oldest 事件缓冲。
- `wj8`/`v7d` Channel+BufferOverflow → Harmony 自研
  事件队列（无 Channel —— `taskpool`/`Emitter`）。

## 理由

`pdf{qoe,ov1,na3×2,p6a}` + `yme implements wrd,nsd{p6a×2}` +
`joe{pdf,ype,k6f,hi2,yla}` + `wj8{v7d=w7d.b(0,16,w41.J)}`。

## 后果

Harmony editor 依赖 = 文档服务 + @Observed 工具态 +
聚合 + drop-oldest 编辑事件缓冲 —— 输入背压合并对齐。
