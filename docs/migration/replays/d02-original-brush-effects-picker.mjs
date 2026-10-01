// D02 原版 ui_tools__brush_pack_rainbow/glitter — Phase 1424 fail-closed 契约
// 证据链（decompiled_1.4.2）：
//   yxi.java:69-99 — 笔刷设置行 = u4h 样式项 + t4h 效果 chip，效果区段标题
//     ui_tools__google_ink_section_title，且每个 chip 由 i35.a(zm7) 远端开关门控。
//   i35.java — a(zm7) 读 vnh DataStore/远端 flag（RAINBOW→a, GLITTER→b）；
//     c flag 另门控 wri 变体。zm7.K = {RAINBOW(1), GLITTER(2)} 静态集合。
//   c71/urm — chip 选择映射回 zm7 bitmask；jz0.j 聚合 RAINBOW+GLITTER 组合枚举。
//   cti:672/u81:319 — a11y：tool_with_effects/stroke_style_pill_description
//     仅在效果存在时生效。
//   assets/brushpacks/rainbow.brushpack — ZIP+gzip proto，Google Ink 专有笔刷族
//     资产；Java 层无 RAINBOW/GLITTER shader（ADR-0046：WetMirror/native 引擎
//     着色，发明近似 shader 非证据移植）。
//   googleInkBrushPackId 已按 ADR-1327 fail-closed（恒 NULL）。
// 契约：Harmony 仅做数据无损保留（inkEffects bitmask 透传），不得出现效果
// 选择 UI、不得有 ToolState 效果列、渲染器不得消费 inkEffects（直至真实引擎）。
import assert from 'node:assert/strict';
import fs from 'node:fs';

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};
const read = p => fs.readFileSync(p, 'utf8');

const strokeTypes = read('note/src/main/ets/core/model/StrokeTypes.ets');
const brushTypes = read('note/src/main/ets/core/model/BrushTypes.ets');
const toolbar = read('note/src/main/ets/ui/editor/EditorToolbar.ets');
const painter = read('note/src/main/ets/rendering/StrokeCanvasPainter.ets');
const session = read('note/src/main/ets/rendering/StrokeSession.ets');
const viewModel = read('note/src/main/ets/ui/editor/EditorViewModel.ets');
const strings = read('note/src/main/resources/base/element/string.json');

// 数据层无损保留（ADR-0046 契约不变）
check('RenderSpec retains inkEffects bitmask field', /inkEffects\?: string/.test(strokeTypes));
check('RenderSpec retains inkEffectsTinted + inkEffectPhase',
  /inkEffectsTinted\?: boolean/.test(strokeTypes) && /inkEffectPhase/.test(strokeTypes));
check('RAINBOW=1 GLITTER=2 bitmask comment preserved', /RAINBOW=1/.test(strokeTypes) && /GLITTER=2/.test(strokeTypes));

// 工具状态：无效果列/无 googleInkBrushPackId 之外的专有字段（ADR-1327 恒 NULL）
const toolStateBody = strokeTypes.length && brushTypes.slice(
  brushTypes.indexOf('export interface ToolState'), brushTypes.indexOf('// 1.4.2 ToolStateEntity.shapeKind'));
check('ToolState carries no inkEffects column', !/inkEffects/.test(toolStateBody));
check('googleInkBrushPackId stays fail-closed NULL', /googleInkBrushPackId\?: number \| null/.test(brushTypes));

// 选择器缺位：无 rainbow/glitter chip、无效果 setter、无 Google Ink 区段
check('no rainbow/glitter picker strings', !/brush_pack_rainbow|brush_pack_glitter/.test(strings));
check('EditorToolbar has no effect chip UI', !/rainbow|glitter|inkEffect/i.test(toolbar));
check('ViewModel exposes no setInkEffects/toggleEffect mutator', !/setInkEffects|toggle.*[Ee]ffect/.test(viewModel));

// 渲染器不消费 inkEffects（近似 shader 会发明非证据行为）
check('StrokeCanvasPainter ignores inkEffects', !/inkEffect/.test(painter));
check('StrokeSession ignores inkEffects', !/inkEffect/.test(session));

console.log(`TOTAL=${checks.length} FAILED=0`);
