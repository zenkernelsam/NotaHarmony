# Phase 902 证据 — `o0j.b` = Play Asset Delivery 增量补丁器（GMS 内部件）

## 目的

归类 878 发现的二进制补丁应用器。`decompiled_1.0.3`。

## 定界：`o0j.b` 归属 GMS AssetPacks，非 Notability 自有格式

- `jjg`（输出汇）= `classes3.dex` 的 OutputStream：
  字段 `File J`+`FileOutputStream N`+**`assetpacks.p K`**+
  `ujg`/`vig`——Play Asset Delivery **slice 文件输出流**。
- `c`（基类抽象）= 资产包内容提供者抽象；
  `aig` = 基文件范围输入流适配（`I.b(start,end)`）。
- 无 Notability 自有代码路径调用 `o0j.b`（defpackage/
  com.gingerlabs 全树搜索无命中）——GMS SDK 内部件。

## 补丁格式（完整实证，备查）

```text
header:  int32 magic = 0xD1FFD1FF (D1 FF D1 FF)
         u8    version = 4
opcodes:
  0      END → jjg.flush + return
  247 F7   u16 len → d(): literal 拷贝 patch→out
  248 F8   i32 len → d(): literal 拷贝
  249 F9   u16 off + u8 len  → c(): 基文件拷贝
  250 FA   u16 off + u16 len → c(): 基文件拷贝
  251 FB   u16 off + i32 len → c(): 基文件拷贝
```

- `d()` = literal 拷贝（16KB 块，readFully，underrun 守卫）。
- `c()` = 基文件范围拷贝（`aig` 范围视图 → out）。
- 守卫：copyLength/inputOffset 负值、输出超界
  （期望总长 `j`）、patch underrun、truncated input。

## Harmony 结论

**fail-closed**：GMS AssetPacks 依赖（863 HWR 语言包
同款边界）。Harmony 无 Play Asset Delivery → 此补丁
通道不可达；Notability 同步走自有 op-bundle（858-861）
而非此格式。仅为完整性归档。

## 产出定位

GMS 内部件归档（格式已完整恢复，无需实现）。
