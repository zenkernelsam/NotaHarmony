# ADR-1060：op 重序列化 + v71 零拷贝

## 状态

已接受（Phase 1116）。

## 决策

- `kci.j(f46,a)` = op 表复制进新 builder（重写/再打包）。
- `dbj.c` = createString + `v71` 零拷贝（字节直灌 ByteBuffer）。
- `sg5.b` = thread-local 序列化 scratch。

## 依据

`h(6,bb)`/`g(6)` 取字节 + `a.m(bb)` 重创 + v71 fast-path。

## 后果

Harmony：op 重写走 builder 重建；字节串 CharSequence 用
ArrayBuffer 直灌，免重复编码。
