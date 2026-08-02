package defpackage;

import android.graphics.Path;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/* JADX INFO: loaded from: classes2.dex */
public abstract class w4a {
    public static final kv8 d;
    public static final kv8 e;
    public static final kv8 f;
    public static final kv8 g;
    public static final kv8 h;
    public static final kv8 i;
    public static final /* synthetic */ cj6[] a = {new oxa(w4a.class, "reusablePoint1", "getReusablePoint1()Lcom/gingerlabs/notability/bezierkit/CGPoint;"), new oxa(w4a.class, "reusablePoint2", "getReusablePoint2()Lcom/gingerlabs/notability/bezierkit/CGPoint;"), new oxa(w4a.class, "reusableIndexedPathComponentLocation1", "getReusableIndexedPathComponentLocation1()Lcom/gingerlabs/notability/bezierkit/IndexedPathComponentLocation;"), new oxa(w4a.class, "reusableIndexedPathComponentLocation2", "getReusableIndexedPathComponentLocation2()Lcom/gingerlabs/notability/bezierkit/IndexedPathComponentLocation;"), new oxa(w4a.class, "reusableAndCGFloat", "getReusableAndCGFloat()Lcom/gingerlabs/notability/bezierkit/AndCGFloat;"), new oxa(w4a.class, "reusableDetermineInternalArcResult", "getReusableDetermineInternalArcResult()Lcom/gingerlabs/notability/bezierkit/extensions/AttributedPathComponentIterator$DetermineInternalArcResult;"), new oxa(w4a.class, "reusableLineSegment", "getReusableLineSegment()Lcom/gingerlabs/notability/bezierkit/LineSegment;"), new oxa(w4a.class, "reusableAndCGFloatCubicCurve", "getReusableAndCGFloatCubicCurve()Lcom/gingerlabs/notability/bezierkit/AndCGFloat;")};
    public static final kv8 b = kwb.d();
    public static final kv8 c = kwb.d();
    public static final p7e j = new p7e(new v4a(0));

    static {
        int i2 = 9;
        int i3 = 23;
        d = new kv8(new v4a(i2), new g77(i3));
        e = new kv8(new v4a(i2), new g77(i3));
        f = new kv8(new v4a(new e57(29)), new g77(i3));
        g = new kv8(new v4a(15), new g77(i3));
        h = new kv8(new iwb(2), new g77(i3));
        i = new kv8(new v4a(10), new g77(i3));
    }

    /* JADX WARN: Code duplicated, block: B:154:0x01d0 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:95:0x01c4  */
    /* JADX WARN: Code duplicated, block: B:96:0x01c7  */
    /* JADX WARN: Code duplicated, block: B:98:0x01cb  */
    public static final xw0 a(xw0 xw0Var, double d2) {
        long j2;
        int i2;
        long j3;
        List list;
        long j4;
        long j5;
        long j6;
        long j7;
        xw0Var.getClass();
        List list2 = xw0Var.a;
        int size = list2.size();
        int i3 = 0;
        int i4 = 0;
        ArrayList arrayList = null;
        while (i4 < size) {
            i4a i4aVar = (i4a) list2.get(i4);
            og8 og8Var = i4aVar.b;
            r8d r8dVar = i4aVar.a;
            int i5 = og8Var.b;
            int iF = og8Var.f(i3);
            long jS = i4aVar.s();
            int i6 = i3;
            int i7 = i6;
            int i8 = i7;
            r8d r8dVar2 = null;
            og8 og8Var2 = null;
            while (true) {
                int i9 = 1;
                if (i8 == 0) {
                    long jG0 = r8dVar2 != null ? ny7.g0(r8dVar2) : jS;
                    double dL0 = 0.0d;
                    if (iF > 0 && 1 <= iF) {
                        i2 = 1;
                        while (true) {
                            int i10 = i7 + i9;
                            if (r8dVar.d) {
                                i10 = (r8dVar.e - 1) - i10;
                            }
                            long[] jArr = r8dVar.a;
                            if (jArr != null) {
                                long j8 = jArr[i10];
                                int i11 = q8d.c;
                                j3 = j8;
                            } else {
                                ByteBuffer byteBuffer = r8dVar.b;
                                if (byteBuffer == null) {
                                    yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                    return null;
                                }
                                j3 = byteBuffer.getLong(i10 * 8);
                                int i12 = q8d.c;
                            }
                            list = list2;
                            j4 = jS;
                            dL0 = w76.l0(((double) Float.intBitsToFloat((int) (j3 >> 32))) - ((double) Float.intBitsToFloat((int) (jG0 >> 32))), ((double) Float.intBitsToFloat((int) (j3 & 4294967295L))) - ((double) Float.intBitsToFloat((int) (jG0 & 4294967295L)))) + dL0;
                            if (dL0 >= d2 || i9 == iF) {
                                break;
                            }
                            i9++;
                            list2 = list;
                            size = size;
                            jG0 = j3;
                            jS = j4;
                        }
                    } else {
                        size = size;
                        i2 = 1;
                        j4 = jS;
                        list = list2;
                    }
                    if (dL0 >= d2) {
                        if (r8dVar2 == null) {
                            int i13 = i7 + iF;
                            if (r8dVar.d) {
                                i13 = (r8dVar.e - 1) - i13;
                            }
                            long[] jArr2 = r8dVar.a;
                            if (jArr2 != null) {
                                j6 = jArr2[i13];
                                int i14 = q8d.c;
                            } else {
                                ByteBuffer byteBuffer2 = r8dVar.b;
                                if (byteBuffer2 == null) {
                                    yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                    return null;
                                }
                                j6 = byteBuffer2.getLong(i13 * 8);
                                int i15 = q8d.c;
                            }
                            jS = j6;
                        } else {
                            if (og8Var2 == null) {
                                yz3.l("resultingOrders is null when resultingPoints is not null");
                                return null;
                            }
                            og8Var2.a(iF);
                            int i16 = i2;
                            if (i16 <= iF) {
                                int i17 = i16;
                                while (true) {
                                    int i18 = i7 + i17;
                                    if (r8dVar.d) {
                                        i18 = (r8dVar.e - i16) - i18;
                                    }
                                    long[] jArr3 = r8dVar.a;
                                    if (jArr3 != null) {
                                        j7 = jArr3[i18];
                                        int i19 = q8d.c;
                                    } else {
                                        ByteBuffer byteBuffer3 = r8dVar.b;
                                        if (byteBuffer3 == null) {
                                            yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                            return null;
                                        }
                                        j7 = byteBuffer3.getLong(i18 * 8);
                                        int i20 = q8d.c;
                                    }
                                    r8dVar2.a(j7);
                                    if (i17 == iF) {
                                        break;
                                    }
                                    i17++;
                                    i16 = 1;
                                }
                            }
                        }
                        i7 += iF;
                        i6++;
                        if (i6 >= i5) {
                            i8 = 1;
                        } else {
                            i8 = 0;
                        }
                        if (i8 == 0) {
                            iF = og8Var.f(i6);
                        }
                        list2 = list;
                        size = size;
                    } else if (r8dVar2 == null) {
                        if (arrayList == null) {
                            arrayList = new ArrayList(list.size());
                            for (int i21 = 0; i21 < i4; i21++) {
                                arrayList.add(list.get(i21));
                            }
                        }
                        r8dVar2 = new r8d(r8dVar.e, r8dVar.c);
                        og8Var2 = new og8(i4aVar.b.b);
                        r8dVar2.a(i4aVar.s());
                        int i22 = 0;
                        int i23 = 0;
                        while (i22 < i6) {
                            int iF2 = og8Var.f(i22);
                            og8Var2.a(iF2);
                            boolean z = true;
                            if (1 <= iF2) {
                                int i24 = 1;
                                while (true) {
                                    int i25 = i23 + i24;
                                    if (r8dVar.d) {
                                        i25 = (r8dVar.e - 1) - i25;
                                    }
                                    long[] jArr4 = r8dVar.a;
                                    if (jArr4 != null) {
                                        long j9 = jArr4[i25];
                                        int i26 = q8d.c;
                                        j5 = j9;
                                    } else {
                                        ByteBuffer byteBuffer4 = r8dVar.b;
                                        if (byteBuffer4 == null) {
                                            yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                            return null;
                                        }
                                        long j10 = byteBuffer4.getLong(i25 * 8);
                                        int i27 = q8d.c;
                                        j5 = j10;
                                    }
                                    r8dVar2.a(j5);
                                    if (i24 == iF2) {
                                        break;
                                    }
                                    i24++;
                                    i23 = i23;
                                    i22 = i22;
                                    z = true;
                                }
                            } else {
                                i22 = i22;
                                i23 = i23;
                            }
                            i23 += iF2;
                            i22++;
                        }
                    }
                    jS = j4;
                    i7 += iF;
                    i6++;
                    if (i6 >= i5) {
                        i8 = 1;
                    } else {
                        i8 = 0;
                    }
                    if (i8 == 0) {
                        iF = og8Var.f(i6);
                    }
                    list2 = list;
                    size = size;
                }
            }
            int i28 = size;
            List list3 = list2;
            if (arrayList != null) {
                if (og8Var2 == null) {
                    arrayList.add(i4aVar);
                } else if (og8Var2.b == 0) {
                    continue;
                } else {
                    if (r8dVar2 == null) {
                        yz3.l("resultingPoints is null when resultingOrders is not null and not empty");
                        return null;
                    }
                    boolean z2 = r8dVar2.d;
                    if (i4aVar.u()) {
                        int i29 = r8dVar2.e - 1;
                        int i30 = z2 ? i29 : 0;
                        long[] jArr5 = r8dVar2.a;
                        if (jArr5 != null) {
                            j2 = jArr5[i30];
                        } else {
                            ByteBuffer byteBuffer5 = r8dVar2.b;
                            if (byteBuffer5 == null) {
                                yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                return null;
                            }
                            j2 = byteBuffer5.getLong(i30 * 8);
                        }
                        if (z2) {
                            i29 = (r8dVar2.e - 1) - i29;
                        }
                        long[] jArr6 = r8dVar2.a;
                        if (jArr6 != null) {
                            jArr6[i29] = j2;
                        } else {
                            ByteBuffer byteBuffer6 = r8dVar2.b;
                            if (byteBuffer6 == null) {
                                yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                return null;
                            }
                            byteBuffer6.putLong(i29 * 8, j2);
                        }
                    }
                    arrayList.add(new i4a(r8dVar2, og8Var2, i4aVar.c));
                }
            }
            i4++;
            i3 = 0;
            list2 = list3;
            size = i28;
        }
        return arrayList != null ? new xw0(arrayList) : xw0Var;
    }

    /* JADX WARN: Code duplicated, block: B:33:0x00e8  */
    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r2v8, types: [java.lang.Object[], o4a[]] */
    /* JADX WARN: Type inference failed for: r4v2 */
    /* JADX WARN: Type inference failed for: r4v3, types: [i4a, ic0] */
    /* JADX WARN: Type inference failed for: r4v34, types: [i4a, ic0] */
    /* JADX WARN: Type inference failed for: r4v35 */
    /* JADX WARN: Type inference failed for: r4v45, types: [i4a] */
    /* JADX WARN: Type inference failed for: r4v47 */
    /* JADX WARN: Type inference failed for: r4v61 */
    /* JADX WARN: Type inference failed for: r4v62 */
    /* JADX WARN: Type inference failed for: r4v66 */
    /* JADX WARN: Type inference failed for: r55v0 */
    /* JADX WARN: Type inference failed for: r55v1 */
    /* JADX WARN: Type inference failed for: r55v3 */
    /* JADX WARN: Type inference failed for: r55v4 */
    /* JADX WARN: Type inference failed for: r55v6 */
    /* JADX WARN: Type inference failed for: r55v7 */
    /* JADX WARN: Type inference failed for: r55v8 */
    /* JADX WARN: Type inference failed for: r55v9 */
    /* JADX WARN: Type inference failed for: r7v1 */
    /* JADX WARN: Type inference failed for: r7v13 */
    /* JADX WARN: Type inference failed for: r7v14 */
    /* JADX WARN: Type inference failed for: r7v19 */
    /* JADX WARN: Type inference failed for: r7v2, types: [i4a, ic0] */
    /* JADX WARN: Type inference failed for: r7v23 */
    /* JADX WARN: Type inference failed for: r7v24 */
    /* JADX WARN: Type inference failed for: r7v25 */
    /* JADX WARN: Type inference failed for: r7v26 */
    /* JADX WARN: Type inference failed for: r8v27, types: [gp2, hd7, m2b] */
    public static final xw0 b(xw0 xw0Var, double d2) {
        double d3;
        r8d r8dVar;
        int i2;
        xw0 xw0Var2;
        double d4;
        Object objH;
        jc0 jc0Var;
        ArrayList arrayList;
        i4a i4aVar;
        r8d r8dVar2;
        double d5;
        ?? ic0Var;
        i4a i4aVar2;
        og8 og8Var;
        List uhVar;
        List<o4a> list;
        jc0 jc0Var2;
        xw0 xw0Var3;
        int i3;
        int i4;
        ow5 ow5Var;
        double d6;
        List<fv0> listL0;
        List listL1;
        ArrayList arrayList2;
        og8 og8Var2;
        r8d r8dVar3;
        long j2;
        int iV;
        int i5;
        ?? r55;
        boolean z;
        List listM0;
        fc0 hc0Var;
        ?? r56;
        long j3;
        double dC;
        long j4;
        long j5;
        fc0 fc0Var;
        fc0 fc0Var2;
        double d7 = d2;
        jc0 jc0Var3 = new jc0(d7);
        List list2 = xw0Var.a;
        ArrayList arrayList3 = new ArrayList();
        Iterator it = list2.iterator();
        while (it.hasNext()) {
            i4a i4aVar3 = (i4a) it.next();
            og8 og8Var3 = i4aVar3.b;
            double d8 = i4aVar3.c;
            r8d r8dVar4 = i4aVar3.a;
            int i6 = 0;
            if (og8Var3.b == 1 && og8Var3.f(0) == 1) {
                ic0 ic0Var2 = i4aVar3 instanceof ic0 ? (ic0) i4aVar3 : null;
                List list3 = ic0Var2 != null ? ic0Var2.o : null;
                double dE = (list3 == null || (fc0Var2 = (fc0) zs1.c1(list3)) == null) ? 1.0d : fc0Var2.e();
                if (dE == ((list3 == null || (fc0Var = (fc0) zs1.m1(list3)) == null) ? 1.0d : fc0Var.e())) {
                    d4 = 1.0d;
                    double dIntBitsToFloat = Float.intBitsToFloat((int) (i4aVar3.s() >> 32));
                    double dIntBitsToFloat2 = Float.intBitsToFloat((int) (i4aVar3.s() & 4294967295L));
                    d3 = d8;
                    double dIntBitsToFloat3 = Float.intBitsToFloat((int) (ny7.g0(r8dVar4) >> 32));
                    r8dVar = r8dVar4;
                    double dIntBitsToFloat4 = Float.intBitsToFloat((int) (ny7.g0(r8dVar4) & 4294967295L));
                    i2 = 1;
                    xw0Var2 = null;
                    if (w76.m0(dIntBitsToFloat3 - dIntBitsToFloat, dIntBitsToFloat4 - dIntBitsToFloat2) <= 1.0E-4d) {
                        double d9 = dE * 0.5d * d7 * d3;
                        objH = ((ic0) j.getValue()).h(new z71(d9, 0.0d, 0.0d, d9, dIntBitsToFloat3, dIntBitsToFloat4));
                    }
                } else {
                    d3 = d8;
                    r8dVar = r8dVar4;
                    i2 = 1;
                    xw0Var2 = null;
                    d4 = 1.0d;
                }
                objH = xw0Var2;
            } else {
                d3 = d8;
                r8dVar = r8dVar4;
                i2 = 1;
                xw0Var2 = null;
                d4 = 1.0d;
                objH = xw0Var2;
            }
            if (objH != null) {
                listL1 = ny7.l0(objH);
                it = it;
                arrayList2 = arrayList3;
                jc0Var2 = jc0Var3;
            } else {
                ?? r7 = i4aVar3 instanceof ic0 ? (ic0) i4aVar3 : xw0Var2;
                if (r7 != 0) {
                    og8 og8Var4 = r7.b;
                    int i7 = og8Var4.b;
                    if (i7 >= 2) {
                        d5 = 0.0d;
                        int i8 = i7 + 1;
                        List list4 = r7.o;
                        if (list4.size() != i8) {
                            jc0Var = jc0Var3;
                            it = it;
                            arrayList = arrayList3;
                            i4aVar = i4aVar3;
                            ic0Var = r7;
                            r8dVar2 = r8dVar;
                            break;
                        }
                        double dE2 = ((fc0) list4.get(0)).e();
                        int i9 = i2;
                        while (true) {
                            if (i9 >= i8) {
                                jc0Var = jc0Var3;
                                it = it;
                                arrayList = arrayList3;
                                i4aVar = i4aVar3;
                                ic0Var = r7;
                                r8dVar2 = r8dVar;
                                break;
                            }
                            if (((fc0) list4.get(i9)).e() != dE2) {
                                r8d r8dVar5 = r7.a;
                                double[] dArr = new double[i7];
                                int i10 = 0;
                                int i11 = 0;
                                while (i10 < i7) {
                                    int iF = og8Var4.f(i10);
                                    int i12 = i6;
                                    int i13 = r8dVar5.d ? (r8dVar5.e - 1) - i11 : i11;
                                    long[] jArr = r8dVar5.a;
                                    if (jArr != null) {
                                        j4 = jArr[i13];
                                        int i14 = q8d.c;
                                    } else {
                                        ByteBuffer byteBuffer = r8dVar5.b;
                                        if (byteBuffer == null) {
                                            yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                            return xw0Var2;
                                        }
                                        j4 = byteBuffer.getLong(i13 * 8);
                                        int i15 = q8d.c;
                                    }
                                    i11 += iF;
                                    int i16 = r8dVar5.d ? (r8dVar5.e - 1) - i11 : i11;
                                    long j6 = j4;
                                    long[] jArr2 = r8dVar5.a;
                                    if (jArr2 != null) {
                                        j5 = jArr2[i16];
                                    } else {
                                        ByteBuffer byteBuffer2 = r8dVar5.b;
                                        if (byteBuffer2 == null) {
                                            yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                            return xw0Var2;
                                        }
                                        j5 = byteBuffer2.getLong(i16 * 8);
                                    }
                                    long j7 = j5;
                                    r8d r8dVar6 = r8dVar;
                                    double dL0 = w76.l0(Float.intBitsToFloat((int) (j7 >> 32)) - Float.intBitsToFloat((int) (j6 >> 32)), Float.intBitsToFloat((int) (j7 & 4294967295L)) - Float.intBitsToFloat((int) (j6 & 4294967295L)));
                                    if (dL0 < 1.0E-6d) {
                                        dL0 = 1.0E-6d;
                                    }
                                    dArr[i10] = dL0;
                                    i10++;
                                    i6 = i12;
                                    r8dVar = r8dVar6;
                                }
                                r8dVar2 = r8dVar;
                                int i17 = i6;
                                double[] dArr2 = new double[i8];
                                for (int i18 = i17; i18 < i8; i18++) {
                                    dArr2[i18] = ((fc0) list4.get(i18)).e();
                                }
                                double[] dArr3 = new double[i7];
                                int i19 = i17;
                                while (i19 < i7) {
                                    int i20 = i19 + 1;
                                    dArr3[i19] = (dArr2[i20] - dArr2[i19]) / dArr[i19];
                                    i19 = i20;
                                }
                                double[] dArr4 = new double[i8];
                                dArr4[i17] = dArr3[i17];
                                dArr4[i7] = dArr3[i7 - 1];
                                for (int i21 = i2; i21 < i7; i21++) {
                                    int i22 = i21 - 1;
                                    double d10 = dArr3[i22];
                                    double d11 = dArr3[i21];
                                    if (d10 * d11 <= 0.0d) {
                                        dC = 0.0d;
                                    } else {
                                        double d12 = dArr[i22];
                                        double d13 = dArr[i21];
                                        dC = (3.0d * (d12 + d13)) / ((((d12 * 2.0d) + d13) / d11) + f92.c(d13, 2.0d, d12, d10));
                                    }
                                    dArr4[i21] = dC;
                                }
                                int i23 = r8dVar5.e;
                                boolean z2 = r8dVar5.d;
                                ArrayList arrayList4 = new ArrayList(i23 + 18);
                                og8 og8Var5 = new og8(i7 + 6);
                                ArrayList arrayList5 = new ArrayList(i7 + 7);
                                int i24 = z2 ? r8dVar5.e - 1 : i17;
                                long[] jArr3 = r8dVar5.a;
                                if (jArr3 != null) {
                                    j2 = jArr3[i24];
                                    int i25 = q8d.c;
                                } else {
                                    ByteBuffer byteBuffer3 = r8dVar5.b;
                                    if (byteBuffer3 == null) {
                                        xw0 xw0Var4 = xw0Var2;
                                        yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                        return xw0Var4;
                                    }
                                    j2 = byteBuffer3.getLong(i24 * 8);
                                    int i26 = q8d.c;
                                }
                                arrayList4.add(xi7.j(j2));
                                arrayList5.add(list4.get(i17));
                                boolean z3 = false;
                                int i27 = 0;
                                int i28 = 0;
                                ?? r8 = r7;
                                while (i27 < i7) {
                                    boolean z4 = z3;
                                    int iF2 = og8Var4.f(i27);
                                    double d14 = dArr[i27];
                                    double d15 = dArr2[i27];
                                    int i29 = i7;
                                    int i30 = i27 + 1;
                                    double d16 = dArr2[i30];
                                    double d17 = dArr4[i27];
                                    double d18 = dArr4[i30];
                                    ArrayList arrayList6 = arrayList3;
                                    double[] dArr5 = dArr4;
                                    boolean z5 = z2;
                                    double[] dArr6 = dArr;
                                    double dMax = 0.0d;
                                    int i31 = 0;
                                    ?? r9 = r8;
                                    while (i31 < 3) {
                                        double d19 = oki.a[i31];
                                        ?? r57 = r9;
                                        double d20 = d15;
                                        double d21 = d16;
                                        dMax = Math.max(dMax, Math.abs(oki.b(d15, d17, d14, d16, d18, d19) - (((d21 - d20) * d19) + d20)));
                                        d15 = d20;
                                        d16 = d21;
                                        i4aVar3 = i4aVar3;
                                        r9 = r57;
                                        i27 = i27;
                                        i31++;
                                        jc0Var3 = jc0Var3;
                                    }
                                    jc0 jc0Var4 = jc0Var3;
                                    int i32 = i27;
                                    i4a i4aVar4 = i4aVar3;
                                    ?? r58 = r9;
                                    double d22 = d16;
                                    double d23 = dMax * 1.2d;
                                    double dMax2 = Math.max(Math.max(d15, d22), 0.05d) * 0.005d;
                                    if (Math.abs(d23) > Double.MAX_VALUE || d23 <= dMax2) {
                                        iV = i2;
                                        i5 = iV;
                                    } else {
                                        iV = me8.v((int) Math.ceil(Math.sqrt(d23 / dMax2)), 2, 6);
                                        i5 = i2;
                                    }
                                    if (iV == i5) {
                                        if (i5 <= iF2) {
                                            int i33 = i5;
                                            while (true) {
                                                int i34 = i28 + i33;
                                                if (z5) {
                                                    i34 = (r8dVar5.e - i5) - i34;
                                                }
                                                long[] jArr4 = r8dVar5.a;
                                                if (jArr4 != null) {
                                                    j3 = jArr4[i34];
                                                    int i35 = q8d.c;
                                                } else {
                                                    ByteBuffer byteBuffer4 = r8dVar5.b;
                                                    if (byteBuffer4 == null) {
                                                        yz3.l("SinglePrecisionCGPointList: offHeap storage null when heap is also null");
                                                        return xw0Var2;
                                                    }
                                                    j3 = byteBuffer4.getLong(i34 * 8);
                                                    int i36 = q8d.c;
                                                }
                                                arrayList4.add(xi7.j(j3));
                                                if (i33 == iF2) {
                                                    break;
                                                }
                                                i33++;
                                                i5 = 1;
                                            }
                                        }
                                        og8Var5.a(iF2);
                                        arrayList5.add(list4.get(i30));
                                        z = z4;
                                        r56 = r58;
                                    } else {
                                        int i37 = i32;
                                        fc0 fc0Var3 = (fc0) list4.get(i37);
                                        fc0 fc0Var4 = (fc0) list4.get(i30);
                                        int i38 = 0;
                                        while (i38 < iV) {
                                            int i39 = i37;
                                            double d24 = iV;
                                            int i40 = iV;
                                            double d25 = ((double) i38) / d24;
                                            int i41 = i38 + 1;
                                            fc0 fc0Var5 = fc0Var3;
                                            int i42 = i30;
                                            double d26 = ((double) i41) / d24;
                                            double d27 = d22;
                                            ?? r10 = xw0Var2;
                                            ?? r4 = r55;
                                            r8d r8dVar7 = r8dVar5;
                                            cv0 cv0VarP = r4.p(i39, r10, r10, r10);
                                            if (cv0VarP instanceof gp2) {
                                                r55 = r58;
                                                listM0 = ((gp2) cv0VarP).b(d25, d26).a();
                                            } else if (cv0VarP instanceof m2b) {
                                                r55 = r58;
                                                listM0 = ((m2b) cv0VarP).b(d25, d26).a();
                                            } else {
                                                if (!(cv0VarP instanceof hd7)) {
                                                    r55 = r58;
                                                    throw new IllegalStateException(("unexpected curve order " + og8Var4.f(i39)).toString());
                                                }
                                                r55 = r58;
                                                hd7 hd7Var = (hd7) cv0VarP;
                                                a81 a81VarC = hd7Var.c(d25, null);
                                                a81 a81VarC2 = hd7Var.c(d26, null);
                                                a81VarC.getClass();
                                                a81VarC2.getClass();
                                                listM0 = ny7.m0(a81VarC, a81VarC2);
                                            }
                                            int size = listM0.size();
                                            int i43 = 1;
                                            while (i43 < size) {
                                                arrayList4.add(new a81(((a81) listM0.get(i43)).a, ((a81) listM0.get(i43)).b));
                                                i43++;
                                                listM0 = listM0;
                                                size = size;
                                                d26 = d26;
                                            }
                                            double d28 = d26;
                                            og8Var5.a(iF2);
                                            if (i38 < i40 - 1) {
                                                double dB = oki.b(d15, d17, d14, d27, d18, d28);
                                                double d29 = fc0Var5.d();
                                                double d30 = ((fc0Var4.d() - d29) * d28) + d29;
                                                double dA = fc0Var5.a();
                                                double dA2 = ((fc0Var4.a() - dA) * d28) + dA;
                                                double dB2 = fc0Var5.b();
                                                double dB3 = ((fc0Var4.b() - dB2) * d28) + dB2;
                                                double dC2 = fc0Var5.c();
                                                double dC3 = ((fc0Var4.c() - dC2) * d28) + dC2;
                                                hr1 hr1Var = ic0.q;
                                                hc0Var = new hc0(dB, d30, dA2, dB3, dC3);
                                            } else {
                                                hc0Var = fc0Var4;
                                            }
                                            arrayList5.add(hc0Var);
                                            fc0Var3 = fc0Var5;
                                            iV = i40;
                                            i30 = i42;
                                            r8dVar5 = r8dVar7;
                                            i38 = i41;
                                            xw0Var2 = null;
                                            r55 = r4;
                                            i37 = i39;
                                            d22 = d27;
                                        }
                                        r55 = r58;
                                        z = true;
                                        r56 = r55;
                                    }
                                    int i44 = i30;
                                    i28 += iF2;
                                    z3 = z;
                                    r8 = r56;
                                    i7 = i29;
                                    dArr = dArr6;
                                    z2 = z5;
                                    dArr4 = dArr5;
                                    arrayList3 = arrayList6;
                                    i27 = i44;
                                    i4aVar3 = i4aVar4;
                                    r8dVar5 = r8dVar5;
                                    jc0Var3 = jc0Var4;
                                    xw0Var2 = null;
                                    i2 = 1;
                                }
                                jc0Var = jc0Var3;
                                arrayList = arrayList3;
                                i4aVar = i4aVar3;
                                ?? r5 = r8;
                                ic0Var = r5;
                                if (!z3) {
                                    break;
                                }
                                ic0Var = new ic0(new r8d(arrayList4, (s8d) null), og8Var5, arrayList5, r5.c, r5.n);
                                break;
                            }
                            i9++;
                        }
                    } else {
                        jc0Var = jc0Var3;
                        it = it;
                        arrayList = arrayList3;
                        i4aVar = i4aVar3;
                        ic0Var = r7;
                        r8dVar2 = r8dVar;
                        d5 = 0.0d;
                    }
                } else {
                    jc0Var = jc0Var3;
                    it = it;
                    arrayList = arrayList3;
                    i4aVar = i4aVar3;
                    r8dVar2 = r8dVar;
                    d5 = 0.0d;
                    ic0Var = 0;
                }
                r8d r8dVar8 = (ic0Var == 0 || (r8dVar3 = ic0Var.a) == null) ? r8dVar2 : r8dVar3;
                if (ic0Var == 0 || (og8Var2 = ic0Var.b) == null) {
                    i4aVar2 = i4aVar;
                    og8Var = i4aVar2.b;
                } else {
                    og8Var = og8Var2;
                    i4aVar2 = i4aVar;
                }
                if (ic0Var == 0 || (uhVar = ic0Var.o) == null) {
                    uhVar = new uh(hr1.o(ic0.q, d5, 31), hr1.w(i4aVar2));
                }
                ic0 ic0Var3 = new ic0(r8dVar8, og8Var, uhVar, d3 * d2, 16);
                boolean zV = ic0Var3.v();
                ow5 ow5Var2 = ow5.c;
                if (!zV) {
                    u46 u46VarV = me8.V(0, og8Var.b);
                    ArrayList arrayList7 = new ArrayList(bt1.H0(u46VarV, 10));
                    Iterator it2 = u46VarV.iterator();
                    while (((t46) it2).K) {
                        arrayList7.add(ic0Var3.p(((t46) it2).nextInt(), null, null, null));
                    }
                    ArrayList arrayList8 = new ArrayList(bt1.H0(arrayList7, 10));
                    Iterator it3 = arrayList7.iterator();
                    int i45 = 0;
                    while (true) {
                        boolean zHasNext = it3.hasNext();
                        List list5 = ic0Var3.o;
                        if (!zHasNext) {
                            ArrayList arrayListI0 = bt1.I0(arrayList8);
                            if (arrayListI0.isEmpty()) {
                                list = ru3.I;
                            } else {
                                ArrayList arrayListO0 = ny7.o0(new o4a[]{arrayListI0.get(0)});
                                int size2 = arrayListI0.size();
                                for (int i46 = 1; i46 < size2; i46++) {
                                    if (((o4a) arrayListI0.get(i46)).a.b > 0.0d || ((o4a) zs1.m1(arrayListO0)).b.b < d4 || ((o4a) arrayListI0.get(i46)).a.a != ((o4a) zs1.m1(arrayListO0)).b.a + 1) {
                                        arrayListO0.add(arrayListI0.get(i46));
                                    } else {
                                        int size3 = arrayListO0.size() - 1;
                                        o4a o4aVar = (o4a) zs1.m1(arrayListO0);
                                        ow5 ow5Var3 = ((o4a) arrayListI0.get(i46)).b;
                                        ow5 ow5Var4 = o4aVar.a;
                                        ow5Var4.getClass();
                                        ow5Var3.getClass();
                                        arrayListO0.set(size3, new o4a(ow5Var4, ow5Var3));
                                    }
                                }
                                list = arrayListO0;
                            }
                            ArrayList<o4a> arrayList9 = new ArrayList();
                            boolean zIsEmpty = list.isEmpty();
                            ow5 ow5Var5 = ic0Var3.l;
                            if (zIsEmpty) {
                                arrayList9.add(new o4a(ow5Var2, ow5Var5));
                            } else {
                                for (o4a o4aVar2 : list) {
                                    ow5 ow5Var6 = o4aVar2.a;
                                    if (ow5Var6.a(ow5Var2) > 0) {
                                        arrayList9.add(new o4a(ow5Var2, ow5Var6));
                                    }
                                    ow5Var2 = o4aVar2.b;
                                }
                                if (ow5Var2.a(ow5Var5) < 0) {
                                    arrayList9.add(new o4a(ow5Var2, ow5Var5));
                                }
                            }
                            ArrayList arrayList10 = new ArrayList();
                            for (o4a o4aVar3 : list) {
                                ow5 ow5Var7 = o4aVar3.a;
                                if (ow5Var7.b <= 0.0d) {
                                    i4 = ow5Var7.a;
                                    i3 = 1;
                                } else {
                                    i3 = 1;
                                    i4 = ow5Var7.a + 1;
                                }
                                ow5 ow5Var8 = o4aVar3.b;
                                int i47 = ow5Var8.b < d4 ? ow5Var8.a : ow5Var8.a + i3;
                                if (i47 >= i4 && i4 <= i47) {
                                    while (true) {
                                        if ((i4 == 0 || ((fc0) list5.get(i4)).e() >= ((fc0) list5.get(i4 - 1)).e()) && (i4 == list5.size() - 1 || ((fc0) list5.get(i4)).e() > ((fc0) list5.get(i4 + 1)).e())) {
                                            if (i4 < og8Var.b) {
                                                ow5Var = new ow5(0.0d, i4);
                                                d6 = d4;
                                            } else {
                                                d6 = d4;
                                                ow5Var = new ow5(d6, i4 - 1);
                                            }
                                            arrayList10.add(ic0Var3.G(ow5Var).a.get(0));
                                        } else {
                                            d6 = d4;
                                        }
                                        if (i4 == i47) {
                                            break;
                                        }
                                        i4++;
                                        d4 = d6;
                                    }
                                    d4 = d6;
                                }
                            }
                            for (o4a o4aVar4 : arrayList9) {
                                ic0 ic0Var4 = (ic0) ic0Var3.C(new o4a(o4aVar4.a, o4aVar4.b));
                                r8d r8dVar9 = ic0Var4.a;
                                ic0 ic0Var5 = new ic0(r8dVar9, ic0Var4.b, ic0Var4.o, ic0Var4.c * 0.5d, 16);
                                Path path = new Path();
                                jc0 jc0Var5 = jc0Var;
                                mc0 mc0Var = new mc0(ic0Var5, jc0Var5);
                                ix9 ix9VarI = ic0.I(path, mc0Var);
                                int iIntValue = ((Number) ix9VarI.I).intValue();
                                int iIntValue2 = ((Number) ix9VarI.J).intValue();
                                ow5 ow5Var9 = mc0Var.C;
                                ow5Var9.a = 0;
                                ow5Var9.b = 0.0d;
                                lc0 lc0Var = mc0Var.v;
                                lc0Var.a = false;
                                lc0 lc0Var2 = mc0Var.w;
                                lc0Var2.a = false;
                                if (!mc0Var.k) {
                                    mc0Var.k = true;
                                    lc0Var.a = false;
                                    lc0Var2.a = false;
                                    mc0Var.x = -1;
                                }
                                ix9 ix9VarI2 = ic0.I(path, mc0Var);
                                int iIntValue3 = ((Number) ix9VarI2.I).intValue();
                                int iIntValue4 = iIntValue2 + ((Number) ix9VarI2.J).intValue();
                                path.close();
                                xw0 xw0Var5 = xw0.f;
                                arrayList10.addAll(a(rab.x(path, iIntValue + iIntValue3, iIntValue4, r8dVar9.c), jc0Var5.b).a);
                                jc0Var = jc0Var5;
                            }
                            jc0Var2 = jc0Var;
                            xw0Var3 = new xw0(arrayList10);
                            break;
                        }
                        Object next = it3.next();
                        int i48 = i45 + 1;
                        if (i45 < 0) {
                            ny7.E0();
                            throw null;
                        }
                        cv0 cv0Var = (cv0) next;
                        double dE3 = ((fc0) list5.get(i45)).e() * 0.5d;
                        double d31 = ic0Var3.c;
                        ou0 ou0Var = new ou0(dE3 * d31, d31 * ((fc0) list5.get(i48)).e() * 0.5d);
                        cj6[] cj6VarArr = dv0.a;
                        cv0Var.getClass();
                        gu8 gu8VarJ = ou0Var.j(null);
                        gu8VarJ.getClass();
                        double d32 = ((nu0) ((l2e) gu8VarJ).d()).a;
                        int order = cv0Var.getOrder();
                        if (order == 0) {
                            listL0 = ny7.l0(fv0.c);
                        } else if (order == 1) {
                            hd7 hd7Var2 = (hd7) cv0Var;
                            listL0 = dv0.a(cv0Var, hd7Var2.f((ou0) v72.x(dv0.b, cj6VarArr[0])), hd7Var2.k((ou0) v72.x(dv0.c, cj6VarArr[1])), d32);
                        } else if (order == 2) {
                            m2b m2bVar = (m2b) cv0Var;
                            listL0 = dv0.a(cv0Var, m2bVar.q((qu0) v72.x(dv0.e, cj6VarArr[3])), m2bVar.r((qu0) v72.x(dv0.f, cj6VarArr[4])), d32);
                        } else {
                            if (order != 3) {
                                yz3.l(tg2.l(cv0Var.getOrder(), "Unexpected curve order "));
                                return null;
                            }
                            gp2 gp2Var = (gp2) cv0Var;
                            listL0 = dv0.a(cv0Var, gp2Var.f((su0) v72.x(dv0.h, cj6VarArr[6])), gp2Var.k((su0) v72.x(dv0.i, cj6VarArr[7])), d32);
                        }
                        ArrayList arrayList11 = new ArrayList(bt1.H0(listL0, 10));
                        for (fv0 fv0Var : listL0) {
                            arrayList11.add(new o4a(new ow5(fv0Var.a, i45), new ow5(fv0Var.b, i45)));
                        }
                        arrayList8.add(arrayList11);
                        i45 = i48;
                    }
                } else {
                    xw0Var3 = ic0Var3.G(ow5Var2);
                    jc0Var2 = jc0Var;
                }
                listL1 = xw0Var3.a;
                arrayList2 = arrayList;
            }
            zs1.O0(arrayList2, listL1);
            jc0Var3 = jc0Var2;
            it = it;
            arrayList3 = arrayList2;
            d7 = d2;
        }
        return new xw0(arrayList3);
    }
}
