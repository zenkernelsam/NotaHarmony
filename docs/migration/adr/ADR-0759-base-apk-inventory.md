# ADR-0759 — base APK 内部清单闭合(dex/META-INF/properties)

- 状态：Accepted
- 日期：2026-09-26
- 关联：ADR-0749~0757(资源层)、ADR-0747/0750(依赖清单)、
  Phase 795(XAPK split)、Phase 811(原生库)

## 背景

base APK 的内部成员结构(dex 数、META-INF、properties、顶层
文件)是打包层的最后未登记面。

## 取证结论

- 成员计数：1132(1.0.1)→1140(1.0.3)→1569(1.4.2)。
- **dex 3→4**:1.4.2 新增 classes4.dex,跨第三个 64K 方法边界,
  与功能扩容一致。
- res 成员 665→625(厂商裁剪);assets 115→576(全量已登记);
  META-INF 176→184(+23/−15)。
- META-INF 差异全部归属已登记面:Metro DI 框架 +7、
  ink-storage .version(798 互证)、Singular 12.15→12.16、
  jsoup LICENSE、lifecycle LICENSE、许可证更名、
  okhttp GraalVM 元数据移除、services 混淆名 11→10 重排。
- ~60 个 vendor properties 两版一致;顶层 marker 文件不变。

## 决策

1. 容器层差异登记为打包事实，不产生移植动作(Harmony HAP 无
   dex/META-INF 对应物)。
2. **Metro DI**(dev.zacsweers.metro)登记为 1.4.2 新随包的
   依赖注入框架 —— 应用代码无直接 import(混淆/生成代码层
   使用),属实现细节，不改变已登记的行为面。
3. services 混淆名重排登记为无语义的服务注册改写。

## 后果

- APK 容器层闭合：成员、dex、META-INF、properties 四层差异
  全部登记且归属既有集群。
- Replay `d02-base-apk-inventory.mjs` 18/18 钉住。
