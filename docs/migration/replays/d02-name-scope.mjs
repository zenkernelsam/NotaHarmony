// Phase 1103 — ym8 Name + xt4/wt4 scope tree + marker ifaces
import { readFileSync } from 'fs';
import { strict as assert } from 'assert';
const D = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage/';
const R = f => readFileSync(D + f + '.java', 'utf8');
const ym8 = R('ym8'), xt4 = R('xt4'), wt4 = R('wt4'),
      uz = R('uz'), rr6 = R('rr6'), hli = R('hli');
let n = 0;
const t = (name, ok) => { assert.ok(ok, name); console.log('ok - ' + name); n++; };

t('ym8 = Comparable Name', ym8.includes('final class ym8 implements Comparable'));
t('ym8: e(identifier)+g(special)+d(dispatch)', ym8.includes('ym8 e(String') && ym8.includes('ym8 g(String') && ym8.includes('ym8 d(String'));
t('ym8: g for <…> names', ym8.includes('startsWith("<")'));
t('ym8: asString + StripSpecialMarkers', ym8.includes('asString') && ym8.includes('asStringStripSpecialMarkers'));
t('xt4: ym8.g("<root>") root', xt4.includes('ym8.g("<root>")'));
t('xt4: dot-split Pattern', xt4.includes('Pattern.compile("\\\\.")'));
t('xt4: a(ym8) child a()+parent e() scope', xt4.includes('xt4 a(ym8') && xt4.includes('xt4 e()'));
t('wt4: {xt4 a, wt4 b} scope chain', wt4.includes('xt4 a') && wt4.includes('wt4 b'));
t('uz empty marker iface', uz.includes('interface uz'));
t('rr6 {K(Object)} sink + hli iface', rr6.includes('void K(Object obj)') && hli.includes('interface hli'));
console.log('name-scope replay: ' + n + '/10 checks green');
