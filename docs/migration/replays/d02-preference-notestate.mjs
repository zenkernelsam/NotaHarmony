// Phase 1026 — Preference KV + NoteStateEntity
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const e47 = readFileSync(D + 'e47.java', 'utf8');
const na4 = readFileSync(D + 'na4.java', 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('Preference: key PK', e47.includes('`Preference` (`key` TEXT NOT NULL, `long_value` INTEGER'));
t('Preference: upsert', na4.includes('INSERT OR REPLACE INTO `Preference` (`key`,`long_value`) VALUES (?,?)'));
t('NoteStateEntity: 6 cols', e47.includes('`NoteStateEntity`') && e47.includes('`zoom` REAL') && e47.includes('`scrollOffset` INTEGER'));
t('NoteStateEntity: codeblock lang', e47.includes('`lastCodeBlockLanguage` TEXT'));
t('NoteStateEntity: zoomView cols', e47.includes('`zoomViewSourceRect` TEXT') && e47.includes('`zoomViewShown` INTEGER'));
t('NoteStateEntity: id PK', /NoteStateEntity.*PRIMARY KEY\(`id`\)/.test(e47));
t('na4: NoteStateEntity INSERT 6', na4.includes('INSERT INTO `NoteStateEntity` (`id`,`zoom`,`scrollOffset`,`lastCodeBlockLanguage`,`zoomViewSourceRect`,`zoomViewShown`) VALUES (?,?,?,?,?,?)'));
// both in same DB (na4 binder = toolbox/note-state db)
t('na4: toolbox+notestate co-located', na4.includes('NoteStateEntity') && na4.includes('ToolboxEntity'));
// WorkManager Preference is separate
t('WM Preference named same', e47.includes('androidx.work.impl.model.Preference'));
t('nullable zoomViewSourceRect', e47.includes('`zoomViewSourceRect` TEXT,'));
console.log('preference-notestate replay: ' + n + '/10 checks green');
