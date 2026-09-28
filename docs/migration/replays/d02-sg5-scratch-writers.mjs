// Phase 954 — sg5 草稿池写侧：f=cxc 12B 写器 + g=元素提供器 + exc 排序
import { readFileSync } from 'node:fs';

const ROOT = 'C:/Users/Cisco He/Desktop/Notability/decompiled_1.0.3/sources/defpackage';
const sg5 = readFileSync(`${ROOT}/sg5.java`, 'utf8');
const exc = readFileSync(`${ROOT}/exc.java`, 'utf8');

let pass = 0, fail = 0;
const ok = (cond, name) => { if (cond) { pass++; console.log('  ok', name); } else { fail++; console.log('FAIL', name); } };

// 13 个持有者属性名（Kotlin 属性名实证）
for (const [prop, type] of [
  ['offsetsHolder', 'Ljava/util/List;'],
  ['nestedOffsetsHolder', 'Ljava/util/List;'],
  ['usingOffsetsHolder', 'Ljava/util/concurrent/atomic/AtomicBoolean;'],
  ['ID_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/Id;'],
  ['SEQ_ID_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/SeqId;'],
  ['STYLE_MAP_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/StyleMap;'],
  ['RECORDING_SEGMENT_PROVIDER', 'Lcom/gingerlabs/notability/core/flatbuffers/RecordingSegment;'],
  ['POINT_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/Point;'],
  ['SIZE_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/Size;'],
  ['MODIFY_POSITION_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/ModifyPosition;'],
  ['DUPLICATE_OP_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/DuplicateOp;'],
  ['OP_ACK_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/OpAck;'],
  ['OP_HOLDER', 'Lcom/gingerlabs/notability/core/flatbuffers/Op;'],
]) {
  const getter = `get${prop[0].toUpperCase()}${prop.slice(1)}`;
  ok(sg5.includes(`"${prop}", "${getter}()${type}"`), `holder ${prop} = ${type}`);
}

// f = cxc 12B inline writer, reverse order (index→timestamp→pad→site)
ok(/public static final int f\(a aVar, exc excVar\)/.test(sg5), 'f = cxc writer');
ok(/aVar\.t\(4, 12\);\s*aVar\.w\(iC\);\s*aVar\.w\(iA1\);\s*aVar\.s\(2\);\s*aVar\.y\(sM\);\s*return aVar\.r\(\)/.test(sg5), 'f: t(4,12) w(idx) w(ts) s(2) y(site)');

// g = element-provider factory (empty -> d1.W sentinel)
ok(/public static final ix4 g\(List list\)/.test(sg5), 'g = provider factory');
ok(/list == null \|\| list\.isEmpty\(\)\) \? o : new o1\(list\)/.test(sg5), 'g: empty->o sentinel else o1(list)');
ok(/o = d1\.W/.test(sg5), 'o = d1.W empty sentinel');

// exc = SeqId Comparable interface
ok(/public interface exc extends Comparable/.test(exc), 'exc = Comparable SeqId iface');
ok(/int C\(\);/.test(exc) && /int a1\(\);/.test(exc) && /short m\(\);/.test(exc), 'exc: C=index a1=timestamp m=site');
ok(/iA1 != 0/.test(exc) && /\(m\(\) & 65535\)/.test(exc), 'exc.A0 ordering: ts -> site -> index');

// acquire via property delegate
ok(/x82\.x\(f, a\[3\]\)/.test(sg5) && /x82\.x\(g, a\[4\]\)/.test(sg5), 'a()/b() acquire ID/SEQ_ID holders');

console.log(`\nsg5-scratch-writers replay: ${pass}/${pass + fail} checks green`);
process.exit(fail ? 1 : 0);
