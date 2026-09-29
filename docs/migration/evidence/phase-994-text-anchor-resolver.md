# Phase 994 — `z5c.y` 文本锚点→矩形解析器 + `u3c`

来源：`decompiled_1.0.3/sources/defpackage/z5c.java`

## 1. 签名与两分支

`y(qo5, x09) → u3c`；`x09` 强转 `a79`（文档模型页）。

### 分支 A：`qo5 == null`（页级锚点）

```java
nz9 = a79.K            // PageBackground
m4c = a79.B            // 页面对象?
margins = nz9.j() → vy7
pageless: a79.c()==tv6.PAGELESS → y 起点 0
  else jA = ei3.a(vy7.d(), vy7.f())   // 上边距+间距→y
size: (nz9.n() ?: m09.b).d() - (vy7.d()+vy7.e())
       // 页宽 - 左右边距
return u3c(m4c, yPos, textWidth)
```

### 分支 B：`qo5 != null`（实体锚点）

```java
xhe = a79.E.I.get(qo5) ?: a79.I.get(qo5)   // 双映射查找
null → yn7.TEXT "Text block with id not found" + null
cie = (xhe)
  .f = vy7 margins; .b = ry0 文本 layout
  ry0.r = qed 内容 size → fC = gi3.c(gi3.a(w,h)) 行高?
  di3 = max(fC - vy7.d - vy7.e, 1.0f)      // 高≥1
  jQ = xj2.Q(ry0.p)                        // 段落区间
  bmb = do6.i(ry0.o, a79.h) → fqa 页内 origin
return u3c(cie.c, ei3.a(ei3.e(jQ)+origin.c+d, f+2+ei3.f(jQ)+origin.d), di3)
```

## 2. 语义

**文本评论/锚点的矩形解析**：页级锚→页边距算文本区；
实体锚→文本块 id 查 `xhe`→`cie`→布局行高+页内偏移→
`u3c`{anchor, ei3 位置, di3 尺寸}。供 `my3` EntityAnchor/
`tl2` CreateComment 等锚点渲染定位。

## 3. 命名推断

- `xhe`/`cie`：文本实体（block/comment-target）。
- `a79.E.I`/`a79.I`：页内两张实体索引表
  （blocks / inline-entities 分表）。
- `ei3`/`di3`：坐标/尺寸值类（`a(x,y)`、`e/f` 区间端点）。

## 4. Harmony 对齐

等价语义：锚点→矩形解析（Harmony 文本布局行高由
measure 提供——ParagraphLayout 管线已建）。

## 5. 验证

`d02-text-anchor-resolver.mjs` 静态断言。
