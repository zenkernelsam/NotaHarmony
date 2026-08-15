# 原版 Partial Eraser transient preview/end：JADX 证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- APK SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 主反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- JADX：1.5.6
- 日期：2026-08-16

本证据承接
`original-partial-erase-entity-replacement-jadx-2026-08-15.md`。`jt1.invokeSuspend()` 与
`wc.invoke()` 的 fallback SHA-256 仍分别为
`22E7F02B2483D45FEB577541C79CD90A601BC17EBE8FACAFE94859B06856BEA5` 和
`17A0E86702415B5A4181F8F2B1E81E147AD23D3B6DA1DEDB3C60B58B97679895`；本阶段没有修改原版目录或重新生成 APK。

## 1. pointer-down 创建 transient tool-5 Ink

`kt1.d()` 在尚无 active Ink ID 时读取第一个路径点。工具为 `d04.J` 时明确选择
`u16.PARTIAL_ERASER`，再用 `u5j.g(...)` 创建 Ink payload（`kt1.java:267-312`）：

```java
if ((q5fVarC instanceof q4f) && ((q4f) q5fVarC).b() == d04.J) {
    u16VarL = u16.PARTIAL_ERASER;
}
...
dm2 dm2VarG = u5j.g(..., u16Var, ...);
...
new bt1(this, dm2VarG, xgbVarB, u16Var, fqaVarG2, cxcVar, 0)
```

`bt1` mode 0 把 CREATE_INK 明确标记为 transient，并把返回的 operation ID 保存为 active
interaction/Ink ID（`bt1.java:36-46`）：

```java
kt1Var.l = xq9Var.a(new wq9((dm2) obj6, null, true, (xgb) obj5, 10));
kt1Var.m = (u16) obj4;
```

所以 tool-5 路径首先是手势预览实体，不是抬手后应永久留在页面上的 destination-out Ink。

## 2. move 只向 active transient Ink 追加路径

`kt1.c()` 把 actual 与 estimated 列表分别归一化为空/非空，再用 active Ink ID 调用
`u5j.a(...)` 生成 ADD_PATH_ELEMENTS（`kt1.java:245-264`）：

```java
if (arrayList.isEmpty() && arrayList2.isEmpty()) return;
...
qo5Var = this.l;
gdVarA = u5j.a(a(), qo5Var, arrayList, arrayList2);
...
new ns(m1dVarA, gdVarA, qo5Var, this.r, this, null, 1)
```

Phase 110 已依据 `wq9/kt1/u5j` 固化：这些 append 带 `_inProgressTransientId`，不进入 durable model
journal。Harmony 的本地实时预览因此也必须驻留内存，不能边移动边写 page snapshot 或 operation log。

## 3. 正常结束先提交 durable replacement，再结束 transient interaction

`dh5.java:341-351` 对 `d04.J` 启动 `jt1`，而不是走普通笔画的单 CREATE_INK finish：

```java
if (q4fVar.b() == d04.J) {
    ...
    new jt1(kt1Var5, ..., listL0, qo5Var2, xgbVar4, andSet, null)
}
```

恢复后的 `jt1 → wc mode 3` 顺序为：物化所有 remnant Ink、更新/删除 Group、删除 source entity，最后
调用 `oqi.a(activeInteractionId)`。因此本地预览应在 durable transaction 等待期间继续遮罩，只有 transaction
成功安装或明确进入 fail-closed fallback 后才能清除；提前在 pointer-up 清除会产生可见闪回。

## 4. cancel 也必须结束且不得持久化 preview

原版另一条 inking controller 的取消路径 `a5g.cancel()` 在发现 active transient ID 时调用
`new fg2(id, 5)`（`a5g.java:175-188`）。`fg2` mode 5 只派发：

```java
xq9Var.a(new wq9(oqi.a(qo5Var), null, false, null, 30));
```

这证明取消不是把 tool-5 preview 转成 durable Ink；它只结束 transient interaction 并恢复原内容。

## 5. `wq9` 的 transient 分类

`wq9` 保存 payload、transient flag、`_inProgressTransientId` 与 audio time。显式 `z=true` 或存在
in-progress ID 时 `z2=true`；type 26 `TRANSIENT_INTERACTION_ENDED` 默认也归类 transient。preview 与 end
属于同一非持久生命周期，而 durable replacement 是另一组 operation。

## 文件 SHA-256

- `kt1.java`：`815C902D4F4F34CCBD993BAFD5A90577302C8CB669CBBFDC512CD3AD4E77CFF3`
- `bt1.java`：`A42BD4E3A450900EC67A9596A047FAA3D07B806E14F0702B9CFBA8B64529FFDA`
- `dh5.java`：`5EF6189DC5FC363D066AAF92A864E043AD8E7771D2A8043F1259C70A4A79E2A0`
- `a5g.java`：`D6F3539A8F05A1EB13A7C23106375D6B069285AC8EB41622EEA6514F59D14531`
- `fg2.java`：`058705B93D5610C83ACCA860166E4AA9350EC330836911A46BD156177D80001D`
- `oqi.java`：`A04AF8D890CC19BE6583246A2EEBC84F1E92AA9529C6DDCF294A4DCFE8F33918`
- `wq9.java`：`EE6CAA556033B5F8E8A7DAE9D42A7A48FF31F1B8697A15C5D805BA7A4144C4A5`

## Harmony 当前边界

本阶段闭环本机可见的 transient preview、成功/失败/取消清理和非持久门禁。项目仍没有已认证的原版协作
transport，也没有 incoming transient CREATE_INK/ADD_PATH_ELEMENTS 的 view-model reducer；因此没有把
preview bytes 写进 durable outbox，也不宣称远端实时墨迹协作已经完成。
