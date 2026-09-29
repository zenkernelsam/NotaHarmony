# Phase 1016 证据 — WorkManager 售卖 schema + worker 名册

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## Vendored 表（e47；androidx.work impl_db）

六表全 FK CASCADE→`WorkSpec`（库内部，无应用数据）：

| 表 | PK | 说明 |
|---|---|---|
| `WorkSpec` | id | ~30 列完整 spec（state/input/output/backoff/
  constraints/next_schedule_time_override/trace_tag/
  backoff_on_system_interruptions —— 对应
  WorkManager 2.9+ schema） |
| `WorkTag` | (tag,work_spec_id) | 标签索引 |
| `WorkName` | (name,work_spec_id) | 唯一名链 |
| `WorkProgress` | work_spec_id | progress BLOB |
| `SystemIdInfo` | (work_spec_id,generation) | JobScheduler id |
| `Dependency` | (work_spec_id,prerequisite_id) | 链依赖 |

## App worker 名册（decompiled 字符串）

| Worker | 职责 |
|---|---|
| `NoteOpsUpdaterWorker` | ClientOp 上传触发（nr1 的周期补充） |
| `ExtractionWorker` | 文本抽取→NoteIndexableChanges |
| `ExportSweepWorker` | 导出残留清扫 |
| `HandwritingPackDownloadWorker` | 手写语言包下载 |

## HarmonyOS 决策

- **WorkManager 六表不平移**——HarmonyOS 无
  WorkManager；以 `WORK_SCHEDULER`/`TASK_GROUP` +
  本地队列表替代（ADR 记）。
- worker 语义保留：ops 上传、抽取、导出清扫需
  Harmony 侧等价调度；手写语言包下载
  fail-closed（服务端资产分发）。

## 产出

- fixture `d02-workmanager-schema.mjs`（10 断言）。
- ADR-0960；中文报告。
