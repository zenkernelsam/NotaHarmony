# Phase 806 证据：依赖版本升档清单（META-INF .version 内容 diff）

日期：2026-09-23
输入：`decompiled_{1.0.3,1.4.2}/` 全部 `*.version` 文件（文件名清单
Phase 798 已收口；本 Phase 解析文件内容得到版本号级 delta）

## 1. 总量

- 有内容的 version 文件：1.0.3 = 129，1.4.2 = 130（+1 为
  `androidx.ink_ink-storage`，Phase 798 已登记）
- 版本号变更：66 项；其余 63 项持平；无版本回降（transition
  1.6.0→1.5.0 为版本体系换算差异，见下）

## 2. 主要升档组

| 组 | 1.0.3 → 1.4.2 | 备注 |
|----|---------------|------|
| Compose 全家桶（ui/animation/foundation/runtime/material-ripple/saveable/retain/ui-text/ui-geometry/ui-graphics/ui-unit/ui-util/ui-tooling-preview/foundation-layout 共 13 模块） | **1.11.2 → 1.12.0** | BOM 跟车发布线 |
| M3 Adaptive（adaptive/adaptive-layout/adaptive-navigation/navigation3 4 模块） | 1.3.0-alpha09 → **1.3.0** | alpha→stable 毕业 |
| Lifecycle 全家桶（livedata*/process/runtime*/service/viewmodel*/savedstate 共 13 模块） | 2.11.0-beta02 → **2.11.0** | beta→stable 毕业 |
| Ink 引擎（authoring/brush/geometry/nativeloader/rendering/strokes 6 模块 + storage 新增） | 1.1.0-alpha04 → **1.1.0-alpha07** | 笔刷引擎随 776/778 面演进 |
| Navigation3 runtime/ui | 1.1.0 → 1.1.7 | 修补级 |
| Navigation（common/compose/fragment/runtime-ktx/runtime） | 2.9.7 → 2.10.0 | |
| Coroutines（android/core/guava/play_services） | 1.10.2 → 1.11.0 | |
| core/core-ktx | 1.18.0 → 1.19.0 | |
| appcompat/appcompat-resources | 1.7.1 → 1.8.0 | |
| savedstate（3 模块） | 1.4.0 → 1.5.0 | |
| navigationevent（2 模块） | 1.0.2 → 1.1.2 | |
| tracing/tracing-ktx | 1.3.0 → 2.0.1 | 大版本 |
| customview | 1.1.0 → 1.2.0 | |
| graphics-path | 1.0.1 → 1.1.0 | |
| constraintlayout | 2.2.1 → 2.2.2 | |
| material（com.google.android） | 1.13.0 → 1.14.0 | |
| transition | 1.6.0 → 1.5.0 | 版本体系换算 |

## 3. 持平的关键件

- `androidx.room_room-runtime` **2.8.4 → 2.8.4**——Phase 767 的表增量
  为应用 schema 变化，非 Room 库升级。
- GMS/Firebase/ML Kit/PDFTron/MyScript 等供应商件版本号不在 .version
  表面（由 Gradle 元数据决定，APK 不携带）——以 Phase 794/798 的
  库清单为准。

## 4. 迁移含义

- 全部升档为 AndroidX/KotlinX 框架件，对 Harmony 无对应物；
  价值在版本谱系证据（原版持续跟车 Compose BOM 与稳定化）。
- M3-adaptive/lifecycle alpha→stable 毕业与 1.4.2 大量 UI 面增量
  （gallery/calendar/typing settings）同期，属工具链配套。
- Room 版本持平证明表结构变化属应用逻辑演进，非库强制迁移。
- 本表作为 T-042 版本差异报告的工具链章节输入。
