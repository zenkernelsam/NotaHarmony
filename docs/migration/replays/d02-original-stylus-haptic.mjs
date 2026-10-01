// Phase 1436 replay: 原版连接触控笔触觉反馈轴 fail-closed 裁定。
// 原版证据（decompiled_1.4.2）：
//   iu6.java   = hapticPreferences DataStore（intensity 默认 100）
//   p5h.java   = stylusConnection DataStore（isConnected）
//   ou6.java   = 8 触觉纹理 {None,Ink,Pencil,Brush,Marker,ChiselMarker,
//                Eraser,Sparkle}
//   nu6.java   = 触觉会话管理器（纹理下发 nu6.i、intensity 持久化 c(j)、
//                "Interactive effect not supported" 日志、ju6 设备门面）
//   ygg.java   = 工具→纹理映射（eti 0/1→Ink、2→Pencil、3→ChiselMarker、
//                5→Eraser、其余→None）
//   yb0.java   = feature_note__options_menu_disconnect_stylus 菜单项
//   au6.java   = "Haptic" 设置分组 + intensity 滑条
//   HapticPreferencesInitializer = androidx.startup 初始化
// Harmony：无 BLE 连接触控笔硬件生态/API（PenKit 只提供输入预测，
// 无触觉下行通路）——isConnected 永假，菜单/设置面不可达 = 干净
// fail-closed（无可达坏路径）。
import { readFileSync } from 'node:fs';
import { strict as assert } from 'node:assert';

const read = (p) => readFileSync(p, 'utf8');
const list = (p) => readFileSync(p, 'utf8');

// (1) Harmony 侧不虚构连接笔面：无 disconnect_stylus / haptic 入口
const menu = list('note/src/main/resources/base/element/string.json');
assert.ok(!menu.includes('disconnect_stylus'),
  '不注册 disconnect_stylus 串（无连接笔 → 无菜单面）');
const zh = list('note/src/main/resources/zh_CN/element/string.json');
assert.ok(!zh.includes('disconnect_stylus'), 'zh_CN 同样不含');

// (2) 编辑器无触觉纹理分发（ou6/i 字段语义不存在）
const vm = list('note/src/main/ets/ui/editor/EditorViewModel.ets');
assert.ok(!/haptic/i.test(vm), 'EditorViewModel 无 haptic 通道');

// (3) 设置页无 "Haptic"/intensity 行（au6 rf3 设置项等价物不存在）
const settings = list('note/src/main/ets/ui/settings/SettingsPage.ets');
assert.ok(!/haptic|intensity/i.test(settings), '设置页无 haptic/intensity 行');

// (4) 工具切换路径无 ou6 纹理写入（ygg 工具→纹理映射不虚构）
const toolbar = list('note/src/main/ets/ui/editor/EditorToolbar.ets');
assert.ok(!/ou6|hapticTexture|stylusHaptic/i.test(toolbar),
  '工具栏不写触觉纹理');

// (5) 文档登记 fail-closed 边界 + 原版证据锚点
const adr = read('docs/migration/adr/ADR-1371-stylus-haptic-failclosed.md');
assert.match(adr, /ou6|Ink.*Pencil.*Brush/, '8 纹理枚举登记');
assert.match(adr, /iu6|hapticPreferences/, 'intensity 偏好登记');
assert.match(adr, /p5h|stylusConnection|isConnected/, '连接态登记');
assert.match(adr, /disconnect_stylus/, '菜单项登记');
assert.match(adr, /fail-closed|fail.closed/i, 'fail-closed 裁定');

const ev = read('docs/migration/evidence/phase-1435-memory-trim.md');
assert.match(ev, /cs0|BackgroundMaintenanceWorker/, 'P1435 证据衔接（同轴类）');

console.log('d02-original-stylus-haptic: OK (11 checks)');
