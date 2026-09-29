# ADR-0975 — 导入管线（boh+zb5+gg1/qma）

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3` 实证）

- `boh` 三面：`a(int×5,bool)→jqe` 条目校验/
  `c(File)→String` 读 conf/`d(InputStream,File)` unzip。
- `zb5` = 导入器接口；`gg1`/`qma` impl——
  `boh.d` unzip + `boh.c` conf + pack 缓存 +
  `"Pack for X has no conf"` IOException。
- `cu9` 三次 `boh.a` = manifest 校验。

## Harmony 决策

导入管线等价（unzip+conf+缓存）；手写包导入
fail-closed；.note 导入独立路径。

## Parity 状态

包导入等价；手写包分发 fail-closed。

## 验证

- `d02-import-pipeline.mjs`：10/10 通过。
