# Phase 828 — Application onCreate 初始化链

证据：`decompiled_1.4.2/sources/com/gingerlabs/notability/app/NbApplication.java`

## 一、进程分层（两行级差异）

`onCreate` 首段按进程名分叉：

```java
String processName = Application.getProcessName();
if (r0h.E0(processName, ':')) {          // 子进程（含 ':' 后缀）
    super.onCreate();
    if (ib5.a) {
        fb5.f(this);
        FirebaseCrashlytics.getInstance();   // 仅 Crashlytics + 进程名标记
        a.a.a(pb5.a);
        a.h(zg9.APP, "process", processName2);
    }
    return;                                 // 立即返回——不跑主初始化
}
```

**结论**：子进程（renderer/isolated/供 Provider 的 binder 进程）只初始化
Crashlytics；主进程才跑完整链。多层进程模型 —— 与 825 的
`process=":web"` 无关（本版 manifest 无显式 process 属性，子进程由
vendor SDK 自身声明）。

## 二、主进程初始化序列（按源码顺序）

| # | 初始化项 | 证据行 |
|---|---------|--------|
| 1 | `StrictMode.ThreadPolicy.LAX` + `VmPolicy.LAX`（**显式关闭** StrictMode） | 头两行 |
| 2 | `ProcessFreezeDetector` 守护线程启动（`zhd` CAS 单例，线程名 `"ProcessFreezeDetector"`） | `zci.setDaemon(true)` |
| 3 | `MobileMeasurement.start` Trace 段 + `a7a` 分析开关（`!a7aVar.b` 才启动） | `Trace.beginSection` |
| 4 | ~15 个 `o1l.r(...)` 子系统注册（obfuscated `b().X2.invoke()` = Metro/Dagger 组件 getter）：`b7a`/`tm`/`fn`/`r9h`/`vbb`/`ax2`/`qe3`/`x35`/`w9h`/`eth`/`ig1`/`ygh`/`fw4`/`eq9`/`avc`/`lme` | 主体 |
| 5 | `lme` 内网络客户端缓冲上限按设备分级：`41943040`(40MB)/`83886080`(80MB)（`l24Var.a` 低内存档） | `lme` 块 |
| 6 | `dob`/`s93`/`j6c`/`nae` 协程启动 | 尾部 |
| 7 | **BackgroundMaintenanceWorker** 唯一周期任务：周期 `43200000ms`(12h)、flex `14400000ms`(4h)+300s 抖动；`enqueueUniquePeriodic` | `z6kVar.h/i` |
| 8 | **StickerPackPrefetchWorker** 唯一任务：约束 `vu4.G`(CONNECTED)，`l6kVar2.d("StickerPackPrefetchWorker", ...)` | `x0c` 块 |
| 9 | `dma.d(new a40(Process.myPid()))` — 记录自身 PID 到崩溃上下文 | 末行 |

## 三、Harmony 侧映射

`note/src/main/ets/noteability/NoteAbility.ets` `onCreate`：

| 原版步骤 | Harmony 等价 | 状态 |
|---------|-------------|------|
| 子进程 minimal init | Harmony 无多进程应用模型 | 平台差，登记 |
| StrictMode LAX | 无对应概念 | 登记 |
| ProcessFreezeDetector | 无（HiAppEvent 系统级 ANR 检测替代） | 登记 |
| ~15 子系统注册 | 4 个 ingress enqueue + `ThemeStore.init()` + colorMode | 对齐（瘦身后） |
| 两个周期 Worker | Phase 823 已登记 fail-closed | 已登记 |
| PID 崩溃标记 | 无对应 | 登记 |

## 四、结论

原版 onCreate = **进程分层 + LAX 调试策略 + 冻结看门狗 + 15 子系统
延迟注册（`o1l.r` 是惰性 dispatcher）+ 两个 WorkManager 周期任务**。
Harmony 采用 ability 级轻量 onCreate + ingress 队列，重初始化下沉到
首帧/页面层——启动路径语义保留、形态收敛，差异全部登记。
