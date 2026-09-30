# Phase 1159 证据 — com.myscript.iink 手写识别 SDK 边界

来源：`com/myscript/iink/`（73 Java 文件 + graphics/ + text/）。

## MyScript Interactive Ink SDK

```java
Engine            // 识别引擎（native 后端）
Editor            // 编辑会话（笔画→内容块）
ContentPart/Block/Package/Selection   // 内容模型
HandwritingGenerator/Profile/Result   // 手写生成器
IImagePainter/IRenderTarget/IRendererListener  // 渲染
GLRenderer                              // GL 渲染
HistoryManager                          // 历史
ToolController/IGestureHandler/GestureAction   // 手势/工具
ChangesetOperation/Type                // 变更集
MathVariableDefinition(s)              // 数学变量
graphics/ text/                        // 子包
```

## 判定：fail-closed 边界

- **专有 native SDK**：MyScript iink 是闭源商业手写识别
  引擎（`Engine`/`Editor` 下有 native 后端），无 HarmonyOS
  开源等价。
- Notability 的手写→文本/数学识别 = iink —— HarmonyOS
  上**必须 fail-closed**（不 stub 识别结果）。
- 渲染面 `IImagePainter`/`IRenderTarget` 是 SDK 回调
  （iink 绘制字形/块）—— 识别功能缺失时整块关闭。

## 与笔记耦合

- `Editor`/`ContentBlock` ↔ 文本块实体（`cie`/`hp5` 的
  `m4c` member-collection 里的 ink 实体）。
- `HandwritingGenerator` = 手写合成（生成假手迹?）。
- `MathVariable*` = 数学变量识别（LaTeX 域）。

## Harmony 决策

- **fail-closed ADR**：iink 手写识别不可移植 —— Harmony
  上 ink 实体只读渲染已有笔画，识别 API 抛
  `UnsupportedOperationException` 等价。
- 不写假识别；`Engine`/`Editor` 全部关闭。

## 产出

- fixture `d02-iink.mjs`（10 断言）。
- ADR-1103（fail-closed）；中文报告。
