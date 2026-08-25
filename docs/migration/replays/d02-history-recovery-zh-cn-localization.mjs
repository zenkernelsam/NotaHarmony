#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';

const readJson = (path) => JSON.parse(fs.readFileSync(path, 'utf8'));
const base = readJson('note/src/main/resources/base/element/string.json');
const zh = readJson('note/src/main/resources/zh_CN/element/string.json');

const expected = {
  history_recovery_title: ['Undo History Needs Attention', '撤销历史需要处理'],
  history_recovery_message: [
    'This note is safe to edit, but its saved undo history could not be verified. Continue without the saved history, or reset only the local undo history to start fresh. Your note content and operation log will be kept.',
    '笔记内容可以继续编辑，但已保存的撤销历史无法验证。可以不使用已保存历史继续编辑，也可以仅重置本地撤销历史后重新开始。笔记内容和操作日志都会保留。',
  ],
  continue_editing: ['Continue Editing', '继续编辑'],
  reset_undo_history: ['Reset Undo History', '重置撤销历史'],
  history_recovery_needed: [
    'Saved undo history could not be verified. Editing remains available.',
    '已保存的撤销历史无法验证，仍可继续编辑。',
  ],
  history_recovery_complete: [
    'Undo history reset. New edits can be undone.',
    '撤销历史已重置，新修改可撤销。',
  ],
  history_recovery_failed: [
    'Could not reset undo history. Editing remains available without saved Undo.',
    '无法重置撤销历史；仍可在没有已保存撤销的情况下继续编辑。',
  ],
};

function value(json, name) {
  const entry = json.string.find((item) => item.name === name);
  assert.ok(entry, `${name} exists`);
  return entry.value;
}

for (const [name, [defaultText, chineseText]] of Object.entries(expected)) {
  assert.equal(value(base, name), defaultText);
  assert.equal(value(zh, name), chineseText);
}

assert.doesNotMatch(value(base, 'history_recovery_title'), /[\u4e00-\u9fff]/);
assert.match(value(zh, 'history_recovery_title'), /撤销/u);

console.log('D02_HISTORY_RECOVERY_ZH_CN_LOCALIZATION_REPLAY_OK TOTAL=9 FAILED=0');
