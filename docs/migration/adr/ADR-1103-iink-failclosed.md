# ADR-1103：MyScript iink 手写识别 — fail-closed

## 状态

已接受（Phase 1159）—— **fail-closed**。

## 决策

`com.myscript.iink`（73 文件：Engine/Editor/ContentPart/
HandwritingGenerator/GLRenderer/IRenderTarget）= 专有
商业手写识别 SDK —— **不可移植，HarmonyOS fail-closed**。

## 理由

- MyScript iink 是闭源商业引擎（native 后端），无
  HarmonyOS 开源等价；不能 stub 识别结果（违反
  数据语义）。
- `Editor`/`ContentBlock` ↔ 笔记 ink 实体/文本块耦合，
  但识别 API（笔画→文本/数学）整块关闭。

## 后果

- Harmony：ink 实体**只读渲染已存笔画**（序列化数据），
  识别相关 API（`Editor.recognize`、`HandwritingGenerator`、
  `MathVariable*`）抛 `Unsupported` 等价。
- 不写假识别、不伪造结果；UI 上隐藏"手写识别"入口
  或置灰。

## 备选

若未来有 HarmonyOS 手写识别服务（系统 ScribeBoard?），
经同一 `Editor`-like 接口接入 —— 但当前 fail-closed。
