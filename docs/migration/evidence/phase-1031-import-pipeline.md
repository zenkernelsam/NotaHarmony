# Phase 1031 证据 — 导入管线（boh+zb5+gg1/qma）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `boh` 完整面

| 方法 | 形态 |
|---|---|
| `a(int,int,int,int,int,boolean)→jqe` | 条目哈希/元数据
  （`cu9` 调 3 次 —— manifest 校验） |
| `c(File)→String` | **读 conf/manifest** 字符串 |
| `d(InputStream,File)` | **unzip 到目录**（1030） |

## `zb5` = 导入器接口 `{b,c,d,e}`

- `boolean b(`, `void c(`, `Object d(`, `Object e(`
  ——导入器统一接口。

## `gg1`/`qma implements zb5` = 包导入器

```java
// gg1
boh.d((InputStream) closeable, file);   // unzip
String strC = boh.c(file);               // 读 conf
if (strC == null)
    throw new IOException("Pack for " + dc5Var2.I
        + " has no conf directory");
this.e.put(dc5Var2, strC);               // 存 conf
```

- `dc5Var`/`e.put` = pack 缓存——**手写语言包导入**
  （对应 `HandwritingPackDownloadWorker`）。
- `qma` 同理：`boh.c(new File(strA))` 读 conf。

## `cu9` = manifest 校验器

- 三次 `boh.a(...)` 调用 —— 多条目哈希校验
  （manifest vs 实际资产）。

## HarmonyOS 决策

- 导入管线等价——unzip+conf 读+缓存；
  手写包导入 fail-closed（服务端资产分发）。
- `.note` 导入走独立路径（qma/gg1 是包类）。

## 产出

- fixture `d02-import-pipeline.mjs`（10 断言）。
- ADR-0975；中文报告。
