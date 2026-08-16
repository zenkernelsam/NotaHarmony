# 原版 1.0.3 共享纸张设置数据库、收藏与 spacing 证据

## 1. 范围与基准

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- JADX：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- 本阶段重点类：`SettingsDatabase_Impl/e47/ige/gq0/l3a/s3a/rs0/ks0/kq0/hge/l7e/na4/vb4`
- UI/ViewModel 交叉证据：`bq0/cq0/kci/dhb/rge/vge/nge/tge`
- `ks0.invokeSuspend()` 的普通 JADX 输出被跳过，因此另以 JADX 1.5.6
  `--single-class defpackage.ks0 --decompilation-mode simple --show-bad-code` 复核 DEX 控制流。

本证据只证明原版共享纸张设置、收藏和 spacing 的职责及数据语义；默认模板路由与编辑器职责分离见
`original-default-template-route-jadx-2026-08-16.md`。

## 2. Room 表是独立设置状态，不是 selectedDefaultTemplate

`SettingsDatabase_Impl.java` / `e47.java` 明文创建：

```sql
CREATE TABLE IF NOT EXISTS `PaperBackground` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  `paperSize` INTEGER NOT NULL,
  `paperOrientation` TEXT NOT NULL,
  `backgroundColor` INTEGER,
  `legacyPaperIndex` INTEGER,
  `paperLineType` TEXT NOT NULL,
  `spacing` REAL,
  `hasOptions` INTEGER NOT NULL
)

CREATE TABLE IF NOT EXISTS `BackgroundInfo` (
  `paperLineType` TEXT NOT NULL,
  `spacing` REAL,
  `hasOptions` INTEGER NOT NULL,
  PRIMARY KEY(`paperLineType`)
)
```

`na4.q()` 给出两个插入 adapter，`vb4.I1()` 给出收藏删除/更新和 BackgroundInfo 更新：

```text
INSERT INTO PaperBackground (...)
  VALUES (nullif(?, 0),?,?,?,?,?,?,?)
INSERT INTO BackgroundInfo (paperLineType,spacing,hasOptions) VALUES (?,?,?)
DELETE FROM PaperBackground WHERE id = ?
UPDATE BackgroundInfo SET paperLineType=?,spacing=?,hasOptions=? WHERE paperLineType=?
```

因此：

1. `PaperBackground` 是完整纸张组合的收藏集合；
2. `BackgroundInfo` 是按 PLAIN/LINES/GRID/DOTS 共享的线型设置；
3. 两表不能替代 root `nz9` 的 `selectedDefaultTemplate`，也不能替代当前笔记的 note background operation。

## 3. 四类 BackgroundInfo 的空表回退

`gq0` 有两个关键构造：

```java
public gq0() {
    this(jq0.J, null, false);
}

public gq0(jq0 jq0Var) {
    this(jq0Var, Float.valueOf(0.5f), true);
}
```

`rs0` 为四类分别建立 Flow，并在 DAO 返回 null 时给出对应初值：

```text
PLAIN -> new gq0()              -> spacing=null, hasOptions=false
LINES -> new gq0(LINES)         -> spacing=0.5f, hasOptions=true
GRID  -> new gq0(GRID)          -> spacing=0.5f, hasOptions=true
DOTS  -> new gq0(DOTS)          -> spacing=0.5f, hasOptions=true
```

这说明空表不应预写四行；观察层使用上述四个 fallback 即可。

## 4. spacing 写入、可空旧值和十档 UI

`rs0.f(jq0,float)` 对 PLAIN 直接返回；其他线型启动 `ks0`。DEX simple 输出显示 `ks0 case 0`：

```text
current = rs0.c(lineType)
spacing = current.lineType == PLAIN ? null : requestedFloat
updated = gq0.copy(current, spacing=spacing, hasOptions=current.hasOptions)
ige.d.P(transaction, updated)
```

其中 `ige.d` 由 BackgroundInfo insert adapter 与 update adapter 组成，因此是按主键 insert-or-update；
`gq0.copy` 的 bitmask 保留已有 `hasOptions`。

`kq0.a` 是原版十档 Float32 列表：

```text
0.1968505, 0.25, 0.393701, 0.5, 0.5905515,
0.75, 0.787402, 1.0, 1.181103, 1.5
```

`kci.e()` 用 `list.indexOf(spacing)` 显示 `index + 1`，Compose Slider 的 steps 为
`list.size() - 2`；`dhb case 24` 将滑块值取整后重新映射到 `kq0.a`。

同时，原版实体与 Room 列都允许 `spacing = null`：`gq0` 的字段是 `Float`，`na4` 对 null 绑定 SQL NULL，
`crb/l7e/zec` 也按 nullable Float 读取。`fad.t(nz9)` 从旧/导入背景还原 `l3a` 时，如果底层背景没有
interval，同样会生成 null；若存在 interval，则它不保证一定属于 UI 十档。

移植结论：UI 新写入仍限定十档，但读取、收藏比较和旧数据换算必须保留 nullable/legacy 正 Float，不能把
原版可读数据误判为损坏。

## 5. 收藏比较忽略 Room id，删除复用已存 id

`l3a` 的 `equals/hashCode` 只比较 `s3a paperInfo` 与 `gq0 backgroundInfo`，不比较可变字段 `c`；`l7e`
从 Room 读取后才把行 id 写入 `l3a.c`。

`hge` 的两个分支证明：

- 添加：先读取全部收藏；`contains(candidate)` 为真时不插入，否则调用 insert adapter；
- 删除：先在集合中寻找 `equals(candidate)` 的已存对象，找到后用该对象（含 Room id）调用 delete adapter。

所以收藏去重必须比较完整语义：纸型、方向、颜色、legacy index、线型、spacing、hasOptions；但不能把
调用方临时 `id=0` 纳入 equality。取消收藏也不能直接删除 `id=0`，必须先取得语义相同行的真实 id。

## 6. paperSize 是两个 Float32 raw bits 组成的 SQLite INTEGER

`ndj.f(h4a)`：

```java
qed metric = paperSize.c(oof.METRIC, null, null);
return ((long) Float.floatToRawIntBits(metric.width) << 32)
    | ((long) Float.floatToRawIntBits(metric.height) & 0xffffffffL);
```

按原版八种纸型计算出的十进制 INTEGER：

| 纸型 | packed INTEGER |
|---|---:|
| A3 | 4869657835720540160 |
| A4 | 4850939749765251072 |
| A5 | 4833488301204832256 |
| A6 | 4814910952737865728 |
| A7 | 4797459504177479680 |
| Letter | 4852600450409280307 |
| Legal | 4852600450411777229 |
| Tabloid | 4867180855066879590 |

这些值均超过 JavaScript `Number.MAX_SAFE_INTEGER`。Harmony 边界必须以十进制字符串绑定，让 SQLite
INTEGER affinity 完成精确转换；读取必须 `CAST(paperSize AS TEXT)`，不能先经过 JS number 再写回。

## 7. 颜色必须保留完整 ARGB alpha

`tu1.b(hu1)` 直接把 alpha/red/green/blue 四个 byte 打包为 signed ARGB：

```java
return (blue & 255)
    | ((alpha & 255) << 24)
    | ((red & 255) << 16)
    | ((green & 255) << 8);
```

`fad.t(nz9)` 从原版 paper color 调用 `tu1.b()` 写入 `s3a.backgroundColor`，没有“不透明”门禁。因此 UI
预设虽然通常为 opaque，模型、收藏和导入兼容层仍必须保存 alpha；例如 ARGB `0x80123456` 的 signed
值为 `-2146290602`。

## 8. 设置页与编辑器共享两表，但提交目标不同

`rge` 与 `vge` 都持有同一个 `rs0`，并把 PLAIN/LINES/GRID/DOTS 四条 Flow 交给 `dq0/cq0` 生成
`bq0 BackgroundDrawingInfo`。`bq0` 同时含：

```text
isSelected, isFavorited, paperLineType, spacing, hasOptions, drawCommands
```

`cq0` 的 selected/favorited 都用当前 `s3a + gq0` 完整 `l3a` 比较；`kci.d()` 只在 `hasOptions` 为真时
显示 spacing 设置；`kci.a()` 独立处理收藏动画与回调。

两端共享数据库状态，但职责仍是：

```text
Settings TemplateRoute/rge -> selectedDefaultTemplate Preferences
Editor vge                 -> 当前笔记 background operation
两端 rs0/ige               -> BackgroundInfo + PaperBackground
```

## 9. Harmony 适配结论

1. 数据库升至 v63，原子增加两张原版表；最新 schema 也必须直接创建。
2. 所有写入使用全局 RDB 单写者和事务；失败回滚。
3. packed paperSize 以字符串跨 ArkTS/SQLite 边界，避免 64 位精度损失。
4. 收藏按完整 `l3a` 语义去重，删除前取真实 id。
5. 设置页与编辑器复用同一 `PageSettingsPanel`/Store；组件自身确保 DatabaseManager 已初始化。
6. Slider 拖动期间只做本地预览，在 ArkUI `End/Click` 提交最终离散值，避免异步 busy 丢掉最后落点。
7. spacing 修改只更新共享 `BackgroundInfo`；必须再次点模板卡，才写默认模板或当前笔记。
8. 本阶段不宣称完成完整 paper color/legacy picker；仅确保现有颜色与 legacy 值不被破坏。
