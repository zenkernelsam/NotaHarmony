# Phase 904 证据 — `xgb` = `Realtime` 音频时间值类

## 目的

实名贯穿 op 元数据的音频时间类型。`decompiled_1.0.3`。

## `xgb` = `Realtime`（toString 实证）

```java
public final class xgb implements Comparable {
    public final long I;
    toString: "Realtime(value=" + njj.j0(10, I) + ")"  // 无符号十进制
    compareTo: Long.compareUnsigned                    // 无符号比较
}
```

- **ULong 语义的领域值类**：`Realtime` = 录音/回放
  实时位置（无符号 long）。
- `a(long)` 构造；Kotlin `ULong` 直参内联类。

## 使用点（全链实证）

| 位置 | 角色 |
|------|------|
| `wq9.d` | OpCreationMetadata.audioTime（881：掩码 bit16 默认 null） |
| `uq9` 字段3 | op 封套 audioTime——**读侧为 `tmf`/long**（xgb 仅
创建侧域类型，线上裸 ULong） |
| `w0j.a` 等工厂参数 | 创建 op 时携带录音时刻 |
| `f8d.c rawAudioTime` | CRDT 节点音频时间（903） |

- 与 `tmf`(ULong 通用型) 区分：`xgb`=**Realtime 领域
  语义**（时间戳），`tmf`=通用 ULong（zIndex 等）。

## 无符号值类家族终态

| 类 | 基础 | Kotlin | 语义 |
|----|------|--------|------|
| mmf | int | UInt | 页数/尺寸 |
| ymf | short | UShort | schemaVersion |
| tmf | long | ULong | zIndex/通用 |
| xgb | long | ULong 领域型 | **Realtime 音频时刻** |

## Harmony 侧

`OriginalInsertText`/op 编码的 audioTime ↔ Realtime
ULong；录音-回放时间轴对齐（OpAudioTime 语义）。

## 结论

xgb=Realtime 实名（无符号 long 音频时刻）；
op-元数据音频时间链闭合；值类家族四位补全。
纯文档+fixture 阶段。
