# Phase 1453 证据 — 原版旋转柄 90° 角度吸附（guf.e / twm.d / vtf）

## 原版证据（decompiled_1.4.2/sources/defpackage）

### 变换会话类型（ms1.java 构造点）

| 会话类 | toString 身份 | 触发 | 字段 |
|--------|--------------|------|------|
| `xtf` | Move | 选区内拖拽 | dragStart+累积位移 |
| `vtf` | **Rotate** | 旋转柄 | c=dragStartPoint、d=centerAbsolute、e=startingRadians、g=lastDragPoint、h=initialSelectionState |
| `wtf` | **Scale** | 角柄（stf 四角枚举） | axis/xAxis/yAxis、locksAspectRatio、fixedCorner |
| `ttf` | Shape | lsf 形状顶点拖拽 | 顶点字段 |

`wtf`（Scale）**无角度字段**——1.4.2 角柄拖拽只缩放不旋转
（与 1.0.3 `htc.e` 自由变换不同，版本演进差异）。

### guf.java:29-36 — 吸附常量

```java
static {
    int i = gsf.f;
    l = 44;
    m = fq9.z(5.0f);            // 5° → 弧度 = 0.0873
    vnh vnhVar = si5.a;          // si5.a = π（fbc:37 以 0/π 对照旋转坐实）
    n = oag.y2(                  // 吸附角集合
        Float.valueOf(-V),       // -180°
        Float.valueOf(-V / 2),   // -90°
        Float.valueOf(0.0f),     // 0°
        Float.valueOf(V / 2),    // 90°
        Float.valueOf(V));       // 180°
}
```

### guf.java:48-64 — 旋转柄拖拽角度

```java
public static float e(long j, vtf vtfVar) {
    long jF = xxb.f(j, vtfVar.f());          // cur − centerAbsolute
    float fAtan2 = (float) Math.atan2(s64.f(jF), s64.e(jF));
    for (n 中每个吸附角 next) {
        if (Math.abs(fAtan2 - next) < m) { fAtan2 = next; break; }
    }
    return fAtan2 - vtfVar.i();              // − startingRadians
}
```

即：**绝对指针角先吸附 {0,±90,±180}°（5° 阈值），再减起始角**。
`vtf.e=startingRadians` 在 `ms1:525` 构造时为 `fFloatValue2`，
`yj8Var == yj8.G`（RTL 左柄位）时额外 `+si5.a`=+π。

### twm.java:68-72 — 捏合路径同款吸附

```java
public static final float d(float f, float f2) {
    float F = wv9.F(f / 1.5707964f) * 1.5707964f;   // round(θ/(π/2))·(π/2)
    return Math.abs(f - F) <= f2 ? F : f;
}
```

`guf.v`（utf 捏合变换会话）：`fD = twm.d(f2, m)` —— 同一 5°→90° 吸附，
作用于捏合手势的旋转增量。

### wtf locksAspectRatio（ms1:392-395）

`z7` 默认 true；`lsf` 单选且元素为 `vvh`（文本块）时 → `false`
（文本块允许自由拉伸，其余锁纵横比）。`guf.f` 返回 `(sx,sy)`
双轴缩放对（fom.a 打包）——wtf 应用端在 `guf.r/s`（反编译失败）。

## Harmony 修改

- `applySelectionResize`：`resizeIsRotate`（旋转柄路径）下，
  绝对指针角 `atan2(cur−anchor)` 先吸附最近 π/2 倍数（≤5°），
  再减起始角。新增 `SELECTION_ROTATE_SNAP_RAD = π·5/180`。

## 登记差异

1. 角柄路径保留 1.0.3 自由变换语义（等比缩放+角位移旋转）——1.4.2
   `wtf` 缩放会话不产旋转且支持双轴缩放，但 `guf.r/s` 应用路径反编译
   失败，无法确证 (sx,sy) 在 locksAspectRatio 下的合并语义 → 登记，
   暂不改角柄。
2. 捏合旋转吸附（guf.v/twm.d）——Harmony 无双指选区变换会话，
   无对应面。
3. RTL 左柄位 +π 起始角补偿（ms1:525 yj8.G 支）——Harmony 旋转柄
   恒右锚（P1450 已登记 RTL 差异）。
