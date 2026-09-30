# ADR-1291：单元测试套件

## 状态

已接受（Phase 1349）。

## 决策

单元测试 = 121 个 per-module `.test.ets` 休眠参考套件
（Hypium 设备运行被禁，未注册进 ohosTest runner）。

## 理由

`note/src/test/` 121 测试覆盖全部核心模块（算法/CRDT/
持久化/plist/橡皮/录音/`Original*`）；`ohosTest/List.test`
仅注册占位 `abilityTest()` —— Hypium 需真机（用户禁
模拟器/真机），故 `src/test` 为休眠参考测试，不阻塞
build。真实验证由 1205 Desktop Replay fixtures 承担
（可离设备运行）。

## 后果

测试覆盖存在（121）但依赖设备运行 —— 静态验证以
Desktop Replay 为主。
