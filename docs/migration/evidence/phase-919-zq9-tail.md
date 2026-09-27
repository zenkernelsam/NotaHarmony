# Phase 919 证据 — zq9 注册表尾部六表

## 目的

zq9 注册表尾簇实名——zq9 全部 op 载荷读侧闭合。

## 六表（toString 实证）

### `l2d` = `SetMetadata`（8 字段 = a79 寄存器镜像）

`SetMetadata(title=, pageBackground=, handwritingLanguage=,
alignTextToLines=, defaultFontFamily=, defaultFontSize=,
layoutMode=, blockWrapSupport=)`

- title:`z2d`、pageBackground:`m2d`、handwritingLanguage:`z2d`、
  alignTextToLines:`Boolean`、defaultFontFamily:`String`、
  defaultFontSize:`Float`、layoutMode:`tv6`、
  blockWrapSupport:`dz0`。
- **与 a79（885）的 8 个 LWW 寄存器一一对应**——
  SET_METADATA 是文档级寄存器的写入口；混合裸值与
  setter 包装。
- `haa.SET_METADATA`。

### `ee8` = `ModifyPDFField`

`{assetHash, key, valueType, valueString, valueBoolean}`
—— PDF 表单字段更新（值双表示 string/bool）。

### `mqf` = `UpdateCheckbox`

`{textField:qo5, location:cxc, isChecked:bool}` ——
CHECKBOX_OP 里程碑（ar6=3）对应的复选框状态 op。

### `tl2` = `CreateComment`

`{anchor:z5c.t(多态子表), text}` —— 评论锚点复用
z5c 判别分发机制。

### `ud8` = `ModifyComment`

`{comment:qo5, anchor, text, resolved}` —— 含 resolved
布尔（评论解决状态）。

### `ra0` = `AssetCloudPersisted`

`{assetHash}` —— 资产云端持久化标记 op（同步协议
信号：资产已上传）。

## 结论

zq9 注册表 op 载荷读侧全部实名：26+ 类，
30+ payload 类型闭合（SET_METADATA→…→MODIFY_COMMENT）。
