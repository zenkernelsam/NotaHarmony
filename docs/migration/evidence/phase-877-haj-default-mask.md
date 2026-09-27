# Phase 877 证据 — `haj` CreatePage 助手与 Kotlin `$default` 掩码语义

## 目的

解开 `u5j`/`haj` 工厂末位 `int` 的真实语义——证实全部为
Kotlin 默认参数位掩码，并登记 `haj` 的 CreatePage 助手族。

## Kotlin 掩码契约（判定规则）

`$default` 存根中掩码位 = **参数在声明中的序号的 2 次幂**；
带默认值的参数得到 `if ((mask & 2^idx) != 0) p = default`
分支；扩展函数 receiver 不占位。

实测吻合：

| 方法 | 反编译存根 | 观察分支 | 位=参数序号 |
|------|-----------|----------|------------|
| `haj.a` | `a(cxc,nz9,i,oz9,int i2)` | `&1`→cxc=null、`&2`→nz9=null、`&8`→oz9=UNBOOKMARKED | cxc@0、nz9@1、oz9@3；pageCount@2 无默认（无 `&4`） |
| `u5j.s` | `s(x09,List,Integer,m2d,oz9,int i)` | `&2`→num、`&4`→m2d、`&8`→oz9 | value 参数序号 num@1、m2d@2、oz9@3 → `x09.s(...)` 扩展，receiver 不占位 |
| `u5j.i` | `i(x09,int i,int i2,int i3)` | `i3&4`→i2=1 | pageCount@2；普通函数 x09@0 占位 |
| `u5j.f` | `f(x09,cz0,cxc,fqa,qed,qed,dp5,String,hu1,int)` | `&32`→qed、`&1024`→dp5、`&8192`→str、`&16384`→hu1 | qed@5、dp5@10、str@12、hu1@13（x09@0 占位） |
| `u5j.j` | `j(x09,...,int)` | `&4`→Float、`&64`→t16.FIXED_WIDTH、`&1024`→hu1、`&2048`→xgb | 序号 2/6/10/11 |
| `u5j.q` | `q(x09,ArrayList,hu1,Float,t16,int)` | `&32`→hu1、`&64`→Float、`&256`→t16 | 序号 5/6/8（非连续序号=有可空 setter 跳位） |
| `u5j.x` | `x(x09,...,int)` | `&2/4/32/128/512/1024/2048/8192` → cxc/fqa/v4d/t16/hu1/Float/g2d/Boolean | 序号 1/2/5/7/9/10/11/13 |
| `u5j.l` | `l(...,int i2)` | `if (i2 != 0)` 整体默认分支 | 掩码整体判定 |

跳位规则：非默认值参数（如 f 的 cz0/cxc/fqa/qed2/dp5…中
required 项）消耗序号但无分支；同一序号对应 2^idx 唯一。

## `haj` 族登记（`defpackage/haj.java`）

| 方法 | 语义 |
|------|------|
| `a(cxc?,nz9?,int,oz9,int mask)` | `ln2` CreatePage 构造器：C(4) 四字段——location@0(cxc 经 nti.X)、background@1(nz9 经 vv7.L)、pageCount@2(`e(2,i,1)` FB 默认 1)、bookmarked@3(`c(3,oz9.I,0)`)；构造后 `ybg.c` 校验 |
| `c(ln2,a)` | `ln2` 再序列化器（qee 分发表调用——ops-bundle 写侧） |
| `b(pd8,long,long,List,ix4,t42,int,int)` | **无关 Compose UI**（uz4 组合器进度条/spinner；同名混淆巧合，非 ops 层） |

### `haj.a` 掩码位（实测调用点）

| 掩码 | 调用点 | 含义 |
|------|--------|------|
| 16 | wz9.u、u5j.i、te0、kp5、eca、zm7 | 仅 bit4——四参全显式；**参数序号 4 存在但被 JADX 省略**（本文件类型推断失败；ln2 仅 C(4) 字段，p4 非线可见——登记为默认构造提示参数，所有调用方一律取默认） |
| 26=1+8+16 | zm7 | cxc=null、oz9→UNBOOKMARKED、p4 默认；`haj.a(cxc,null,1,null,26)` |
| 27=1+2+8+16 | nx6、zm7 | 全默认：`haj.a(null,null,2,null,27)` = pageCount=2 空白双页 |

### `ln2` 字段（toString 实证）

`CreatePage(location, background, pageCount=mmf.a(m()), bookmarked)`：
field2 为 **pageCount**（mmf 包装 int，`m()` 缺省返回 1）。
`u5j.i` 掩码 `&4` 亦默认 pageCount→1。

### 派生默认（工厂体硬编码）

- `f`：ty0.SQUARE、ive.PIXEL_ALIGN 固定；qed==(1.0,1.0) 时丢弃。
- `j`：t16 缺省 FIXED_WIDTH。

## Harmony 侧

- `OriginalCreatePagePayloadEncoder`：location/background/
  pageCount(默认 1)/bookmark 四字段与 `haj.a` 线格式一致，
  注释已引 `haj.a`/`wz9.u`。
- `Original*Operation` 的可空参数形态与可空 setter 默认理念
  对应；CreateBlock 编码器同样硬编码块类型/像素对齐默认。

## 结论

末位 int 全为 Kotlin `$default` 掩码（位=参数序号幂），非
语义标志；`haj.a` 掩码 16 = 被省略参数序号 4 的恒默认位。
876 的「固定标志位」登记由此升级为精确掩码语义。
纯文档+fixture 阶段。
