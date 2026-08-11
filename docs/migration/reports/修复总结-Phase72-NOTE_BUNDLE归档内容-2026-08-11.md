# Phase 72 修复总结：NOTE_BUNDLE 归档页面内容闭环

日期：2026-08-11

## 问题

Phase 63 曾记录 NOTE_BUNDLE CREATE_BLOCK 可直接写入最终归档页，但生产 bootstrap 实际把所有最终 tombstone
都写成 `visible=0,page_id=NULL`，且不创建 `original_deleted_page`。因此 standalone Ink/Block reducer 虽支持归档快照，
在完整 bundle 首次导入时仍找不到目标；CREATE_INK 还被 preflight 主动拒绝。这是测试模型与生产状态机不一致造成的假闭环。

## 修复

- 依据原版 `uae/gr7/zq9/v69`，确认 NOTE_BUNDLE child 仍进入同一 CREATE_INK/CREATE_BLOCK reducer，页面最终删除
  不代表 child 内容可被丢弃。
- 预检通过后收集 CREATE_INK/CREATE_BLOCK 目标页及 MODIFY_INK/MODIFY_BLOCK 的显式 pageOrigin；目标不在 bundle
  page history 时零写入 deferred。只有“最终 deleted 且被内容历史引用”的页面才分配确定性 original storage ID、建立
  `original_deleted_page`；纯历史空 tombstone 继续保持 unbound，不生成伪空白页。
- 在内容回放前建立归档容器，使 Ink/Block 复用既有归档 snapshot、z-order、revision、搜索失效、hidden entity 和
  exact retry 逻辑；移除 CREATE_INK 的错误 archived-page deferred 门。
- bundle metadata/content 回放完成后，背景物化同时支持 live 与 archive。页面显式 null 可正确取得最终 note-level
  fallback，PDF/pageInAsset 也不会因为归档容器的临时背景而丢失。
- 幂等核对要求 archive 数量、identity、稳定 page ID 完全一致；缺失、额外或错绑 archive 仍整包冲突回滚。

## 验证

- 新增 `d02-note-bundle-archived-content.mjs`：覆盖 live 页、Ink+Text Block 归档页、MODIFY_INK 跨归档页移动、
  无内容 tombstone、双页 revision、metadata 后背景、恢复、稳定 ID 与注入故障全回滚。
- 全量桌面 replay：`TOTAL=59 FAILED=0`。
- `note@default assembleHap`：BUILD SUCCESSFUL。
- 明确指定 `module=note@ohosTest` 后，测试 HAP：BUILD SUCCESSFUL。
- 未启动模拟器/真机，未执行设备 Hypium。

## 设备验收边界

需用真实 NOTE_BUNDLE 构造已删除页，混合 Ink、Text、IMAGE、MATH 后再 undelete，核对背景、层序、搜索、重启恢复
及资产到达刷新。纯 tombstone 必须继续不可见且不生成空白页。
