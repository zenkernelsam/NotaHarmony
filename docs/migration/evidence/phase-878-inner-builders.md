# Phase 878 证据 — `*0j`/`baj` 内层构造器与混合静态

## 目的

`u5j` 工厂做参数归一化后委托给内层构造器建表；登记该层
映射与派生语义（`decompiled_1.0.3/sources/defpackage/`）。

## u5j → 内层构造器映射

| u5j | 内层 | payload | 备注 |
|-----|------|---------|------|
| i | `haj.a` | ln2 CREATE_PAGE | 877 已登记 |
| s/t | `r0j.a` | ge8 MODIFY_PAGE | `r0j.d` 为其序列化器 |
| u | `v0j.b` | he8 MODIFY_PARAGRAPH_STYLE | `v0j.d/e` 序列化器；he8 多一 Boolean 槽（`u()` 传 null） |
| v | `x0j.a(list, true)` | je8 MODIFY_POSITIONS | `x0j.n` 序列化器；第二参恒 true=writeAll |
| r | `o0j.a` | wd8 MODIFY_INK | xgb→`tmf(xgb.I)` 包装；list2 经 `rz1.i0` 防御拷贝；分段构建时负长报 `Got negative length` 并置 null |
| f | `baj.a` | rl2 CREATE_BLOCK | 21 逻辑参 + 掩码；见下 |

其余 u5j 方法（A/D/E/G/H/J/a/g/j/k/l/n/p/q/w/x）直接建表或经
各自 `*0j`/助手——签名层 876 已登记。

## `baj.a`（rl2 CREATE_BLOCK）掩码

`a(cz0,ty0,cxc,fqa,Float,qed,qed,ive,z,xgb,dp5,bmb,str,str,hu1,k3a,z,z,vy7,z,z,int)`：

- `&262144`(bit18)→vy7=null、`&524288`(bit19)→z4=false、
  `&1048576`(bit20)→z5=false。
- u5j.f 实传掩码 `2883584` = bit18+19+21：vy7/z4 取默认、
  z5 显式 false；bit21 = 序号21 参数（同 haj.a 模式，
  JADX 省略）。
- xgb 一律包装 `new tmf(xgb.I)` 入表（tmf=挂钟值类）。
- u5j.f 另硬编码 ty0.SQUARE、ive.PIXEL_ALIGN；qed=(1,1) 丢弃。

## `*0j` 混合静态属性

每个类仅一个方法是 op 构造器，其余为混淆合流的无关静态：

- `r0j.b/c` = Bundle 日志助手；`x0j.b-i` = protobuf wire 解码；
  `v0j.a/c` = Compose/protobuf；`baj.b/c` = 协程重试。
- **`o0j.b/c/d` = 二进制补丁应用器**：magic `-771763713`
  （0xD1FFD1FF）、version=4、`Patch file overrun`、op 码
  switch 写 `jjg` 输出——delta/补丁格式表面（无上层调用点，
  登记待查）。

## Harmony 侧

- ModifyPage/Paragraph/Positions/Ink/Block 编码器入参形态与
  内层构造器对应；`tmf` 挂钟包装在 875 已登记；块类型/像素
  对齐默认在 CreateBlock 编码器硬编码（等价 f 的派生默认）。
- 补丁应用器无对应面（原版上层调用缺失，保持登记）。

## 结论

内层构造层登记完毕；`*0j` 混合静态属性与 21 参 `baj.a`
掩码语义留档；`o0j` 补丁格式登记待查。纯文档+fixture 阶段。
