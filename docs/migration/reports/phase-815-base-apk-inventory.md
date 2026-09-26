# Phase 815 — base APK 内部清单闭合(中文报告)

## 本阶段结论

base APK 容器层完成版本对比：成员 1132→1140→1569,
**dex 3→4**(classes4.dex 新增),META-INF 176→184(+23/−15),
差异全部归属已登记集群。

## 结构差

| 层 | 1.0.3 → 1.4.2 | 性质 |
|---|---|---|
| dex | 3 → 4 | 代码扩容跨 64K 边界 |
| res 成员 | 665 → 625 | 厂商裁剪(791/810) |
| assets 成员 | 115 → 576 | 全量已登记(761/762/763/792) |
| META-INF | 176 → 184 | 见下 |

## META-INF 差异归属

- +7 `dev/zacsweers/metro*`:**Metro DI 框架**新随包(应用代码
  无直接 import，经生成代码/传递依赖使用 —— 实现细节)。
- +1 `ink-storage.version`、+1 jsoup LICENSE、+1 lifecycle
  LICENSE —— 依赖增量互证。
- Singular `v12.15.0`→`v12.16.0` kotlin_module。
- 许可证更名(FastDoubleParser/thirdparty→Schubfach)+
  okhttp GraalVM 元数据移除。
- `META-INF/services/*` 混淆名 11→10 重排(无语义)。

## Harmony 侧

HAP 无 dex/META-INF 对应物；容器差异仅打包层登记，无移植动作。

## 验证

- Replay:`d02-base-apk-inventory.mjs` 18/18;全量 688/688 绿。
- 双 HAP(note@default + note@ohosTest)构建成功。

## 交付物

- `docs/migration/evidence/phase-815-base-apk-inventory.md`
- `docs/migration/replays/d02-base-apk-inventory.mjs`
- `docs/migration/adr/ADR-0759-base-apk-inventory.md`
- 本报告
