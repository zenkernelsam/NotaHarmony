# 原版空白新笔记 Bootstrap：JADX 与 DEX 线性证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- DEX 复核：Android SDK `apkanalyzer dex code --class id7`
- 日期：2026-08-16

本证据回答普通空白新笔记究竟创建几页、首批 operation 的类型和顺序、默认纸张从何处读取、
`selectedDefaultTemplate` 的真实存储格式，以及创建 API 对初始 operation 列表的硬性要求。

## 1. `id7.d()` 构造的是两个 operation，不是一张默认首页

`id7.java:227-315` 的反编译控制流先创建长度为 2 的 `cee[]`，再依次写入：

```java
cee[] operations = new cee[2];
operations[0] = id7.h(title, continuation);
operations[1] = haj.a(null, null, 2, null, 27);
List list = m18.m0(operations);
```

JADX 对局部变量的恢复不完整，但 DEX 本体明确给出：

```text
new-array v7, v2, [Lcee;
invoke-virtual {p0, p1, v10}, Lid7;->h(Ljava/lang/String;Lff2;)Ljava/lang/Object;
aput-object v0, v7, v12
invoke-static {v4, v4, v2, v4, v0}, Lhaj;->a(Lcxc;Lnz9;ILoz9;I)Lln2;
aput-object v0, v8, v3
invoke-static {v8}, Lm18;->m0([Ljava/lang/Object;)Ljava/util/List;
```

这里 `v2 == 2`，既是数组长度，也是传给 `haj.a()` 的第三个实参。因此普通空白新笔记的初始
`CREATE_PAGE` 是一个 `pageCount=2` 的页面组，不是此前 Harmony 假定的单页 `0→1`。

## 2. `ln2.field2` 就是 `pageCount`，默认值 1 但本路径显式写 2

`haj.java:13-47` 的 builder 对四字段 `ln2` 调用：

```java
aVarA.C(4);
...
aVarA.e(2, i, 1);
aVarA.c(3, oz9Var.I, 0);
```

`ln2.java:77-86` 从 vtable field 2 读取 uint32，字段缺省时才返回 1；`toString()` 又明确命名为
`pageCount`：

```java
public final int m() {
  int offset = c(8);
  return offset != 0 ? buffer.getInt(offset + this.I) : 1;
}

return "CreatePage(location=" + l() + ", background=" + j()
  + ", pageCount=" + mmf.a(m()) + ", bookmarked=" + k() + ")";
```

`ln2.a()` 还拒绝 0 页。`haj.a(null, null, 2, null, 27)` 的 mask 令 location、background 和 bookmark
采用默认值，但没有覆盖第三个参数，所以 wire 必须显式携带 2。

## 3. 第一条 operation 是标题与具体默认背景合并的 `SET_METADATA`

`id7.java:1132-1169` 的 `h(title)`：

1. 非空标题经 `dhh.a(title)` 生成 `z2d SetString`；
2. 调用 `o59.e()` 读取 `noteEditorSettings.selectedDefaultTemplate`；
3. 以 `l3a.a(template, null, null, 7)` 生成具体 `nz9`；
4. 经 `qgh.b(nz9)` 包成 `m2d SetPageBackground`；
5. 以 mask 508 调用 `xj2.d(titleSetter, backgroundSetter, ...)`。

DEX 同样显示：

```text
invoke-static {p0, v0}, Lo59;->e(Lo59;Lff2;)Ljava/lang/Object;
check-cast p2, Ll3a;
invoke-static {p2, v3, v3, 0x7}, Ll3a;->a(Ll3a;Lqed;Lnz9;I)Lnz9;
invoke-static {p0}, Lqgh;->b(Lnz9;)Lm2d;
invoke-static/range {..., 0x1fc}, Lxj2;->d(...)Ll2d;
```

因此创建首条 metadata 不是 title-only，也不是 background-only，而是同一 `l2d` 中同时存在
field 0 title 与 field 1 pageBackground。第二条 `CREATE_PAGE` 省略自己的 background，让两页继承
这条 note-level winner。

## 4. 默认模板偏好是 root `nz9` FlatBuffer `byte[]`，不是 JSON

`o59.java:24-28` 固定：

```java
new eua("selectedDefaultTemplate")
super(context, "noteEditorSettings", ...)
```

保存路径 `ss8.java:71-79` 先执行 `l3a.a(..., mask=7)`，再把 `nz9` 作为 FlatBuffer root 写入 builder，
最后以 `aVar.A()` 的 `byte[]` 保存：

```java
aVar.p(vv7.L(l3a.a(l3aVar, null, null, 7), aVar));
tk8Var.g(o59.s, aVar.A());
```

读取路径 `o59.java:100-174` 直接对 `byte[]` 建立 little-endian `ByteBuffer`，从 root offset 初始化
`nz9`，再由 `fad.t()` 还原 `l3a`。AssertionError 或截断会回退 `l3a.d`；偏好值类型错误时，
`ko8 case 4 → bc7(28)` 只删除 `o59.s` 这一项后回退。

Harmony 因而使用 Preferences `Uint8Array` 保存同一 root FlatBuffer：

- 类型错误：删除该 key，并回退原版默认模板；
- malformed/truncated bytes：回退但保留原字节，避免擅自改写可诊断现场；
- 不引入 JSON 私有格式。

## 5. `l3a` 语义不止尺寸、模板和方向

`s3a` 保存 paper size、orientation、background color 与 legacy paper index；`gq0` 保存 line type、
spacing 和 options。`l3a.a(mask=7)` 会：

- 从选择的标准纸张与方向重新计算 source size；
- 清除旧 `nz9` 的 PDF/rotation 载荷；
- 使用 `m09.d` 的 36 pt 四边距；
- 保留纸张颜色、line/grid/dots 类型、spacing 与 legacy paper index；
- 令 LINES 不 bleed，其他模板 bleed，并令 centered 为 false。

因此 Harmony codec 不能只保存三个 enum。Phase 246 在边修边审中补齐了这些纸张字段的语义 round-trip，
同时仍按原版 mask 7 归一化为 paper-only background。

## 6. operation 列表顺序就是提交顺序

`pq1.java:98-104` 的 case 5 对传入 List 顺序迭代，并逐个调用 `xq9.a(new wq9(...))`，没有排序或类型重排：

```java
Iterator it = list.iterator();
while (it.hasNext()) {
  xq9Var.a(new wq9((cee) it.next(), null, false, null, 30));
}
```

所以 `id7.d()` 的数组顺序具有协议意义：combined `SET_METADATA` 必须先于 `CREATE_PAGE(pageCount=2)`。

## 7. 创建 API 强制要求正页数 CREATE_PAGE、SET_METADATA 与非空标题

`oq1.java:127-210` 在真正调用 `createNote` 前：

- 查找至少一条 `CREATE_PAGE`，并要求其 `pageCount` unsigned compare 大于 0；
- 查找 `SET_METADATA`，不存在即报 `SetMetadata op not found`；
- 要求其中 title setter 与字符串值均非空；
- 找不到正页数 CREATE_PAGE 时报 `CreatePage op with positive pageCount not found`。

这排除了“只插 note_meta，稍后编辑器补页”或“先造页面、随后异步补 metadata”的实现。初始 note、metadata、
页面与待上传 operation 必须作为一个不可分割的创建结果。

## 8. 内建回退是 Letter / Plain

`a79.java:62-68` 固定默认 source size 为 612×792 pt，即 Letter 8.5×11 in；`a79.O` 是四边 36 pt。
`m09.f` 以这组尺寸、默认白纸和边距构造 `nz9`，`l3a.d` 再从 `m09.f` 建立内建默认模板。

因此：

- 没有选中模板、偏好损坏或读取失败时，创建两张 Letter / Plain 页面；
- legacy/corrupt 零页恢复也应使用 Letter，不应继续造 A4；
- 正常新笔记不会进入编辑器的零页补偿，因为两页已经在创建事务内提交。

## 文件 SHA-256

- `id7.java`：`1BB5FDA05605AA7361498FAC3B5BC4F083CDE9A4658B5A32A40B8BEE12E9FF80`
- `haj.java`：`050705A3C00C671E32A1CC3A70D965CCA5511C9266D5324A0DB7D8D77F812BDD`
- `ln2.java`：`85A444AE931A9D5780044BD6D20F0B52657AADD1893FC6CBD09492F89C72F622`
- `o59.java`：`3B468503F7B02AC7F81613D995254DBB51913F7BA5BE13590D0E14AE41D98F56`
- `l3a.java`：`93FD679009AB625DF12EAF39127211D6964E587747B725D0213A0075D5A04836`
- `ss8.java`：`30898824A57C18F2BA217F7CE71D135DFE8E87616DD6149181F20E149428E92C`
- `pq1.java`：`2ADC17EEDFCA9DB69319F198EA4F1A26AF770B2FEA48BBC32CD4838F7A3C8865`
- `oq1.java`：`A8594B8C56729E1DE8CBC6D6F0882D5159083468B4C75690A2A0898956EB9D71`
- `qgh.java`：`2431A774872F58C30B64FFA5EE2A90C82B29C24D349B5A4EBF3CDD1BF6785698`
- `a79.java`：`FE5C7C5FBA990B53DD3296E96953CA37F9D8D309CA15509F2F78634EA4B14E13`
- `m09.java`：`3B6E92A54E7A5F15BB450A8B89A0A62ED25F2882D65F159595303CD29B6B214A`

## 设备边界

本阶段没有启动设备、模拟器、虚拟机或 Hypium。真机仍需验证新建后直接显示两页、默认模板切换、杀进程重开、
偏好损坏回退、页面继承、同步上传/ACK 与重新下载后的 operation 顺序和背景一致性。
