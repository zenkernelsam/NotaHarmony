# Phase 1017 证据 — nr1 同步引擎方法图

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## nr1 = 同步引擎核心（9 依赖）

```java
oq1 a;        // 上传 client（Phase 997）
nce b;        // synced-note store（979/984）
ssf c; qr1 d; jl3 e; sxa f; v2f g;   // 待钉
pce h; pce i;                        // 双时钟/服务
sfb j; k; l;  // 三 Room-invalidation Flow
em8 m; o;     // 双 Mutex
LinkedHashMap n;  // 待同步笔记集
asd p;
```

## 方法图

| 方法 | 角色 |
|---|---|
| `d()` → `kq1` | ClientOp DAO 访问器 |
| `e()` → `NoteBundleMetadataDatabase` | 元数据库 |
| `a()` | `zp1` 插入事务（Phase 999） |
| `b(ttf,ArrayList,ff2)` | **上传 ops**（suspend） |
| `g(ttf,ff2)` → `jq1` | per-note Room 查询 |
| `f(ff2)` → `dr1` | 同步 tick coroutine |
| `c(ff2)` | 三 Flow 收集循环 |
| `i(ff2)` | **761-inst 协程**（decompile 跳过） |
| `j(ff2)` | **8622-inst 巨型状态机**（decompile 跳过） |

## 关键发现

- `j()` = **主同步状态机**——8622 指令单元的
  suspend coroutine（JADX 反编译失败，stub）——
  上传/下载/冲突解决的完整调度在此。
- `i()` = 761 单元协程（同样 stub）。
- 两巨型协程是反编译极限；行为需从调用图+
  状态机常量+produce/consume 关系推断。

## HarmonyOS 决策

- 引擎逻辑重写为 ArkTS async 状态机；
  触发源=三 Flow（ClientOp/DraftNote/索引变化）
  +WorkManager 周期（Phase 1016）。
- `i`/`j` 的精确语义无法从字节码完全恢复——
  按上游（oq1/ko/nce API）+ 下游（Room 写）的
  可证契约重构，标注"部分推断"。

## 产出

- fixture `d02-sync-engine-map.mjs`（10 断言）。
- ADR-0961；中文报告。
