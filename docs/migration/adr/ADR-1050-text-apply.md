# ADR-1050：文本 op 应用状态机

## 状态

已接受（Phase 1106）。

## 决策

- `e4c` = live 文本块（哨兵 opId `{-1,0}` + gja store + al2 tombstone）。
- `e4c.b(uq9)` = op ordinal 分派：7→`e46`→`uwc` 记录；8→`f46`→
  UTF-8 ByteBuffer 解码；→ `h4c`/`i4c`。
- tombstone 判定 `swc.d(hr5)` 派生锚 + `xj2.f` 查 tombstone map。

## 依据

ordinal 分派 + UTF-8 解码 + 锚位序 + tombstone。

## 后果

Harmony 文本应用 = op 路由 + UTF-8 解码 + tombstone 过滤 +
位序定位；哨兵 opId 作起始锚。
