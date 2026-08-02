# Notability → HarmonyOS / OpenHarmony 逆向分析笔记

> 本文档持续积累逆向分析发现，作为鸿蒙移植的知识库。
> 状态标记：✅ 证据闭环 | 🟡 主体已确认、仍有缺口 | ⚠️ 线索/推断待验证 | ❓ 待探索

---

## 📖 知识库总览（导航索引）

> 开工速查：想复现什么 → 看对应章节。深水区 = ⚠️ 需要 jadx-gui 交互分析。

### 一、基础（1-3）—— 项目身份与代码分布
| 章 | 内容 | 一句话结论 | 关键文件 |
|----|------|-----------|---------|
| 1 | XAPK 基本信息 | 包名/版本/保护壳/DI 框架 | manifest.json |
| 2 | Native SO 功能身份 | 25 个第三方/运行时；libglmath 是应用专用 LaTeX JNI，所有权来源未证实 | dump_exports.py |
| 3 | Java 包结构 | Clean Architecture，私有逻辑全在 DEX | com/gingerlabs/** |

### 二、手写核心（4-8）—— 渲染/输入/模型/纸张/数据库
| 章 | 内容 | 一句话结论 | 关键文件 |
|----|------|-----------|---------|
| 4 | 渲染架构 ⭐ | MotionEvent 经 Notability workflow 转为 AndroidX Ink StrokeInput，再由三档渲染辅助上屏 | cxe/ys0/uc8/cu5/hda/in |
| 5 | 输入模型 | `hda.v()` 映射坐标、压感、倾斜、方位角和工具类型；支持 history + predicted event | hda/cu5 |
| 5b | 橡皮擦 | PARTIAL（clipOutPath 挖洞）+ WHOLE（整条删除）双模式 | zy5/jze/h76 |
| 6 | 笔画数据模型 | 渲染态 s78 + PencilSplat(faa) + WetMirrorRenderSpec(vzf) | s78/faa/vzf |
| 7 | 纸张模板 | 页面背景程序化绘制+REPEAT 平铺；另有 15 张纸张预览缩略图 | qae/lp0/core_paper__paper* |
| 8 | 本地数据库 | 全部 Room 表结构（ClientOp/ToolState/NoteAsset...） | m17 |

### 三、手感三件套（17-19）—— 平滑/质感/延迟 ⭐ 移植核心
| 章 | 内容 | 一句话结论 | 关键文件 |
|----|------|-----------|---------|
| 17 | 普通笔迹平滑 | Force smoothing + 最小二乘三次贝塞尔分段拟合；动态容差语义仍待补 | ms1/sqh/gp2/dr4 |
| 18 | PencilSplat | 预制 splat 纹理 + 程序化散布：LCG 随机、旋转、缩放、透明度 | xaa/oz5/te6/uaa |
| 19 | 低延迟 | V33 双 SurfaceControl/RenderNode；V29 单 SurfaceView/RenderNode；均有独立渲染路径 | vd1/kd1/w20 |

### 四、工具系统（22-25）—— 笔刷/形状/选区
| 章 | 内容 | 一句话结论 | 关键文件 |
|----|------|-----------|---------|
| 22 | 工具栏与笔刷 | Brush(style/width/color/well) + 8 种工具枚举 | f21/zy5 |
| 23 | 笔刷样式与轮廓 | Taper→VARIABLE_WIDTH；普通 ink 通过 `w4a.b()` 生成可变宽度轮廓 | dxe/hy5/w4a/y5a/hz5 |
| 24 | 形状工具 | 笔画完成后识别直线/椭圆/多边形，失败保留手画 | cxe/b90/nzf分支 |
| 25 | 选区工具 | Drawn/Lasso 模型 + 22 项菜单操作 + 统一 transform | ooc/noc/mnc/urd |

### 五、P2 功能（30-32）—— 文本/图片/录音
| 章 | 内容 | 一句话结论 | 关键文件 |
|----|------|-----------|---------|
| 30 | 文本框 | TextBlockInfo + StaticLayout 渲染 + 统一 ID 可变换 | cde/tke |
| 31 | 图片资源 🟡 | NoteAsset 哈希引用 + 上传/下载 Worker已确认；元素类/裁剪结构待补 | NoteAsset DB |
| 32 | 录音锚点 🟡 | 前台服务和 audioLinked 字段已定位；时间戳→回放进度赋值链待补 | RecordingForegroundService |

### 六、兼容与边界（26-29）—— Fallback/开关
| 章 | 内容 | 一句话结论 | 关键文件 |
|----|------|-----------|---------|
| 26 | 渲染 Fallback | RuntimeShader API33+；API34+仅特殊 scratch 路径；HardwareBuffer 固定 RGBA_8888、usage 降级 | uaa/w20 |
| 27 | 输入 Fallback | 缺失 pressure/tilt/orientation 使用 `-1`；工具映射与 predicted event 降级已确认 | hda/cu5 |
| 28 | 笔刷行为 Fallback | 识别失败保留手画、置信度合并、边界 clamp | b90/xaa |
| 29 | Feature Flag | qa4 检查链（覆盖→远程→等级）+ 67 项枚举 | qa4/fa4 |

### 七、架构与规划（9-16, 20-21, 33-39）
| 章 | 内容 | 一句话结论 | 关键证据 |
|----|------|-----------|----------|
| 9 | UI 结构 | 从 strings.xml 还原（库/编辑器/工具栏/纸张类型） | strings.xml |
| 10 | 数据同步 ⚠️ | op 流 + GraphQL + WorkManager 已见；OT/CRDT 与冲突语义未闭环 | data/note/ops |
| 11 | 保护机制 | PairIP 壳/Play License（移植不需要） | AndroidManifest |
| 12 | 目标端替代方案 | 区分华为 HarmonyOS SDK 与 OpenHarmony 上游能力 | 华为官方文档 |
| 13 | 待探索问题 | 深水区清单（op 顶层分发/选区边框/图片元素类） | — |
| 14 | 移植难点 🟡 | 风险集中在手感、低延迟、可变宽度和数据兼容；部分细节仍待闭环 | 17-21/35-37 |
| 15 | 混淆程度 | 仅 defpackage 混淆，第三方库明文 | decompiled/sources |
| 16 | 开发路线 | Phase1-5 分期规划 | — |
| 20 | AndroidX Ink 对照 | 官方 1.0 模块 vs Notability 自研扩展点 | androidx/ink |
| 21 | op 流持久化 | 元素 schema 已还原（yc7/zzc/a0d），顶层分发⚠️ | ClientOp/yc7/zzc |
| 33 | 共享抽象层 🟡 | 已确认 c9e 基类、三条 ink 渲染路径和 transform；完整元素类型表待补 | hz5/zy7/ulc |
| 34 | UI 图标资源 | 200+ 矢量 XML，多层叠加系统，可批量转 SVG | decompiled/resources/res |
| 35 | 可变宽度审计 🟡 | “钢笔统一固定宽度”不成立；Taper/逐点宽度进入轮廓路径，因子来源待补 | dxe/hy5/w4a/jz5 |
| 36 | HarmonyOS 低延迟 API 🟡 | 华为 SDK 有预测/帧加速能力，但 RenderNode 非 SurfaceControl 直接等价物，延迟必须真机量测 | 华为官方文档 |
| 37 | HarmonyOS 纹理渲染方案 ✅ | Canvas2D → ShaderEffect(API20+) → XComponent/OpenGL ES 三层路线；AGSL 不可直接迁移 | 华为官方文档 |
| 38 | 启动/登录状态机 ✅ | 四层状态、`first(hnf.e)` 阻塞点与 v14 本地注入路径已静态+运行时闭环 | un7/hp8/hnf/aq8 |
| 39 | UI 入口与移植地图 🟡 | 根 Compose、主/笔记双层路由、资料库响应式布局和编辑器组件已定位；精确主题 token/动画仍待量测 | MainActivity/s4g/b87/xs7/t09 |

### 快速导航（按需求）
| 想复现什么 | 看 |
|------------|-----|
| 笔迹手感（平滑+铅笔+延迟） | 17 + 18 + 19 |
| 渲染上屏链路 | 4 + 19 |
| 橡皮擦 | 5b |
| 形状自动识别 | 24 |
| 选区与变换 | 25 + 33 |
| 多设备兼容 | 26 + 27 + 28 |
| 可开关功能 | 29 |
| 数据格式兼容（.note 文件） | 21 + 33 + 6 |
| 笔刷/工具参数 | 22 + 23 + 7 |
| UI 图标/资源 | 34 |
| 移植风险确认 | 35 + 36 + 37 |
| 启动与登录状态机 | 38 |
| UI 页面入口与一比一移植 | 39 |

---

## 1. XAPK 基本信息

| 项目 | 值 |
|------|-----|
| 包名 | `com.gingerlabs.notability` |
| 版本 | 1.0.1 (code: 1001) |
| Min SDK | 32 (Android 12L) |
| Target SDK | 36 |
| Compile SDK | 37 |
| 总大小 | ~197 MB |
| Application 类 | `com.pairip.application.Application` (PairIP 保护壳) |
| DI 框架 | Metro (`dev.zacsweers.metrox.android.MetroAppComponentFactory`) |
| Kotlin 版本 | 2.3.0 (Metadata mv = {2, 3, 0}) |

### Split APKs
| 文件 | 用途 |
|------|------|
| `com.gingerlabs.notability.apk` | base（dex + 资源） |
| `config.arm64_v8a.apk` | ARM64 native so 库 |
| `config.en.apk` | 英文语言资源 |
| `config.xxhdpi.apk` | 高密度图片资源 |

---

## 2. Native SO 库功能身份确认 (arm64-v8a) ✅

> 2026-08-02 通过 dump_exports.py 解析 ELF 导出表，26 个 so 的功能类别已定位。
> **结论：25 个可归为第三方库或基础运行时；`libglmath.so` 暴露 `com.gingerlabs.notability` JNI 且服务于 LaTeX，但 JNI 命名只能证明应用集成，不能单独证明代码所有权。**

### 按供应商分组

| 供应商 | SO 数量 | 总大小 | 鸿蒙替代 |
|--------|---------|--------|----------|
| MyScript (法国) | 11 个 | ~45 MB | MVP 不集成；预留识别接口，必要时商务问询 |
| PDFTron (加拿大) | 1 个 | 59 MB | PDF Kit；功能差距不可接受时换 HarmonyOS 兼容引擎 |
| Google (MLKit/Icing/AndroidX) | 4 个 | ~16 MB | HarmonyOS OCR + 自研搜索 + ArkGraphics/ArkUI |
| Rive (美国) | 1 个 | 5 MB | `rive-runtime` 上游源码用 OHOS NDK 重编 + N-API |
| org.beyka (开源 TIFF) | 4 个 | ~1.7 MB | `libtiff` 源码重编；JNI/Android Bitmap 包装层重写 |
| **应用专用 JNI（来源待确认）** | **1 个** | **2.7 MB** | 若已掌握且获授权的源码：保留核心，JNI 改 N-API |
| 基础运行时 (C++/SQLite/DataStore) | 3 个 | ~2.5 MB | 不搬 Android 二进制；改用目标 NDK/ArkData/轻量状态实现 |

### 逐个明细

| SO 文件 | 大小 | 确认身份 (JNI包名) | 功能 | 鸿蒙替代 |
|---------|------|---------|------|----------|
| `libiink.so` | 24 MB | com.myscript.iink (315 JNI) | 手写识别+编辑器+渲染 | MVP 不集成；保留可插拔识别接口 |
| `libink.so` | 1.3 MB | androidx.ink.brush (314 JNI) | 笔刷物理+Mesh渲染 | 自研 ArkGraphics 2D / Canvas；性能不足再下沉 XComponent |
| `libglmath.so` | 2.7 MB | com.gingerlabs.notability (3 JNI) | **LaTeX 公式渲染** (tex::port) | 若有合法源码：OHOS NDK 重编 + JNI→N-API |
| `libPDFNetC.so` | 59 MB | com.pdftron (2517 JNI) | PDF 渲染/标注/转换 | PDF Kit；功能 PoC 不通过则换兼容引擎 |
| `librive-android.so` | 5.1 MB | app.rive (270 JNI) | 矢量动画引擎 | `rive-runtime` 源码重编 + N-API/目标渲染后端 |
| `libmlkit_google_ocr_pipeline.so` | 11 MB | com.google.android (33 JNI) | OCR 文字识别 | HarmonyOS 文本识别能力；准确模块名以目标 SDK 为准 |
| `libicing.so` | 3.5 MB | com.google.android (3 JNI) | 应用内搜索引擎 | 自研索引 / relationalStore 查询；按需评估 FTS |
| `libgraphics-core.so` | 207 KB | androidx.graphics (2 JNI) | Surface buffer | ArkGraphics / XComponent / PixelMap 对应能力 |
| `libandroidx.graphics.path.so` | 9 KB | (JNI_OnLoad only) | Path 解析 | ArkUI / ArkGraphics Path |
| `libMyScript2D.so` | 435 KB | (无JNI，被 libiink 调用) | 2D 图形识别 | 不需要 |
| `libMyScriptAnalyzer.so` | 592 KB | (无JNI) | 内容分析 | 不需要 |
| `libMyScriptDocument.so` | 2.7 MB | (无JNI) | 文档识别 | 不需要 |
| `libMyScriptEngine.so` | 2.0 MB | (无JNI) | 识别引擎核心 | 不需要 |
| `libMyScriptGesture.so` | 520 KB | (无JNI) | 手势识别 | 不需要 |
| `libMyScriptInk.so` | 964 KB | (无JNI) | 墨迹处理 | 不需要 |
| `libMyScriptMath.so` | 593 KB | (无JNI) | 数学识别 | 不需要 |
| `libMyScriptMLOrt.so` | 10 MB | (无JNI) | ML推理 (ONNX Runtime) | MindSpore Lite |
| `libMyScriptShape.so` | 476 KB | (无JNI) | 形状识别 | 不需要 |
| `libMyScriptText.so` | 3.1 MB | (无JNI) | 文字识别 | 不需要 |
| `libtiff.so` | 655 KB | (无JNI，C库) | TIFF 编解码 | 维护中的 libtiff 源码用 OHOS NDK 重编 |
| `libtiffconverter.so` | 716 KB | org.beyka (16 JNI) | TIFF→Bitmap | 不搬；重写 N-API + PixelMap 转换层 |
| `libtifffactory.so` | 301 KB | org.beyka (3 JNI) | TIFF 工厂 | 不搬；并入新的 TIFF 服务封装 |
| `libtiffsaver.so` | 14 KB | org.beyka (2 JNI) | TIFF 保存 | 不搬；并入新的 TIFF 服务封装 |
| `libc++_shared.so` | 1.3 MB | (无JNI) | C++ 标准库 | 不搬；由 OHOS NDK 构建和运行时配置决定 |
| `libsqliteJni.so` | 1.1 MB | (无JNI) | SQLite | ArkData RelationalStore |
| `libdatastore_shared_counter.so` | 7 KB | androidx.datastore (4 JNI) | 共享计数器 | Preferences / relationalStore 事务 / 自研并发计数 |

### 关键结论
- **手写核心无需盲扫全部 so**：`libink.so` 是 AndroidX Ink，其余手写/识别相关库也已归类；当前没有证据表明 Notability 私有手写算法藏在 native 层
- **defpackage 中 0 个 native 方法**：Notability 100% 私有逻辑在 DEX (Java) 层
- **应用专用 so**：`libglmath.so` 仅见 LaTeX 的 init/measure/draw 三个 JNI 入口；其第三方来源或所有权仍需额外来源证据

### 鸿蒙二进制复用判定（2026-08-02 外部专家分析确认）
> 结论：**0 个 Android so 可作为受支持的预构建二进制直接复用**。
> 依据：HarmonyOS 官方预构建库路线要求 .so 由鸿蒙 NDK 工具链编译；Android Bionic ABI、JNI/ART、平台 API、C++ 运行时、动态链接命名空间均不兼容。

| 分类 | 库 | 路线 |
|------|-----|------|
| 源码重编优先 | libtiff（OpenHarmony-SIG 已有交叉编译案例）、libglmath（仅在已掌握且获授权源码的前提下） | OHOS NDK + CMake |
| 复用上游核心源码 | Rive C++ runtime（开源 rive-runtime） | 鸿蒙 NDK 编译 + N-API 封装 |
| 厂商版本或替换 | MyScript（平台矩阵无鸿蒙）、PDFNet | MyScript 默认不纳入 MVP；PDF 优先 PDF Kit，必要时再采购兼容引擎 |
| HarmonyOS 能力直接替代 | ML Kit OCR→文本识别能力、AndroidX Ink→自研、Icing→自研搜索、graphics/path→ArkGraphics/ArkUI、SQLite JNI→relationalStore | 官方 API；具体包名与能力以目标 SDK/API Level 为准 |
| 删除 | Android `libc++_shared.so` | 不随应用搬运；使用 OHOS NDK 对应运行时和一致的 C++ ABI 配置 |

**技术修正要点**（vs 早期判断）：
- `Java_*`/`JNI_OnLoad` 是导出符号，不一定导致 dlopen 失败；真正的杀手是 `DT_NEEDED`（liblog/libandroid/libjnigraphics 等）与 Bionic 专有符号
- JNI 符号数=0 不代表不依赖 JNI（RegisterNatives 可隐藏符号）
- libc++_shared.so 不是"鸿蒙自带不需要"，而是"不应搬，由 NDK 构建配置决定"
- 商业授权风险：提取重打包 MyScript/PDFTron 可能违约
- 验证手段：llvm-readelf 检查 DT_NEEDED/UND/版本；测试用 RTLD_NOW 而非 RTLD_LAZY

---

## 3. Java 包结构 (Clean Architecture)

```
com.gingerlabs.notability/
├── app/                    # 应用入口
│   ├── NbApplication       # Application (Worker注册、全局初始化)
│   ├── MainActivity        # 唯一 Activity (Compose 单Activity)
│   ├── MissingNativeLibraryActivity
│   ├── AppUpgradeReceiver
│   ├── initializers/       # AppStartup 初始化器
│   └── widgets/            # 桌面小组件 (5种)
│
├── core/                   # 核心基础
│   ├── analytics/          # 埋点
│   ├── common/             # 通用工具 (日志)
│   ├── flatbuffers/        # FlatBuffers 序列化 (笔记格式)
│   ├── glmath/             # GLMath JNI (LaTeX渲染)
│   ├── model/              # 核心数据模型
│   ├── network/            # 网络层
│   ├── retrofit/           # Retrofit 接口
│   └── user/               # 用户数据
│
├── data/                   # 数据层
│   ├── billing/            # Google Play 计费
│   ├── handwritingrecognition/  # 手写识别 (MyScript包装)
│   ├── learn/              # AI 学习功能
│   ├── library/            # 笔记库 (状态同步)
│   ├── note/               # 笔记核心
│   │   ├── assets/         # 资源上传/下载 Worker
│   │   ├── ops/            # 操作同步 (OT/CRDT)
│   │   │   ├── database/
│   │   │   └── synced/
│   │   └── state/
│   ├── samsungbilling/     # 三星计费
│   ├── search/             # 搜索
│   ├── settings/           # 设置
│   ├── stylus/             # 手写笔 (触觉反馈)
│   │   └── haptic/
│   ├── subscription/       # 订阅
│   ├── theme/              # 主题
│   ├── toolbar/            # 工具栏
│   └── transcription/      # 音频转文字
│
├── domain/                 # 领域层
│   └── subscription/
│
├── feature/                # 功能层
│   ├── login/              # 登录 (Apple/Microsoft)
│   └── note/               # 笔记编辑
│       └── toolbox/audio/record/  # 录音
│
└── ui/                     # UI 层
    ├── fileimport/         # 文件导入
    └── support/            # 帮助
```

---

## 4. 实时墨迹与渲染架构 ✅（2026-08-02 复核）

> **重要纠错**：`gc8/jma/ag5` 是 Jetpack Compose 指针事件转换链，不是 AndroidX Ink 的墨迹采集链。
> `jma.toString()` 明确输出 `PointerInputEventData`，其中 Axis 9/10、50/51、52 分别对应滚动、平移手势和缩放手势数据。
> MyScript 的 `PointerEvent/GLRenderer` 也不能直接当成业务实时画布入口。

### 业务实时输入→上屏链

```text
MotionEvent + predicted MotionEvent
  → cxe.i() / ys0 的对应分支
  → oc8（DOWN，携带工具状态）/ nc8（后续事件）
  → uc8 事件流
  → szf / nzf 的具体 Wet Ink workflow 分支
  → cu5（进行中笔画入口，校验 predicted MotionEvent）
  → hda.t()/v()（MotionEvent history/current → AndroidX Ink StrokeInput）
  → jv5 / in（进行中笔画状态与渲染调度）
      ├── jd1：高延迟、主线程 View 重绘
      ├── vd1：API 33+ 前端缓冲辅助
      └── kd1：旧版本非 UI 线程渲染辅助
  → pzf / uaa 等 Notability 绘制器
  → Android Canvas/Skia 上屏
```

证据入口：`cxe.java:i()`、`audit_ys0/ys0.java` 对应分支、`oc8.java`、`nc8.java`、`cu5.java:a()`、`hda.java:t()/v()`。

### 渲染器选择逻辑（in.java 构造函数）

| 条件 | 渲染器 | 说明 |
|------|--------|------|
| `getUseHighLatencyRenderHelper()` | jd1 | 高延迟模式，主线程 View 重绘 |
| API >= 33 | vd1 | V33 前端缓冲辅助，使用 RenderNode/SurfaceControl 路径 |
| 其他 | kd1 | V29 兼容路径，非 UI 线程绘制 |

### 笔刷渲染不是单一 `strokePath`

| 类型 | 已确认路径 | 结论 |
|------|------------|------|
| Mono | `dxe.a()` → `FIXED_WIDTH` | 固定中心线宽度 |
| Dash / Dot | `DASH` / `DOTS` → `pzf.g()` + DashPathEffect | 固定中心线宽度 |
| Taper | `dxe.a()` → `VARIABLE_WIDTH`；普通 ink 路径调用 `w4a.b()` | 需要逐点宽度轮廓，不能概括为固定宽度+尾部三角 |
| Pencil | PencilSplat 内容 → `uaa` | 预制 splat 纹理 + 程序化散布/网格 |

`jz5` 中把 `VARIABLE_WIDTH` 改成 `FIXED_WIDTH` 的代码位于 `calculateForShapes`，只说明形状内容强制固定宽度，不能外推到普通 ink。

### 笔画绘制规格 WetMirrorRenderSpec（vzf，名称恢复）

| 字段 | 类型 | 说明 |
|------|------|------|
| color | int | 颜色 ARGB |
| brushWidth | float | 基础笔宽 |
| inkStyle | enum sz5 | `VARIABLE_WIDTH/FIXED_WIDTH/DASH/DOTS` |
| isHighlighter | bool | 荧光笔 |
| isPencil | bool | 铅笔（走 PencilSplat 路径） |

### 铅笔渲染 PencilSplatRenderer（uaa）

- 纹理：预制 `res/drawable-nodpi/ui_renderer__pencil_splat.png`，程序只生成每个 splat 的位置、旋转、缩放和透明度。
- 每个 splat 是一个四边形（两个三角形），批量由 `drawVertices` 提交。
- RuntimeShader：**API 33+ 且硬件 Canvas**；编译失败返回 null 并走 BitmapShader/PorterDuff 路径。
- `uaa.z()` 的 **API 34+** 判断只控制特殊 scratch/硬件缓存优化，不是 RuntimeShader 的最低版本。
- CPU/兼容路径：BitmapShader + PorterDuffColorFilter(SRC_IN) + drawVertices。
- 批量优化：scratch bitmap、LruCache、颜色过滤器缓存；每批最多 16383 顶点。

### 固定中心线路径（pzf.g）

- 实线：StrokeCap.ROUND + StrokeJoin.ROUND。
- DASH：DashPathEffect `{2×width, 1×width}`。
- DOTS：DashPathEffect `{0.001×width, 2×width}`。
- 荧光笔：颜色 alpha 调整 `yw1.e(color, 107)`。
- 遮罩：`h76.l0` 使用 clipOutPath + 绘制路径/遮罩。
- 这部分不能代表 `VARIABLE_WIDTH` 普通 ink 的全部实现；轮廓构建见第 23/35 节。

### 文档坐标与其他渲染

- `pzf.d()`：scrollOffset、zoom、viewport clipRect 和页面居中变换。
- `qae`：纸张背景。
- `GLMathNative`：LaTeX 初始化、测量和绘制；与实时墨迹输入链无关。

---

## 5. AndroidX Ink 输入模型 ✅（2026-08-02 复核）

### Compose 指针链为何不是墨迹链

- `jma.toString()` = `PointerInputEventData(...)`。
- `jma` 的 `scrollDelta`、`panGestureOffset`、`scaleGestureFactor` 属于 Compose 手势数据。
- 因此旧文对 `gc8` 的 pressure/tilt/classification 解释不成立，不能再作为 StrokeInput fallback 证据。

### 真实转换链

```text
MotionEvent / predicted MotionEvent
  → oc8 / nc8 → uc8
  → szf/nzf 的对应 workflow 分支
  → cu5.a()
      ├── 当前 MotionEvent → hda.t() 批量加入 history + current
      └── predicted MotionEvent → 单独转换；时间戳为 0 时忽略
  → hda.v()
  → androidx.ink.strokes.StrokeInput
```

### `hda.v()` → StrokeInput 字段映射

| StrokeInput 字段 | MotionEvent 来源 | 处理 |
|-------------------|------------------|------|
| x / y | Axis 0 / 1 | 先经 Matrix 映射到笔画坐标 |
| elapsedTimeMillis | eventTime / historicalEventTime | 减去笔画起始时间 |
| toolType | `getToolType()` | stylus/eraser→STYLUS，mouse→MOUSE，其余→TOUCH |
| strokeUnitLengthCm | 调用方传入 | 不是 pressure |
| pressure | Axis 2 | 仅 stylus 且设备声明能力时读取，clamp 到 `[0,1]`；否则 `-1` |
| tiltRadians | Axis 25 | 仅 stylus 且有能力时读取，clamp 到 `[0,π/2]`；否则 `-1` |
| orientationRadians | Axis 8 | 仅 stylus 且有能力时读取，归一化到 `[0,2π)`；否则 `-1` |

AndroidX Ink `StrokeInput` 本身的字段顺序可由其 Kotlin Metadata/`update()` 签名确认：

```text
update(x, y, elapsedTimeMillis, toolTypeInt,
       strokeUnitLengthCm, pressure, tiltRadians, orientationRadians)
```

### history 与预测点

- `hda.r()` 根据索引选择 `getAxisValue/getHistoricalAxisValue`；`hda.t()` 将 history 与当前点批量加入 StrokeInputBatch。
- `cu5.a()` 对 predicted MotionEvent 做单独校验：eventTime 或任一 historicalEventTime 为 0 时忽略预测事件。
- 预测点只用于进行中笔画的低延迟显示；移植时应与真实采样点分开标记，避免直接污染最终持久化数据。

### 关键证据

- `decompiled/sources/defpackage/jma.java:102`
- `decompiled/sources/defpackage/hda.java:802-840`
- `decompiled/sources/defpackage/cu5.java:101-180`
- `decompiled/sources/androidx/ink/strokes/StrokeInput.java:15-83`

---

## 5b. 橡皮擦机制 ✅（2026-08-02 确认）

### 结论：两种橡皮擦都有（像素级 + 笔画级）

| 模式 | 工具枚举 | 实现方式 | 证据 |
|------|---------|---------|------|
| 部分擦除 | `PARTIAL_ERASER` (zy5序号2) | 像素级：橡皮擦路径作为 mask，`clipOutPath(mask)` 挖洞后重绘 | pzf.g → h76.l0；f0g.n (maskPath) + s78.h |
| 整条擦除 | `WHOLE_ERASER` (zy5序号7) | 操作级：删除整条 stroke | zy5 枚举 + z29 工具集 |

### 关键类
- `zy5` = 工具枚举: DEFAULT/SELECTION/PARTIAL_ERASER/PEN/HIGHLIGHTER/PENCIL/REVIEW/WHOLE_ERASER
- `jze` = `EraserState(brush, id, trayId, trayIndex, isPartial)`（橡皮擦带笔刷配置）
- `qob` = `PartialEraser` 功能开关（fa4.PARTIAL_ERASER，FeatureFlag#14）
- 持久化: `ToolStateEntity.eraserIsPartial` (Room 表字段)
- 数据库: ToolStateEntity (`tool_id, tray_owner_id, toolType, trayIndex, color, widthSize, style, selectedColorWellIndex, selectedWidthSizeWellIndex, tapePattern, selectionIsFreehand, eraserIsPartial`)

### 像素擦除原理（h76.l0）
```java
canvas.clipOutPath(maskPath);   // 橡皮擦路径挖洞
canvas.drawPath(strokePath);     // 重绘剩余部分
canvas.drawPath(maskPath);       // 画遮罩本身
```

---

## 6. 笔画数据模型 ✅（2026-08-02 还原）

### 渲染态 Stroke（s78 字段）
| 字段 | 类型 | 说明 |
|------|------|------|
| d | volatile Path | 笔画轮廓 Path（三缓冲 f0g.a[]，平滑后轮廓） |
| e | volatile vzf | WetMirrorRenderSpec（样式规格） |
| f | volatile List<faa> | PencilSplat 点列表（铅笔专用） |
| g | volatile List<faa> | 第二组 splat 点（高亮层？） |
| h | volatile Path | maskPath（擦除/遮罩） |
| i | volatile Float | 宽度 |
| j/k/l/m/p/r | RectF | 边界盒（含 splat 半径膨胀 √2 倍） |
| s | bool | finishInput 标记 |
| n | bool | 取消标记 |

### 笔画点 PencilSplat（faa，名称恢复）
| 字段 | 类型 | 说明 |
|------|------|------|
| x | float | 坐标 |
| y | float | 坐标 |
| rotation | float | 旋转角 |
| scale | float | 缩放（压感映射） |
| opacity | float | 透明度 |

### 持久化点格式（vm4/r4a + q4a 枚举）
- q4a 枚举：NON_ATTRIBUTED/ATTRIBUTED × MOVE_TO/LINE/QUADRATIC/CUBIC
- 字段：定点数 long×3（x/y/控制点）+ float×2 + double + long
- 归属：AndroidX Ink StrokePoint 格式（tni.java 与 StrokeInput 互转）

### 输入态（AndroidX Ink StrokeInput）
- x/y/t/pressure/tilt/orientation/toolType（fi8 封装写入 StrokeInputBatch）

### 数据流
```
StrokeInput → fi8(StrokeInputBatch) → s78.e() → s78.g() 生成Path/边界盒
  → jv5(i): onDraw 循环 → mo0.c() → l78.c() → pzf.e()/g() → Canvas
  → 完成笔画: s78.f() → k78(快照) → 持久化 op (FlatBuffers)
```

---

## 7. 纸张模板系统 ✅（2026-08-02 复核）

### 结论：实际页面背景程序化绘制，资源包另含预览缩略图

- 页面上的格线/横线/点阵背景由 `qae` 生成小位图后 REPEAT 平铺，不依赖整页背景图片。
- `core_paper__paper01~15.webp` 是纸张选择界面的预览缩略图；它们不否定实际页面背景的程序化实现。

### 模板枚举（lp0）
| 枚举 | 绘制方式（qae.java） | 参数 |
|------|-------------------|------|
| PLAIN | 空白 | — |
| LINES | 横线 | 间距 8px（另有 28/26px 变体），线宽 1px |
| GRID | 水平+垂直方格 | 间距 8px，线宽 1px |
| DOTS | 点阵 | 间距 8px，半径 1.25px，隔行偏移 4px |
| (对角网格) | 45° 斜线 | 间距 11.313708 (=8√2)，线宽 2px |
| (装饰线) | 横线+五瓣花纹 | 行距 13px × 列距 15px |

### 渲染实现（qae = PaperTemplateRenderer）
1. 生成小位图（ARGB_8888，尺寸=间距×密度）
2. Canvas 循环画线/圆/路径
3. `BitmapShader(bitmap, REPEAT, REPEAT)` + setLocalMatrix 缩放
4. 平铺填充页面 → 缓存（pzf.m 持有 qae 实例）

### 预览资源

- `decompiled/resources/res/drawable/core_paper__paper01~15.webp`：15 张纸张预览缩略图。
- 移植时可重新生成预览；若直接复用原资源，需先确认授权范围。

### 纸张尺寸枚举（e0a 实现类，名称恢复）
| 尺寸 | 宽×高 | 单位 | 资源 |
|------|-------|------|------|
| A3 | 297×420 | mm | core_paper__a3 |
| A4 | 210×297 | mm | core_paper__a4 |
| A5 | 148×210 | mm | core_paper__a5 |
| A6 | 105×148 | mm | core_paper__a6 |
| A7 | 74×105 | mm | core_paper__a7 |
| Letter | 8.5×11 | in | core_paper__letter |
| Legal | 8.5×14 | in | core_paper__legal |
| Tabloid | 11×17 | in | core_paper__tabloid |

### 页面管理 ⚠️（深水区，待继续）
- 笔记内容 = **op 流**（FlatBuffers BLOB，存于 `ClientOp` 表：noteId, op, opId, clientTime）
- `SyncedOpMetadata`：id, legacyId, editorSiteId, editorId, createdAt, opCount, opFileSize, schemaVersion, fingerprints
- `NoteStateEntity`：id, zoom, scrollOffset（视图状态独立存）
- 页面增删/尺寸在 op 流中编码（混淆类，需 jadx-gui 交互分析）

---

## 8. 本地数据库（Room）✅ 2026-08-02

| 表 | 字段 | 用途 |
|----|------|------|
| NoteStateEntity | id, zoom, scrollOffset, lastCodeBlockLanguage, zoomViewSourceRect, zoomViewShown | 笔记视图状态 |
| ToolStateEntity | tool_id, tray_owner_id, toolType, trayIndex, color, widthSize, style, selectedColorWellIndex, selectedWidthSizeWellIndex, tapePattern, selectionIsFreehand, eraserIsPartial | 工具栏状态（含笔刷配置） |
| ClientOp | noteId, op(BLOB), uploadImmediately, hasTitle, title, opId, clientTime | 本地操作流（FlatBuffers） |
| SyncedOpMetadata | id, legacyId, editorSiteId, editorId, createdAt, creatorId, updatedAt, maxServerTime, title, titleOpId, opCount, opFileSize, maxTimestamp, schemaVersion, fingerprintFileLengths, opsChecksum, offsetsChecksum | 同步元数据 |
| SyncedNoteMetadata | id, title, createdAt, updatedAt, favorite, lastOpened, deletedAt, folderId, titleOpId, thumbnailUrl, thumbnailOpId, legacyNoteId, mostRecentOpTime, shared, hasRecordings, linkAccessLevel, linkPermissionScope, userAccessLevel | 笔记库元数据 |
| NoteAsset | assetHash, status, noteIds, fileSize | 资源文件 |
| NoteIndexableChanges | noteId, ids, pageIds, newPageInsertLocations, mainBodyText, initialLoad, processing, chunkIndex | 搜索索引增量 |
| LearnNoteState / SummaryEntity / LearnJob / StudyItemsInfo / QuizSession / QuizOp | — | AI 学习 |
| DraftNote | noteId | 草稿 |
| DeferredSyncedOps | id, noteId, schemaVersion, tableType, fileSize, checksum | 延迟同步 |
| PermanentlyDeletedNote | noteId | 永久删除标记 |

---

## 9. UI 结构 (从 strings.xml 还原) ✅

### 主要页面
1. **登录页** — Apple/Google/Microsoft/Email 登录 + 引导轮播
2. **笔记库 (Library)** — 文件夹 + 笔记列表/网格 + 搜索
3. **笔记编辑器** — 画布 + 工具栏 + 页面管理器
4. **设置**
5. **桌面小组件** — 新建笔记/录音/最近笔记/缩略图/文件夹

### 编辑器工具栏
- Pen / Pencil / Highlighter / Eraser / Color
- Undo / Redo / Share
- 选择工具 (Copy/Cut/Paste/Delete/Group/Lock/层级/转换)
- 页面管理器 (Add/Delete/Duplicate/Bookmark/Template)
- 数学编辑器 (LaTeX)
- 录音面板
- Learn 面板 (AI Chat/Quiz/Flashcards)
- 版本历史
- S Pen Quick Tools

### 纸张类型
A3/A4/A5/A6/A7/Letter/Legal/Tabloid + Plain/Rule/Grid/Dots + Portrait/Landscape

---

## 10. 数据同步机制 ⚠️

- `data/note/ops/` — 基于操作的同步 (类 OT/CRDT)
- `data/note/ops/database/` — 本地操作数据库
- `data/note/ops/synced/` — 已同步操作
- `data/library/state/` — 笔记库状态上传 (WorkManager)
- `data/note/assets/` — 资源上传/下载 Worker
- 网络: Apollo GraphQL + Retrofit + OkHttp
- 数据库: Room

---

## 11. 保护机制 ⚠️

- **PairIP** (`com.pairip.application.Application`) — 应用保护壳
- **Google Play License Check** (`com.pairip.licensecheck.LicenseActivity`)
- **Samsung IAP** — 三星应用内购买
- 移植时这些全部不需要

---

## 12. HarmonyOS 目标端替代方案（按能力解耦）

| Android/Notability 能力 | HarmonyOS SDK / OpenHarmony 候选 | 优先级 | 边界 |
|------------------------|------------------|--------|------|
| MotionEvent history/predicted → `hda` → StrokeInput | 华为 HarmonyOS SDK：TouchEvent + Pen Kit `PointPredictor`；6.0.0(20)+ C HandWrite 亦可预测 | P0 | 不是已证实的 OpenHarmony 上游通用 API；原始、历史、预测点必须分轨记录 |
| StrokesController / 进行中笔画状态机 | 自研 StrokeSession + 调度层 | P0 | 不把平台 View/Node 类型写进核心数据模型 |
| CanvasFrontBufferedRenderer | Canvas/ArkGraphics 2D + 脏区；API26 帧加速；必要时 XComponent | P0 | 尚无证据证明存在 SurfaceControl 前端缓冲的直接等价物 |
| Mono/Dash/Dot 中心线路径 | Canvas 2D Path/Pen/LineDash | P0 | 可直接映射 |
| Taper/逐点宽度轮廓 | 自研中心线→填充轮廓算法，对照 `w4a.b()` | P0 | 不能降级为统一固定 strokeWidth 后仍声称等效 |
| PencilSplatRenderer | Canvas 2D source-in + OffscreenCanvas；API20+ ShaderEffect；高阶用 OpenGL ES | P0 | 详见第37节 |
| `ui_renderer__pencil_splat.png` | 自有等效纹理或经授权资源 | P0 | 算法可复现不代表原图可直接商用 |
| PencilSplat 程序化散布 | 平台无关算法模块 | P0 | 保留确定性随机、位置、旋转、缩放、透明度 |
| 纸张 `qae` 程序背景 | Canvas 程序绘制/小纹理平铺 | P0 | 预览 webp 与实际背景分开 |
| MyScript Recognizer | MVP 暂不实现；预留 `RecognitionProvider` 接口 | P3/可选 | 后续确有文字/数学/形状识别需求时再商务问询或接入平台能力 |
| GLMathNative (LaTeX) | 若有合法源码：保留平台无关核心，OHOS NDK 重编，JNI→N-API | P2 | 先确认源码与授权；重写日志、资源、字体、Bitmap/Surface/EGL 等 Android 胶水 |
| libtiff + org.beyka JNI 包装 | 维护中的 libtiff 源码用 OHOS NDK 重编，重写 N-API + PixelMap 包装 | P2 | OpenHarmony-SIG 配方仅作移植参考；需覆盖多页、方向、压缩格式、大图内存和损坏文件 |
| PDFNetC (PDF) | PDF Kit 优先；不满足需求时换 HarmonyOS 兼容第三方引擎 | P1/P2 | 必须先做标注/墨迹、增量保存、密码加密、字体、页面导入导出和大文件 PoC |
| Room Database | ArkData RelationalStore | P1 | schema、事务和迁移策略需设计 |
| Apollo GraphQL | 自研网络层 / 暂不需要（离线优先） | P3 | 服务端协议尚未纳入 MVP |
| WorkManager 同步 | Background Tasks Kit / 自研调度 | P3 | 后台约束和系统配额需核验 |
| Rive 动画 | `rive-runtime` 上游源码 + OHOS NDK + N-API + 目标渲染后端 | P3 | 字体、音频、渲染器及 HarfBuzz/SheenBidi/Yoga/Miniaudio/Luau 等可选依赖按实际功能裁剪 |
| ML Kit OCR | HarmonyOS 文本识别能力（`@ohos.ai.textRecognition` 仅作候选名） | P2 | 以目标 SDK 的实际模块路径为准；核验语言、离线、权限、设备覆盖和并发性能 |
| Icing 本地搜索 | 自研索引 / relationalStore 查询；需要时评估 FTS 或独立索引 | P2 | 不把 Android 搜索二进制带入；先根据笔记规模做性能基准 |
| 录音 Service | Audio Kit / 后台音频能力 | P1 | 权限、后台生命周期和中断处理需验证 |

平台映射原则：优先抽象“输入批次、笔画几何、纹理散布、脏区、持久化”这些能力，不按 Android 类名一对一仿造。表中 Pen Kit、StylusFrameBoost 等结论仅覆盖华为 HarmonyOS SDK/目标设备；若要兼容纯 OpenHarmony 发行版，必须另做 API 可用性检查和降级层。

### 最终第三方 Native 迁移决策（覆盖 26 个 `.so`）

> **总体结论：路线可行，可作为正式迁移方案。**生产构建中不直接携带或 `dlopen` 这些 Android/Bionic 二进制；“源码重编”统一指取得合法源码及其依赖源码后，使用目标 HarmonyOS/OpenHarmony SDK、OHOS NDK 与 CMake 从源代码重新构建。它不是对 Android ELF 做一次重链接或补几个兼容符号。

| 能力 / 原库 | 覆盖数量 | 最终路线 | 判断 | 实施边界与回退方案 |
|-------------|:--------:|----------|------|--------------------|
| 手写渲染/笔刷：`libink.so` | 1 | 自研 ArkGraphics 2D / Canvas；仅在真机性能证据要求时下沉 XComponent/OpenGL ES | ✅ 确认 | 核心模型保持平台无关；按输入→几何→纹理→脏区分层。以压力/倾斜、P50/P95 延迟、掉帧和笔尖跟随误差验收 |
| LaTeX：`libglmath.so` | 1 | 保留平台无关计算/排版核心，OHOS NDK 重编，JNI 接口改为 N-API | ⚠️ 有条件确认 | 前提是确实持有可修改、可分发的源码及字体/资源授权。若核心仍引用 Android API，则逐项替换；若无源码或授权不清，回退到自研/KaTeX 类方案 |
| TIFF：`libtiff.so` + `libtiffconverter.so` + `libtifffactory.so` + `libtiffsaver.so` | 4 | 维护中的 libtiff 源码重编；原 Beyka JNI/Android Bitmap 包装废弃，重写 N-API + PixelMap 服务层 | ✅ 确认 | [OpenHarmony-SIG TIFF 配方](https://gitee.com/openharmony-sig/tpc_c_cplusplus/tree/master/thirdparty/tiff) 可作为交叉编译参考，但不应因此固定旧版本；编解码依赖也要全部用 OHOS 工具链构建 |
| Rive：`librive-android.so` | 1 | 使用上游 [`rive-runtime`](https://github.com/rive-app/rive-runtime) 源码，OHOS NDK 构建，提供窄 N-API/C ABI 门面并接入目标渲染后端 | ⚠️ 有条件确认 | 源码可移植不等于低成本；先盘点 `.riv` 资源使用的文字、音频、状态机和高级特性。若动画数量少或功能简单，转换资产/用 ArkUI 重做可能成本更低 |
| PDF：`libPDFNetC.so` | 1 | PDF Kit 优先 | ⚠️ PoC 后确认 | 不能只验证“能打开 PDF”；必须验证墨迹/批注读写、增量保存、密码与加密、字体替换/嵌入、页面导入导出、超大文件和损坏文件。若关键能力缺失，切换 HarmonyOS 兼容商业/开源 PDF 引擎 |
| OCR：`libmlkit_google_ocr_pipeline.so` | 1 | HarmonyOS 文本识别能力替换 | ⚠️ SDK 核验后确认 | `@ohos.ai.textRecognition` 表达的是目标能力，不保证在所有 SDK/API Level 中都是当前导入路径；锁定目标 SDK 后核验包名、权限、语言、离线模型、设备范围、时延与并发限制 |
| 数据库：`libsqliteJni.so` | 1 | ArkData `relationalStore` | ✅ 确认 | 映射 Room schema、索引、事务、BLOB、并发、版本迁移和回滚；若原 Icing 承担全文检索，还需单独设计 FTS/索引，不应把普通 SQL 查询当作等价替代 |
| 识别：`libiink.so` + 10 个 `libMyScript*.so` | 11 | MVP 不集成；保留可插拔识别服务接口 | ✅ 确认（按当前范围） | 如果产品后续要求手写转文字、数学或形状识别，再向 MyScript 询问 HarmonyOS 授权/定制构建，或接入平台/自研能力；不要提取重打包现有 Android 商业库 |
| 本地搜索：`libicing.so` | 1 | 自研搜索索引，或基于 relationalStore/可用 FTS 能力实现 | ✅ 替换 | 用真实笔记量验证索引构建、增量更新、中文分词、排序和查询时延；保持搜索接口与具体索引后端解耦 |
| Android 图形胶水：`libgraphics-core.so` + `libandroidx.graphics.path.so` | 2 | ArkGraphics/ArkUI Path、PixelMap、XComponent 等目标端能力 | ✅ 替换 | 这是平台适配层，不值得做二进制兼容；按实际调用分别重写 Surface/Buffer/Path 转换 |
| DataStore 共享计数：`libdatastore_shared_counter.so` | 1 | Preferences、relationalStore 事务或极小的并发安全计数模块 | ✅ 替换 | 先确认是否要求跨线程、跨进程或崩溃一致性，再选择最小实现；不要为 7 KB Android JNI 包装维护兼容层 |
| C++ 运行时：Android `libc++_shared.so` | 1 | 删除 Android 文件，由 OHOS NDK 构建配置选择并统一 C++ 运行时 | ✅ 确认 | 所有本地模块统一工具链、STL/异常/RTTI 配置；N-API 边界不要暴露 STL 对象或跨模块释放不明所有权的内存 |
| **合计** | **26** | **源码级移植、平台能力替换或删除；直接二进制复用为 0** | **通过** | **每个 native 产物均需检查 `DT_NEEDED`/未定义符号，确保不再依赖 Android `liblog`、`libandroid`、`libjnigraphics`、Bionic 或 ART/JNI** |

#### 落地顺序与验收闸门

1. **P0 手写链路**：先完成输入、笔画模型、Canvas/ArkGraphics 2D 渲染和真机基准；只有基准不达标才增加 XComponent/原生渲染复杂度。
2. **P1 数据与 PDF PoC**：先迁移 relationalStore schema/事务/版本升级，同时用真实 Notability 样本验证 PDF Kit。PDF PoC 失败应尽早触发引擎选型，避免后期返工。
3. **P2 LaTeX、TIFF、OCR**：先完成源码/许可证和目标 SDK 可用性核验，再实现统一 ArkTS 服务接口。TIFF 与 LaTeX 的 N-API 只暴露稳定的数据结构、句柄和错误码。
4. **P3 Rive 与可选识别**：先统计实际动画资产和特性覆盖，再决定完整移植 Rive、只裁剪所需模块，还是转换/重做动画。MyScript 保持可选，不阻塞 MVP。
5. **Native 交付标准**：所有源码及传递依赖均由 OHOS NDK 构建；arm64 真机以 `RTLD_NOW` 加载测试；执行 ABI、内存、线程、异常、许可证和第三方声明检查。

---

## 13. 待探索问题 ❓

- [x] ~~FlatBuffers schema 具体结构（笔记数据模型）~~ → 已确认 op 流模式（ClientOp 表 BLOB），元素 schema 已还原（yc7/zzc/a0d），顶层分发待解析
- [x] ~~笔画数据模型：一个 stroke 存储哪些字段~~ → 渲染态 s78 + PencilSplat + WetMirrorRenderSpec（第 6 节）
- [x] ~~笔刷纹理资源在哪里~~ → 铅笔使用 `ui_renderer__pencil_splat.png`；其他样式包含固定中心线和可变宽度轮廓（第 4/23 节）
- [x] ~~橡皮擦实现：像素擦除 vs 笔画擦除~~ → 两种都有（第 5b 节）
- [x] ~~普通笔画平滑主体~~ → Force smoothing + 最小二乘三次贝塞尔分段拟合（第 17 节）
- [x] ~~PencilSplat 生成逻辑~~ → 完整公式（第 18 节）：LCG 随机 + 椭圆盘 + 压感 5 次方缓动
- [x] ~~低延迟渲染机制~~ → 双 SurfaceControl + 双 RenderNode + 渲染线程（第 19 节）
- [ ] op 流顶层分发：op 类型枚举、页面增删操作、编号方案（第 21 节 ⚠️）
- [ ] 普通平滑动态容差公式中各变量的业务语义，以及不同工具分支
- [ ] `fc0.e()` 逐点宽度因子的生成/写入链：默认样式、压感、Taper、编辑变换分别如何影响
- [ ] `w4a.b()` 可变宽度轮廓的完整可读伪代码和尖角/自交边界处理
- [ ] 选区边框/控制点 UI 的绘制入口
- [ ] 图片元素具体类与裁剪数据结构
- [ ] 鸿蒙目标设备的输入→绘制→上屏延迟、压力/倾斜范围和不同渲染路线基准

---

## 14. 移植难点与已知边界 🟡

### 需要调优还原的部分
| 秘密 | 难度 | 说明 |
|------|------|------|
| 笔刷手感调参 | 中 | 已定位核心：PencilSplat 压感→scale/opacity 映射 + WetMirrorRenderSpec 组合，大量试错调出 |
| 低延迟管线 | 中高 | Android 已确认 history/prediction + 独立渲染 + 脏区/图层交接；鸿蒙端指标需真机量测 |
| 笔画平滑算法 | 中 | Force smoothing + 三次贝塞尔分段拟合；容差随笔宽/zoom 动态变化 |
| 可变宽度轮廓 | 中高 | Taper/逐点宽度需要中心线→轮廓；`w4a.b()` 主体已定位，参数来源待补 |

### 标准工程模式或已知做法
| 内容 | 说明 |
|------|------|
| 纸张模板 | 程序化绘制 + BitmapShader REPEAT 平铺（qae），PLAIN/LINES/GRID/DOTS，格距 8px |
| 橡皮擦 | PARTIAL_ERASER 像素擦除(clipOutPath挖洞) + WHOLE_ERASER 整条删除 |
| Undo/Redo | Command 模式 / 操作栈 |
| 多页管理 | 已确认进入 FlatBuffers op 流；页面增删、顺序和渲染实例组织仍待闭环，不能先写死“每页一个 surface” |
| 文本框 | 标准文本编辑 + 排版 |
| 录音 | 系统录音 API + 时间戳 |
| 同步 | 已确认 op 流 + GraphQL/WorkManager；是否属于 OT/CRDT 及冲突合并语义仍待确认 |

### 纸张模板本质
```
纸张尺寸: A3(297×420), A4(210×297), A5, A6, A7, Letter, Legal, Tabloid
方向: Portrait / Landscape
样式: Plain(空白) / Rule(横线) / Grid(方格) / Dots(点阵)
```
实现 = 背景绘制函数（循环画线/画点），无任何技术壁垒。

### 工程判断
> 当前证据显示，主要移植风险集中在交互细节、笔刷调参、可变宽度、低延迟和数据兼容，而不是某个尚未发现的单一“秘密算法”。
> 移植核心工作：还原交互设计 + 调出手写手感 + 在目标 HarmonyOS 设备上验证预测/帧加速能力和自研渲染管线。

### 体验标准（非简化版，是对标原版）
> **目标：鸿蒙平板 + 华为手写笔 的 Notability 体验 ≥ iPad + Apple Pencil 的 Notability 体验**
>
> 必须做到：
> - 铅笔纹理质感 (PencilSplat) — 不是简单 Path
> - 精确压感曲线 — 轻重过渡自然
> - 倾斜侧锋响应 — 铅笔斜着写变粗变淡
> - 低延迟 — 以目标设备实测 P50/P95、掉帧和笔尖跟随误差为验收依据；`<16ms` 只能作为目标，不是当前已证实结论
> - 笔画平滑 — 快速书写不抖动不折线
>
> 仅凭硬件规格不能推导最终手写体验；输入采样、预测、渲染调度、屏幕刷新率和笔刷算法都必须在目标设备上联合量测。

---

## 15. 混淆程度分析 ✅

| 对比项 | SchoolBox | Notability |
|--------|-----------|------------|
| 类名 | 混淆 | 大部分保留（Kotlin Metadata） |
| 方法名 | 混淆 | 保留（pointerDown, drawModel 等） |
| 第三方 SDK | — | 完全未混淆（MyScript iink 全套明文） |
| 字符串 | 可能加密 | 全部明文，带模块前缀 |
| 真正混淆的 | 全部 | 仅 `defpackage` 下的业务胶水代码 |

原因：R8 keep 规则 + Kotlin @Metadata + Metro DI 需要类名可发现。

### MyScript 耦合度极低
- `com.gingerlabs.notability` 包：**0 个** MyScript import
- `defpackage` 中：仅 `lj8.java` + `kj8.java` 两个文件
- 且只用了 Engine/Recognizer/Configuration/MimeType（全是识别相关）
- 结论：渲染层已完全解耦，识别层也仅 2 个文件的薄封装

---

## 16. 开发路线 (初步)

### Phase 1: MVP 手写画布
- 鸿蒙项目骨架 (DevEco Studio)
- XComponent / Canvas 手写输入
- 基础笔迹渲染 (压感 → 粗细)
- 单页笔记

### Phase 2: 工具系统
- 笔刷 Stamping 引擎
- 橡皮擦
- 颜色/粗细选择
- Undo/Redo

### Phase 3: 笔记管理
- 多页笔记
- 笔记库 (文件夹/列表)
- 本地持久化

### Phase 4: 高级功能
- 文本框
- 图片插入
- PDF 导入/标注
- 录音

### Phase 5: 智能功能
- 手写识别
- LaTeX 数学
- AI 学习 (可选)

---

## 17. 普通笔迹平滑 🟡（2026-08-02 复核）

> **纠错**：旧版第 17 节描述的是形状识别，不是普通手写平滑。形状识别已独立整理到第 24 节。
> 普通 ink 的平滑主体是 **force smoothing + 最小二乘三次贝塞尔分段拟合**。

### 主链

```text
输入事件批次（ns1[] + 当前 ns1）
  → ms1.b()
  → yc4.a() / ForceSmootherConfig 处理 force 与点批次
  → vy5 保存/筛选 ke2 点
  → 根据笔宽、zoom 等计算动态容差 d3
  → sqh.f() 分段拟合
      ├── sqh.g()：最小二乘求三次贝塞尔控制点
      ├── sqh.h()：检查区间最大点到曲线误差
      └── 二分搜索最长可接受区间
  → gp2 = CubicCurve(p0, p1, p2, p3)
  → yy5 / eq2 拟合段结果
```

### Force smoothing

`ms1` 构造器创建：

```java
new dr4(0.15f, sdg.s0(8L, np3.MILLISECONDS), true)
```

结合 `dr4.toString()` 的 `ForceSmootherConfig` 字段，可确认：

| 参数 | 值 | 状态 |
|------|-----|------|
| enabled | true | ✅ |
| smoothing window | 8 ms | ✅ |
| 单点最大 force 变化 | 0.15 | ✅ |

### 三次贝塞尔拟合

- `gp2.toString()` 明确为 `CubicCurve(p0,p1,p2,p3)`。
- `sqh.g()` 构造三次 Bernstein 基函数并解 2×2 正规方程，求两个控制点；病态或非有限结果退回直线三等分控制点。
- `sqh.h(start,end,tolerance,...)` 对拟合区间逐点采样曲线，计算最大欧氏误差；任一点超过 tolerance 即拒绝该区间。
- 单次拟合区间最多 200 点。
- 拟合使用区间前后最多各扩 5 点作为上下文，但误差验收仍针对目标区间。
- 整段无法一次接受时，`sqh.f()` 用二分查找找到最长可接受终点，再继续后续分段。

### 动态容差

`ms1.b()` 传入 `sqh.f()` 的容差公式为：

```text
d3 = (0.5 /
      ((((dd4.d(vy5.b() * vy5.a) - 2.6) / 15.4) * 1.5) + 1.0))
     / vy5.a
```

从调用关系可确认它随笔宽/显示缩放相关量动态变化，而不是固定像素阈值。由于 `vy5.a`、`vy5.b()` 和 `dd4.d()` 的最终业务命名尚未全部恢复，本公式的精确单位与每个工具分支仍标 🟡，不能提前写成确定的“X px 容差”。

### 移植要点

1. Force smoothing 与几何平滑分成两个模块，便于分别调参和关闭。
2. 拟合输出使用三次贝塞尔，不要用形状识别的二次曲线替代。
3. 容差应由基础笔宽和 zoom 推导，并用不同书写速度/缩放级别回归测试。
4. 仍需补齐 Pen、Highlighter、Eraser 等工具是否共享完全相同的预处理分支。

### 关键证据

- `decompiled/sources/defpackage/ms1.java:22-35, 60-211`
- `decompiled/sources/defpackage/sqh.java:f()/g()/h()`
- `decompiled/sources/defpackage/gp2.java`
- `decompiled/sources/defpackage/dr4.java`

---

## 18. 铅笔质感：PencilSplat 生成算法 ✅（2026-08-02 完整还原）

> **核心结论：铅笔质感 = 预制 `ui_renderer__pencil_splat.png` 纹理 + 程序化随机散布；每个 splat 记录位置、旋转、缩放和透明度等参数。**

### 生成链路
```
笔画数据 (ic0 点序列)
  → oz5.t() = buildPencilStrokeContent（实时）
  → e0d.b() = buildPencilStrokeContent（离线，从持久化元素解码）
  → te6.q(): 逐点 walk → xaa（单点生成器）
  → skd 回调 → haa (FloatBuffer 20字节/点) → faa(x,y,rotation,scale,opacity)
```

### 单点 splat 生成（xaa.b() 完整公式）
```
输入：当前曲线位置、间距 d2、点数据 fc0（d()=width/压力, a()=方位角, b()/c()=切线）

// 1. 基础尺寸系数（xaa.d()）
power5(x) = x⁵
sizePressure = 1 - power5(1 - min(pressure,2)/2)          // 压感→尺寸 5次方缓动
sizeTilt     = 1 - power5(min((tilt-π/2)/(-0.94248), 1))  // 倾斜→尺寸（-0.3π 归一）
sizeFactor   = sizePressure*sizeTilt + (1-sizeTilt)*1.0    // 倾斜时保持尺寸

// 2. 散布盘参数
scaleBase = min(width,2)/2 * 0.97 + 0.03                  // 0.03~1.0
angleDiff = max(π/5 - 方位角, 0)                          // 角度差
splatCount = floor(angleDiff / (π/125)) + 1               // 细分数量（最多26）
ellipseR   = 1.2 * (d2/2) * 0.5 * floor(angleDiff/(π/125)) // 椭圆长半轴
ellipseS   = (angleDiff/(π/2)) * (-0.48) + 0.5            // 椭圆短半轴系数
scale      = ellipseS * d2 * sizeFactor                    // 输出 scale

// 3. 每 splat 随机散布（LCG 伪随机）
seed = (seed * 1118393071) % 1946926193                  // 确定性随机（可复现！）
u1 = seed / 1.946926193e9
θ  = (next_seed / 1.946926193e9) * 2π
r  = sqrt(u1)                                            // 均匀盘分布
x  = 0.9 * cos(θ) * r                                    // 椭圆收缩 0.9
len= (angleNorm + sin(θ)) * 1.0                          // 沿切线分量
pos = 曲线点 + (len*切线Y + x*(-切线X))*ellipseR, (len*切线X + x*切线Y)*ellipseR

// 4. 输出参数
rotation = next_rand * 2π                                 // 完全随机旋转
opacity  = (1 - sqrt(u1)) * (angleNorm 混合 0.1) * scaleBase  // 边缘淡出
其中：angleNorm = min(max(angleDiff/0.45332, 0), 1)
      edgeFactor = (1-angleNorm) + 0.1*angleNorm

// 5. 曲线上等距前进（xaa.a() advanceBy）
二分查找：子段 0.1 精度 → 40 次迭代 1e-4 收敛（w76.x 距离）
```

### 关键参数表
| 参数 | 值 | 含义 |
|------|-----|------|
| 间距 | 调用方传入（oz5/e0d 的 d） | splat 密度 |
| 压感幂次 | 5（d³·d²） | 压感→尺寸缓动 |
| 倾斜归一 | -0.94248 rad (≈-0.3π) | 倾斜→尺寸 |
| 椭圆收缩 | 0.9 | x 方向 |
| 角度细分 | π/125 = 0.02513 rad | 方位角细分步长 |
| 最大细分 | 26（π/5 范围内） | 每点 splat 数 |
| LCG 乘子 | 1118393071 / 1946926193 | 确定性伪随机 |
| 边缘透明度 | 1-√u1 | 泊松盘半径衰减 |

### 渲染端（已在第 4 节）
- 每个 splat = 四边形（2 三角形）drawVertices
- GPU: RuntimeShader(AGSL) `tintColor * splatTexture.eval(coord).a * dimAlpha`
- CPU: BitmapShader + PorterDuffColorFilter(SRC_IN)
- 纹理：预制 `ui_renderer__pencil_splat.png` 提供 alpha/颗粒形状；程序化算法决定散布位置、旋转、缩放和透明度

---

## 19. 低延迟渲染架构 ✅（2026-08-02 还原）

> **核心结论：双 SurfaceControl 层 + 双 RenderNode + 独立渲染线程，笔画完成后硬件交接。**

### V33 架构（vd1 = CanvasFrontBufferedRendererV33）
```
┌─ 主线程 (UI) ──────────────────────────────┐
│ StrokesView → 输入事件 → Stroke 状态机 (jv5) │
│ o() handoff：完成笔画 → 缓冲交接             │
└────────────┬────────────────────────────────┘
             │
┌─ 渲染线程 (pd1 HandlerThread) ──────────────┐
│ w20.e(): 后缓冲准备（旧内容 RenderNode 重录）│
│ w20.f(): 前缓冲清空 (CLEAR)                 │
│ 绘制进行中笔画 → Front RenderNode           │
│ SurfaceControl Transaction 提交 (w20.h)     │
└─────────────────────────────────────────────┘
```

### 缓冲机制（w20 = FrontBufferedBufferManager）
| 组件 | 用途 | 证据 |
|------|------|------|
| SurfaceControl ×2 | OffScreen + Front 层（setZOrderOnTop + TRANSLUCENT） | w20.a() L57-74 |
| RenderNode ×2 | "-OffScreen" + "-Front" 离屏录制 | w20.a() L61-66 |
| HardwareBuffer | `format=1`（RGBA_8888）固定；usage 在 `0x100000B00` 与 `0xB30` 间选择 | w20.a() L52 |
| SurfaceControl.Transaction | 交接提交（p2e.z0 显示 + m1 隐藏 + Y 排序） | w20.h() L331-345 |
| CountDownLatch | 交接同步（cc0.a CAS） | vd1.o() L250 |

### 增量渲染
- 脏区 = 笔画边界盒 ±3px（m() 方法）
- `clipRect(floor(box)-3, ceil(box)+3)` 限制重绘区域（kd1 L194-199 / vd1 L204）
- 新缓冲先 `drawColor(0, CLEAR)` 再绘制新笔画

### V29 对比（kd1）
- 无 SurfaceControl：单个 SurfaceView + RenderNode 离屏
- `RenderNode.beginRecording() → drawRenderNode(renderNode2)` 合成
- 同样非 UI 线程渲染 + CLEAR 清屏
- 高延迟模式（jd1）：主线程 View.invalidate() 直接重绘

### 延迟链路关键点
1. `hda.t()` 批量加入 MotionEvent history，`cu5.a()` 另行处理 predicted MotionEvent
2. 渲染线程独立于 UI → 输入不阻塞绘制
3. 增量区域重绘 → 不整屏重画
4. V33 使用 HardwareBuffer + SurfaceControl Transaction 提交图层；这是 Android 专有实现，鸿蒙端不能直接假定存在同语义接口

### HardwareBuffer 常量纠错

```java
HardwareBuffer.isSupported(1, 1, 1, 1, 4294970112L)
```

四个整型参数中的第 3 个 `1` 是 format，即 `HardwareBuffer.RGBA_8888`；最后一个 long 才是 usage：

- `4294970112 = 0x100000B00`：包含 FRONT_BUFFER 等用途的首选 usage。
- `2864 = 0xB30`：不支持首选 usage 时的兼容 usage。

因此这里是 **usage flags 降级**，不存在旧文所写的 `RGBA_1010102 → RGBA_8888` 格式降级。

---

## 20. AndroidX Ink 官方文档对照 ✅（2026-08-02）

> 官方版本：1.0.0 稳定版（2025-12-17），1.1.0-alpha04（2026-06-17）

### 官方模块结构
| 模块 | 功能 | Notability 使用情况 |
|------|------|-------------------|
| ink-strokes | StrokeInputBatch / InProgressStroke / Stroke(+ImmutableStrokeInputBatch+Brush+PartitionedMesh) | ✅ 输入+几何（fi8/esd/jv5） |
| ink-brush | Brush(style+BrushFamily) / StockBrushes(pressurePen/highlighter/marker/pressure) | ✅ Brush 模型（f21） |
| ink-geometry | Box/Vec/PartitionedMesh 相交检测 | ✅ BoxAccumulator/MutableBox |
| ink-rendering | CanvasMeshRenderer / StrokesView / StrokesController | ✅ 全部（in/jv5/kd1/vd1） |
| ink-authoring | InProgressStrokes 低延迟创作 | ✅ StrokesController 即此 |
| ink-storage | 笔触序列化 | ❌ 未用（Notability 用自有 FlatBuffers op 流） |

### Notability 的自研扩展（官方库之外）
| 扩展 | 说明 |
|------|------|
| PencilSplatRenderer | 程序化铅笔纹理散布（官方只提供 Mesh） |
| WetMirrorRenderSpec | 自研样式规格（color/width/style/isHighlighter/isPencil） |
| 形状识别系统 | 笔画完成后识别/拟合直线、椭圆和多边形（非实时；官方无此功能） |
| op 流持久化 | 自研 FlatBuffers 格式（官方用 ink-storage） |
| 纸张模板 | 自研程序化背景 |

### 鸿蒙复现要点
- Brush 概念 → 鸿蒙自定 BrushSpec（family + color + size + epsilon）
- InProgressStroke → 自研 Stroke 状态机（已有 s78 参照）
- 低延迟 → 鸿蒙离屏 Canvas / 图层合成

---

## 21. 笔记持久化 op 流 ⚠️（2026-08-02 部分还原）

### 已确认
| 层 | 结构 | 证据 |
|----|------|------|
| 存储 | ClientOp 表：noteId + op(BLOB) + opId + clientTime | m17.java L336 |
| 元数据 | SyncedOpMetadata：editorSiteId/editorId/opCount/opFileSize/schemaVersion/checksum | m17.java L336 |
| 元素 | yc7(笔画) schema：0=起点 3=终点 1=控制点1 2=控制点2 4=样式(c90) | zli.java L16-50 |
| 元素 | wv8(椭圆) / ina(多边形) / c9e 基类 | j1c.a0 L1230-1246 |
| 序列化 | zli.a()/d()（写/读）+ rkb.Y(yla) 点编码 + n7j 路径编解码 | zli.java / n7j.java L231-249 |
| 点格式 | p4a 定点数（long 编码 float） | n7j/p4a |

### 待探索 ⚠️
- op 顶层类型分发（哪些 op：createPage/insertStrokes/deleteStrokes/变换...）
- 页面数据结构（页面列表如何组织）
- 编号方案（opId 分配、引用关系）
- 建议：jadx-gui 交互式追踪 o6e（op 应用协程）或 j3c 相关 op 处理链

---

## 22. 工具栏与笔刷模型 ✅（2026-08-02 还原）

### Brush 模型（f21，toString 恢复）
```
Brush(brushStyle: z21, widthSize: float, color: int, selectedWidthWellIndex: int, selectedColorWellIndex: int)
```
- 默认：widthSize=36.0, color=-16777216(黑), style=FIXED_WIDTH
- brushStyle 枚举含 "Taper"（z21.java）

### 工具枚举（zy5）
```
DEFAULT / SELECTION / PARTIAL_ERASER / PEN / HIGHLIGHTER / PENCIL / REVIEW / WHOLE_ERASER
```

### 工具状态（jze = EraserState，j0f 基类 = 通用工具状态）
```
EraserState(brush: f21, id, trayId, trayIndex, isPartial)
```
- 每个工具 = brush + 布局位置（trayId/trayIndex）

### 持久化
- ToolStateEntity：tool_id, tray_owner_id, toolType, trayIndex, color, widthSize, style, selectedColorWellIndex, selectedWidthSizeWellIndex, tapePattern, selectionIsFreehand, eraserIsPartial
- 工具栏托盘（TrayEntity）：分组管理工具

### 样式枚举（sz5）
```
FIXED_WIDTH / DASH / DOTS / 实线（pzf 渲染分支）
```

## 23. 笔刷样式与可变宽度轮廓 🟡（2026-08-02 复核）

### 样式映射已确认

`z21`：

```text
Mono / Taper / Dash / Dot
```

`dxe.a(z21)` 的明确映射：

| BrushStyle | sz5 |
|------------|-----|
| Mono | FIXED_WIDTH |
| Taper | VARIABLE_WIDTH |
| Dash | DASH |
| Dot | DOTS |

因此 Taper 不是“固定中心线 + 尾部三角”的同义词，它从样式层就进入 `VARIABLE_WIDTH`。

### 逐点宽度证据

- `hy5.e()`：即便初始样式是 FIXED_WIDTH，只要 `ic0.o` 中任一 `fc0.e() != 1.0`，返回值也会升级为 `VARIABLE_WIDTH`。
- 这说明普通 ink 数据里真实存在逐点宽度因子，且它不只由样式枚举决定。
- 尚未完全恢复：哪些输入/工具生成 `fc0.e()`、是否直接来自压感、Taper 默认曲线以及编辑后如何重算。

### `w4a.a()` 与 `w4a.b()` 不能混为一谈

| 方法 | 职责 | 状态 |
|------|------|------|
| `w4a.a()` | 按距离重采样/抽稀中心线点，支持 heap/off-heap 和子序列 | ✅ |
| `w4a.b()` | 读取每点 `fc0.e()` 等属性，从中心线构造可变宽度填充轮廓 | 🟡 主体已定位，混淆变量语义待恢复 |

普通 ink 实际调用证据：

- `y5a.n()`：非 DASH/DOTS 分支调用 `w4a.b(xw0, width).r()` 构造 Path。
- `hz5.g()`（日志名 `calculateForInks`）在截断/回放路径中调用 `w4a.b()`。
- `w4a.b()` 内多处读取 `fc0.e()`，并以 `widthFactor * baseWidth / 2` 计算局部半宽。

### `h76.W()` / `jz5` 的适用边界

- `jz5` 的日志名是 `calculateForShapes`。
- 其 `VARIABLE_WIDTH → FIXED_WIDTH` 处理只用于形状内容，因为形状不接受可变宽度 ink。
- `h76.W()` 在该形状/中心路径分支生成主体路径与端部几何；它不能代表普通 Taper ink 的完整轮廓算法。

### 移植结论

- Mono/Dash/Dot 可优先走固定中心线 Canvas Path。
- Taper 与任何 `fc0.e()!=1` 的普通 ink 需要保存逐点宽度并生成填充轮廓。
- 若 MVP 暂不实现 `w4a.b()` 等价算法，必须把 Taper 标为显式功能降级，不能宣称视觉/数据兼容。

---

## 24. 形状工具（停笔识别）✅（2026-08-02 Day2）

### 触发链路
```
笔画完成（AndroidX Ink StrokesController 交接后）
  → cxe.onShapeDetectionTriggered()（协程回调，dsd case 13）
  → cxe.k()（应用形状）
  → b90：椭圆(最小二乘) / 直线(Shared Line Detector) / 多边形
  → nzf 的形状处理分支：yc7(线) / zzc(椭圆) / a0d(多边形) 替换手画笔画
```

### 关键确认
| 项 | 结论 |
|----|------|
| 开关 | `shapeDetectionEnabled` 设置，默认 true（cc2.java L696） |
| 触发时机 | 笔画完成时（非实时）——AndroidX Ink 回调 |
| 触发源 | 完全自研（androidx.ink 源码无 shapeDetection） |
| 检测器 | b90；直线/椭圆/多边形候选评分 |
| 替换方式 | 检测后生成新元素（yc7/zzc/a0d）替换原始笔画 |
| ⚠️ 时间阈值 | 未找到停笔 delay 参数——疑似抬笔即触发（非 hold 触发） |

### 检测器与关键参数

```text
形状输入点
  → 形状处理分支的 3 点滑动平均
  → b90 生成直线/椭圆/多边形候选
  → 选择最高评分候选
  → 新点相对当前形状偏差达到阈值时重新拟合
```

| 参数 | 值 | 证据 |
|------|-----|------|
| 重拟合偏差 | 5.0 px | `nzf` 对应分支 `abh.e(...) >= 5.0d` |
| 滑动平均窗口 | 3 点 | 对应分支环形缓冲 `%3` |
| 直线判据 | 距离/跨度 > 0.6 | `b90` |
| 直线评分提升 | 拟合度 >0.5 且长度 >60px 时 `(1+score)*0.5` | `b90` |
| 椭圆检测首尾距 | <120px | `b90` |
| 椭圆拟合 | 最小二乘矩阵 + 判别式 | `b90` |

注意：`nzf` 是 R8 合并/大型混淆类，本节只给其已核对的形状处理分支命名，不把整个类统一命名为“形状识别器”。

### 支持形状
- 直线（二次贝塞尔，控制点投影）
- 圆/椭圆（最小二乘拟合 + 圆化条件）
- 多边形（顶点集，含矩形正交约束 abh.c）

### 形状持久化元素

| 元素 | 类型 | Path 构建 |
|------|------|-----------|
| yc7 | LINE | 两控制点→cubicTo；一控制点→quadTo；无控制点→lineTo |
| wv8/zzc 路径 | NORMAL_SHAPE | addOval/椭圆参数 |
| ina/a0d 路径 | POLYGON | 顶点 moveTo/lineTo/close |

---

## 25. 选区工具 ✅（2026-08-02 Day2 还原）

### 选区状态模型（ooc = Drawn，toString 恢复）
```
Drawn(
  rect, finalizedRect,          // 矩形选区（含旋转角 rect + rotationRadians）
  bounds,                        // 选区边界
  rotationRadians, finalizedRotationRadians,  // 旋转角（浮点，度）
  inProgress,                    // 进行中标记
  selectedIds,                   // 选中元素 ID 集合
  deselectMode, deselectedIds,   // 反选模式（按住笔画取消选择）
  id,
  lassoPoints, finalizedLassoPoints,  // 套索点列表（自由选区）
  groups, finalizedGroups        // 分组集合
)
```

### 套索模型（noc = Lasso）
```
Lasso(points: List, bounds: vhb, id: UUIDv4)
- points = 套索路径点
- id = 随机 UUID（kjc.a.nextBytes → ny7.X 编码）
```

### 选区创建（两种）
| 方式 | 数据 | 开关 |
|------|------|------|
| 矩形框选 | Drawn.rect（含旋转角） | selectionIsFreehand=0（默认） |
| 自由套索 | Drawn.lassoPoints | selectionIsFreehand=1（ToolStateEntity 持久化） |
| 交集判定 | vji.e(rect, rotation, groups) → bounds；选内笔画命中检测 | 两种模式共用 |

### 选区菜单操作（mnc = 22 项完整枚举）
```
STYLE / COPY / CUT / DUPLICATE / GROUP / UNGROUP
SEND_FORWARD / SEND_BACKWARD / SEND_TO_FRONT / SEND_TO_BACK
DELETE / CONVERT_TO_MATH / CONVERT_TO_TEXT / EDIT_MATH
CROP / FIT_TO_PAGE / FLIP_HORIZONTALLY / FLIP_VERTICALLY
LOCK / UNLOCK / DESELECT / MORE
```

### 变换操作的数据落地
- 渲染内容模型（urd = BezierStrokeContent）：
```
BezierStrokeContent(origin, path, selectedCenterPath, width, color, blendMode,
  toDim, transform(zy7.k 矩阵), audioLinkedAlpha, audioLinkedProgress,
  audioLinkedTruncatedPath, pathElementCount, tapePattern, tapePatternColor, revealOutline)
```
- 移动/旋转/缩放 = 修改 transform 矩阵（zy7 序列化）→ 应用到 path
- 几何计算：vji.h/i（rect × 矩阵）、vji.e（bounds 合并）
- 复制/剪切 = 深拷贝元素（jf2.java L617 粘贴逻辑）；分组 = groups 集合

### 选区 UI
- 选区菜单字符串：feature_note__selection_menu_ungroup 等（vt9.java）
- 边框/控制点绘制：待探索 ⚠️（疑在 cxe 的 overlay 渲染）

## 26. 渲染 Fallback 全图 ✅（2026-08-02 Day3）

### 渲染器选择（in.java 构造函数 L1395-1411）
```
if (getUseHighLatencyRenderHelper())  → jd1（高延迟：主线程 View 重绘）
else if (SDK >= 33)                   → vd1（CanvasFrontBufferedRendererV33）
else                                  → kd1（CanvasFrontBufferedRendererV29）
```

### PencilSplat 渲染降级（uaa.java）
| 分支 | 条件 | 路径 |
|------|------|------|
| RuntimeShader | `API>=33 && canvas.isHardwareAccelerated()` | AGSL tint + drawVertices |
| CPU/兼容 | API<33、软件 Canvas 或 shader=null | BitmapShader + PorterDuffColorFilter(SRC_IN) + drawVertices |
| Shader 编译失败 | `iaa.a()` 抛 IllegalArgumentException | 日志 + `q()` 返回 null → 走 CPU 路径（L252-270） |
| 批次位图分配失败 | `qd7.a()` 返回 null（i() L363-365） | 降级为逐 splat 直接绘制（j() 逐个 g()） |
| 特殊 scratch/硬件缓存 | `uaa.z()`：API>=34 且硬件 Canvas | 仅控制优化路径，不是 RuntimeShader 最低版本 |

### 硬件缓冲降级（w20.java）
| 分支 | 条件 | 路径 |
|------|------|------|
| format | 第 3 个整型参数固定为 `1` | RGBA_8888 |
| 首选 usage | `isSupported(..., 4294970112L)` | `0x100000B00`，含 FRONT_BUFFER 等用途 |
| 备选 usage | 首选 usage 不支持 | `2864 = 0xB30` |
| 缓冲创建失败 | `vd1Var.l.getAndIncrement()` 计数 | 延迟重试（n() L215） |

### 防御性检查（pzf.java）
- `path == null || path.isEmpty()` → 直接 return（L133-135）
- `list.isEmpty() && list2.isEmpty()` → return（L140-141）
- 矩阵不可逆 → 日志 + 跳过 blit（uaa.c L290-293）
- 尺寸非法（≤0）→ 抛异常（w20.a L55-57）

---

## 27. 输入 Fallback 表 ✅（2026-08-02 复核）

### 设备能力 × `hda.v()` 处理

| 场景 | StrokeInput 结果 | 证据 |
|------|------------------|------|
| stylus 有 pressure 能力 | Axis 2，clamp `[0,1]` | `hda.java:823` |
| 非 stylus 或无 pressure range | pressure=`-1` | `hda.java:822-824` |
| stylus 有 tilt 能力 | Axis 25，clamp `[0,π/2]` | `hda.java:824` |
| 无 tilt 能力 | tiltRadians=`-1` | 同上 |
| stylus 有 orientation 能力 | Axis 8，归一化到 `[0,2π)` | `hda.java:825-830` |
| 无 orientation 能力 | orientationRadians=`-1` | 同上 |
| TOOL_TYPE_STYLUS | InputToolType.STYLUS | `hda.java:812-814` |
| TOOL_TYPE_ERASER | InputToolType.STYLUS | `hda.java:816-820` |
| TOOL_TYPE_MOUSE | InputToolType.MOUSE | `hda.java:814-816` |
| FINGER/UNKNOWN/其他 | InputToolType.TOUCH | `hda.java:816-818` |
| history 点 | historical axis/time | `hda.r()/v()` |
| predicted event 时间戳非法 | 整个预测事件忽略并记日志 | `cu5.java:112-130` |

`-1` 是 AndroidX Ink 对“不存在该可选属性”的 sentinel；不能替换成 1.0/0 后仍声称保持原语义。

### 注意 eraser 的两层含义

- MotionEvent 的 TOOL_TYPE_ERASER 在 AndroidX Ink 输入工具类型上仍映射为 STYLUS。
- 当前应用工具是否执行 PARTIAL/WHOLE_ERASER，由 Notability 工具状态/workflow 决定；不能只看 StrokeInput.toolType。

### 悬停（Hover）

- `cxe.onStylusHoverEnter(ToolType)`：笔悬停进入回调（对应合并 lambda 分支）。
- `ko3.java` / `f48.java` 有 onHoverEvent 处理；具体预览光标视觉仍可继续核验。

---

## 28. 笔刷行为 Fallback ✅（2026-08-02 Day3）

### 形状识别失败处理（b90 + nzf）
| 场景 | 处理 |
|------|------|
| 无候选形状 | `b90.b() → null` → 保留原始手画路径 |
| 多形状竞争 | 评分合并 `(f7*0.5)+(f6*0.5)`，>0.5 强化为 1.0，取最高 |
| 多边形置信度 | `min(1.0, f×1.1)`（b90 L1198） |
| 偏差大 | 新点距形状 ≥5px → 重新拟合（nzf L607） |
| 椭圆距离上限 | 首尾距 <120px 才检测椭圆（b90 L169） |
| 直线评分 | 拟合度 fA>0.5 且长>60px 时 `(1+fA)*0.5` 提升（b90 L285-287） |
| 直线拟合 | 有中间点 → 三次贝塞尔（控制点 2/3 系数 nbh.v 0.6667）；无 → 二次 |

### 笔刷边界条件（xaa/pzf/s78）
| 场景 | 处理 |
|------|------|
| 间距=0 | `xaa.b()` 直接 return（L146） |
| 空笔画 | `ic0.b.b==0` 或 `ic0.v()` → return（L150） |
| 点数过少 | 循环不进入 → 无 splat |
| 快速滑动 | 等距前进 advanceBy 二分（0.1 精度 + 40 次迭代）自动补点 |
| 压感超界 | `min(pressure, 2.0)` clamp（xaa.d L45） |
| 角度超界 | `min(max(d7,0)/0.45332, 1)` clamp（xaa L198） |
| splat 坐标异常 | `Math.abs(f) <= Float.MAX_VALUE` 检查（xaa L235） |

---

## 29. Feature Flag 全枚举 ✅（2026-08-02 Day3）

### 开关机制（qa4.java）
```
qa4.a(fa4) 检查顺序：
1. 本地覆盖 map（knd StateFlow，d() 可设置）
2. 远程配置：jnb.e(fa4.J)（ud2 读取，服务端覆盖）※仅非 DEBUG 且等级允许
3. 等级闸门：ea4.I(关闭)/J(内部测试)/K(Beta)/L(生产)
   - 当前环境 ≤ J → true；≤ K → true；L → 仅远程/覆盖
4. 默认 false
```

### fa4 枚举（67 项，选关键）
| Flag | 作用 | 已知使用 |
|------|------|---------|
| PARTIAL_ERASER(14) | 部分擦除 | qob |
| ENTITY_GROUPS(10) | 元素分组 | in2 L182：`qa4.a(fa4.V) ? et1.c(分组) : 普通ulc` |
| SNAP_TO_GRID(7) | 网格吸附 | — |
| SHAPE_EDIT_SNAPPING(13) | 形状编辑吸附 | — |
| MATH_CONVERSION(20) | 数学转换 | t09 L1511 |
| HANDWRITING_TO_TEXT(21) | 手写转文字 | t09 L1527 |
| NOTE_LIMIT(26) | 笔记数限制 | t09 L1683 |
| LEARN_* (38-45) | AI 学习全家桶 | bki/e5j/eki 等 |
| LIBRARY_HOME(46) | 新库首页 | zyc L17 |
| AI_REGION_ALLOWED(45) | AI 区域 | qhi L152 |
| NOTE_NIGHT_MODE(54) | 夜间模式 | — |
| SETTINGS_HANDWRITING_DRAWING(56) | 手写设置页 | zyc |
| SETTINGS_NAV_PAGES(57) | 导航页设置 | zyc |

### 用户设置项（DataStore/Preferences，影响行为）
| 设置 | 默认 | 影响 |
|------|------|------|
| shapeDetectionEnabled | true（cc2 L696） | 形状识别开关 |
| autoDeselectEraser | false（k19.f） | 擦除后自动取消选择 |
| eraserIsPartial | 0（ToolStateEntity） | 部分/整条擦除 |
| selectionIsFreehand | 0 | 套索/矩形选区 |

## 30. 文本框工具 ✅（2026-08-02 Day4）

### 文本块模型（cde = TextBlockInfo，toString 恢复）
```
TextBlockInfo(
  transforms: float[][]（zy7.k 矩阵数组，支持嵌套变换）,
  note: ex8（笔记引用）,
  richText: vzb（富文本内容）,
  textFieldId: rm5（元素 ID，与笔画元素同体系）,
  textOrigin: ng3（文本原点）,
  blockScaledSize: z9d（块尺寸）,
  textContentLeftInset / textContentTopInset: float（内边距）,
  rotationRadians: Float（旋转角）
)
```

### 渲染实现（tke = 文本渲染器）
- **Android StaticLayout / BoringLayout**（ur2.q 工厂 / cyi.d）
- TextPaint + TextDirectionHeuristic + TruncateAt + FontMetricsInt
- 支持 SpannableString（富文本 spans，fd7[] 数组）
- 绘制入口：u5c.java `canvas.drawText`

### 文本与笔画的关系
- 文本元素 ID（textFieldId）与笔画元素（rm5）同一 ID 体系 → **可统一选中/移动/旋转/缩放**（TextBlockInfo.transforms 矩阵）
- 文本渲染走独立路径（hz5 只处理 ry5 笔画），渲染时经 transforms 变换
- 编辑态：`cxe.onEnterMainText`（dsd case 17）→ 文本框进入编辑模式

### 手写转文字
- CONVERT_TO_TEXT（mnc 选区菜单）+ fa4.HANDWRITING_TO_TEXT(21) 开关
- MyScript 识别（lj8/kj8）→ 生成文本块

---

## 31. 图片插入与资源存储 🟡（2026-08-02 复核）

### 资源存储模型（NoteAsset 系统）
| 组件 | 说明 |
|------|------|
| NoteAsset 表 | assetHash(BLOB PK), status, noteIds(TEXT 多笔记共享), fileSize |
| NoteAssetsRepository | 资源仓库（ns5 L399） |
| NoteAssetUploadWorker / DownloadWorker | 同步 Worker（v68） |
| 存储位置 | 应用沙箱，按 hash 引用（vfb 含 assetHash） |

### 图片元素
- 选区菜单存在 CROP / FIT_TO_PAGE，且 UI 行为表明图片应进入统一选中/变换体系。
- ⚠️ 具体 `c9e` 子类、裁剪参数、z-order 和持久化引用尚未形成静态调用闭环，因此不能把“图片元素模型已还原”标为 ✅。
- 下一步从 addImage/import 入口反向追踪到 `NoteAsset.assetHash` 与具体元素构造器。

### TIFF 用途 ⚠️
- org.beyka TIFF 库（4 个 so）已确认存在，具体用途（页面快照/缩略图/扫描）待探索

---

## 32. 录音 + 时间锚点 🟡（2026-08-02 复核）

### 录音服务
| 组件 | 说明 |
|------|------|
| RecordingForegroundService | 前台录音服务（feature/note/toolbox/audio/record） |
| AudioCaptureService | 音频采集 |
| 转文字 | TranscriptionDatabase（Room）+ LiveTranscriptionHttpException（流式）+ GCSUploadException（GCS 上传） |
| 元数据 | SyncedNoteMetadata.hasRecordings |

### 时间锚点机制（audioLinked 系列字段）
- 三种渲染内容都有音频关联字段：
```
audioLinkedAlpha        // 回放透明度（已播放部分）
audioLinkedProgress     // 回放进度（0~1）
audioLinkedTruncatedPath / audioLinkedTruncatedSplats  // 按进度截断的路径/飞溅点
```
- 字段名和三种渲染内容结构支持“按录音进度截断笔画并调节 alpha”的解释。
- ⚠️ 赋值链、录音时间戳来源和播放进度如何映射到 `audioLinkedProgress` 尚未闭环，因此当前只能作为实现假设，不能标为完整机制 ✅。

---

## 33. 共享抽象层地图 🟡（2026-08-02 复核）

### 元素体系
```
c9e（FlatBuffers 元素基类，25+ 子类）
├── yc7（笔画 LINE：起点/终点/控制点1/2 + c90 样式）
├── wv8（椭圆 NORMAL_SHAPE）
├── ina（多边形 POLYGON）
├── lce（selection 包装）
└── 其他 20+ 子类 → 待逐个确认，不能先按文本/图片/胶带/箭头强行命名
已检查的相关类型实现 p84 接口并使用 rm5 ID；是否覆盖所有 c9e 子类仍待枚举闭环
```

### 渲染分发（hz5.g() = calculateForInks）
```
按 ry5.k 工具类型分三条渲染内容路径：
├── PENCIL      → wrd = PencilSplatContent（splat 点+audioLinkedTruncatedSplats）
├── TAPE        → vrd = CentralPathStrokeContent（中心路径+fillPath+箭头+胶带图案）
└── 其他笔画     → urd = BezierStrokeContent（贝塞尔路径+revealOutline）

共性字段（三个都有）：origin/path/width/color/blendMode/transform/audioLinked*
批量：并行计算（最多 5000 笔画，并行度参数），结果缓存（n5d.F）
```

### 变换系统（zy7）
- 所有元素统一 transform 矩阵（zy7.k 序列化）
- 移动/旋转/缩放 = 矩阵操作（vji.h/i 几何计算）
- 文本支持矩阵数组（TextBlockInfo.transforms 嵌套变换）

### 选中/碰撞（ulc = SelectionCollisionResult）
```
SelectionCollisionResult(entities: Set, groups: Set)  // 选中元素+分组
et1（分组容器，fa4.V 开关控制）vs 普通 ulc
```

### 持久化
- 已定位的笔记元素走 op 流（FlatBuffers，ClientOp 表）；图片具体元素类仍见第 31 节 🟡
- 图片资源独立 NoteAsset（hash 引用）
- 文本内容独立 richText（vzb 富文本）

---

## 34. UI 图标与资源系统 ✅（2026-08-02）

### 图标格式
- 主工具栏/UI 图标以 Vector Drawable XML 为主，位于 `decompiled/resources/res/drawable/`。
- 同时存在 PNG/WebP 栅格资源：PencilSplat、空笔画点、设置插画和 15 张纸张预览等；不能再概括为“全部矢量”。
- 矢量资源可提取 path data 转鸿蒙 SVG/Path；栅格资源需逐项判断用途和授权。

### 命名规则与分组
| 前缀 | 数量 | 内容 |
|------|------|------|
| `ui_designsystem__*` | ~120 | 主 UI 图标（工具/导航/操作） |
| `ui_tools__*` | ~40 | 笔刷样式/粗细指示器/胶带花纹/色轮 |
| `ui_text__*` | ~18 | 文本格式（bold/italic/list/align） |
| `core_paper__*` | 15 | 纸张模板预览图（webp） |
| `app_widgets__*` | ~15 | 桌面小组件 |
| `feature_login__*` | ~5 | 登录页插画 |

### 多层叠加系统（每个工具图标 = 多层组合）
```
shadow    → 底部阴影层
fill      → 填充色层
outline   → 轮廓线层
highlight → 选中高亮层
overlay   → 顶部覆盖层（部分图标）
```
示例：`ui_designsystem__text_fill.xml` + `_outline` + `_highlight` + `_shadow` + `_overlay` = 完整文本工具图标

### 笔刷样式图标（对应 z21 枚举）
- `ui_tools__brushstyle_mono/taper/dashed/dotted` — 4 种笔刷样式
- `ui_tools__strokeindicator_{mono/taper/dash/dot}_size{1/2/3}_{fill/outline}` — 24 个粗细预览

### 胶带花纹（8 种）
`ui_tools__tape_pattern_{checkers/dots/flowers/grid/hearts/stars/stripes/waves}`

### 特殊图片资源
| 文件 | 位置 | 用途 |
|------|------|------|
| `ui_renderer__pencil_splat.png` | drawable-nodpi | 铅笔纹理（10.7KB） |
| `blank_stroke_dot.png` | drawable-xxhdpi | 空笔画点 |
| `feature_settings__upsell_illustration.webp` | drawable-nodpi | 设置页升级插画 |
| `core_paper__paper01~15.webp` | drawable | 15 种纸张预览缩略图 |

### 移植要点
- 矢量 XML 可批量转鸿蒙 SVG（提取 `<path android:pathData="..."/>`）
- 多层叠加在鸿蒙用 Stack + 状态切换实现
- 实际纸张背景继续程序化生成；预览图可重新渲染，直接复用原资源前需确认授权

## 35. 普通 ink 可变宽度审计 🟡（2026-08-02 复核）

### 结论

“钢笔/荧光笔统一固定宽度，VARIABLE_WIDTH 只用于检测”不成立。当前证据已确认：

1. Taper 样式明确映射为 `VARIABLE_WIDTH`。
2. 普通 ink 点可携带 `fc0.e()` 逐点宽度因子。
3. `w4a.b()` 在普通 ink 的实际路径中构造可变宽度轮廓。
4. `jz5` 的 VARIABLE_WIDTH→FIXED_WIDTH 只发生在 `calculateForShapes`，不能代表普通 ink。

### 证据链

| 证据 | 位置 | 结论 |
|------|------|------|
| Taper→VARIABLE_WIDTH | `dxe.a()` | 样式层明确选择可变宽度 |
| 任一点 `fc0.e()!=1` 即判 VARIABLE_WIDTH | `hy5.e()` | 逐点宽度数据真实参与语义判断 |
| 多处读取 `fc0.e()` 并构造局部半宽 | `w4a.b()` | 存在中心线→轮廓实现 |
| 普通 ink 调用 `w4a.b()` | `y5a.n()`、`hz5.g()` | 轮廓算法并非只用于识别/编辑 |
| 日志名 `calculateForShapes` | `jz5.invokeSuspend()` | 该类分支只处理形状 |
| 形状拒绝 variable width | `gb8/wm2` 文案及 `jz5` 分支 | 只能证明形状固定宽度 |

“搜索不到 StockBrushes/pressurePen”最多说明未找到该官方笔刷构造路径，不能反证 Notability 自研的逐点宽度未被使用。

### 尚未闭环

- `fc0.e()` 的完整写入/生成来源。
- Pen、Highlighter、Taper 的默认宽度曲线，以及 pressure 是否直接或经平滑后参与。
- `w4a.b()` 尖角、自交、极短段的完整可读伪代码。

### 对鸿蒙实现的影响

- 数据模型必须允许每点 width factor。
- 渲染层至少有“固定中心线”和“可变宽度填充轮廓”两条路径。
- 仅实现 `strokePath + 末端三角` 可作为早期降级，但不等价于原版 Taper/VARIABLE_WIDTH。

---

## 36. HarmonyOS 手写低延迟能力 🟡（2026-08-02 官方文档复核）

### 结论

华为 HarmonyOS SDK 已公开报点预测和手写笔帧加速能力，但这不能自动外推成 OpenHarmony 上游通用能力，官方资料也未保证本应用端到端 `2ms` 或 `<16ms`。`RenderNode` 不是已证实的 Android SurfaceControl/前端缓冲直接等价物。最终路线和指标必须在目标 MatePad、目标系统版本与目标 SDK 上量测。

### Pen Kit 报点预测

ArkTS：

```ts
import { PointPredictor } from '@kit.Penkit';

getPredictionPoint(event: TouchEvent): TouchPoint
```

- Stage 模型。
- `SystemCapability.Stylus.Handwrite`。
- 起始版本 **5.0.0(12)**，不是 API 20。

C API（`native_handwrite_api.h`），起始版本 **6.0.0(20)**：

```c
int32_t HMS_HandWrite_GetPredictPoint(
    const HandWrite_HistoricalPoint* event,
    int32_t size,
    float* predictPointX,
    float* predictPointY
);
```

API **26.0.0 Beta** 另有：

```c
int32_t HMS_HandWrite_SetRefreshDelayOff(
    const char* xcomponentId,
    const bool enable
);
```

### StylusFrameBoost（API 26.0.0 Beta）

```ts
import { StylusFrameBoost } from '@kit.Penkit';

forceRefreshOneFrame(action: number): number
```

官方限制：

- 需要 `ohos.permission.STYLUS_FRAME_BOOST`。
- 设备必须已连接手写笔。
- 应用屏幕刷新率必须大于 60Hz。

它表示平台提供“请求一帧跟手性加速”的能力，不等于对端到端上屏延迟作固定数值承诺。

### 压感范围纠错

- `HandWrite_HistoricalPoint.force` 官方只写“压力值”，**未规定取值范围**。
- ArkTS `TouchPoint.pressure` 从 API 15 起给出的范围是 `[0,65535)`。
- 旧文的“0-8192 级”和“5ms~200ms 可配置采样周期”没有 Pen Kit 官方证据，已删除。
- 移植时必须在目标设备上记录 raw range，再归一化到内部 `[0,1]`；不要硬编码 8192。

### RenderNode 的真实边界

- RenderNode 是自绘制渲染节点，支持节点树、属性、变换、裁剪、遮罩等。
- `draw(context: DrawContext)` 的 Canvas 是**记录指令的临时 Canvas，并非节点真实 Canvas**。
- `invalidate()` 会触发重新渲染并重新执行 `draw()`。
- 官方参考没有承诺 FRONT_BUFFER、SurfaceControl Transaction 或硬件层交接语义，因此不能直接写成 SurfaceControl 等价物。

### 建议的可测架构

```text
输入层：真实点 + history + PointPredictor 预测点（分轨）
几何层：Force smoother + cubic fitter + 可变宽度轮廓
渲染层：已完成层缓存 + 当前笔画层 + 脏矩形
加速层：可用时调用 StylusFrameBoost；失败时不影响正确性
测量层：eventTime / 接收 / 绘制提交 / 可观察上屏时间
```

至少报告平均、P50、P95、最大值、掉帧、设备/系统/刷新率，并分别比较开启/关闭预测和帧加速。

### 官方资料

- [PointPredictor](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/pen-pointpredictor)
- [HandWrite C API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/pen-handwrite-c)
- [HandWrite_HistoricalPoint](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/pen-handwrite-struct-historicalpoint)
- [StylusFrameBoost](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/pen-stylusframeboost)
- [手写笔跟手性加速接入与限制](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/pen-stylus-frame-boost)
- [TouchEvent/TouchPoint](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-universal-events-touch)
- [RenderNode](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-arkui-rendernode)

---

## 37. HarmonyOS 纹理与 Shader 能力边界 ✅（2026-08-02 官方文档复核）

### 结论

Android `RuntimeShader` 使用的 AGSL 源码不能原样移植，**但不能因此概括为“HarmonyOS 无 Shader”**。目标端有三层可验证路线：Canvas 2D 遮罩合成、ArkGraphics 2D `ShaderEffect`、XComponent + EGL/OpenGL ES。三者的效果和性能都需用同一批 splat 数据做基准，不能预先声称“完全还原”。

### 能力分层

| 路线 | 可用能力 | 适用阶段 | 关键边界 |
|------|----------|----------|----------|
| Canvas 2D | `OffscreenCanvas`、`drawImage`、`source-in` 遮罩着色 | MVP 首选 | 无 `drawVertices` 直接等价；逐 splat 调用与离屏合成成本需实测 |
| ArkGraphics 2D | API 12+ Color/Gradient Shader；API 20+ `ImageShader`/`ComposeShader`，并有 `SRC_IN`/`MODULATE`/`MULTIPLY` BlendMode | 第二阶段 | 不是任意 AGSL 源码运行器；`ImageShader` 用于录制类型画布有官方性能提醒 |
| XComponent + EGL/OpenGL ES | 自定义 GLSL、四边形批次、纹理采样和混合 | 基准证明前两层不足时 | 工程和生命周期成本最高；效果/延迟仍需真机验证 |

### Canvas 2D MVP 映射

```text
Android RuntimeShader tint     → 离屏绘制 splat alpha，再以 source-in 填充笔色
Android drawVertices quads     → drawImage + translate/rotate/scale 逐 splat 绘制
Android scratch/batch bitmap   → OffscreenCanvas 累积后再合成到主画布
Android 颜色过滤缓存           → Map<color, offscreen image/pixel map>
```

- 不再使用旧文的 `globalCompositeOperation = 'multiply'`：ArkUI Canvas 2D 的字符串合成模式与 ArkGraphics `BlendMode.MULTIPLY` 不是同一套 API；MVP 使用已核验的 `source-in`，需要 multiply/modulate 时转到 ArkGraphics 2D 并实测。
- 不再假设 Canvas 2D “无需考虑 RGBA_F16”。色带、透明度叠加和多次合成可能受色彩空间/精度影响，应纳入截图差分与性能基准。
- `ShaderEffect.createImageShader`/`createComposeShader` 可用于 API 20+ 路线，但 RenderNode 等录制画布场景要特别验证官方所提示的性能风险。

### 推荐验证顺序

```text
1. Canvas 2D + OffscreenCanvas + source-in：验证正确性与最低工程成本
2. ShaderEffect(API20+)：验证批次、BlendMode、录制画布性能
3. XComponent + OpenGL ES：仅在前两层无法达到效果/吞吐目标时投入
```

### 官方资料

- [Canvas 画布绘制通用属性（含 globalCompositeOperation）](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-components-canvas-common-property)
- [OffscreenCanvas](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-components-offscreencanvas)
- [ShaderEffect](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-graphics-drawing-shadereffect)
- [ArkGraphics 2D BlendMode](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-graphics-drawing-e#blendmode)

---

## 38. 启动状态机与本地登录绕过 v14 ✅（2026-08-02 静态+运行时复核）

> 朋友协作完成 v14，在本地模拟器的离线 UI/架构研究范围内进入资料库 `o77` 与笔记编辑器。
> 完整推理链、环境和限制见 `LOGIN_BYPASS_RETROSPECTIVE.md`。

### 启动四层状态（关键认知：不要把「用户」当成一个变量）
```
Compose 初始化状态      r26.a（CompositionLocal）
登录页面展示状态        zn7（LoginState）
用户域真实状态          hnf.e（完整 vmf 用户 Flow） / hnf.f（tmf 身份 StateFlow）
主导航状态              aq8 / jk8（导航栈：si7 启动 → o77 资料库 / dn7 登录）
```
在本次冷启动路径中四层必须保持自洽；只伪造 `zn7` 已通过 v13 对照实验确认不足以进入主导航。

### 关键条件（un7.java）
```java
// 只有 user != null && initializedLogin == false 才触发跳转！
if (zn7Var2.a != null && !zn7Var2.c) {
    function0.invoke();  // resetToLibraryOrSurvey()
}
```
静态条件明确证明：把 `initializedLogin` 强制为 `true` 会阻止该跳转。把它解释成“初始化动作已消费”是目前最符合行为的命名恢复，但字段的原始 Kotlin 名称仍未从 metadata 闭环。

### 加载阶段的直接阻塞点（hp8 case 5）
```java
bp.U(hnf.e, continuation)  // = Flow.first()，等待 hnf.e 的首个用户值
```
本次实验中，页面离开登录界面后直接等待 `first(hnf.e)`；给该流提供首个 `vmf` 后导航继续。因此“用户流无首值”是已验证的直接阻塞点，但不能据此排除服务器/会话逻辑可能是上游未发射的原因。

### v14 当前已验证方案
1. `knd.$init/k` 拦截：zn7 重建为 user=fake + **initializedLogin=false**
2. `hnf.$init(w55, nmf, cr4, ou6)` 后反射替换：
   - `hnf.e` = `kbb(c3d(1, 1, SUSPEND))`，预发射 fake vmf
   - `hnf.f` = `knd(fake tmf)`
   - 同一 `iof` 贯穿 fakeId/Identity/User（一致性）
3. `bp.U(sj4, ce2)` 窄范围 fallback：仅对 tracked hnf.e 实例返回 fake vmf
4. `r26.a` 按 key 匹配返回 TRUE（hook xi7.K）
5. 防登出：block `cr4.a(String)`；`aq8.s()`（resetToLogin）重定向到 `aq8.r()`（resetToLibrary）
6. 导航验证：hook `jk8.e` 记录导航栈，证明真正进入 `[o77]` 而非表面 UI

### 验证结果
- 本地模拟器：登录页 → 加载阶段 → 资料库主页面 `o77` → 笔记编辑器，均有运行时/画面证据。
- 截图：`Screenshot/notability_v14_home.png` / `notability_v14.png` / `notability_v14_library.png`
- 脚本：`frida_scripts/bypass_login_v14.py`（20 秒自动诊断：`--duration 20`）
- 导航：`jk8.e` 日志观察到 `[si7] → [o77]`，不是仅覆盖登录页的表面 UI。
- 边界：脚本不创建真实账户或云端会话；Hook 不持久化，下次冷启动仍需重新注入。

### 证据分层

| 层级 | 证据 | 结论 |
|------|------|------|
| 静态 | `un7.java:1478-1481` | `user != null && !initializedLogin` 才触发跳转 |
| 静态 | `hp8.java:169-188` | case 5 等待 `first(hnf.e)` 后更新导航 |
| 静态 | `hnf.java:14-25` | `e` 为 `kbb` 用户流，`f` 为 `ind` 身份流 |
| 静态 | `aq8.r/s()` + `t78` case 6/7 | 两个 reset 分别落到 `o77` / `dn7` |
| 运行时 | v14 日志、`jk8.e` 导航栈、三张截图 | 本地模拟器已进入资料库和编辑器 |

### 对鸿蒙版的指导
- 状态分层：展示状态/用户域状态/导航状态必须职责分离
- 避免启动流程依赖多个隐式 Flow（`first()` 永远等待是常见坑）
- 导航成功与否要验证状态机，不能只看 UI

---

## 39. UI 根入口、双层路由与一比一移植地图 🟡（2026-08-02 静态+运行时复核）

> 结论：现在已经不只是“根据截图猜 UI”。根 `ComposeView`、主导航、资料库页面、笔记页面及笔记内部导航都已定位；截图可用于视觉校准，反编译代码可用于恢复结构、断点和状态来源。当前仍缺的是完整主题 token、所有弹层锚点和动画参数，因此本节标 🟡。

### 39.1 Frida 绕过与真实 UI 的边界

v14 并非简单隐藏登录页，而是使以下四层状态同时自洽：

```text
r26.a          Compose 初始化状态
zn7            登录页展示状态
hnf.e / hnf.f  完整用户 Flow / 身份 StateFlow
aq8 / jk8      主导航栈
```

因此运行日志中的：

```text
[si7] → [o77]
Main nav stack: o77 → f89
Note nav stack: zz8
```

表示应用已进入原有资料库、笔记主路由和笔记内部画布路由，不是把一张伪 UI 覆盖在登录页上。

移植时必须区分：

| 内容 | 是否属于真实产品 UI | 移植处理 |
|------|--------------------|----------|
| `o77`、`f89`、`zz8` 后的 Compose 页面、布局分支和组件状态 | 是 | 作为 UI/架构依据 |
| Frida 构造的 `vmf/tmf/iof`、重定向 `resetToLogin()` | 否 | 仅用于本地研究，不进入产品代码 |
| 假身份下的头像、订阅、云同步、Shared/Learn/AI 可用状态 | 可能失真 | 单独恢复 feature gate 和真实账户状态，不以当前空数据画面定案 |
| 本地笔记编辑器、工具按钮、响应式尺寸和导航层级 | 基本真实 | 可直接建立 HarmonyOS 页面骨架，再补动态细节 |

### 39.2 根 UI 入口与主导航

根入口调用链已闭环：

```text
decompiled/resources/AndroidManifest.xml
→ com.gingerlabs.notability.app.MainActivity
→ MainActivity.onCreate()
→ r02.a(...)
→ ComposeView.setContent(...)
→ xr7 / ag2 / yw2 / zr7 组合根包装
→ s4g.d(...)
→ aq8 ViewModel + d30 路由注册表
```

关键证据：

- `AndroidManifest.xml:112-121`：`MainActivity` 为 `MAIN/LAUNCHER` Activity。
- `MainActivity.java:341-462`：`onCreate()` 最终调用 `r02.a(this, new n12(new xr7(this, 2), ...))`。
- `r02.java:8-33`：复用或创建 `ComposeView`，调用 `setContent()` 并设为 Activity 内容视图。
- `zr7.java:84`：根包装最终进入 `s4g.d(...)`。
- `s4g.java:652`：`s4g.d` 创建/订阅 `aq8`，并构造 `d30` 路由注册表。

已闭环的主干路由：

| 混淆类 | `toString()` / 含义 | 注册位置 | 页面入口 |
|--------|----------------------|----------|----------|
| `si7` | `LoadingRoute` | `s4g.java:1338` | `t33` |
| `dn7` | `LoginRoute` | `me8.I()`，由 `s4g.java:1551` 调用 | `vn7` / 登录 Composable |
| `o77` | `LibraryRoute` | `tni.I()`，由 `s4g.java:1387` 调用 | `c1(I=4)` → `bc(I=2)` |
| `f89` | `NoteRoute(...)` | `s4g.java:1542` | `c1(I=9)` → `i37(I=4)` |

主栈并非一次性局部变量：

- `aq8.b0 = jk8.d`：内存中的主路由列表状态。
- `jk8.c`：SavedState 中序列化后的 `navBackStack`。
- `jk8.e(...)`：同时提交序列化栈和内存栈，并打印 `Main nav stack updated`。
- 2026-08-02 运行时 `logcat` 再次观察到 `nav.stack: o77, f89`，证明资料库打开笔记时主栈确实新增 `f89`。

### 39.3 资料库 `o77` 的页面层级与状态源

```text
o77 LibraryRoute
→ tni.I(...)
→ c1(I=4)
→ bc(I=2/default branch)
→ b87.b(...)
→ p87 ViewModel
→ p87.g() UiState Flow
→ h87 Loaded
→ p77
→ b87.a(...)
   ├── xbh.g / xbh.h       左侧导航
   └── hp0.c               主内容分发
       ├── section == bjc.a → zlh.a  Home
       └── 其它 section     → zf9.b  Notes / Shared / Folder
```

`h87.toString()` 直接恢复了 Loaded 状态字段：

```text
Loaded(
  section,
  noteCount,
  searchQuery,
  highlightNoteId,
  learnCards,
  favoriteNotes,
  recentNotes,
  showFavoriteNotes,
  showRecentNotes,
  showNoteLimitAlert,
  starterNoteLimitEducation
)
```

Section 类型和侧栏入口：

| 类型 | 页面含义 | 静态证据 |
|------|----------|----------|
| `bjc.a` | Home | `xbh.java:736`、`hp0.java:128` |
| `cjc.a` | Notes | `xbh.java:775` |
| `djc.a` | Shared with me | `xbh.java:782` |
| `ajc(jof)` | Folder | `ajc.java` + `xbh` 文件夹列表 |

内容分发不是仅由字符串推断：`hp0.java:128-140` 明确在 Home 调 `zlh.a(...)`，其它 Section 调 `zf9.b(...)`。

- `zlh`：Let's get started、Recent notes、Favorite notes、Record a lecture、Take notes、Up next to learn。
- `zf9`：搜索、排序、Grid/List、空状态；`eg9` 过滤为 `ALL_NOTES / RECENT / FAVORITES / UNFILED`。

### 39.4 资料库响应式规则

`b87.a(...)` 中存在可直接迁移的 dp 断点：

| 条件 | 侧栏目标宽度 | 内容列数 |
|------|--------------|----------|
| 屏宽 `< 600dp` 且无常驻侧栏 | `0dp` | 2 |
| 屏宽 `600-839dp` 且无常驻侧栏 | `0dp` | 3 |
| 屏宽 `840-951dp` | `280dp` | 2 |
| 屏宽 `952-1399dp` | `332dp` | 3 |
| 屏宽 `>= 1400dp` | `332dp` | 4 |

对应证据：

- `b87.java:61`：`840dp` 决定是否常驻显示侧栏。
- `b87.java:109`：`952dp` 决定侧栏为 `332dp` 或 `280dp`。
- `b87.java:113-126`：`1400/952/600dp` 决定 4/3/2 列。

这组规则应优先于从一张 1920×1080 截图按百分比猜宽度。

### 39.5 编辑器 `f89` 与笔记内部导航

`f89.toString()` 直接恢复了路由参数：

```text
NoteRoute(
  id,
  initialTool,
  pendingCameraImageUri,
  librarySearchQuery,
  pendingSpanKey,
  restoredFromNoteId,
  initialLearnMode
)
```

主路由到笔记内部导航的调用链：

```text
f89
→ s4g.d 路由注册
→ c1(I=9)
→ i37(I=4)
→ c29.a(noteId) 取得 note-scoped x20
→ a59
→ xs7.a(...)
→ 独立的笔记内部 d30/hk8 导航栈
   ├── zz8 = NoteCanvasRoute（默认）
   ├── nb2 / uk5 / prf / h8g 等内部页面
   └── AdaptivePanelRole / ListDetailPane 相关路由
```

运行时日志与静态代码相互印证：主栈是 `o77, f89`，内部栈单独打印 `zz8`。HarmonyOS 版也应保留“两级导航”，不要把编辑器面板全部塞进应用主导航栈。

默认画布链：

```text
zz8
→ t09.e(...)
→ r99 ViewModel
→ v89 UiState
→ t09.d(...)
→ s89 Loaded
→ f09 → t09.f(...)
→ a90.g(...) + yue.c(...)
→ yue.d(...) / cxe 画布与主编辑布局
```

`v89` 的页面状态：

| 类 | 含义 |
|----|------|
| `t89` | Loading |
| `r89` | LoadFailed |
| `q89` | DownloadFailed |
| `p89` | AccessDenied |
| `u89` | NoteDeleted |
| `s89` | Loaded |

`s89` 字段包括：`noteId`、`title`、`content`、`isRendered`、`useBezier`、`showTileBorder`、Force smoothing 参数、`stylusConnected`、`eyedropperState`、`isContentBlank`、`isEditable`。

### 39.6 截图中的编辑器组件已对应到代码

| 截图区域/动作 | 代码入口 | 当前结论 |
|---------------|----------|----------|
| 顶部浮动工具栏及工具状态 | `a90.g(...)` + `p4f` | 根入口与状态流已定位，样式弹层/动画仍需逐个量测 |
| 笔记画布和整体编辑布局 | `yue.c/yue.d` + `cxe` | 真实内容区，不是截图背景 |
| Undo / Redo | `i4f` | 图标、enabled 状态和 action 已定位 |
| Learn / Smart Notes 面板 | `dg2` | 面板 toggle 已定位 |
| Pages/content manager | `wo8(I=2)` | 右栏第二个 toggle 已定位 |
| Share | `ld1(I=13)` | 分享 action 已定位 |
| More options | `me8` | 右栏更多菜单入口已定位 |
| 空白笔记底部 Record / Import / Scan / Capture and add | `s30` + `wu3` | 由 `isContentBlank` 等状态控制 |
| 插入菜单 Add Files / Add Photo / Take Photo / Add GIF / Insert Math | `bc(I=0)` | 文案、图标和 action 分支已定位 |

### 39.7 单设备运行时尺寸基线

模拟器报告物理尺寸 `1080×1920`、density `280dpi`；当前横屏 UI dump 为 `1920×1080`、rotation=1，因此：

```text
1dp = 280 / 160 = 1.75px
```

UIAutomator 在真实 Compose 页面量到：

| 元素 | 像素边界 | 换算结果 |
|------|----------|----------|
| 资料库主内容分界 | `x=581px` | 侧栏正好 `332dp`，与 `b87` 的 `>=952dp` 分支一致 |
| 资料库选中导航行 | `[28,168][553,252]` | 左右约 `16dp`，宽 `300dp`，高 `48dp` |
| 资料库搜索框 | `[623,84][1829,168]` | 内容区左边距 `24dp`，高度 `48dp` |
| Add note 浮动按钮 | `[1766,926][1878,1038]` | `64dp`，距右/下约 `24dp` |
| 编辑器 Back 点击区 | `[42,42][126,126]` | `48dp × 48dp`，顶/左边距 `24dp` |
| 编辑器主工具栏 | `[518,42][1402,126]` | 高 `48dp`，宽约 `505dp`，顶部 `24dp` |
| 单个工具点击区 / 图标 | `84px / 42px` | `48dp` 点击区内放 `24dp` 图标 |
| 编辑器右侧工具轨 | `[1794,42][1878,560]` | 宽 `48dp`，顶部 `24dp` |

这些是当前 280dpi 横屏设备的实测基线，可用于首版一比一对齐；不能外推成所有屏幕的固定绝对坐标，仍应执行上面的响应式规则。

### 39.8 截图证据需要正确命名

| 文件 | 实际内容 | 证据用途 |
|------|----------|----------|
| `Screenshot/notability_v14_home.png` | 资料库壳，左侧实际选中 **Notes**，并非 Home 内容 | 资料库常规态、侧栏、搜索、Tab、Grid、FAB |
| `Screenshot/notability_v14_library.png` | 同一 Notes 页面打开笔记上下文菜单 | 菜单宽度、分组、图标和锚点参考 |
| `Screenshot/notability_v14.png` | 空白笔记编辑器 | 工具栏、右侧工具轨、标题区和底部快捷入口 |
| `Screenshot/current_state.png` | 旧的加载圈阻塞状态 | 只用于登录绕过排障，不代表目标 UI |
| `N1.webp`–`N4.webp` | 营销素材 | 只作视觉/功能参考，不作当前 Android 运行时尺寸证据 |

### 39.9 HarmonyOS 推荐页面结构

```text
AppRoot
├── SessionStore                 展示/用户域状态分离
├── MainNavStore                对应 aq8/jk8 主栈
└── MainNavigation
    ├── LoadingPage
    ├── LoginPage（真实产品认证，不含 Frida 假用户）
    ├── LibraryPage
    │   ├── AdaptiveSidebar     840/952dp 断点
    │   └── LibraryContent      Home 或 Notes/Shared/Folder
    └── NotePage(noteRouteArgs)
        ├── NoteLocalNavigator  对应 xs7，默认 CanvasRoute
        ├── EditorChrome        顶部工具栏/右侧工具轨/弹层
        └── NoteCanvas          Canvas/XComponent 渲染层
```

实现原则：

1. Android `dp` 在 ArkUI 中先按 `vp` 保留语义，不把 1920×1080 像素坐标硬编码。
2. `h87`、`v89` 这类 UiState 使用明确的联合状态/状态机，Loading/Error/Loaded 分支不要混在一个布尔集合里。
3. 主导航和笔记内部导航分离，保证 Pages/Learn/Smart Notes 等面板不会污染应用级返回栈。
4. 先复刻结构、断点、点击热区和状态切换，再校准颜色、字体、圆角、阴影、动画和菜单锚点。
5. Frida 绕过只作为进入真实 UI 的研究工具；HarmonyOS 产品版必须有独立、可测试的账户和离线状态模型。

### 39.10 仍需动态量测

- 主题色板、字体家族/字重/行高、圆角、描边、elevation/shadow 的 token 来源。
- 工具选择、二级工具条、菜单、侧栏和 List/Grid 切换的 duration/easing。
- 600/840/952/1400dp 临界点前后的真实重排、折叠侧栏和窗口 resize 行为。
- 笔记上下文菜单、工具属性面板、Learn/Pages 面板的锚点、最大宽高和避让规则。
- Light/Dark、空/有内容、可编辑/只读、无网络/真实账户等状态矩阵。

---

## 40. HarmonyOS 适配层架构（API 版本演进兼容）✅ 2026-08-02

> 结论：当前基于 API 20+（模拟器 6.0.1）开发，**鸿蒙 7 的新 API 不会破坏架构**——
> 前提是核心代码不直接调平台 API，全部经由适配层接口。

### 设计动机（从 Notability 学到的教训）

原版用 `ICanvas` 接口解耦 MyScript GLRenderer（§4），使渲染后端可替换。
鸿蒙版同样用接口隔离**鸿蒙 API 版本差异**：鸿蒙 API 是增量增强（向前兼容），
7 的新能力只是「更好的实现」，不是「唯一实现」。

### 三层结构

```
业务层（笔记/笔画/工具/页面 —— 版本无关）
    ↓ 只依赖接口
适配层（接口定义 —— 版本差异全隔离在这里）
    ↓ 可插拔实现
实现 A（API 20 / 6.0.1）：Canvas 2D + PenEvent
实现 B（API 22+ / 鸿蒙 7）：新增强 API（未来按需添加）
```

### 三个核心适配接口

| 接口 | 职责 | 实现 A（当前） | 实现 B（未来鸿蒙 7） |
|------|------|--------------|--------------------|
| `InkInputProvider` | 笔事件采集（压感/倾斜/坐标/时间戳） | PenEvent | 7 的增强笔事件（若有） |
| `StrokeRenderer` | 笔迹渲染（Path/纹理/透明） | Canvas 2D | ArkGraphics 2D ShaderEffect |
| `Predictor` | 低延迟预测点 | 空/简单插值 | HMS_HandWrite / PenKit 增强 |

### 规则

1. 业务代码**禁止**直接 import `@ohos.*` 平台 API，只能经适配层
2. 适配层接口按「未来可扩展」设计（参数对象而非裸参）
3. 新 API 到来时 = 新增一个实现类，业务零改动
4. 鸿蒙 6.0.1 的 Canvas 方案永远有效，只是可能不是最优化解

---

*最后更新: 2026-08-02*
*反编译工具: jadx-1.5.6*
*分析状态: 手写核心审计收尾中；登录绕过 v14 与 UI 主干入口/双层路由已在本地模拟器闭环验证；鸿蒙适配层架构已确定（§40）*
*下次方向: UI 主题/动画动态量测 + 逐点宽度/平滑缺口 + HarmonyOS 目标设备 MVP（适配层接口先行）与延迟基准*
