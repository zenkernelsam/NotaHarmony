# ADR-1059：op 建表配方（f46 三字段）

## 状态

已接受（Phase 1115）。

## 决策

- `kci.b(exc,str,qo5)` = op 建表：`dk4` 池 builder →
  `dbj.c` 字符串 → `C(3)` startTable → `h(1)` string +
  `j(0)=sg5.f exc` + `j(2)=rh8.O opId` → `n()` end →
  `z`/`p` finish → bind → `ybg.c` 校验 → `rh8.q` 回收。
- `f46` 表 `{0:exc, 1:string, 2:qo5}`。
- `kci` 含 MP3 bitrate/sample 查找表。

## 依据

完整 startTable→addField→endTable→finish→bind→validate 序列。

## 后果

Harmony op 序列化 = 同序建表；子 struct 用 sg5.f/rh8.O 内联；
builder 池化 + 校验 + 回收必做。
