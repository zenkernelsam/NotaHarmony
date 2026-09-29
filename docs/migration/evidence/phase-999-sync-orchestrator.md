# Phase 999 证据 — 同步编排器（nr1 / wq1 / q93 / pzb / ozb）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `q93` = SyncErrorType 枚举（32 行）

```
I="CREATE"(0)  J="APPEND"(1)  K="BUNDLE_DOWNLOAD"(2)
L="SYNC_DOWNLOAD"(3)
```

恰好对应四个端点：create / append / bundle / sync。

## `pzb`/`ozb` = Kotlin Result monad

- `pzb{Object I}` = `kotlin.Result`（内联类壳）；
  `a(obj)` = exceptionOrNull（`ozb→I`，否则 null）；
  `b(obj)` = Result.toString。
- `ozb{Throwable I}` = `Result.Failure` 承载体。
- 用法定式：`pzb.a(r)` 非空→失败；`Error`/
  `CancellationException` 重抛；余按失败处理。

## `wq1` = Dagger Provider

```java
final class wq1 implements ca4 /* extends t5b=Provider */
get(): new nr1(oq1, bk3, nce, ssf, qr1, jl3, sxa, v2f)
```

## `nr1` = 同步引擎（3417 行 mega-class）

### 构造依赖（`nr1(oq1,cx6,nce,ssf,qr1,jl3,sxa,v2f)`）

| 字段 | 类型 | 角色 |
|------|------|------|
| a | oq1 | 上传客户端（Phase 997） |
| b | nce | 同步笔记库（Phases 979/984/985） |
| c | ssf | — |
| d | qr1 | — |
| e | jl3 | — |
| f | sxa | — |
| g | v2f | 接口（时钟/配置） |
| h,i | pce | lazy |
| j | sfb | `ys2.r(db,[ClientOp])`→`cq.u0` 共享失效 Flow |
| k | sfb | 同上，watch `{"ClientOp","DraftNote"}` |
| l | sfb | `ap1(ys2.r(...ClientOp),1)` 变体 |
| m,o | em8←`fm8.a()` | Mutex ×2 |
| n | LinkedHashMap | 每 note 在途状态 |
| p | asd←`bsd.a(0)` | 计数信号量/dispatcher |

- `we2 we2VarA = s01.a(dh3.a)` = 协程作用域
  （`dh3` = CoroutineDispatcher 键）。
- `ys2.r(db, false, tables, λ)` = **Room
  InvalidationTracker→Flow**；`cq.u0(flow,scope,ord,1)`
  = `shareIn`（重放缓存 1）→ 表变更驱动同步循环。

### `nr1.a(ttf, Collection<uq9>)` — op→ClientOp

- 每 op `new zp1(ttf, uq9)` 实体；
- `l96.L0(db, false, true, q0 λ)` = Room
  `withTransaction` 批量插入（suspending）。

### `nr1.b(ttf, ArrayList<File>)` — WAL 消费

- `cm8 o` Mutex 串行化；逐 File 处理（`fr1` 读路径）
  后 `File.delete()`；`t2f.a(j)` 计时。

## 闭环全貌（Phases 981-999）

```
编辑产生 uq9 op
  → nr1.a: zp1→Room ClientOp 表 (+WAL 双写 ky)
  → InvalidationTracker Flow (j/k/l) 触发
  → nr1.b: fr1 读 WAL → 收集 ops
  → oq1.b: aa6.r0→vt9→d8d→wqf.a/b 上传
  → q89 acks → SyncedOpMetadata 更新
  ↓ 下行
  → ko.n/o: GET sync/bundle → ko.B→qud
  → uhj.n/uae/lv2.T 物化 → obe tx → .ops/.offsets
  → 模型 lgf/mia/z5c.x 应用
```

## HarmonyOS 决策

- `nr1` 编排逻辑可平移：`@ohos.data.relationalStore`
  的 dataChange 事件 ≈ InvalidationTracker Flow；
  Mutex/Signal 原语 ArkTS 有等价物。
- 网络端点仍 fail-closed（无服务器）。

## 产出

- fixture `d02-sync-orchestrator.mjs`（16 断言）。
- ADR-0943；中文报告。
