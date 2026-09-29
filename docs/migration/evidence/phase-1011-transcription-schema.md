# Phase 1011 证据 — 转写子系统（transcriptions + segments + ncf）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 表：`transcriptions`（e47:387-391）

```sql
id INTEGER PRIMARY KEY AUTOINCREMENT,
sha512Hash TEXT NOT NULL UNIQUE INDEX,   -- 音频内容哈希=幂等键
recordingId TEXT,      INDEX
noteId TEXT,           INDEX
status TEXT NOT NULL,  INDEX             -- 状态枚举字符串
language TEXT,
fullText TEXT,
processorVersion REAL,
createdAt INTEGER NOT NULL,  INDEX
updatedAt INTEGER NOT NULL,
serverCompletedAt INTEGER                -- 服务端完成时间戳
```

- `sha512Hash` UNIQUE —— 音频指纹幂等去重；
  同音频不重转写。
- `serverCompletedAt` —— **服务端转写**
  （后端依赖信号）。

## 表：`transcription_segments`（e47:392-394）

```sql
id INTEGER PRIMARY KEY AUTOINCREMENT,
transcriptionId INTEGER NOT NULL
  FOREIGN KEY→transcriptions(id) ON DELETE CASCADE,
text TEXT NOT NULL,
startTime REAL NOT NULL,   -- 秒（double）
endTime REAL NOT NULL,
confidence REAL NOT NULL
INDEX(transcriptionId), INDEX(startTime)
```

- 段级置信度 + 时间区间；FK 级联删除。

## `ncf` = 段模型

```java
final class ncf { double a, b; ucf c; int d; }
// a=startTime b=endTime c=segment-content ucf
// d=?(chunk/speaker idx)
```

`ncf.a(...)` = copy 合成构造。

## 独立数据库

`TranscriptionDatabase` 单独 Room DB
（`TranscriptionDatabase_Impl` import）；与主库
分离 —— 大文本隔离。

## HarmonyOS 决策

- 两表平移 relationalStore（FK CASCADE + 索引保留）。
- **转写服务后端依赖 fail-closed**：Harmony 版无
  服务端转写；表结构保留以便兼容导入的原版库。
- `sha512Hash` 幂等键语义保留。

## 产出

- fixture `d02-transcription-schema.mjs`（12 断言）。
- ADR-0955；中文报告。
