# Phase 1029 证据 — manifest.json 字段 + w59 修正

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `yk9` manifest.json 键

- `"version"` —— 导出格式版本（Int）
- `"noteBundle"` —— FlatBuffer 键引用
- `"assets/"` —— 资产目录键
- `"get"` —— JSON 访问器常量

（资产字段经 `pa0.toString()`/wa0 元数据进 manifest——
Phase 996 的 hash/fileName/mimeType/fileSize。）

## `w59` = **suspend-continuation 状态**（修正 1028）

```java
public final class w59 extends ff2 {   // 非 sink iface!
    public ttf I; public String J; public lq4 K;
    public Closeable L; public boolean M; public int N;
    public Object O; public final y59 P;
}
```

- `w59` 是 `zk9.a(...)` 的 **suspend 续体状态**——
  `y59` 是外层 suspend 函数；`zk9.a` 的参数 `w59`
  实为续体而非回调接口。
- **修正 Phase 1028**：导出返回值经 suspend 返回，
  非 `w59` 回调。

## `lq4`/`y59`

- `lq4` = 协程类型（FileChannel/输出流推断）；
- `y59` = 外层导出 coroutine 类。

## HarmonyOS 决策

- manifest.json 字段（version/noteBundle/assets）
  保留；版本号对齐 ar6 schema。
- suspend 导出 → ArkTS async 函数。

## 产出

- fixture `d02-manifest-fields.mjs`（10 断言）。
- ADR-0973；中文报告。
