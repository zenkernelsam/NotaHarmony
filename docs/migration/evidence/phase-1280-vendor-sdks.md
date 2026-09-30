# Phase 1280 证据 — MyScript iink 手写识别 + Play 授权（里程碑）

来源：`com/myscript/iink/*`（94 文件）+ `com/pairip/*`（8 文件）。

## `com.myscript.iink` = **MyScript 交互墨水识别 SDK**

```
Engine               // 识别引擎（加载 .conf 配置/证书）
Editor               // 识别编辑器（ContentBlock 树+事件）
OffscreenEditor      // 离屏识别（转文本/latex/图形）
ContentBlock         // 内容块（Text/Math/Diagram/Drawing）
ContentPackage       // 内容包（笔记文件）
IEditorListener / IOffscreenEditorListener
graphics/ text/ util/   // 渲染+文本+工具
```

→ Notability **手写→文本/数学公式/图形识别**核心 ——
商业 SDK（需许可+证书资源），引擎原生加载。

## `com.pairip` = **Google Play 授权/完整性**

```
LicenseClient            // 授权检查客户端
LicenseActivity          // 授权失败提示 Activity
LicenseResponseHelper    // 授权响应解析
LicenseContentProvider   // 启动期初始化
ILicenseV2ResultListener // AIDL 结果
RepeatedCheckMetadata    // 周期性复检
```

→ **Play App Licensing/Integrity** —— 校验 App 从
Play 安装（反盗版），否则阻断。

## 语义

**两个商业/SDK 依赖**：
- MyScript iink = 手写识别（文本/数学/图形转结构化）；
- pairip = Play 完整性/授权（反盗版守护）。

## Harmony 决策

MyScript → Harmony 无移植 —— 手写识别 fail-closed：
用系统 handwriting/ML Kit 回退或禁用识别特性；
pairip → Harmony 无对应 —— 完整性校验省略（Harmony
无 Play 授权）—— 两 SDK 均 fail-closed。

## 产出

- fixture `d02-vendor-sdks.mjs`（10 断言）。
- ADR-1224（fail-closed）；中文报告。
