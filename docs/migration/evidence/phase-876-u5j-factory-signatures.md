# Phase 876 证据 — `u5j` 操作工厂签名登记

## 目的

登记原版 op 工厂 `u5j` 的全部公开方法签名——每个 op 类型
的构造参数契约（857 已登记方法→表映射与校验；本阶段补全
逐参数签名）。

## 原版证据（`decompiled_1.0.3/sources/defpackage/u5j.java`）

所有方法首参 `x09`（文档模型上下文）：

| 方法 | 返回（payload） | 参数（去掉 x09） |
|------|----------------|------------------|
| A | me8 MODIFY_STYLE | qo5, z1d×3, g2d, z2d, k2d, g2d, z2d, z1d×3, z66 —— 13 个样式 setter |
| D | pub REMOVE_CHAR | cxc, qo5 |
| E | qub REMOVE_CHARS | ArrayList(cxc), qo5 |
| G | f2c REVIVE_CHARS | qo5, List(cxc) |
| H | l2d SET_METADATA | z2d, m2d, z2d, Boolean, String, Float, tv6, dz0 —— 与 l2d 8 字段逐项对应 |
| J | mqf UPDATE_CHECKBOX | qo5, exc 位置, boolean 勾选 |
| a | gd ADD_PATH_ELEMENTS | qo5, List, List |
| f | rl2 CREATE_BLOCK | cz0, cxc, fqa, qed, qed, dp5, String, hu1, int |
| g | dm2 CREATE_INK | cxc, fqa, Float, qed, u16, t16, ife, hu1, float, List, ArrayList×2, hu1, List, xgb, mmf —— 16 参对应 19 槽 |
| i | ln2 CREATE_PAGE | int, int, int |
| j | ao2 CREATE_SHAPE | cxc, fqa, Float, v4d, u16, t16, hu1, float, hu1, xgb, Float, int |
| k | s83 DELETE_ENTITIES | List×4（entityDel/entityUndel/pageDel/pageUndel） |
| l | s83（重载） | List, List, int |
| n | td8 MODIFY_BLOCK | List, ty0, cxc, fqa, k2d, y2d, qed, ive, Boolean, xgb, z2d, g2d, p2d, n2d, Boolean×3 —— 18 参 |
| q | wd8（简） | ArrayList, hu1, Float, t16, int |
| r | wd8（全） | List, cxc, fqa, k2d, y2d, t16, hu1, Float, nl8×3, g2d, List, xgb, ife |
| s | ge8 MODIFY_PAGE | List(pages), Integer, m2d, oz9, int |
| t | ge8（moveTo 变体） | List, lxc, m2d, oz9 |
| u | he8 MODIFY_PARAGRAPH_STYLE | exc, exc, qo5, a3d, o2d, k2d, j2d, z2d, b3d —— exc 起止区间对 |
| v | je8 MODIFY_POSITIONS | List |
| w | ke8 MODIFY_RECORDING | qo5, String, List, xgb |
| x | le8 MODIFY_SHAPE | List, cxc, fqa, v4d, t16, hu1, Float, g2d, Boolean, int |
| p | vd8 MODIFY_GROUP | qo5, List |
| c/d/e | 辅助 | 列表/集合变换助手 |

### 语义锚点

- **`exc` 作参数类型**：`J`/`u` 以接口 `exc` 收位置——任何
  实现 exc 的位置结构（cxc 或等价物）皆可。
- **`xgb` 出现在 g/j/n/r/x**：新实体的创建时刻挂钟。
- **`mmf` 仅 g**（CREATE_INK 携带 ink 序数）；**`v4d` 仅 j/x**
  （形状种类包装 vs z4d 枚举）；**`nl8`×3 仅 r**（wd8 三组
  可空 setter）。
- **`haj.a(null, nz9, 1, oz9, 16)`**（wz9.u）：另族助手——
  null/nz9/int/oz9/int 五参；末参 16 为写侧常量
  （语义标记为「固定标志位」登记，不作过度推断）。

## Harmony 侧

`note/src/main/ets/data/Original*PayloadEncoder.ets` 与
`*Operation.ets` 的入参形态与上述签名对应（如 ModifyInk 的
style/color/width/styleMap 子集 = r() 的可空 setter 理念）。

## 结论

工厂签名层登记完毕；op 构造参数与 payload 字段的对应关系
留档。纯文档+fixture 阶段。
