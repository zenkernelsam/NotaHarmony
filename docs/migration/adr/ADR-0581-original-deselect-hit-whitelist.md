# ADR-0581 — deselectMode 点按命中测试白名单（xtc.a(jE, ftc.g)）

- 状态：Accepted
- Phase 612；对齐 `dl1:105-119`/`xtc.a`/`fu1.e` set 参（decompiled_1.0.3）。

## 背景

原版 deselectMode（`ftc.h=true`）按下走
`xtc.a(jE, ftc.g)`——`fu1.e` 的 `set` 参把命中测试白名单限定在
选中 id 集（`set==null || set.contains(id)`，精确与 ±5 容差两程
同适用）。未选中元素不遮挡下层被选中元素：点按穿透命中并
`stc` 移出选区；白名单内无命中才走覆盖层内/外判（utc/qtc）。

Harmony 旧实现先取全集最上层命中再判 `selected.has`——顶层
未选中元素挡住下层被选中元素，deselect 点按落空。

## 决策

1. `hitOrderedElementIdAt`/`topmostPageElementIdAt` 增加可选
   `whitelist` 参：z 序扫描时 `!whitelist.has(id) → continue`；
   两程命中共用（`fu1.e` 全程过滤等价）。
2. `deselectTargetIdsAt` 先建 `selected` 扁平集再传入——
   `ftc.g` 等价；组叶解析不变。
3. 其余调用点默认 `null`——普通点按/tape/链接命中不过滤。

## 后果

- 被覆盖的已选元素在 deselectMode 下可正常点按移除；
- 白名单内无命中行为不变（覆盖层内 utc、层外 qtc）。

## 验证

- `docs/migration/replays/d02-original-deselect-hit-whitelist.mjs`
  13 断言全绿；全量 Desktop Replay 502/502 全绿；
  `note@default` 与 `note@ohosTest` HAP 构建成功。
