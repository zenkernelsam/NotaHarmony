# Phase 951+952 — `vej` 完整面：RemoveChars 工厂/写器 + 富文本光标移动契约

来源：`decompiled_1.0.3/sources/defpackage/vej.java`、`hqe.java`、`t4g.java`、`ti3.java`

## 1. 线协议成员（Phase 951 已解剖 `q`；本 Phase 补 `a`）

### `a(AbstractList, qo5) → qub` — RemoveChars **工厂**

与 `q` 写器成对（模式同 `ys2.d`/`ys2.O`、`haj`/`ln2`）：

```
a aVarA = dk4.a(c8dVar);          // c8d = 可复用 builder 包装
int size = list.size();
if (size < 0) 记 "Got negative length"(yn7.MODEL)，numValueOf=null
else:
  aVarA.D(12, size, 4);           // 12B 内联 cxc 结构向量
  for i=size-1..0: sg5.f(aVarA, (exc) list.get(i));
  numValueOf = aVarA.o();         // 向量偏移
aVarA.C(2);                       // 2 字段表
if (numValueOf != null) aVarA.h(0, numValueOf);   // f0 = locations 向量
if (qo5Var != null) aVarA.j(1, rh8.O(qo5Var,aVarA)); // f1 = textField
int iN = aVarA.n();
aVarA.z(iN, 4);                   // required 根对齐
aVarA.p(iN);                      // finish root
ByteBuffer.wrap(aVarA.A()).order(LITTLE_ENDIAN);
qubVar.d(rootOff, byteBuffer);    // 读回验证
ybg.c(qubVar);                    // 校验（Phase 948）
rh8.q(c8dVar, null);              // 关闭 builder（异常路径记 th）
```

**要点**：工厂序列化后**立刻反读自检**（`d()`+`ybg.c`），
异常经 `rh8.q(c8d,th)` 传播——builder 池正确归还。

### `q(qub, a)` — 写器（Phase 951）

`wj9` 元素提供器 + `sg5.f` 零分配 + 负长日志。工厂/写器字段序完全一致。

## 2. 富文本光标移动契约（`b`–`r`，非线协议）

`ti3` = 文本布局：`a` = 段落列表 `qi3`、`b` = 可视行列表 `ri3`、`i` = `si3` 文本。
`hqe` = 位置值类 `{paragraphIndex I, offset J}`（`ui1` 接口，`K`=(0,0) 哨兵）。
`t4g` = **Affinity{Start,End}** 行亲和枚举。
`di3` = remembered-X（上下移动保持的列偏好）。

| 方法 | 语义 |
|------|------|
| `b(t,hqe,di3)` | **光标下移一行**：`xej.c` 求当前可视行，`rej.i(ei3.a(x,f4))` 用 remembered-X/行中点命中；行尾无可移则原样返回 |
| `r(t,hqe,di3)` | **光标上移一行**：`iC-1` 行镜像 |
| `g/h(t,hqe,n,z)` | **右移 n 个 grapheme 簇**：`BreakIterator.following`，段尾越界进下一段（`z`=affinity 修正 `l96.T0`） |
| `m/n(t,hqe,n,z)` | **左移 n 个 grapheme 簇**：`preceding`，段首越界退上一段尾 |
| `i(t,hqe)` | **下一词右边界**：先跳 `cq.f0` 空白再 BreakIterator 词界；段尾则进下一段 (0) |
| `o(t,hqe)` | **上一词左边界**：递归镜像；段首退上段末尾 |
| `j`/`p` | 词移动但**限同行**（`xej.c` 行号比对，越行返回 null） |
| `k` | 段尾（`qi3.b()`=段长）；`l` | 段首 (0) |
| `c(t)` | 判空：`si3.d()==1 && 首段空` |
| `d(t,fke)` | 首 run 属性检查 `qi3.c.i(0)==kxb.I` |

**Java `BreakIterator` = ICU grapheme/word 边界**——Android 用
`java.text.BreakIterator`（ICU4J），Harmony 无等价 API；
`Intl.Segmenter`（granularity "grapheme"/"word"）为 ES2022 对应物。

## 3. Harmony 现状

`note/src/main/ets/ui/components/TextBlockOverlay.ets` 使用**扁平
`caretOffset: number` + `caretSelectionStart`**（字符串标量偏移），
文本编辑走原生 `TextArea`——无自定义多段布局，光标移动由平台组件
代理，`vej.b`–`r` 的 `{para,offset}` 双维导航无对应需求。

### 决策

- `a`/`q` RemoveChars 序列化对：线型层保持等价（Replay 已覆盖）。
- `b`–`r` 光标数学：**平台委托**。Harmony 原生 TextArea 处理方向键/
  词跳跃（系统已实现 grapheme/词界）；若未来引入自绘文本布局，
  需以 `Intl.Segmenter` 重建本契约。**记录为平台差异，非缺陷。**

## 4. 验证

- `d02-vej-cursor-helpers.mjs` 静态核查 `vej.java` 结构断言。
