// Phase 852 — emoji 目录资产 + 杂项资产尾部
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const A = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.4.2/resources/assets';
const results = [];
const ck = (n, ok) => results.push([n, ok]);

const emojis = JSON.parse(readFileSync(join(A, 'emojis_unicode.json'), 'utf8'));
ck('emoji 目录 1913 条', emojis.length === 1913);
ck('字段完整', ['emoji', 'description', 'category', 'aliases', 'tags', 'unicode_version', 'ios_version'].every(k => k in emojis[0]));
const cats = {};
for (const e of emojis) cats[e.category] = (cats[e.category] || 0) + 1;
ck('九类齐全', ['Smileys & Emotion', 'People & Body', 'Animals & Nature', 'Food & Drink', 'Travel & Places', 'Activities', 'Objects', 'Symbols', 'Flags'].every(c => cats[c] > 0));
ck('Objects=266 TravelPlaces=219', cats['Objects'] === 266 && cats['Travel & Places'] === 219);

const lp = readFileSync('C:/HarmonyProject/NotaHarmony/note/src/main/ets/ui/library/LibraryPage.ets', 'utf8');
const m = lp.match(/FOLDER_EMOJI_FALLBACK_CATEGORIES[^;]*;/s);
ck('Harmony 179 条策划子集（加载占位）', (m[0].match(/'/g) || []).length / 2 === 179);
ck('无 U+FFFD 损坏', !m[0].includes('�'));
ck('剪刀/清真寺/印度庙/犹太会堂已修复', m[0].includes('✂️') && m[0].includes('🕌') && m[0].includes('🛕') && m[0].includes('🕍'));
ck('九类注释 du3', ['du3.Smileys', 'du3.PeopleBody', 'du3.AnimalsNature', 'du3.FoodDrink', 'du3.Activities', 'du3.Objects', 'du3.TravelPlaces', 'du3.Symbols', 'du3.Flags'].every(c => m[0].includes(c)));

// 尾部资产存在性
ck('ConversionRates.csv', existsSync(join(A, 'ConversionRates.csv')));
ck('PublicSuffixDatabase.list', existsSync(join(A, 'PublicSuffixDatabase.list')));
ck('planners/ 学术种子', readdirSync(join(A, 'planners')).some(f => f.includes('academic_planner_2026_2027')));
const csv = readFileSync(join(A, 'ConversionRates.csv'), 'utf8');
ck('换算表含币种行', csv.includes('USD') && csv.includes('AED'));

let pass = 0;
for (const [n, ok] of results) {
  if (ok) { pass++; console.log(`PASS ${n}`); }
  else console.log(`FAIL ${n}`);
}
console.log(`${pass}/${results.length} checks passed`);
process.exit(pass === results.length ? 0 : 1);
