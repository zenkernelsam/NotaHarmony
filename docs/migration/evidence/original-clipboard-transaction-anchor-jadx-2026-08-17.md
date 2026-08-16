# 原版 Copy/Cut/Paste 事务、锚点与 Group 可达图证据（JADX，2026-08-17）

## 基准与哈希

- 原版基准：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- `sources/defpackage/lg2.java`：
  `6C55D5F3E23CCCDE4CDD6DE155E3683431B98A8EC5CA02DFED7AD902A5540414`
- `sources/defpackage/cg2.java`：
  `BBB88AAF2CD5DD8F3FAC96B580B15B876AAA914F5FE9E77C09E57A208C577AE7`
- `sources/defpackage/mg2.java`：
  `FF1F24A01B6146B281D7B0E11D7326058AB09E42FF2C7213F816A76168E6B47C`
- `sources/defpackage/w43.java`：
  `96E8A7DBA2B4FE01FAC35C2D589D7E73136C489D4722DFE658715EE50F3F95F3`
- `sources/defpackage/v49.java`：
  `FDA359392543834C332350465F32C61F112F43EAAAA41F4621E56C3570B5AF10`
- `sources/defpackage/t39.java`：
  `7D43D59795402EAD8E35F77D0C0BD9FBEC8F712DCBE2980F9C2C78CAB7932FB5`
- `sources/defpackage/g39.java`：
  `3E2174E71FC0D982AF0A2A2837D553D226F5579E4137784C54A8DD6E79F2D719`

## 1. Cut 先生成完整 Copy 快照，删除成功后才发布

`lg2.d()` 的反编译指令虽位于 JADX 注释块，但控制流完整：

```java
gg2 r8 = g(r9, r8)                 // 先生成 CopiedEntitiesData + copiedIds
...
java.util.Set r1 = r8.a()
...
java.lang.Object r9 = x82.I(...)   // 等待选中实体删除完成
...
mg2 r7 = r7.c
cg2 r8 = r8.b()
r7.a = r8                          // 最后发布到会话 clipboard manager
```

`x82.I()` 把传入 ID 逐个包装为删除 operation，再交给模型事务。若 Copy 快照构造失败，方法在删除前返回；若删除
抛错/挂起未成功恢复，也不会执行 `mg2.a = copiedData`。因此原版 Cut 的可观察顺序是：

```text
prepare full copy snapshot -> delete selected IDs -> publish clipboard
```

它不是“先覆盖剪贴板，再尽力删除”，也不是“先删 UI，稍后异步补剪贴板”。

## 2. Cut 删除叶实体，不主动清除 Group 记录

`gg2.a()` 返回 `lg2.g()` 保存的 selection `set`；`lg2.d()` 只把这个 ID 集合交给 `x82.I()`。复制时递归生成的
Group operation 列表保存在 `cg2`，没有加入 Cut 的删除集合。原版因此允许 Group 关系在叶实体隐藏期间继续存在，
Undo 恢复叶实体后原 Group 身份自然重新可见。

Harmony 删除/Cut 后不应因为 Group 暂时没有可见叶子就擅自从 `selectionGroups` 清除它；否则 Undo 虽恢复元素，
Group identity 与嵌套关系却永久丢失。

## 3. Copy 只遍历本次选择可达的 Group 子图

`lg2.g()` 从 selection state 提取本次选中的 Group descriptor，随后只对这些 descriptor 的 Group ID 调用递归
`lg2.c()`：

- 已选叶实体直接进入 copy set；
- Group 递归按 child-before-parent 收集；
- 成员既不是 Group 也不是页面实体时，该可达分支失败；
- unrelated Group 不进入这次递归，不应阻断独立叶或另一棵 Group 的 Copy。

因此 Harmony 必须严格拒绝**可达**的缺成员、空 Group、循环、重复 ID、多父和非根 top Group，但不能因为数据库
中一个与选择无关的损坏 Group 而让所有 Copy 失效。

## 4. 普通 Paste 使用用户请求位置，不使用递增 20/40/60 偏移

`t39` 的数据类明确打印为 `Paste(position=..., source=...)`。`w43.java:435-478` 把手势/命令提供的文档位置 `j`
交给 `d39`；`v49.java:87-115` 点击 Paste 菜单后继续把同一个 `j3` 传给 `zn3`；`lg2.f()/e()` 最终将请求位置
与 `cg2.c()` 原包围盒中心相减，作为粘贴平移量。

`cg2.a()` 确实存在 `min(width * 10%, 30)` 的同轴偏移，但调用点是 `lg2.b()` 的 Duplicate 路径：它先读取该
偏移，再自行构造目标位置。不能把 Duplicate 的视觉错开放进普通 Paste，更不能让连续 Paste 的几何由 sequence
决定。

Harmony 的普通 Paste 适配应为：

```text
delta = requestedCanvasPosition - copiedBoundsCenter
delta = clampWholeSelectionToPageMargin(delta, margin=8)
```

sequence 只用于生成新 identity/防重复，不参与几何。

## 5. Paste 命令只在来源可用时出现，并有约 200ms 并发门

`w43` 先检查内部 `mg2.a`；为空时仅在系统 clipboard 可读且内容类型支持时创建 Paste source。没有来源时不构建
Paste 命令。

`g39.a()` 在请求开始记录 `System.currentTimeMillis()`；`g39.b()` 在 `last + 200 >= now` 时拒绝新的并发请求。
该门是操作并发抑制，不是连续 Paste 的几何步进。

Harmony 当前产品边界只实现编辑器会话内的内部元素剪贴板；系统图片 clipboard 仍是独立能力，不因本阶段被
伪称完成。菜单至少必须同时满足：已有内容、页面加载成功、loaded/current page identity 一致、没有 history
事务占用。

## 移植结论

- Copy 使用 unpublished preparation；只有显式 commit 才替换已发布剪贴板。
- Cut/Delete 先构造未来页面快照和 prepared history，并让同步 save enqueue 完整通过；失败时保留文档、选区、
  history 与旧 clipboard。成功后才应用 UI/history，Cut 再发布 preparation。
- Paste preparation 不消费 sequence，并绑定当前 published clipboard revision；入队失败或 clipboard 已被新 Copy
  替换时不能提交旧 preparation。
- 普通 Paste 使用长按画布位置；选区菜单 Paste 使用选区中心；页面边缘只整体 clamp，不改变内部相对几何。
- 只复制选中 top Group 的可达、bottom-up、single-parent 子图；Cut 后保留 Group records 供 Undo 恢复。
- 200ms 只用于并发命令抑制；Paste 菜单只在实际可用时出现。

## 验证边界

桌面 replay 与 ArkTS fixture 可证明发布顺序、同步入队失败不改状态、revision/sequence、目标中心、边缘 clamp、
Group 可达图及静态 UI 接线。长按与书写手势竞争、系统菜单定位、连续快速点击反馈、跨页实际显示、保存失败提示
和混合元素像素结果仍需设备/Hypium 验收。
