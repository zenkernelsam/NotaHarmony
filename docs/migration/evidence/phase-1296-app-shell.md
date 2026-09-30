# Phase 1296 证据 — app/ 壳（Hilt DI+Startup+原生回退）

来源：`app/{NbApplication,MainActivity,
MissingNativeLibraryActivity,AppUpgradeReceiver,
initializers/*}.java`。

## `NbApplication extends Application implements fed`

`fed`=Hilt `GeneratedComponentManager` iface；`x30 I`=
component manager；`a(Context)→igb`/`b()→id7`/`c()→g72`
= Hilt 注入器 —— **Dagger Hilt DI** 应用容器。

## `MainActivity extends r12`

`{boolean W, ConcurrentLinkedQueue X, long Y/Z}` + `r12`=
基 Activity + `uiState`(fv7 委托) —— Compose 单
Activity 壳。

## `MissingNativeLibraryActivity`

AlertDialog "missing native library" —— 原生 .so
（glmath/iink/…）加载失败的降级提示（不可取消）。

## `AppUpgradeReceiver` = `BroadcastReceiver`

包升级（MY_PACKAGE_REPLACED）→ `goAsync`+Executor
处理升级任务。

## `initializers/* implements g06`（AndroidX Startup
`Initializer<>`）

`AppStartupInitializer.create`→`NbApplication`+`is1.j0`；
`LoggingInitializer.create`→读 `backend_override`
SharedPreferences URL —— Startup 驱动的启动初始化链。

## 语义

**应用壳** —— Hilt DI 容器+Compose 单 Activity+Startup
Initializer 链+原生库缺失回退+升级 Receiver ——
启动引导+DI+容错架构。

## Harmony 决策

Hilt DI → Harmony 手动 DI/容器；Startup Initializer →
`EntryAbility.onCreate`+初始化链；原生缺失回退 →
`hilog`+提示 —— 应用壳语义映射。

## 产出

- fixture `d02-app-shell.mjs`（10 断言）。
- ADR-1240；中文报告。
