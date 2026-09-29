# Phase 1046 证据 — 页面操作载荷 + ddg 共享校验库

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## 页面操作

| 载荷 | 字段（toString 实名） |
|---|---|
| `ln2` CreatePage | `{location, background:nz9@6, pageCount:int, bookmarked}` |
| `ge8` ModifyPage | `{pages:list(lv2.Y), moveTo, background:m2d@8, bookmarked}` |

`nz9` = **PageBackground{paper, pdf:sw9, rotation, size, margins}**；
`m2d` = SetPageBackground{value:nz9}；`sw9` = PDF 引用
（`o()`=消耗页数）。

## 校验（`a()` 实测）

- `ln2`：`m()==0`→"Cannot create 0 pages"；`ddg.g(nz9)` 子校验；
  带 PDF 时 `m()!=sw9.o()`→"Number of pages created must
  match the number of consumed pages in the PDF"，否则
  `ddg.f(sw9)`。
- `ge8`：`m2d.j()→nz9`→`ddg.g`；`m()==0`→"Must specify
  more than 0 pages"；PDF 消耗页数须相等。

## `ddg` = 共享校验库

| 函数 | 目标 | 规则（错误文案实测） |
|---|---|---|
| `b(po4)` | 触控笔点 | azimuth 单位向量、altitude≤π/2、width/force 非 NaN 非无穷非负 |
| `c(long)`/`d(float)` | 标量 | 非无穷、非 NaN |
| `f(sw9)` | PDF | 每消耗页须给 crop box 尺寸 |
| `g(nz9)` | 背景 | PDF 页须显式尺寸；margins<页尺寸；旋转须基本方向 |
| `i(qed)` | 尺寸 | width/height 非负 |

`po4` = 触控笔采样点（azimuth/altitude/width/force）；
`qed` = 尺寸类型（Phase 1037 m09 默认值同源）。

## HarmonyOS 决策

- 页操作字段+PDF 页数一致性校验逐条保留；
  `ddg` 建为共享 `OpValidators` 工具集。

## 产出

- fixture `d02-page-ops-validators.mjs`（12 断言）。
- ADR-0990；中文报告。
