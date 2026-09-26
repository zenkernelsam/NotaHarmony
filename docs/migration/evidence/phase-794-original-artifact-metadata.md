# Phase 794 证据：原版 1.4.2 工件级收尾与版本号注册

日期：2026-09-29
性质：证据登记（无 Harmony 源码变更）——APK 工件面收尾 +
版本号注册（T-042 输入）。
证据源：`decompiled_1.0.3`/`decompiled_1.4.2` AndroidManifest、
`resources/assets/{dexopt,resources,conf}`、`AppScope/app.json5`。
Replay：`docs/migration/replays/d02-original-artifact-metadata.mjs`
ADR：`ADR-0738-original-artifact-metadata.md`

## 1. 版本号注册（T-042 输入证据）

| 包 | versionCode | versionName |
|----|-------------|-------------|
| 原版 1.0.3（当前移植基线） | 1014 | 1.0.3 |
| 原版 1.4.2（最新已分析版） | 1040002 | 1.4.2 |
| NotaHarmony（AppScope/app.json5） | 1000000 | 1.0.0 |

Harmony 端自报 1.0.0——版本目标决策属 T-042 范围；
本行仅注册事实，不改 app.json5。

## 2. dexopt/ —— ART 基线配置

两版均含 `baseline.prof`/`baseline.profm`（ART 基线
profile，启动加速元数据）——Android 专有工件，
Harmony 无对应概念，无移植面。

## 3. MyScript 资源细化（修正 760 粒度）

`assets/resources/`（引擎数据本体）两版均存：
- 移除：`en_US/` 下三个 `*.lite.res`（ak-cur /
  ak-superimposed / lk-text）——lite 识别变体。
- 更新：`document_layout/dl-raw-content.res`、
  `math/math-sr.res`（引擎资源内容更新）。
- `conf/en_US.conf` 内容变更（引擎配置更新）。
- `conf-lite/` 目录整体移除（760 已登记）。

精化结论：1.4.2 **仍内置完整 MyScript 引擎资源**，
仅裁剪 lite 变体——与 768 的"本地 HWR 服务"结论一致
（引擎在端侧，l77 IPC 调用）。

## 4. META-INF / 结构

decompiled 根仅 `resources/`+`sources/`（jadx 输出）；
XAPK 分层（base+stickers+density/locale splits）已在
760/761/763 登记。

## 5. 结论

APK 工件面全量归属完毕；版本号三元组注册为 T-042
输入；MyScript 资源粒度修正完成。
