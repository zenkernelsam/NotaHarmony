// T-032 NSKeyedArchiver / GLKeyedArchiver 对象图解码器
// 纯 ArkTS，无平台依赖。配合 BinaryPlistParser 使用。
//
// 归档布局：
//   {
//     "$archiver": "NSKeyedArchiver" | "GLKeyedArchiver",
//     "$version" : 100000,
//     "$top"     : { "root": UID(1) }        // ← Notability Session.plist 用的是 "$0"，不是 "root"
//     "$objects" : [ "$null", {…}, {…}, { "$classname": "X", "$classes": [...] }, … ]
//   }
//
// 实测要点（来自 OP-AMP.note，见 docs/migration/reports/T-032-完成.md）：
//   1. archiver 名可能是 GLKeyedArchiver（Notability 自有变体），不能只认 NSKeyedArchiver。
//   2. $top 的键名不固定，必须枚举而不是硬编码 "root"。
//   3. **字段值可能是内联标量/内联 NSData，而不是 UID 引用**。
//      例：InkedSpatialHash.curvespoints 是内联 data，而同一 dict 里的 shapes 却是 UID。
//      因此所有取值器都必须"UID 则解引用，否则原地取用"。

import { PlistValue, PlistType, appleTimeToUnixMillis } from './BinaryPlistParser';

// 纯 ArkTS UTF-8 解码（NSString 的 NS.bytes 为 UTF-8 字节，避免依赖 @kit.ArkTS）
function utf8Decode(bytes: Uint8Array): string {
  let out: string = '';
  let i: number = 0;
  while (i < bytes.length) {
    const b0: number = bytes[i] & 0xFF;
    let cp: number;
    if (b0 < 0x80) {
      cp = b0;
      i += 1;
    } else if ((b0 & 0xE0) === 0xC0 && i + 1 < bytes.length) {
      cp = ((b0 & 0x1F) << 6) | (bytes[i + 1] & 0x3F);
      i += 2;
    } else if ((b0 & 0xF0) === 0xE0 && i + 2 < bytes.length) {
      cp = ((b0 & 0x0F) << 12) | ((bytes[i + 1] & 0x3F) << 6) | (bytes[i + 2] & 0x3F);
      i += 3;
    } else if ((b0 & 0xF8) === 0xF0 && i + 3 < bytes.length) {
      cp = ((b0 & 0x07) << 18) | ((bytes[i + 1] & 0x3F) << 12) |
        ((bytes[i + 2] & 0x3F) << 6) | (bytes[i + 3] & 0x3F);
      i += 4;
    } else {
      cp = 0xFFFD;
      i += 1;
    }
    if (cp > 0xFFFF) {
      const v: number = cp - 0x10000;
      out += String.fromCharCode(0xD800 + (v >> 10), 0xDC00 + (v & 0x3FF));
    } else {
      out += String.fromCharCode(cp);
    }
  }
  return out;
}

export class ArchiveDecodeResult {
  decoder: NSKeyedArchiverDecoder | null = null;
  error: string = '';
}

// 对象图中的一个节点（包装 $objects 里的一个 dict）
export class ArchiveNode {
  private owner: NSKeyedArchiverDecoder;
  private value: PlistValue;
  readonly index: number;   // 在 $objects 中的下标；内联对象为 -1

  constructor(owner: NSKeyedArchiverDecoder, value: PlistValue, index: number) {
    this.owner = owner;
    this.value = value;
    this.index = index;
  }

  raw(): PlistValue {
    return this.value;
  }

  // 类名：取 $class → $classname；无则返回空串（普通 dict）
  className(): string {
    const cls: PlistValue | null = this.owner.resolve(this.value.dictGet('$class'));
    if (cls === null) {
      return '';
    }
    const name: PlistValue | null = cls.dictGet('$classname');
    return name !== null ? name.asString('') : '';
  }

  // 类继承链（$classes）
  classHierarchy(): string[] {
    const cls: PlistValue | null = this.owner.resolve(this.value.dictGet('$class'));
    if (cls === null) {
      return [];
    }
    const arr: PlistValue | null = cls.dictGet('$classes');
    if (arr === null) {
      return [];
    }
    const names: string[] = [];
    for (const item of arr.arrayItems()) {
      names.push(item.asString(''));
    }
    return names;
  }

  // 字段名（不含 $class）
  keys(): string[] {
    const out: string[] = [];
    for (const k of this.value.dictKeys()) {
      if (k !== '$class') {
        out.push(k);
      }
    }
    return out;
  }

  has(key: string): boolean {
    return this.value.dictHas(key);
  }

  // 取子节点（UID 解引用；内联 dict 直接包装）
  node(key: string): ArchiveNode | null {
    const raw: PlistValue | null = this.value.dictGet(key);
    if (raw === null) {
      return null;
    }
    return this.owner.nodeOf(raw);
  }

  numberOf(key: string, fallback: number): number {
    const v: PlistValue | null = this.owner.resolve(this.value.dictGet(key));
    return v !== null ? v.asNumber(fallback) : fallback;
  }

  boolOf(key: string, fallback: boolean): boolean {
    const v: PlistValue | null = this.owner.resolve(this.value.dictGet(key));
    return v !== null ? v.asBool(fallback) : fallback;
  }

  // 字符串：兼容裸字符串 / NSString(NS.string) / NSMutableString(NS.bytes, UTF-8)
  stringOf(key: string, fallback: string): string {
    const v: PlistValue | null = this.owner.resolve(this.value.dictGet(key));
    if (v === null) {
      return fallback;
    }
    if (v.type === PlistType.STRING) {
      return v.asString(fallback);
    }
    if (v.type === PlistType.DICT) {
      const inner: PlistValue | null = this.owner.resolve(v.dictGet('NS.string'));
      if (inner !== null && inner.type === PlistType.STRING) {
        return inner.asString(fallback);
      }
      const bytesVal: PlistValue | null = this.owner.resolve(v.dictGet('NS.bytes'));
      if (bytesVal !== null) {
        const bytes: Uint8Array | null = bytesVal.asData();
        if (bytes !== null) {
          return utf8Decode(bytes);
        }
      }
    }
    return fallback;
  }

  // 取本节点**自身**的字符串值（用于 NSDictionary 的 value 位：裸串 / NS.string / NS.bytes）
  asText(fallback: string): string {
    if (this.value.type === PlistType.STRING) {
      return this.value.asString(fallback);
    }
    if (this.value.type === PlistType.DICT) {
      const inner: PlistValue | null = this.owner.resolve(this.value.dictGet('NS.string'));
      if (inner !== null && inner.type === PlistType.STRING) {
        return inner.asString(fallback);
      }
      const bytesVal: PlistValue | null = this.owner.resolve(this.value.dictGet('NS.bytes'));
      if (bytesVal !== null) {
        const bytes: Uint8Array | null = bytesVal.asData();
        if (bytes !== null) {
          return utf8Decode(bytes);
        }
      }
    }
    return fallback;
  }

  // NSData：兼容内联 data 与 UID→data 两种写法（Notability 两者混用）
  dataOf(key: string): Uint8Array | null {
    const v: PlistValue | null = this.owner.resolve(this.value.dictGet(key));
    if (v === null) {
      return null;
    }
    const direct: Uint8Array | null = v.asData();
    if (direct !== null) {
      return direct;
    }
    if (v.type === PlistType.DICT) {
      const inner: PlistValue | null = this.owner.resolve(v.dictGet('NS.data'));
      if (inner !== null) {
        return inner.asData();
      }
    }
    return null;
  }

  // NSDate → Unix 毫秒；缺失返回 fallback
  dateMillisOf(key: string, fallback: number): number {
    const v: PlistValue | null = this.owner.resolve(this.value.dictGet(key));
    if (v === null) {
      return fallback;
    }
    if (v.type === PlistType.DATE) {
      return appleTimeToUnixMillis(v.asNumber(0));
    }
    if (v.type === PlistType.DICT) {
      const t: PlistValue | null = this.owner.resolve(v.dictGet('NS.time'));
      if (t !== null && (t.type === PlistType.REAL || t.type === PlistType.INT || t.type === PlistType.DATE)) {
        return appleTimeToUnixMillis(t.asNumber(0));
      }
    }
    return fallback;
  }

  // NSArray/NSMutableArray → 元素节点列表（读 NS.objects）
  elements(): ArchiveNode[] {
    const arr: PlistValue | null = this.owner.resolve(this.value.dictGet('NS.objects'));
    const out: ArchiveNode[] = [];
    if (arr === null) {
      return out;
    }
    for (const item of arr.arrayItems()) {
      const n: ArchiveNode | null = this.owner.nodeOf(item);
      if (n !== null) {
        out.push(n);
      }
    }
    return out;
  }

  // NSDictionary → 键名列表（NS.keys 全部按字符串取）
  mapKeys(): string[] {
    const keys: PlistValue | null = this.owner.resolve(this.value.dictGet('NS.keys'));
    const out: string[] = [];
    if (keys === null) {
      return out;
    }
    for (const k of keys.arrayItems()) {
      const rk: PlistValue | null = this.owner.resolve(k);
      out.push(rk !== null ? rk.asString('') : '');
    }
    return out;
  }

  // NSDictionary → 按键取值节点
  mapValue(key: string): ArchiveNode | null {
    const keys: string[] = this.mapKeys();
    const vals: PlistValue | null = this.owner.resolve(this.value.dictGet('NS.objects'));
    if (vals === null) {
      return null;
    }
    const items: PlistValue[] = vals.arrayItems();
    for (let i = 0; i < keys.length && i < items.length; i++) {
      if (keys[i] === key) {
        return this.owner.nodeOf(items[i]);
      }
    }
    return null;
  }
}

export class NSKeyedArchiverDecoder {
  private objects: PlistValue[] = [];
  private topKeyNames: string[] = [];
  private topRefs: PlistValue[] = [];
  readonly archiverName: string;

  private constructor(archiverName: string) {
    this.archiverName = archiverName;
  }

  // 解码归档根 dict；结构不符返回带 error 的结果，不抛异常
  static decode(root: PlistValue | null): ArchiveDecodeResult {
    const out = new ArchiveDecodeResult();
    if (root === null || root.type !== PlistType.DICT) {
      out.error = '归档根不是 dict';
      return out;
    }
    const archiverVal: PlistValue | null = root.dictGet('$archiver');
    const archiver: string = archiverVal !== null ? archiverVal.asString('') : '';
    // Notability 用 GLKeyedArchiver；只要有 $objects + $top 就按 keyed archive 处理
    const objectsVal: PlistValue | null = root.dictGet('$objects');
    const topVal: PlistValue | null = root.dictGet('$top');
    if (objectsVal === null || objectsVal.type !== PlistType.ARRAY) {
      out.error = '缺少 $objects 数组';
      return out;
    }
    if (topVal === null || topVal.type !== PlistType.DICT) {
      out.error = '缺少 $top 字典';
      return out;
    }
    const decoder = new NSKeyedArchiverDecoder(archiver);
    decoder.objects = objectsVal.arrayItems();
    decoder.topKeyNames = topVal.dictKeys();
    for (const k of decoder.topKeyNames) {
      const v: PlistValue | null = topVal.dictGet(k);
      decoder.topRefs.push(v !== null ? v : PlistValue.ofNull());
    }
    if (decoder.objects.length === 0) {
      out.error = '$objects 为空';
      return out;
    }
    out.decoder = decoder;
    return out;
  }

  objectCount(): number {
    return this.objects.length;
  }

  topKeys(): string[] {
    return this.topKeyNames;
  }

  // 按 $top 键取根对象
  top(key: string): ArchiveNode | null {
    for (let i = 0; i < this.topKeyNames.length; i++) {
      if (this.topKeyNames[i] === key) {
        return this.nodeOf(this.topRefs[i]);
      }
    }
    return null;
  }

  // 取第一个 $top 项（Notability 是 "$0"，Apple 常规是 "root"）
  rootNode(): ArchiveNode | null {
    const preferred: string[] = ['root', '$0'];
    for (const p of preferred) {
      const n: ArchiveNode | null = this.top(p);
      if (n !== null) {
        return n;
      }
    }
    return this.topRefs.length > 0 ? this.nodeOf(this.topRefs[0]) : null;
  }

  // UID 解引用；非 UID 原样返回（应对内联标量/内联 data）
  resolve(value: PlistValue | null): PlistValue | null {
    if (value === null) {
      return null;
    }
    if (value.type !== PlistType.UID) {
      return value;
    }
    const idx: number = value.asUid();
    if (idx < 0 || idx >= this.objects.length) {
      return null;
    }
    return this.objects[idx];
  }

  // 把一个原始值包装成节点（仅 dict 有意义）
  nodeOf(value: PlistValue | null): ArchiveNode | null {
    if (value === null) {
      return null;
    }
    const idx: number = value.type === PlistType.UID ? value.asUid() : -1;
    const resolved: PlistValue | null = this.resolve(value);
    if (resolved === null || resolved.type !== PlistType.DICT) {
      return null;
    }
    return new ArchiveNode(this, resolved, idx);
  }

  // 按下标取节点（探测用）
  nodeAt(index: number): ArchiveNode | null {
    if (index < 0 || index >= this.objects.length) {
      return null;
    }
    const v: PlistValue = this.objects[index];
    return v.type === PlistType.DICT ? new ArchiveNode(this, v, index) : null;
  }

  // 全量类名清单（探测用）
  classNames(): string[] {
    const out: string[] = [];
    for (const o of this.objects) {
      if (o.type === PlistType.DICT) {
        const cn: PlistValue | null = o.dictGet('$classname');
        if (cn !== null) {
          const name: string = cn.asString('');
          if (name.length > 0 && out.indexOf(name) < 0) {
            out.push(name);
          }
        }
      }
    }
    return out;
  }

  // === 结构打印器：输出对象图层级，供未知格式探测 ===
  describeGraph(maxDepth: number, maxItemsPerNode: number): string {
    const lines: string[] = [];
    lines.push(`archiver=${this.archiverName} objects=${this.objects.length} top=[${this.topKeyNames.join(', ')}]`);
    const visited: Set<number> = new Set<number>();
    const root: ArchiveNode | null = this.rootNode();
    if (root === null) {
      lines.push('  <无法定位根对象>');
      return lines.join('\n');
    }
    this.describeNode(root, 1, maxDepth, maxItemsPerNode, visited, lines);
    return lines.join('\n');
  }

  private describeNode(node: ArchiveNode, depth: number, maxDepth: number,
    maxItems: number, visited: Set<number>, lines: string[]): void {
    const pad: string = '  '.repeat(depth);
    const cls: string = node.className();
    const head: string = cls.length > 0 ? `<${cls}>` : '<dict>';
    lines.push(`${pad}${head} #${node.index}`);
    if (depth >= maxDepth) {
      lines.push(`${pad}  …（深度上限）`);
      return;
    }
    if (node.index >= 0) {
      if (visited.has(node.index)) {
        lines.push(`${pad}  …（已展开过 #${node.index}）`);
        return;
      }
      visited.add(node.index);
    }
    const keys: string[] = node.keys();
    let shown: number = 0;
    for (const k of keys) {
      if (shown >= maxItems) {
        lines.push(`${pad}  …（还有 ${keys.length - shown} 个字段）`);
        break;
      }
      shown++;
      const rawVal: PlistValue | null = node.raw().dictGet(k);
      const resolved: PlistValue | null = this.resolve(rawVal);
      if (resolved === null) {
        lines.push(`${pad}  ${k}: <null>`);
        continue;
      }
      if (resolved.type === PlistType.DICT) {
        const child: ArchiveNode | null = this.nodeOf(rawVal);
        if (child !== null) {
          lines.push(`${pad}  ${k}:`);
          this.describeNode(child, depth + 2, maxDepth, maxItems, visited, lines);
          continue;
        }
      }
      const uidNote: string = rawVal !== null && rawVal.type === PlistType.UID
        ? ` (UID→${rawVal.asUid()})` : ' (内联)';
      lines.push(`${pad}  ${k}: ${resolved.describe()}${uidNote}`);
    }
  }
}
