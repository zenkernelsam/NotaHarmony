// D02 原版 1.4.2 非字符串资源面收尾 — Phase 791
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

const R103 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/resources/res';
const R142 = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/res';
const ls = (root, d) => fs.readdirSync(path.join(root, d)).sort();
const dirs = (root) => fs.readdirSync(root, { withFileTypes: true })
  .filter((e) => e.isDirectory()).map((e) => e.name);

const checks = [];
const check = (name, condition) => {
  assert.equal(condition, true, `FAILED: ${name}`);
  checks.push(name);
  console.log(`PASS: ${name}`);
};

check('values-* qualifier pruning: 24 -> 13 dirs',
  dirs(R103).filter((d) => d.startsWith('values')).length === 24
  && dirs(R142).filter((d) => d.startsWith('values')).length === 13);
check('layout/color buckets dropped (vendor pruning)',
  dirs(R103).filter((d) => d.startsWith('layout')).length === 3
  && dirs(R142).filter((d) => d.startsWith('layout')).length === 1
  && dirs(R103).filter((d) => d.startsWith('color')).length === 2
  && dirs(R142).filter((d) => d.startsWith('color')).length === 1);
check('res/raw identical across versions (rive/pdftron/yt player)',
  ls(R103, 'raw').join('|') === ls(R142, 'raw').join('|'));
check('font delta limited to Inter variable-axis rename',
  ls(R142, 'font').includes('inter_variablefont_wght.ttf')
  && !ls(R142, 'font').includes('inter_variablefont_opszwght.ttf')
  && ls(R103, 'font').includes('inter_variablefont_opszwght.ttf'));
check('nodpi: 10 covers + 4 planner covers + glitter tile',
  ls(R142, 'drawable-nodpi')
    .filter((f) => f.startsWith('ui_notecovers__')).length === 10
  && ls(R142, 'drawable-nodpi')
    .filter((f) => f.startsWith('ui_planners__')).length === 4
  && ls(R142, 'drawable-nodpi')
    .includes('ui_tools__google_ink_glitter_preview_tile.webp'));
check('drawable additions map to registered clusters',
  ['ui_designsystem__calligraphy_fill.xml', 'ui_designsystem__shape_triangle.xml',
    'ui_designsystem__line_style_dotted.xml', 'ui_designsystem__paper_grid_outline.xml',
    'ui_designsystem__stickermenu_recents_outline.xml', 'ui_designsystem__passkey.xml',
    'ui_designsystem__file_type_csv.xml', 'ui_designsystem__quizzes_explain.xml']
    .every((f) => ls(R142, 'drawable').includes(f)));
check('removed drawables are re-keys, not feature removals',
  !ls(R142, 'drawable').includes('feature_note__selection_menu_convert_to_math.xml')
  && ls(R142, 'drawable').includes('ui_designsystem__math.xml')
  && ls(R103, 'drawable').includes('feature_note__selection_menu_convert_to_math.xml'));

console.log(`nonstring-resources replay: ${checks.length}/${checks.length} checks green`);
