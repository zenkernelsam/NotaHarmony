# Phase 978 — 读侧入口 `uhj.n` + `ic3` 标志集

来源：`decompiled_1.0.3/sources/defpackage/{uhj,ic3}.java`

## 1. `uhj.n(ByteBuffer)` = NoteBundle 根读入口

```java
public static r29 n(ByteBuffer bb) {
    r29 r29Var = new r29();
    bb.order(LITTLE_ENDIAN);
    r29Var.d(bb.position() + bb.getInt(bb.position()), bb);
    return r29Var;
}
```

标准 FlatBuffers `getRootAsX`：`position+uoffset` →
`cee.d` 初始化。所有读侧经此进 r29 根表。

## 2. `ic3` = 6 位标志集（反射枚举注册）

```
d = 种子(=1); e=1,f=2,g=4,h=8,i=16,j=32;
k = (d<<6)-1 = 63   // 6 位掩码
l = d|f|g = 7       // 组合
m..q = new ic3(组合位) 实例
r/s = 静态字段反射枚举出的命名标志注册表 (hc3{b,name})
```

`uhj.l/m/o/p/q()` = 返回 `ic3.e/h/f/g/j`——uhj 兼作
标志常量提供者（R8 合并类多职）。

## 3. `uhj` 其他成员（合并类）

- `r(i,i2,i3)` = 环形距离 `(i-i3)<0 ? +i2 : i-i3`。
- `a(byte[],i,i2)` = 数组切片（h81/i81 接口实现）。
- `F()/G()=true`（xn5 特征开关）。

## 4. 结论

读侧入口 = `uhj.n`（LE+root uoffset→d()）；`ic3`
为位标志集（用途待上层语义，疑似会话/能力标志）。

## 5. Harmony 对齐

Harmony `decodeNoteBundle` 已按同法解析根偏移
（既有 Replay 覆盖）。

## 6. 验证

`d02-read-entry.mjs` 静态断言。
