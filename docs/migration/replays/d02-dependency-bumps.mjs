// D02 依赖版本升档清单 — Phase 806
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const load = (root) => {
  const out = {};
  const walk = (d) => {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const p = path.join(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.name.endsWith('.version')) {
        const c = fs.readFileSync(p, 'utf8').trim();
        if (c) out[e.name] = c;
      }
    }
  };
  walk(root);
  return out;
};
const A = load('C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3');
const B = load('C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2');

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

const keys = [...new Set([...Object.keys(A), ...Object.keys(B)])];
const bumped = keys.filter((k) => A[k] !== B[k] && A[k] && B[k]);
const added = keys.filter((k) => !A[k] && B[k]);

check('versioned artifacts 129 -> 130, bumps > 60, additions = ink-storage only',
  Object.keys(A).length === 129 && Object.keys(B).length === 130
  && bumped.length > 60 && added.length === 1
  && added[0] === 'androidx.ink_ink-storage.version' && B[added[0]] === '1.1.0-alpha07');

check('Compose BOM 1.11.2 -> 1.12.0 across ui/runtime/foundation/animation',
  B['androidx.compose.ui_ui.version'] === '1.12.0'
  && B['androidx.compose.runtime_runtime.version'] === '1.12.0'
  && B['androidx.compose.foundation_foundation.version'] === '1.12.0'
  && B['androidx.compose.animation_animation.version'] === '1.12.0'
  && A['androidx.compose.ui_ui.version'] === '1.11.2');

check('M3-adaptive + lifecycle graduated to stable',
  B['androidx.compose.material3.adaptive_adaptive.version'] === '1.3.0'
  && A['androidx.compose.material3.adaptive_adaptive.version'] === '1.3.0-alpha09'
  && B['androidx.lifecycle_lifecycle-runtime.version'] === '2.11.0'
  && A['androidx.lifecycle_lifecycle-runtime.version'] === '2.11.0-beta02');

check('ink engine alpha04 -> alpha07 (6 modules) with new storage',
  ['authoring', 'brush', 'geometry', 'nativeloader', 'rendering', 'strokes']
    .every((m) => A[`androidx.ink_ink-${m}.version`] === '1.1.0-alpha04'
      && B[`androidx.ink_ink-${m}.version`] === '1.1.0-alpha07'));

check('Room runtime unchanged 2.8.4 (schema deltas are app-side)',
  A['androidx.room_room-runtime.version'] === '2.8.4'
  && B['androidx.room_room-runtime.version'] === '2.8.4');

check('navigation3/coroutines/core bumps pinned',
  B['androidx.navigation3_navigation3-runtime.version'] === '1.1.7'
  && B['kotlinx_coroutines_core.version'] === '1.11.0'
  && B['androidx.core_core.version'] === '1.19.0'
  && B['androidx.tracing_tracing.version'] === '2.0.1');

console.log(`dependency-bumps replay: ${checks.length}/${checks.length} checks green`);
