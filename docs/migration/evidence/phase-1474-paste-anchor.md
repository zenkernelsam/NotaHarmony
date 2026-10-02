# Phase 1474 — Ctrl+V 粘贴锚点 = 负载原界中心 + min(w*0.1,30)

- **阶段**: Phase 1474
- **日期**: 2026-08-10
- **原版版本**: decompiled_1.4.2（APK `com.gingerlabs.notability` 1.4.2）
- **Harmony 落点**: `NoteCanvasView.ets` Ctrl+V/PASTE 键支 →
  `StrokeClipboard.payloadBounds()` → `pasteClipboard(target)`

## 原版证据链

### 负载界来源（ot2.java / pt2）

```java
// ot2.d(msf) —— Ctrl+C（w60 byte26 → bd8.K.d）：
//   lt2VarH = h(r0b, msf) 负载构建；
//   this.d.a = lt2VarH.b();        // pt2.a ← 负载 jt2（含 sbe 原界）
//   omeVar.a();                     // 清选
//   h.b(...)                        // 写系统剪贴板
// ot2.b():
public final jt2 b() {
    jt2 jt2Var = this.d.a;          // 负载原界记录
    if (jt2Var != null) {
        ClipboardManager cm = j.f(gqfVar.a);
        if (!j.i(cm.getPrimaryClipDescription(), gqfVar.f)) {
            return jt2Var;          // 剪贴板描述符仍兼容才返回
        }
    }
    return null;
}
```

### Ctrl+V 支（f2.java:182-211，`!pa8.W` 块内）

```java
if (db8.r(keyEventB)) {
    if (pa8.a(db8.n(keyEventB), pa8.H)) {          // H = ofk.e(50) = V
        if (lxm.a(db8.o(keyEventB), 1)) {          // UP
            jt2VarB = bd8Var2.K.b();               // 负载原界
            if (jt2VarB == null) {
                ea1Var.p(qc8Var);                  // 空/不兼容剪贴板 no-op
            } else {
                sbe sbeVar = jt2VarB.b;            // 负载界
                jB = u64.b(sbeVar);                // 界中心
                fMin = Math.min((sbe.c - sbe.a) * 0.1f, 30.0f);
                jA4 = center + (fMin, fMin);       // 双轴等值偏移
                // 屏坐标视口检查（exj.a=zoom、exj.c=ku7 视口矩形）：
                if (x∉(ku7.a, ku7.c) 半开 || y∉(ku7.b, ku7.d) 半开)
                    bdeVar.F = ((exj) ...).c();    // 视口中心回退
                tee.I(z(), new m86(bd8, bdeVar, jt2VarB, byte20), 3);
            }
        }
    }
}
```

- 锚定**负载原界**（复制/剪切/duplicate 时的原位），与当前选区
  无关——`ot2.d/e/a` 均在负载构建后 `ome.a()` 清选。
- `zx7.z` 为半开包含检查（`x≥a && x<c` 同构）。

## Harmony 移植

- `StrokeClipboard.payloadBounds()` 公开访问器：`hasContent` 门 +
  `unionBounds` 合法性检查 → 负载原界；null ≡ `ot2.b()==null`。
- `NoteCanvasView` Ctrl+V/PASTE 支重写：负载非空 →
  `cx,cy = 界中心 + min(w*0.1,30)` → `canvasToScreen` 半开视口
  检查 → 越界/空负载回退视口中心 → **直达 `pasteClipboard(target)`**
  （绕过 `selectionPasteTarget` 的选区中心优先——原版锚定负载）。
- `clipboardAvailable`/`canPasteClipboardNow` 内部门 ≡ `ot2.b()`
  的 `gqf` 描述符兼容检查（外部剪贴板无负载 → null → 视口中心锚，
  但 `pasteClipboard` 空负载 no-op ≈ `qc8`）。

## 差异与残余

- `gqf` 描述符兼容检查：原版读系统 ClipboardManager 描述符比对
  MIME；Harmony 以 `strokeClipboard.hasContent()` + `canPaste`
  内部状态近似——外部富文本剪贴板路径由
  `startOriginalClipboardImagePaste` 另行处理（菜单路径保留）。
- `exj.c` 视口矩形含系统 insets；Harmony 用 `canvasCtx` 画布矩形
  ——差异 ≤ 系统栏像素级。
- 菜单/长按 PASTE 路径保留 `selectionPasteTarget`（选区中心优先）
  ——原版上下文菜单粘贴锚 = 长按点（`bde.F` 由触摸事件设置），
  本次仅校正键盘支。

## 验证

- Replay `d02-original-paste-anchor.mjs`：18 checks（payloadBounds
  pin、锚点式、视口半开检查、回退、直达调用、可执行模型 5 例）。
- 相关剪贴板/键盘 fixture 全绿；`note@default`/`note@ohosTest`
  构建成功。

## 关联

- ADR-1409-paste-anchor
- 报告 `docs/migration/reports/phase-1474-paste-anchor.md`
