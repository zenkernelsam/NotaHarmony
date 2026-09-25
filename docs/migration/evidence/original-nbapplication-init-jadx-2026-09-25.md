# 原版 NbApplication.onCreate 初始化链审计证据（JADX，decompiled_1.0.3）

证据日期：2026-09-25
证据来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\com\gingerlabs\notability\app\NbApplication.java`（226 行）

继 ADR-0679（清单属性）、ADR-0681（MainActivity 方法）之后，
本页关闭 Application 级启动面。`onCreate` 体（159-226 行）逐项对源。

## 逐项清单

| 初始化项 | 原版行为 | 性质 |
| --- | --- | --- |
| `StrictMode.setThreadPolicy/VmPolicy(LAX)` | 显式关闭 StrictMode（159-160 行） | 开发期诊断，无语义 |
| `uya.d` + `fwe` 守护线程 | `compareAndSet` 单次启动名为 **"ProcessFreezeDetector"** 的 daemon 线程（165-172 行） | 内部冻结看门狗（诊断） |
| `w51.a` pce | lazy 预热 | 内部 |
| `zb8.a()` / `tl.a()` / `hm.a()`/`gm` 流订阅 | DI 管理器初始 + 生命周期流订阅（173-178 行） | 见下「wya 生命周期总线」 |
| `j3e.a()` / `y79.a()` | DI 管理器初始（179-180 行） | 内部管线 |
| `qj2`：`ch4.b = r50` + `u50` 协程 | 静态回调装配 + 协程启动（181-184 行） | 内部服务定位 |
| `hv2`：`vv7.e = hv2.b` + `wya.N` 订阅 | 静态注入 + 进程生命周期订阅（185-189 行） | 生命周期消费者 |
| `kc4`：`lc4.f` + `trb.f` + `wya.N` 复合流 | 多流合流订阅（190-195 行） | 生命周期消费者 |
| `l3e.a()` / `g54` / `uv7` / `bga` / `df9` / `ecb` / `zkb` | 各管理器初始 + `wya.N`/`trb.f`/`fcb` 订阅（196-219 行） | 生命周期消费者 |
| `qp8.c(new cj(Process.myPid()))` | 注册 **"App Launch"** 事件（`cj.getName()="App Launch"`，PID 负载）（220 行） | 分析事件（边界） |
| `v98`/`mx7` 工厂表 + `rp8` 执行器池 ×4 | WorkManager `WorkerFactory` 映射：`ExportSweepWorker`→`r64`、`NoteAssetDownloadWorker`→`bn2`、`eb9` 组（142-156 行）；`rp8` executor ×4 | WorkManager 平台边界 + 已对齐清扫 |

## `wya` 进程生命周期总线

`defpackage/wya.java`：实现 `ye7`，`N = cf7(this, true)` 生命周期
注册表 + Handler；`I`/`J` 为 Activity start/stop 计数，
`K`/`L` 延迟标志 —— 即 AndroidX **ProcessLifecycleOwner**：
首个 Activity 前台→ON_START、末个退后→ON_STOP。

`ya0.s(wyaVar.N)` 被 `hm`/`hv2`/`kc4`/`g54`/`uv7`/`bga`/`ecb` 等
以 `je9`/`fv2`/`dx`/`km4` 流算子包装订阅 —— 全部消费者为
同步/上传/订阅刷新/分析等**后端侧反应式管线**，其用户可见面
（云同步、转写上传、计费）均已在既有 ADR 中 fail-closed 登记。

## Harmony 对应

- `NoteAbility.onForeground/onBackground` 钩子已存在（当前仅
  hilog）；因全部消费者属后端边界，**无便携订阅者**，不挂
  前台/后台分发。
- `StrictMode.LAX`、ProcessFreezeDetector、App Launch 事件：
  开发诊断/分析，无对应物需求。
- WorkManager 工位：`ExportSweepWorker` 语义已由
  `NoteExportTemporaryArtifactCleanup`（启动期清扫，Phase 735
  补全覆盖面）承担；`NoteAssetDownloadWorker`（云端资产下载）
  属同步后端边界。

## 涉及原版符号

`NbApplication.java`；`defpackage`: `uya` `fwe` `w51` `zb8` `tl`
`hm` `fm` `gm` `km4` `dx` `cq` `j3e` `y79` `qj2` `ch4` `r50`
`u50` `xj2` `hv2` `vv7` `wya` `cf7` `ya0` `fv2` `je9` `mh`
`kc4` `lc4` `trb` `sfb` `l3e` `g54` `uv7` `sv7` `bga` `fo4`
`df9` `lb9` `ecb` `a92` `fcb` `rt9` `y7b` `zkb` `d40` `t13`
`qp8` `cj` `v98` `mx7` `npb` `pdh` `sdh` `x30` `ac5` `bn2`
`eb9` `rp8` `g72` `u30`；Worker：`ExportSweepWorker`
`NoteAssetDownloadWorker`。

## 未验证声明

- 16 个 DI 管理器的具体职责仅可定位到「进程生命周期/事件流
  订阅者」粒度 —— 混淆名 + 无 named-package 引用；其消费面
  （同步/上传/分析/计费）均属已登记后端边界，未发现有独立
  用户可话语义未被覆盖。
- `g`（15min）常量归属周期工位，`f`（24h）属 g64 清扫 TTL。
