# Phase 1033 证据 — manifest 条目 handler 分类

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 类型图

| 类 | 结构 | 角色 |
|---|---|---|
| `yz` | `implements Appendable` {StringBuilder I,
  ArrayList J} | **manifest 字符串写器** |
| `a00` | `implements CharSequence` {List I} | 条目集合
  （CharSequence 视图） |
| `zz` | {Object a, int b, ...} | 条目
  {handler,typeIdx,...} |
| `wz` | iface | handler 接口 |
| `ug7` | `abstract implements wz` {a():cye, b():cqe} | 资产 handler 基类 |
| `gnd` | `implements wz` {xoe a, long b} | 目录 handler |
| `tg7`/`sg7` | `extends ug7` {String a, cqe b} | 资产 handler |

## `wz`/`ug7`/`gnd`/`tg7`/`sg7` 层级

```
wz (iface)
├── gnd  = 目录 handler {xoe, long}
└── ug7 (abstract {cye a(), cqe b()})
    ├── tg7 = 资产 handler A {String, cqe}
    └── sg7 = 资产 handler B {String, cqe}
```

- `cye`/`cqe` = 资产句柄/游标类型；
  `xoe` = 目录句柄。
- `yz.e(gnd)`/`b(tg7)`/`a(sg7)`/`c(name,handler)` 四类
  写入——目录/资产A/资产B/键值。

## `cu9` 调用回指

- `yz`/`a00`/`zz`/`ug7` 层级构成 manifest 索引
  的完整类型系统（Phase 1032 的写目标）。

## HarmonyOS 决策

handler 分类保留；`yz` Appendable→StringBuilder
等价；cye/cqe 句柄→Harmony 文件/资产句柄。

## 产出

- fixture `d02-manifest-handlers.mjs`（10 断言）。
- ADR-0977；中文报告。
