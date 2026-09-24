# 原版多选文件导入（ALLOW_MULTIPLE → rv5/qv5）— JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「Add Files 多选 → 逐文件物化」链路的静态
证据，支撑 Phase 658。与 Phase 652-657 共用 `jv5`/`yq8` 管线，本阶段
补齐「多选」维度。

## 选择器契约（f35.java）

`f35 extends wa`（ActivityResultContract 家族），按 `this.a` 分派：

```text
case 0: GET_CONTENT * + MIME_TYPES                     （单选）
case 1: GET_CONTENT * + MIME_TYPES + ALLOW_MULTIPLE    （f35.c，多选回退）
case 2: OPEN_DOCUMENT * + MIME_TYPES                   （单选）
case 3: OPEN_DOCUMENT * + MIME_TYPES + ALLOW_MULTIPLE  （多选主契约）
case 7(default): IMAGE_CAPTURE（TakePicture，无关）
```

## 启动器装配（nti.java R:815+）

`nti.R(ix4, composer, i, i2)` 是 Add Files 的启动器助手：

```text
f35Var  = new f35(3)              → OPEN_DOCUMENT + ALLOW_MULTIPLE
nw7VarO = fad.O(f35Var, kz1(3, handler))          → rememberLauncher #1
f35Var2 = f35.c                   → GET_CONTENT   + ALLOW_MULTIPLE
nw7VarO2= fad.O(f35Var2, kz1(4, handler))         → rememberLauncher #2
ix4Var3 = yt0(nw7VarO, nw7VarO2, yn7.LIBRARY, 6)  → 按可用性挑启动器
strArr  = (i2 & 1) == 0 ? oj3.e : oj3.f           → MIME 过滤表
返回 jx(3, ix4Var3, strArr)                        → 点击即 launch
```

`u49.f` 中 `function0R = nti.R(lb(...gl8Var12...), ..., 0, 1)` ——
`i2=1` → 取 `oj3.f`（含 octet-stream）。

## MIME 过滤表（oj3.java 静态块）

```text
oj3.e = 图片9(png jpg jpeg webp tif tiff gif heif heic)
      + 音频6(mp3 mp4 aac wav aiff m4a)
      + Office7(doc docx ppt pptx ppsx xls xlsx)
      + nj3.pdf + nj3.txt                          → 22 项
oj3.f = oj3.e + application/octet-stream           → 23 项
```

**`.note/.nbn/.ntb` 不在表内** —— 原版 Add Files 也不允许把归档并入
既有笔记，印证 Phase 657 的 fail-closed 决定。

## 结果流（lb → tf9 → zvh.a/ou5）

- `lb` case 8：`xj2.A(hi2, null, null, new tf9(list, wx4, context, gl8, null, 21))`
  —— 选中 URI 列表进协程。
- `tf9` case 21 `B()`：`sl(29, ef2, list, context)` 复制 URI → 成功则
  `gl8Var.setValue(list)`，失败 `wx4.invoke(list, null)`。
- `u49`：`gl8Var12.getValue()` 非空 → `zvh.a(list, ttfVar, null, str,
  null, function8, dismiss)` 渲染导入详情页（宿主为打开笔记 `ttf`）。
- `zvh.a` 内实例化 `ou5`（`ImportDetailsViewModel`）：`onAction`
  （`o1`/`ub2` 合成 lambda）、`onPasswordSubmitted`/`onPasswordCancelled`
  —— **加密 PDF 密码提示**存在于此。
- `ub2` case 4：`ou5.p(utfVar)` 选定笔记后 `new qv5(ttfVar)` —— 默认
  目标即当前打开笔记。
- `rv5.toString` = `CreateSeparateNotes(folderId, titleOverrides)` ——
  多文件独立导入的第三目标。

## 结论

原版「Add Files」是**多选**文件导入：OPEN_DOCUMENT（GET_CONTENT 回退）
`ALLOW_MULTIPLE` → URI 列表复制 → `ou5` 导入详情页（逐文件状态、目标
选择、加密密码）→ `yq8.g` 按 `qv5`（既有笔记）/`sv5`（单新笔记）/
`rv5`（每文件一笔记）物化。Harmony 侧 Phase 658 补齐多选：两选择器
`maxSelectNumber=500`（API 上限），逐文件走既有分发表，聚合报告
（全败 CORRUPTED / 部分 PARTIAL / 全胜 SUCCESS）。导入详情页与密码
提示登记为未实现差异（ADR-0625）。
