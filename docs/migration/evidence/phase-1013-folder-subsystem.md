# Phase 1013 证据 — 文件夹子系统（三表 + RawLibraryStateDatabase）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 表结构（e47 DDL）

```sql
SyncedFolderMetadata{id BLOB PK, parentId BLOB,
  updatedAt INT, title TEXT, color INT,
  siblingOrder REAL,        -- 分数排序键
  emoji TEXT?}

ClientFolderEdit{id BLOB PK, parentId?, title?,
  color?, siblingOrder?, createdAt?, updatedAt,
  uploaded INT DEFAULT false,
  idempotencyKey BLOB,      -- 幂等键
  emoji?}

ClientFolderDelete{id BLOB PK, deletedAt,
  childrenHash TEXT?,       -- 子树哈希（冲突检测）
  uploaded DEFAULT false, idempotencyKey BLOB}
```

- `siblingOrder REAL` —— **分数排序**（词典序重排
  避免全列重写）。
- 编辑行 = 稀疏更新（可空字段 = 未改）。
- `idempotencyKey` + `uploaded` = 同步账本模式
  （与 ClientOp 一致）。
- 删除墓碑带 `childrenHash` —— 服务端冲突检测。

## 实体类

- `jae` = SyncedFolderMetadata：`{utf id, utf parentId,
  long updatedAt, String title, int color,
  double siblingOrder, String? emoji}`。
- `xo1 implements yo1` = ClientFolderEdit：`{utf id,
  utf? parentId, String? title, Integer? color,
  Double? siblingOrder, xgb createdAt(Realtime),
  long updatedAt, ...}`。
- `beb` = 文件夹管理器：`{kp1 a, cx6 b, pce c-f}`。

## `jp1` = DAO + 第四数据库

```java
final class jp1 {
    RawLibraryStateDatabase a, b;
    hp1 c, e; a61 d; q36 f, g;   // 双 insert 适配器
}
```

- **`RawLibraryStateDatabase`** = 第四个 Room DB
  （主库 NoteBundleMetadataDatabase、Search、
  Transcription 之外）——文件夹原始态独立存储。
- `ip1` = INSERT binder（Phase 982 已部分记录）。

## HarmonyOS 决策

- 表平移 relationalStore；`siblingOrder` REAL
  分数序、`idempotencyKey` BLOB、`uploaded` 标志、
  `childrenHash` 全部保留。
- 同步上传 fail-closed；本地增删改正常。
- emoji 列保留。

## 产出

- fixture `d02-folder-subsystem.mjs`（14 断言）。
- ADR-0957；中文报告。
