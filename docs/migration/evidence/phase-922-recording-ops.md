# Phase 922 证据 — `yn2`=`CreateRecording` / `ke8`=`ModifyRecording`

## 目的

录音 op 二表读侧实名（873 注册补全）。

## `yn2` = `CreateRecording`（toString 实证）

`CreateRecording(recording=, startTime=, endTime=,
name=, segmentation=, zIndex=)`

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `l()` | c(4) | `akb` | **recording**（RecordingAsset{wa0}） |
| `m()` | c(6) | ulong | **startTime**（njj.j0 无符号格式化） |
| `j()` | c(8) | ulong | **endTime** |
| `k()` | c(10) | String | name |
| `o(ukb,i)`/`lv2.b0` | c(12) | `ukb[]` | **segmentation**（16B 内联结构向量，`(i*16)+f(v)`） |
| `n()` | c(14) | `tmf` | zIndex |

## `ke8` = `ModifyRecording`（toString 实证）

`ModifyRecording(recording=, name=, segmentation=, zIndex=)`

| 访问器 | c(N) | 类型 | 语义 |
|--------|------|------|------|
| `k()` | c(4) | `qo5` | recording 目标 |
| `j()` | c(6) | `z2d` | name（setter） |
| `lv2.c0` | c(8) | 向量 | segmentation |
| `m()` | c(10) | `tmf` | zIndex |

## `ukb` 分割元素

16B 内联结构——`{start:long@0, end:long@8}` 语义
（音频段标记区间；与 cxc 12B/qo5 8B 并列的
结构向量元素宽度实例）。

## Harmony 核对

`OriginalCreateRecording*/OriginalModifyRecording*`
编码对齐：akb 资产 + ULong 起止 + ukb[] 分段 +
zIndex；修改侧 setter 包装 name。

## 结论

zq9 注册表至此全部读侧闭合——26 类载荷
30+ payload 实名完毕。
