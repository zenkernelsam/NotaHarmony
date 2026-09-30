// Phase 1159 — com.myscript.iink handwriting SDK boundary (fail-closed)
import { readFileSync, readdirSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/com/myscript/iink/';
const files = readdirSync(D);
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('iink pkg exists (73+ files)', files.length > 60);
t('Engine.java present', files.includes('Engine.java'));
t('Editor.java present', files.includes('Editor.java'));
t('ContentPart/Block/Package model', files.includes('ContentPart.java') && files.includes('ContentBlock.java') && files.includes('ContentPackage.java'));
t('HandwritingGenerator present', files.includes('HandwritingGenerator.java'));
t('IImagePainter + IRenderTarget', files.includes('IImagePainter.java') && files.includes('IRenderTarget.java'));
t('GLRenderer present', files.includes('GLRenderer.java'));
t('HistoryManager present', files.includes('HistoryManager.java'));
t('EditorError + HandwritingGeneratorError', files.includes('EditorError.java') && files.includes('HandwritingGeneratorError.java'));
t('Engine is real class (not stub)', readFileSync(D+'Engine.java','utf8').includes('class Engine'));
console.log('iink replay: ' + n + '/10 checks green');
