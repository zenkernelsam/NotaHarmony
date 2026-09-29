# Phase 1015 证据 — 测验/学习子系统（5 表）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 表（e47 DDL）

### `QuizSession` PK(noteId, mode)

```sql
noteId BLOB, id TEXT,      -- 会话 UUID
mode TEXT,               -- quiz 模式（quiz/flashcards?）
numQuestions INT, numAnswered INT,
createdAt INT, updatedAt INT, completedAt INT?,
lastViewedQuestion TEXT,
questions TEXT           -- JSON 序列化题集
```

- 每笔记每模式一行；恢复会话靠
  `lastViewedQuestion` + `questions` JSON。

### `QuizOp`（答题账本）

```sql
opId AUTOINCREMENT PK, noteId, mode, sessionId,
isCompleteSession INT,
questionIndex INT?, status TEXT?,
multipleChoiceAnswer TEXT?,
fillInTheBlankAnswer TEXT?,
flashcardRating TEXT?,        -- 三型作答列
createdAt INT
```

- 三种答题类型共存：`multipleChoiceAnswer` /
  `fillInTheBlankAnswer` / `flashcardRating` 互斥用。

### `SummaryEntity` PK(noteId)

```sql
noteId BLOB PK, markdown TEXT   -- AI 摘要 markdown
```

### `LearnJob` PK(noteId)

```sql
noteId BLOB PK, batchId TEXT, language TEXT?,
creationDate INT, asrHashes TEXT   -- ASR 哈希集
```

- 服务端 ASR/学习任务跟踪；`asrHashes` 幂等。

### `StudyItemsInfo` PK(noteId)

```sql
noteId BLOB PK, fetchTime INT, textLength INT,
handwrittenTextLength INT, audioHashes TEXT
```

- 学习项内容度量 + 音频哈希。

## 写形（na4 binders）

- `QuizOp`：`INSERT OR ABORT` + `nullif(?,0)`。
- `QuizSession`：plain INSERT 10 列。

## HarmonyOS 决策

- 全表平移 relationalStore。
- **AI 测验/摘要/ASR 生成全部后端依赖
  fail-closed**；本地读写保留（兼容导入数据）。
- `questions`/`asrHashes`/`audioHashes` 为 TEXT
  JSON/分隔串 —— 列类型保留。

## 产出

- fixture `d02-quiz-learn.mjs`（11 断言）。
- ADR-0959；中文报告。
