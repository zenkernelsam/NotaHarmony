# Phase 1030 证据 — 导入 unzip（zip-slip 防护）

来源：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`

## `boh` = unzip helper（abstract class）

```java
ZipInputStream zis = new ZipInputStream(
    BufferedInputStream(input, 8192));
for (ZipEntry e = zis.getNextEntry(); e != null;
     e = zis.getNextEntry()) {
    File f = new File(dir, e.getName()).getCanonicalFile();
    if (!ba6.o(f, dir)) {                    // ≠dir 本身
        String p = f.getPath();
        if (!svd.n0(p, dir.getPath()+File.separator, false)) {
            throw new IOException(
              "Zip entry escapes target directory: "
              + e.getName());               // zip-slip!
        }
    }
    if (e.isDirectory()) fag.F(f);           // mkdirs
    else { fag.G(f);  l96.i0(zis,fos,8192); } // 8KB 拷贝
}
```

## 关键语义

- **ZipSlip 防护**：canonical path 必须以目标目录
  `+File.separator` 为前缀，否则 IOException
  （"Zip entry escapes target directory"）。
- `svd.n0` = `startsWith` 字符串检查；
  `ba6.o` = 等价比较。
- `fag.F/G` = mkdirs/touch；`l96.i0` = 8KB 流拷贝。
- `o22 a = new o22(y22(27), false, -821934965)`
  ——编译器合成 lambda 表项。

## `jqe`/`o22`/`y22`

- `jqe` = 返回类型（导入结果）；
  `o22`/`y22` = lambda 缓存项。

## HarmonyOS 决策

- 导入=Harmony zip 解压+**同 zip-slip 防护**
  （canonical 前缀检查）。
- 8KB 流拷贝保留。

## 产出

- fixture `d02-import-unzip.mjs`（10 断言）。
- ADR-0974；中文报告。
