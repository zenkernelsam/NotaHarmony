# ADR-0151: Binary plist URL base 引用校验

## 决策

解析 `0x0D` URL-with-base 对象时，即使移植模型最终只保留 URL 字符串，也必须先通过对象表解引用 base，再解引用末尾字符串。base 越界、损坏或形成循环引用时，整个 plist 解析失败。

## 依据

CFBinaryPlist 的 URL-with-base marker 含两个对象引用：base 与 URL 字符串。既有 F-13 修复已补 marker 和载荷边界，但只消费最后一个引用，导致首个引用不受对象图完整性校验。

## 原因

结构化解析器不能因为当前输出模型不使用某字段，就跳过该字段的引用合法性。否则同一归档中的普通 array/dict 引用会被拒绝，而 URL base 的越界或循环引用却被静默包装成成功。

## 验收

静态 replay 检查 base 引用在字符串引用前经 `objectAt()` 校验，并确认失败路径设置 parser error。恶意二进制样本仍应在 ParserHostile 运行套件中执行。
