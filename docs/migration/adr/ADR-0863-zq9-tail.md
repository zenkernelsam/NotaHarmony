# ADR-0863 — zq9 注册表尾簇六表

## 状态

accepted（文档+fixture，无源改动）

## 原版契约（`decompiled_1.0.3`，toString 实证）

- `l2d` SetMetadata 8 字段 = **a79 文档级 LWW 寄存器
  镜像**（title/pageBackground/handwritingLanguage/
  alignTextToLines/defaultFontFamily/defaultFontSize/
  layoutMode/blockWrapSupport）；混合裸值+setter 包装。
- `ee8` ModifyPDFField{assetHash,key,valueType,
  valueString,valueBoolean}；`mqf` UpdateCheckbox
  {textField,location,isChecked}；
  `tl2`/`ud8` CreateComment/ModifyComment（anchor 复用
  z5c 多态分发；ModifyComment 含 resolved）；
  `ra0` AssetCloudPersisted{assetHash} 云同步信号。

## Harmony 决策

元数据 op 与文档寄存器集对齐；评论锚点走同款
判别子+子表多态。

## Parity 状态

等价；zq9 全部 op 载荷读侧闭合。

## 验证

- `d02-zq9-tail.mjs`：14/14 通过。
- 全量 Replay 792 文件绿，见 Phase 919 提交。
