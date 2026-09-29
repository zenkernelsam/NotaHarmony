# Phase 1115 证据 — kci.b 完整 op 建表配方 + dbj.c 字符串

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `kci.b(exc, String, qo5) → f46` = INSERT_STRING op 建表

```java
a buf = dk4.a(c8d);                    // 池化 builder
int iC = dbj.c(str, buf);              // createString
buf.C(3);                              // startTable(3 字段)
buf.h(1, iC);                          //   field1 = string
if (exc != null) buf.j(0, sg5.f(buf, exc));   // field0 = exc 锚 struct
if (qo5 != null) buf.j(2, rh8.O(qo5, buf));   // field2 = qo5 opId struct
int iN = buf.n();                      // endTable
buf.z(iN, 6);                          // 槽位/校验
buf.p(iN);                             // finish root
wrap(buf.A()) LE → f46.d(pos, bb)      // 绑
ybg.c(f46); rh8.q(c8d, null);          // 校验 + 回收
```

- **f46 表 = 3 字段 `{0:exc锚, 1:string, 2:qo5}`**（与读侧 `f46` 字段一一对应）。
- `dbj.c` = FlatBuffers `createString`。
- 与 `rh8.b` 同构：池 builder → 写 → 绑 → 校验 → 回收。

## `kci` 其余 = MP3/audio 头表

`a..i` 静态数组 = MPEG 音频 bitrate/sample-rate 查找表
（`{8000..48000}`、`{5,8,10,12}` 等）—— vendored 媒体解析。

## Harmony 决策

- op 建表 = startTable(n) + addField(i, v) + endTable + finish +
  bind + 校验 —— Harmony FlatBuffers builder 复刻同序。
- 锚/Id 子表走 `sg5.f`/`rh8.O` 内联 struct 写。

## 产出

- fixture `d02-op-build.mjs`（10 断言）。
- ADR-1059；中文报告。
