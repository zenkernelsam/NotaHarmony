# Phase 856 证据 — 操作流 FlatBuffer 序列化层登记

## 目的

`com/gingerlabs/notability/core/flatbuffers` 仅剩 `ValidationException.java`，真正的
序列化面在 `defpackage` 混淆产物中。本阶段登记 1.4.2 的 FlatBuffer 使用面、表字段
容量注册表，并核对 Harmony 手写编码器的字段数引用。

## 原版证据（1.4.2，`decompiled_1.4.2/sources`）

- `defpackage/` 内 133 个文件 `import com.google.flatbuffers`；
  其中 **65 个文件含 startObject 调用（`aVarA.D(n)`）**，即表写入器。
- 字段容量注册表（节选最大表）：
  - `rbn` D(21) — 全场最大表
  - `wbn` D(20)
  - `fcn` / `n6n` D(19) — 19 字段墨迹操作表（对应 1.0.3 `wd8`，Harmony 编码器注释
    `wd8 has 19 fields`）
  - `k2h` 同文件 6 个 `D` 调用（2,2,18,2,19,19 — 复合操作携带多张子表）
  - `y6n` D(18,2) / `dqh` D(3,7,3,4,1,4) — 多表写入器
  - `hw5` D(15)，`t6n` 5 个 D 调用（含 D(10)）
  - `yag` 390 个 D 调用 — 生成的批量向量构建器（非单表）
- `1.0.3` 同层 91 个文件 import flatbuffers；`wd8`/`le8`/`td8` 为表读取类
  （无 D 调用，字段数 = 读取器访问器数量）。
- **无 `.fbs` schema 存活**：字段数只能从 `D(n)` / 读取器访问器恢复。
- `com.github.luben.zstd` 完整实现存在，但 `Zstd.` 直接调用在 app 包内为零 —
  压缩层属库运行支持，非操作线协议本身；134 个 import 中大量为
  `BuildConfig` 残留的厂商 import（与序列化无关）。

## Harmony 侧（`note/src/main/ets/`）

- `OpTypes.ets`：**19 个 `ORIGINAL_*` 扁平缓冲操作类型**（60–78 连续：
  DELETE_ENTITIES/CREATE_RECORDING/CREATE_PAGE/CREATE_INK/MODIFY_INK/
  MODIFY_POSITIONS/MODIFY_BLOCK/MODIFY_SHAPE/CREATE_GROUP/MODIFY_GROUP/
  CREATE_BLOCK/INSERT_TEXT/TEXT_VISIBILITY/MODIFY_TEXT_STYLE/
  MODIFY_PARAGRAPH_STYLE/UPDATE_CHECKBOX/MODIFY_PAGE/SET_METADATA），
  外加 40+ 历史陪伴类型（DUPLICATE_PAGE/PAGE_BOOKMARK/UPDATE_TITLE 等）。
- `data/` 下 **25 个 `Original*PayloadEncoder`** 文件手写还原字节布局：
  - `OriginalModifyInkPayloadEncoder`：`wd8 has 19 fields` ↔ `fcn`/`n6n` D(19)
  - `OriginalModifyShapePayloadEncoder`：`le8 has 17 fields` ↔ 1.0.3 同构读取器
  - `OriginalModifyBlockPayloadEncoder`：`td8 has 18 fields` ↔ `y6n`/`k2h` D(18)
- 编码器显式标注原版表容量并按 slot 填充 `fields[N]` 数组 — 逐字段 parity。

## 结论

操作线序列化层登记完毕：原版 65 个表写入器 / 133 flatbuffer 触点 vs Harmony
19 个 ORIGINAL_* 操作 + 25 个手写编码器；三个已核对的字段数引用（19/17/18）与
原版 D(n) 完全一致；zstd 为非协议厂商支持，不构成缺口。本阶段纯文档+fixture，
无源改动。
