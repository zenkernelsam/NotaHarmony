# Phase 1340 证据（里程碑）— 深度重审覆盖索引

`FINAL-REVIEW-PROMPT.md` 深度重审的整合裁决索引。
Phases 1296–1339 完成；1199 个 replay fixture 全绿。

## 原版普查（1296–1305）

Compose 引擎（slot-table/recompose/semantics/text-layout）
+ 序列化栈（FlatBuffers/protobuf-lite/Wire/Apollo GraphQL/
Socket.IO realtime/OTel）+ 全部 SDK（MyScript iink/
PDFTron/Firebase+AppMeasurement/ML-Kit/Rive/Coil3/
S-Pen/ReLinker/Singular/Mixpanel/Metro-DI/TIFF/SVG）+
完整应用包（Hilt shell/8 Room DB/CRDT/双 IAP/3 OAuth/
转写/learn/search/handwriting/`.ntb`/音频/widget×5）。

## Harmony 覆盖验证（1306–1339）

| 域 | 裁决 |
|----|------|
| CRDT 线格式 | `exc.A0` 序+64-bit pack+FlatBuffer 信封 **字节互操作** |
| `haa` 30-op | 全 `Original*Operation`+`PayloadEncoder` 覆盖 |
| `.note` iOS | bplist00+GLKeyedArchiver 导入+ZIP 导出，往返闭合 |
| `glmath` | 真原生绑定移植 |
| widgets | 5 卡片逐字节（字符串/intent/extras） |
| 算法×5 | 平滑/拟合/形状/轮廓/splat 逐方法保真 |
| 渲染 | 分层合成+几何裁剪橡皮+destination-out |
| 协作文本 | 逐字符墓碑 CRDT（REVOKE_CHARS 复活） |
| 音频关联笔迹 | u64 时间戳 seek（`h3`/`vv7`） |
| 激光笔/预测 | `zt6` 状态机 + PenKit 平台预测 |
| UI | editor+library+settings 保留原版字符串键 |
| 并发 | AsyncMutex+Inbox 强校验+LatestWriteQueue |

## fail-closed 差距（文档化）

OAuth×3、IAP×2、实时转写、MyScript 引擎本体、部分
analytics、360-video —— 均为平台/专有依赖，非移植缺陷。

## 最终裁决

Harmony 移植为**忠实移植**：线格式字节互操作+算法
逐方法保真+UI 字符串键保留。未反编译资源（调色板/
emoji 全量）显式文档化近似。
