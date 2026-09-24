# 原版 Learn / AI 学习面 — JADX 证据（2026-09-24，Phase 703）

来源：`decompiled_1.0.3`（JADX）strings.xml + ac4.java + learn 包。

## 字符串面（约 126 条）

| 前缀 | 条数 | 内容 |
|------|------|------|
| `feature_learn__*` | 17 | chat（input_placeholder/send/history_error）、quota/error |
| `feature_learn_quiz__*` | 50 | 四种学习模式、fill-in-the-blank、flashcard rating、quota limit |
| `feature_learn_summary__*` | 17 | Smart Notes（AI Generating/Analyzing Transcripts/onboarding） |
| `feature_learn_transcription__*` | 15 | Transcripts 面板（Listening/Transcribing/quota 提示/搜索） |
| `ui_learn__*` | 27 | 学习模式标签/进度/描述 |

## 旗标域（ac4.java）

| 字段 | 旗标名 | 序号 | 消费点 |
|------|--------|------|--------|
| u0 | SHOW_TRANSCRIPTS | 36 | `x90:10475` 转录条目渲染 |
| v0 | LIVE_TRANSCRIPTION | 37 | — |
| x0 | LEARN_SUMMARY | 39 | `a99`（z0&&x0→w77:k87）、`cqi` |
| y0 | LEARN_LATEX | 40 | — |
| z0 | SMART_NOTES | 41 | `a99`、`l6e` |
| A0 | LEARN_QUIZZES | 42 | `hb7`/`lv4`/`n3`/`np0` |
| B0 | LEARN_FLASHCARD_RATING | 43 | — |
| C0 | LEARN_OFFLINE | 44 | — |
| D0 | LEARN_CHAT | 45 | — |
| E0 | AI_REGION_ALLOWED | 46 | `ph.java` 地区门 |

## 后端依赖证据

- `com.gingerlabs.notability.data.learn.b`：直接引用
  `com.apollographql.apollo.exception.{ApolloException,
  ApolloHttpException, ApolloNetworkException}`——Apollo GraphQL
  私有后端。
- `LearnError`（sealed Exception）：LLMBadResponse / ContentTooShort /
  InsufficientContext / JobFailed / Timeout / LearnRequestError /
  Network / **Subscription** / **QuotaLimit** / BatchNotFound /
  **AiDisabled** / NoContent——错误域证明 LLM + 订阅 + 配额 + 开关。
- `LearnDatabase extends x5c`（Room）：本地缓存，内容由后端生成。
- `z9b`：`QuizQuestion.MultipleChoice.Answers` 序列化器；`w57`：
  Memorize/Practice/Test/MixAndMatchDevOnly 四模式。

## Harmony 侧核对

`grep -rln "learn\|Learn\|transcript\|Transcript" note/src/main/ets`
仅命中无关项（"Learn More" 说明链接、`learn-from-home` 深链）——
无任何 Learn 入口/实现，等价于旗标关闭态。

## 结论

Learn/AI 学习面整体 fail-closed（ADR-0652）：私有 LLM 后端 +
订阅配额 + 地区门三重外部依赖，无等价 Harmony 服务面。
