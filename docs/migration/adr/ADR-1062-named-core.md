# ADR-1062：core/ 命名包语义锚定

## 状态

已接受（Phase 1118）。

## 决策

- 根页 id = `nti.g(rh8.b(0,-1), 0)` 合成哨兵。
- `c8d` = `SharedMemoryByteArena`（ArenaClosedException =
  IllegalStateException，关闭后访问抛）。
- `core/` 包图：analytics/common/flatbuffers/glmath/model/
  network/retrofit/user —— 真实分层。

## 依据

未混淆包名 + @Metadata Kotlin 注解 + 根页合成。

## 后果

- Harmony 根页 = `{site0, ts-1, seq0}` 同构合成。
- schema 类实名锚定（Id/SeqId/StyleMap/…/Op）。
