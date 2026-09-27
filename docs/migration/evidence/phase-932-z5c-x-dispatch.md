# Phase 932 证据 — `z5c.x(uq9)` 主载荷分发开关

## 目的

单开关完整映射全部 31 个 haa 序数→读类——对
zq9 注册表（860-919）与 haa 枚举（924）的
**权威交叉验证**。

## `z5c.x` 实证（行 2260-2334）

```java
switch (uq9Var.m().ordinal()) {
  case 0: rgc.b(...); throw null;   // NONE → 硬抛错
  case 1: new l2d()    // SetMetadata
  case 2: new ra0()    // AssetCloudPersisted
  case 3: new ln2()    // CreatePage
  case 4: new ge8()    // ModifyPage
  case 5: new yn2()    // CreateRecording
  case 6: new ke8()    // ModifyRecording
  case 7: new e46()    // InsertChar
  case 8: new f46()    // InsertString
  case 9: new pub()    // RemoveChar
  case 10: new qub()   // RemoveChars
  case 11: new f2c()   // ReviveChars
  case 12: new me8()   // ModifyStyle
  case 13: new he8()   // ModifyParagraphStyle
  case 14: new io1()   // ClearStyle
  case 15: new dm2()   // CreateInk
  case 16: new gd()    // AddPathElements
  case 17: new wd8()   // ModifyInk
  case 18: new ao2()   // CreateShape
  case 19: new le8()   // ModifyShape
  case 20: new cm2()   // CreateGroup
  case 21: new vd8()   // ModifyGroup
  case 22: new rl2()   // CreateBlock
  case 23: new td8()   // ModifyBlock
  case 24: new je8()   // ModifyPositions
  case 25: new s83()   // DeleteEntities
  case 26: new tdf()   // TransientInteractionEnded
  case 27: new ee8()   // ModifyPDFField
  case 28: new mqf()   // UpdateCheckbox
  case 29: new yda()   // PeerInteraction
  case 30: new tl2()   // CreateComment
  case 31: new ud8()   // ModifyComment
}
uq9Var.q(l2dVar);  // payload 子表初始化
```

## 要点

- **case 0 NONE 硬抛错**（`rgc.b` schema-version
  错误 + throw）——与 `m()` 读端 NONE 回退不同：
  读枚举容忍未知字节，分发 NONE 载荷即失败关闭。
- `zgb`/`vq9`/`sdf`/`r29` 不在此开关——它们是
  信封层表，非 uq9 payload 类型。
- 31 类与 haa 序数、zq9 注册**逐项一致**。

## `z5c.y(qo5,x09)` = 内容高度助手

`u3c{m4c, long, float}`——nz9.j()=vy7 边距
（上+下）扣页高；PAGELESS 分支；文本块查找
xhe→cie。布局域非线型。

## 结论

z5c.x = 主分发开关，注册表权威交叉验证通过。
