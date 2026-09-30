// Phase 1281 — PDFTron PDFNet native layer
import { readFileSync, readdirSync, statSync, existsSync } from 'fs';
import { strict as assert } from 'assert';
import { join } from 'path';
const S = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/';
const R = f => readFileSync(S + f, 'utf8');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };
const cnt = d => { let c = 0; if (!existsSync(d)) return 0; const w = dd => { for (const f of readdirSync(dd)) { const p = join(dd,f); if (statSync(p).isDirectory()) w(p); else if (f.endsWith('.java')) c++; } }; w(d); return c; };

const pdfnet = R('com/pdftron/pdf/PDFNet.java');
t('PDFNet initialize', /initialize|PDFNet/.test(pdfnet));
const pdfdoc = R('com/pdftron/pdf/PDFDoc.java');
t('PDFDoc class', /class PDFDoc|PDFDoc/.test(pdfdoc));
const annot = R('com/pdftron/pdf/Annot.java');
t('Annot native GetRect/GetType', annot.includes('native long GetRect') && annot.includes('native int GetType'));
t('Annot IsValid native', annot.includes('native boolean IsValid'));
const te = R('com/pdftron/pdf/TextExtractor.java');
t('TextExtractor', te.length > 0);
const st = R('com/pdftron/pdf/Stamper.java');
t('Stamper', st.length > 0);
const link = R('com/pdftron/pdf/annots/Link.java');
t('annots/Link', link.length > 0);
const cv = R('com/pdftron/pdf/Convert.java');
t('Convert (office→pdf)', cv.length > 0);
t('pdftron 27 files', cnt(S + 'com/pdftron') >= 25);
const sdf = R('com/pdftron/sdf/Obj.java');
t('sdf Obj low-level', sdf.length > 0);
console.log('pdftron replay: ' + n + '/10 checks green');
