# Phase 963 — `z0c` 三归并写器类全拓扑：ywd/pee/qee

来源：`decompiled_1.0.3/sources/defpackage/z0c.java`、`qee.java`、
`yec.java`（962）、`pee`（匿名）

## 1. 65 表注册的三大类分派

`z0c.invoke()` case24 构建 IdentityHashMap，65 个 put 分三类：

| 载体类 | 数量 | 成员 |
|--------|------|------|
| `ywd` 匿名 wx4 | **23** | 大型 op/信封表（tsi.c=uf7 … j7j.c=sw9，962 全表） |
| `pee` 匿名 wx4 | **~31** | ra0/wa0/io1/yn2/ao2/s83/pra/zgb/akb/pub/qub/f2c/lxc + 12 setter（z1d/g2d/k2d/j2d/l2d/m2d/n2d/o2d/p2d/y2d/z2d/a3d）+ sdf/tdf/mqf/yda/tl2 |
| `qee` 合成 wx4（I=序数） | **11** | 见下表 |

## 2. `qee` 序数→写器映射（实证）

| I | 目标 | 含义 |
|---|------|------|
| 0 | `k0j.c(ud8)` | ModifyComment |
| 1 | `rr2.b(my3)` | EntityAnchor |
| 2 | `qdi.a(lhe)` | TextAnchor |
| 3 | `baj.c(rl2)` | CreateBlock |
| 4 | `eaj.b(cm2)` | CreateGroup |
| 5 | **`ys2.O(dm2…)`** | **CreateInk — Phase 947 写器即注册项**（读全 17 字段后转调） |
| 6 | `haj.c(ln2)` | **CreatePage — Phase 945 写器即注册项** |
| 7 | yq3（抽象基，空/fallthrough） | ReceiveOpsEvent 基？ |
| 8 | `iuh.c(dp5)` | ImageAsset |
| 9 | `fci.d(e46)` | InsertChar |
| 10 | `kci.j(f46)` | InsertString |

## 3. 架构判定

- **三归并类 = R8 λ 合并层**：`ywd`/`pee` 为共享匿名类
  （switch(捕获序数)），`qee` 为显式 `/* synthetic */` 类
  （switch(this.I)）。语义等同：注册表存的是"序数标记的
  λ 实例"。
- `qee` case5 实证 `ys2.O` = dm2 CreateInk 的注册写器——
  **独立命名写器（o0j.f/ys2.O/haj.c）与匿名内联写器并存**：
  大型表抽出命名函数，小表直接内联。
- `qee` case7 (yq3) 无实写体——抽象 sealed 基注册为
  占位/防错（fail-closed：若真序列化则落入默认分支）。

## 4. 注册拓扑终图

```
z0c.invoke() case24 → IdentityHashMap:
  23 × ywd-anon（命名写器直调）
  31 × pee-anon（setter/小表内联或调用）
  11 × qee(I)（大 op + 锚 + asset）
case21 → mx7:
  15 × yec(N)/ywd-anon（结构写器，962 全表）
```

65 + 15 = **80 注册项**（Phase 949 计数最终落位）。

## 5. Harmony 对齐

Harmony 写侧分派需覆盖三族全部语义；`ys2.O`/`haj.c`
/`o0j.f` 等命名写器与 Harmony 已有写函数对应（Replay
覆盖字段序）；`yq3` 抽象基占位 = 注册但不可序列化实体。

## 6. 验证

- `d02-z0c-three-classes.mjs` 静态断言。
