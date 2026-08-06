# -*- coding: utf-8 -*-
"""归一化对比 1.0.1 与 1.0.3 的混淆类（忽略类名/依赖名差异，检测真实逻辑差异）"""
import re, os, difflib

# 1.0.1 -> 1.0.3 类名映射（由引用链推导）
MAP = {
    'xaa': 'cfa', 'ic0': 'fd0', 'fc0': 'cd0', 'a81': 'z81', 'ow5': 'qy5',
    'cv0': 'aw0', 'gp2': 'kq2', 'm2b': 't6b', 'hd7': 'dg7', 'skd': 'hpd',
    'w76': 'aa6', 'f92': 'fa2', 'kv8': 'cz8', 'hp2': 'lq2', 'v72': 'x82',
    'cj6': 'fl6', 'ny7': 'm18', 'b01': 'a11', 'gg8': 'kj8', 'bof': 'mtf',
    'p5c': 'dac', 'x76': 'ba6', 'z02': 'a22', 'xu0': 'vv0', 'su0': 'qv0',
    'sq5': 'qs5', 'pdh': 'gjh', 'cmi': 'vsi', 'qq5': 'os5', 'wm': 'xn',
    'z71': 'y81', 'wu0': 'uv0', 'owi': 'p2j', 'ix9': 'k1a',
}

def normalize(src):
    # 单向：只把 1.0.1 的类名替换为 1.0.3 名；排除短名避免误替换
    pairs = [(a, b) for a, b in MAP.items() if len(a) >= 3]
    pairs.sort(key=lambda p: -len(p[0]))
    out = src
    for a, b in pairs:
        out = re.sub(r'\b' + a + r'\b', b, out)
    return out

def strip(src):
    s = re.sub(r'/\*.*?\*/', '', src, flags=re.S)
    s = re.sub(r'//.*', '', s)
    s = re.sub(r'\s+', ' ', s)
    return s

if __name__ == '__main__':
    d101 = r'c:\HarmonyProject\NotaHarmony\reference\defpackage'
    d103 = r'C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage'
    for name101, name103 in MAP.items():
        p101 = os.path.join(d101, name101 + '.java')
        p103 = os.path.join(d103, name103 + '.java')
        if not (os.path.exists(p101) and os.path.exists(p103)):
            print('MISSING', name101, name103)
            continue
        s101 = strip(normalize(open(p101, encoding='utf-8', errors='ignore').read()))
        s103 = strip(open(p103, encoding='utf-8', errors='ignore').read())
        if s101 == s103:
            print('SAME  ', name101, '<->', name103)
        else:
            ratio = difflib.SequenceMatcher(None, s101, s103).ratio()
            print('DIFF  ', name101, '<->', name103, 'sim=', round(ratio, 3))
