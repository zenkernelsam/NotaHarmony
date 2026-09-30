# ADR-1074：文本 op 应用记录谱系

## 状态

已接受（Phase 1130）。

## 决策

- `e4c.b` ordinal 分派：7=uwc 插字符、8=twc 插串、9=vwc
  删、10=wwc 范围删、11=xwc 恢复、12-14=f4c 标记、
  28=f4c(bl2) tombstone op。
- `ywc`/`i4c` 基类/接口；`h4c`/`f4c` 两类记录。

## 依据

完整分派表 + `{element|tombstone, opId}` 记录结构。

## 后果

Harmony 文本应用 = ordinal→记录工厂；恢复带 item 向量；
删除 op 直产 tombstone。
