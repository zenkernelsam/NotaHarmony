# ADR-0690 — Zoom View 旗标判定更正：ZOOM 为默认开启的真实缺口

日期：2026-09-25
状态：已登记（更正 ADR-0644 的 ZOOM 项；POINTER/RULER/view-only 三项维持原判）

## 背景

ADR-0644 将原版工具箱缺失的 ZOOM 工具（`a6f.U`）登记为
“`s01.a0` 仅 `lc4.a(ac4.e0)`(ZOOM_VIEW) 时保留——旗标功能，1.0.3 未开”。
复核旗标求值链发现该判定有误：

- `ac4.e0` = ZOOM_VIEW，`zb4.L` = **PRODUCTION** 级旗标，远程键 `ztb.c`
  = `"androidZoomView"`。
- `lc4.a` 对 PRODUCTION 级旗标读取远程配置值（`trb.e`→`sh4`），本地无覆盖、
  非 JUnit 运行时、PRODUCTION 构建三个前置条件在 1.0.3 出货包中全部成立。
- `core_remoteconfig__remote_config_defaults.xml` 打包默认
  `androidZoomView = true`；同判定路径的 `androidNoteTapeTool` 同为 `true`
  且 REVIEW(胶带) 工具确实默认可见并已移植，互为印证。

故 1.0.3 原版 `s01.a0` 默认保留 ZOOM 工具，`ww2` 湿墨 Zoom View 控制条
（back/forward/return/close）、`g0j` 自动前移区把手、`vgg`/`ggg` 状态机
构成在线功能面。

## 决策

1. 更正 ADR-0644 的 ZOOM 项：由“旗标未开，缺省即正确”更正为
   **原版默认开启、Harmony 未移植的延迟移植缺口（port-deferred gap）**。
   工具箱 index 位继续留空，但理由从“对等原版不可见”改为“实现未就绪”。
2. POINTER 维持 fail-closed（协作会话后端缺位时无任何可见输出）；
   RULER 维持“原版即隐藏”（`s01.a0` 无条件剔除 `a6f.T`）；
   view-only/presence 体系维持 ADR-0644 登记不变。
3. Zoom View 后续若实施，需覆盖：工具箱 ZOOM 位、`ww2` 四键控制条
   （含 `zoom_view_*` 六个无障碍标签）、`g0j` 前移区把手、`vgg`/`ggg`
   状态机对应的放大书写条与自动前移语义。实施时另立 ADR 系列，
   本 ADR 仅承担更正登记职责。

## 证据

- `docs/migration/evidence/original-zoom-view-flag-correction-jadx-2026-09-25.md`

## 验证

- `docs/migration/replays/d02-original-zoom-view-flag-correction.mjs`：
  原版旗标求值链锚点 + Harmony absence 断言 + ADR 更正登记。
- 全量 Replay 与双 HAP 构建随本阶段通过。
