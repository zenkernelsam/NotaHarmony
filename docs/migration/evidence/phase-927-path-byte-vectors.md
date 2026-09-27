# Phase 927 证据 — `ei7`/`nl8` 路径字节向量层

## 目的

encodedCenterPath/encodedCustomPath/encodedFillPath/
styleMap 的真实线型——非结构向量而是**原始字节向量**。

## `ei7` = 零拷贝字节迭代器（implements hmf）

```java
ei7(Integer len, dm2 dm2) {
  ByteBuffer bb = dm2.g(22);   // cee.g(rawOffset) 取字节切片
  this.I = bb; this.J = bb.position(); this.L = len;
}
byte b() { return I.get(J + K++); }   // 逐字节直读缓冲
```

- `dm2.g(22)`：f9 = encodedCenterPath —— `g` 为
  `cee` 的**原始字节向量访问器**（仍按 4+2i 槽位）。
- 迭代器直读底层 ByteBuffer——零拷贝路径编码视图。

## `nl8` = 可变 byte 列表（implements jmf）

- `byte[] I` + `J` 长度；`b(byte)` 追加（×3/2 扩容）；
  `h(i)` 索引读 + 越界报错；`equals` 用
  `Arrays.copyOf` 前缀比较。

## 线型结论

- encodedCenterPath/encodedCustomPath/encodedFillPath =
  **byte[] 自定打包编码**（非逐点表向量）——路径数据
  以压缩字节流存于表内，lv2.w/x/C/F 物化器经
  ei7/nl8 进出。
- styleMap 的 `x()`/`D(yyd)` 才是 yyd 结构向量。

## Harmony 核对

`encodedCenterPath`/`strokeEncodedPath` 等以字节
透传存储——对齐（路径编码为格式内自定格式，
不展开为字段）。

## 结论

路径编码字节流契约钉死——Harmony 透传语义正确。
