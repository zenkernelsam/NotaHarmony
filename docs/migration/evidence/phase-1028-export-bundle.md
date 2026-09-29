# Phase 1028 证据 — 导出 bundle（.note）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `zk9` = 导出生成器入口

```java
public final class zk9 {
    public final Context a;
    public final af6 b = z5c.b(new k79(13));
    public final Object a(x09 note, utf noteId,
                          String str, String str2,
                          boolean z, w59 w59) {
        return xj2.T(t13.K,
            new yk9(str2, x09Var, this, utfVar, str, z, null),
            w59Var);
    }
}
```

- `a()` 在 `t13.K` dispatcher 上启 `yk9` coroutine——
  导出在专用协程跑。
- `x09` = 文档模型；`w59` = 进度/结果 sink。

## `yk9` = manifest lambda（wx4）

写产物：

| 键 | 内容 |
|---|---|
| `manifest.json` | 导出清单（asset 元数据+版本） |
| `noteBundle` | **r29 FlatBuffer** 笔记 blob |
| `assets/` | 资产文件目录（wa0 元数据引用） |

- `pa0`/`cba`/`cp5`/`zjb` 资产包装（Phase 996）
  提供 `wa0` AssetMetadata 进 manifest。

## 导出格式（.note）

- `.note` = zip 容器：`manifest.json` + `noteBundle`
  （FlatBuffer）+ `assets/*`。

## HarmonyOS 决策

- 导出格式等价——zip 容器+manifest+FlatBuffer
  noteBundle+assets 目录；Harmony `@kit.CoreFileKit`
  zip API。
- `w59` 进度→Harmony 回调。

## 产出

- fixture `d02-export-bundle.mjs`（10 断言）。
- ADR-0972；中文报告。
