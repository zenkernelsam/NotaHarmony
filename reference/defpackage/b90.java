package defpackage;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

/* JADX INFO: loaded from: classes2.dex */
public final class b90 extends k0d {
    public final /* synthetic */ int b;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public /* synthetic */ b90(float f, int i, List list) {
        super(f, list);
        this.b = i;
    }

    /* JADX WARN: Code duplicated, block: B:68:0x0202  */
    private final m0d c() {
        float f;
        float f2;
        f3d f3dVar;
        float fA;
        l0d l0dVar = this.a;
        float f3 = l0dVar.d;
        List list = l0dVar.c;
        float f4 = 15.0f / f3;
        u46 u46VarA0 = ny7.a0(list);
        ArrayList arrayList = new ArrayList(bt1.H0(u46VarA0, 10));
        Iterator it = u46VarA0.iterator();
        while (((t46) it).K) {
            int iNextInt = ((t46) it).nextInt();
            int i = iNextInt - 1;
            while (true) {
                if (i >= 0) {
                    if (nbh.c(((n0d) list.get(i)).a, ((n0d) list.get(iNextInt)).a) > f4) {
                        int i2 = iNextInt + 1;
                        while (true) {
                            if (i2 < list.size()) {
                                if (nbh.c(((n0d) list.get(iNextInt)).a, ((n0d) list.get(i2)).a) > f4) {
                                    p3d p3dVar = ((n0d) list.get(i)).a;
                                    p3d p3dVar2 = ((n0d) list.get(iNextInt)).a;
                                    fA = mbh.a(new f3d(p3dVar, p3dVar2), new f3d(p3dVar2, ((n0d) list.get(i2)).a));
                                    break;
                                }
                                i2++;
                            }
                        }
                    } else {
                        i--;
                    }
                }
                fA = 0.0f;
                break;
            }
            arrayList.add(Float.valueOf(fA));
        }
        ArrayList arrayList2 = new ArrayList();
        int i3 = 0;
        while (i3 < arrayList.size()) {
            if (((Number) arrayList.get(i3)).floatValue() >= 1.5707964f) {
                int i4 = i3 + 1;
                while (i4 < arrayList.size() - 1 && ((Number) arrayList.get(i4)).floatValue() >= 1.5707964f) {
                    i4++;
                }
                Float fQ1 = zs1.q1(arrayList.subList(i3, i4));
                Iterator it2 = arrayList.subList(i3, i4).iterator();
                int i5 = 0;
                while (true) {
                    if (!it2.hasNext()) {
                        i5 = -1;
                        break;
                    }
                    if (x76.l(((Number) it2.next()).floatValue(), fQ1)) {
                        break;
                    }
                    i5++;
                }
                if (i5 >= 0) {
                    arrayList2.add(Integer.valueOf(i3 + i5));
                }
                i3 = i4;
            } else {
                i3++;
            }
        }
        Iterator it3 = arrayList2.iterator();
        ix9 ix9Var = null;
        float f5 = 0.0f;
        while (it3.hasNext()) {
            int iIntValue = ((Number) it3.next()).intValue();
            List listSubList = list.subList(0, iIntValue + 1);
            new l0d(f3, listSubList);
            List listSubList2 = list.subList(iIntValue, list.size());
            new l0d(f3, listSubList2);
            gd7 gd7Var = new gd7(f3, listSubList);
            bn9 bn9Var = new bn9(f3, listSubList2);
            m0d m0dVarB = gd7Var.b();
            if (m0dVarB == null) {
                f5 = f5;
            } else {
                qz5 qz5Var = m0dVarB.c;
                if (qz5Var instanceof sy5) {
                    sy5 sy5Var = (sy5) qz5Var;
                    p3d p3dVar3 = sy5Var.e;
                    p3d p3dVar4 = sy5Var.g;
                    p3d p3dVar5 = sy5Var.f;
                    if (p3dVar4 != null) {
                        p3dVar3.getClass();
                        p3dVar5.getClass();
                        f = 0.0f;
                        p3d p3dVarU = nbh.u(p3dVar3, nbh.v(nbh.t(p3dVar4, p3dVar3), 0.6666666666666666d));
                        p3d p3dVarU2 = nbh.u(p3dVar5, nbh.v(nbh.t(p3dVar4, p3dVar5), 0.6666666666666666d));
                        f3dVar = new f3d(p3dVar5, nbh.u(p3dVar5, nbh.u(nbh.u(nbh.v(nbh.v(nbh.t(p3dVarU, p3dVar3), 3.0d), 0.0d), nbh.v(nbh.v(nbh.t(p3dVarU2, p3dVarU), 3.0d), 0.0d)), nbh.v(nbh.v(nbh.t(p3dVar5, p3dVarU2), 3.0d), 1.0d))));
                    } else {
                        f = 0.0f;
                        f3dVar = new f3d(p3dVar5, nbh.t(nbh.v(p3dVar5, 2.0d), p3dVar3));
                    }
                    bn9Var.b = f3dVar;
                } else {
                    f5 = f5;
                    f = 0.0f;
                }
                m0d m0dVarB2 = bn9Var.b();
                if (m0dVarB2 != null) {
                    float f6 = m0dVarB.a;
                    if (f6 > f) {
                        float f7 = m0dVarB2.a;
                        if (f7 <= f) {
                            f2 = f;
                        } else {
                            if (f7 > 0.5f) {
                                f7 = 1.0f;
                            }
                            f2 = (f7 * 0.5f) + (f6 * 0.5f);
                        }
                    } else {
                        f2 = f;
                    }
                    if (f2 > f5) {
                        ix9Var = new ix9(m0dVarB, m0dVarB2);
                        f5 = f2;
                    }
                }
            }
            f5 = f5;
        }
        float f8 = f5;
        if (ix9Var == null) {
            return null;
        }
        m0d m0dVar = (m0d) ix9Var.I;
        m0d m0dVar2 = (m0d) ix9Var.J;
        qz5 qz5VarG = m0dVar.c;
        qz5 qz5Var2 = m0dVar2.c;
        if (qz5VarG instanceof sy5) {
            qz5VarG = sy5.g((sy5) qz5VarG, null, null, null, 31);
        }
        return new m0d(f8, m0dVar2.b, qz5VarG);
    }

    private final m0d d() {
        Double dValueOf;
        Double dValueOf2;
        l0d l0dVar = this.a;
        p3d p3dVar = l0dVar.f;
        float f = l0dVar.h;
        ArrayList<p3d> arrayList = l0dVar.e;
        if (nbh.c(p3dVar, l0dVar.g) < 120.0d) {
            Iterator it = arrayList.iterator();
            if (it.hasNext()) {
                double dMin = ((p3d) it.next()).a;
                while (it.hasNext()) {
                    dMin = Math.min(dMin, ((p3d) it.next()).a);
                }
                dValueOf = Double.valueOf(dMin);
            } else {
                dValueOf = null;
            }
            if (dValueOf != null) {
                double dDoubleValue = dValueOf.doubleValue();
                Iterator it2 = arrayList.iterator();
                if (it2.hasNext()) {
                    double dMin2 = ((p3d) it2.next()).b;
                    while (it2.hasNext()) {
                        dMin2 = Math.min(dMin2, ((p3d) it2.next()).b);
                    }
                    dValueOf2 = Double.valueOf(dMin2);
                } else {
                    dValueOf2 = null;
                }
                if (dValueOf2 != null) {
                    double dDoubleValue2 = dValueOf2.doubleValue();
                    ArrayList arrayList2 = new ArrayList(bt1.H0(arrayList, 10));
                    for (p3d p3dVar2 : arrayList) {
                        arrayList2.add(new p3d(p3dVar2.a - dDoubleValue, p3dVar2.b - dDoubleValue2));
                    }
                    Iterator it3 = arrayList2.iterator();
                    double dPow = 0.0d;
                    while (it3.hasNext()) {
                        dPow += Math.pow(((p3d) it3.next()).b, 4.0d);
                        f = f;
                    }
                    float f2 = f;
                    List listM0 = ny7.m0(Double.valueOf(dPow), Double.valueOf(nbh.j(arrayList2)), Double.valueOf(nbh.o(arrayList2)), Double.valueOf(nbh.r(arrayList2)), Double.valueOf(nbh.n(arrayList2)));
                    Double dValueOf3 = Double.valueOf(nbh.j(arrayList2));
                    Iterator it4 = arrayList2.iterator();
                    double dPow2 = 0.0d;
                    while (it4.hasNext()) {
                        dPow2 += Math.pow(((p3d) it4.next()).a, 4.0d);
                        arrayList2 = arrayList2;
                        listM0 = listM0;
                    }
                    ArrayList arrayList3 = arrayList2;
                    f01 f01Var = new f01(ny7.m0(listM0, ny7.m0(dValueOf3, Double.valueOf(dPow2), Double.valueOf(nbh.m(arrayList3)), Double.valueOf(nbh.k(arrayList3)), Double.valueOf(nbh.l(arrayList3))), ny7.m0(Double.valueOf(nbh.o(arrayList3)), Double.valueOf(nbh.m(arrayList3)), Double.valueOf(nbh.j(arrayList3)), Double.valueOf(nbh.n(arrayList3)), Double.valueOf(nbh.k(arrayList3))), ny7.m0(Double.valueOf(nbh.r(arrayList3)), Double.valueOf(nbh.k(arrayList3)), Double.valueOf(nbh.n(arrayList3)), Double.valueOf(nbh.q(arrayList3)), Double.valueOf(nbh.p(arrayList3))), ny7.m0(Double.valueOf(nbh.n(arrayList3)), Double.valueOf(nbh.l(arrayList3)), Double.valueOf(nbh.k(arrayList3)), Double.valueOf(nbh.p(arrayList3)), Double.valueOf(nbh.i(arrayList3)))));
                    Double dValueOf4 = Double.valueOf(-nbh.q(arrayList3));
                    Double dValueOf5 = Double.valueOf(-nbh.i(arrayList3));
                    Double dValueOf6 = Double.valueOf(-nbh.p(arrayList3));
                    Iterator it5 = arrayList3.iterator();
                    double d = 0.0d;
                    while (it5.hasNext()) {
                        d += ((p3d) it5.next()).b;
                    }
                    Double dValueOf7 = Double.valueOf(-d);
                    Iterator it6 = arrayList3.iterator();
                    double d2 = 0.0d;
                    while (it6.hasNext()) {
                        d2 += ((p3d) it6.next()).a;
                    }
                    f01 f01VarX = f01Var.z().x(f01Var).v().x(f01Var.z()).x(new f01(ny7.l0(ny7.m0(dValueOf4, dValueOf5, dValueOf6, dValueOf7, Double.valueOf(-d2)))).z());
                    double dR = f01VarX.r(1, 0);
                    double dR2 = f01VarX.r(2, 0);
                    double dR3 = f01VarX.r(0, 0);
                    double dR4 = f01VarX.r(4, 0);
                    double dR5 = f01VarX.r(3, 0);
                    double d3 = dR2 * dR2;
                    double d4 = d3 - ((dR * 4.0d) * dR3);
                    if (d4 >= 0.0d) {
                        return null;
                    }
                    double d5 = dR4 * dR2;
                    p3d p3dVar3 = new p3d(f92.A(dR2, dR5, dR3 * 2.0d * dR4, d4) + dDoubleValue, ((((dR * 2.0d) * dR5) - d5) / d4) + dDoubleValue2);
                    double d6 = (((((dR3 * dR4) * dR4) + ((dR * dR5) * dR5)) - (d5 * dR5)) + d4) * 2.0d;
                    double d7 = dR - dR3;
                    double dSqrt = Math.sqrt(Math.pow(d7, 2.0d) + d3);
                    double d8 = dR + dR3;
                    float fSqrt = (float) ((Math.sqrt((d8 + dSqrt) * d6) * (-1.0d)) / d4);
                    float fSqrt2 = (float) ((Math.sqrt((d8 - dSqrt) * d6) * (-1.0d)) / d4);
                    if (Float.isNaN(fSqrt) || Float.isNaN(fSqrt2)) {
                        return null;
                    }
                    if (fSqrt <= f2 && fSqrt2 <= f2) {
                        return null;
                    }
                    float fMax = Math.max(f2, fSqrt);
                    float fMax2 = Math.max(f2, fSqrt2);
                    ly5 ly5Var = new ly5(p3dVar3, fMax, fMax2, (float) ((dR2 != 0.0d || dR >= dR3) ? (dR2 != 0.0d || dR <= dR3) ? Math.atan(((dR3 - dR) - Math.sqrt(Math.pow(d7, 2.0d) + d3)) / dR2) : 1.5707963267948966d : 0.0d));
                    float fA = ly5Var.a(arrayList);
                    float f3 = (fMax2 + fMax) / 2.0f;
                    boolean z = f3 < 30.0f && fMax2 / fMax > 0.5f;
                    if (fMax2 / fMax > 0.7f || z) {
                        ly5Var = new ly5(p3dVar3, f3, f3, 0.0f);
                    }
                    return new m0d(fA, new p3d(0.0d, 0.0d), ly5Var);
                }
            }
        }
        return null;
    }

    private final m0d e() {
        l0d l0dVar = this.a;
        p3d p3dVar = l0dVar.f;
        p3d p3dVar2 = l0dVar.g;
        ArrayList arrayList = l0dVar.e;
        p3dVar.getClass();
        p3dVar2.getClass();
        float fC = nbh.c(p3dVar, p3dVar2);
        if (fC <= l0dVar.h || fC / l0dVar.i <= 0.6f) {
            return null;
        }
        p3d p3dVar3 = new p3d(0.0d, 0.0d);
        sy5 sy5Var = new sy5("Shared Line Detector", new ty5(), p3dVar, p3dVar2, null, rz5.I);
        float fA = sy5Var.a(arrayList);
        if (fA > 0.5f && fC > 60.0f) {
            fA = Math.max((1.0f + fA) * 0.5f, fA);
        }
        return new m0d(fA, p3dVar3, sy5Var);
    }

    /* JADX WARN: Code duplicated, block: B:100:0x02f2  */
    /* JADX WARN: Code duplicated, block: B:101:0x02f5  */
    /* JADX WARN: Code duplicated, block: B:103:0x02f8  */
    /* JADX WARN: Code duplicated, block: B:104:0x02fb  */
    /* JADX WARN: Code duplicated, block: B:106:0x02ff  */
    /* JADX WARN: Code duplicated, block: B:107:0x0302  */
    /* JADX WARN: Code duplicated, block: B:118:0x0326 A[LOOP:0: B:80:0x01c1->B:118:0x0326, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:123:0x034f A[LOOP:3: B:121:0x0349->B:123:0x034f, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:126:0x0373  */
    /* JADX WARN: Code duplicated, block: B:127:0x0379  */
    /* JADX WARN: Code duplicated, block: B:130:0x0392 A[LOOP:28: B:128:0x038c->B:130:0x0392, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:140:0x040d  */
    /* JADX WARN: Code duplicated, block: B:142:0x0412  */
    /* JADX WARN: Code duplicated, block: B:145:0x0423  */
    /* JADX WARN: Code duplicated, block: B:147:0x0427  */
    /* JADX WARN: Code duplicated, block: B:150:0x0432  */
    /* JADX WARN: Code duplicated, block: B:213:0x06ef  */
    /* JADX WARN: Code duplicated, block: B:216:0x06fd  */
    /* JADX WARN: Code duplicated, block: B:218:0x070e  */
    /* JADX WARN: Code duplicated, block: B:220:0x0725  */
    /* JADX WARN: Code duplicated, block: B:222:0x0752  */
    /* JADX WARN: Code duplicated, block: B:242:0x081a  */
    /* JADX WARN: Code duplicated, block: B:245:0x0828  */
    /* JADX WARN: Code duplicated, block: B:248:0x083d A[LOOP:24: B:246:0x0837->B:248:0x083d, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:251:0x0856  */
    /* JADX WARN: Code duplicated, block: B:253:0x0881  */
    /* JADX WARN: Code duplicated, block: B:255:0x088b  */
    /* JADX WARN: Code duplicated, block: B:256:0x0899  */
    /* JADX WARN: Code duplicated, block: B:257:0x08a1 A[LOOP:25: B:250:0x0854->B:257:0x08a1, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:32:0x00a1  */
    /* JADX WARN: Code duplicated, block: B:341:0x0ac7  */
    /* JADX WARN: Code duplicated, block: B:410:0x0c46  */
    /* JADX WARN: Code duplicated, block: B:411:0x0c49  */
    /* JADX WARN: Code duplicated, block: B:414:0x0c5e A[LOOP:18: B:412:0x0c58->B:414:0x0c5e, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:417:0x0c7b  */
    /* JADX WARN: Code duplicated, block: B:420:0x0c8b A[LOOP:13: B:418:0x0c85->B:420:0x0c8b, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:423:0x0c9e  */
    /* JADX WARN: Code duplicated, block: B:426:0x0cb3  */
    /* JADX WARN: Code duplicated, block: B:429:0x0d3a A[LOOP:15: B:427:0x0d36->B:429:0x0d3a, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:432:0x0d77  */
    /* JADX WARN: Code duplicated, block: B:435:0x0d92 A[LOOP:17: B:433:0x0d8c->B:435:0x0d92, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:445:0x0de0  */
    /* JADX WARN: Code duplicated, block: B:446:0x0de4  */
    /* JADX WARN: Code duplicated, block: B:449:0x0ded  */
    /* JADX WARN: Code duplicated, block: B:451:0x0df1  */
    /* JADX WARN: Code duplicated, block: B:457:0x0e19  */
    /* JADX WARN: Code duplicated, block: B:462:0x0e35  */
    /* JADX WARN: Code duplicated, block: B:464:0x0e40  */
    /* JADX WARN: Code duplicated, block: B:486:0x0330 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:487:0x0330 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:488:0x0336 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:491:0x0319 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:544:0x08a6 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:545:0x0881 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:549:0x0777 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:550:0x0777 A[ADDED_TO_REGION, REMOVE, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:82:0x01cb  */
    /* JADX WARN: Code duplicated, block: B:85:0x01e2 A[LOOP:1: B:83:0x01dc->B:85:0x01e2, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:88:0x01fa  */
    /* JADX WARN: Code duplicated, block: B:90:0x0226  */
    /* JADX WARN: Code duplicated, block: B:91:0x022b  */
    /* JADX WARN: Code duplicated, block: B:93:0x0234 A[LOOP:30: B:92:0x0232->B:93:0x0234, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:98:0x028d  */
    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r11v18, types: [java.util.Collection, java.util.List] */
    /* JADX WARN: Type inference failed for: r11v19, types: [java.lang.Iterable, java.util.List] */
    /* JADX WARN: Type inference failed for: r11v27 */
    /* JADX WARN: Type inference failed for: r5v121 */
    /* JADX WARN: Type inference failed for: r5v122 */
    /* JADX WARN: Type inference failed for: r5v33 */
    /* JADX WARN: Type inference failed for: r5v34 */
    /* JADX WARN: Type inference failed for: r5v35 */
    /* JADX WARN: Type inference failed for: r5v53, types: [java.util.ArrayList] */
    @Override // defpackage.k0d
    public final m0d b() {
        p3d p3dVar;
        float f;
        int i;
        List list;
        m0d m0dVar;
        ArrayList arrayList;
        float f2;
        String str;
        float f3;
        az5 az5Var;
        int i2;
        p3d p3dVar2;
        p3d p3dVar3;
        rf0 rf0Var;
        float f4;
        az5 az5Var2;
        float f5;
        float f6;
        float f7;
        float fH;
        float f8;
        float fMin;
        float fMax;
        float f9;
        float f10;
        float fMax2;
        float f11;
        Object next;
        gv0 gv0Var;
        Object next2;
        ?? arrayList2;
        ?? r11;
        Object next3;
        ArrayList arrayList3;
        Iterator it;
        gy5 gy5Var;
        ArrayList<fp2> arrayList4;
        Iterator it2;
        double dB;
        ArrayList arrayList5;
        ArrayList arrayList6;
        Iterator it3;
        fp2 fp2VarA;
        p3d p3dVar4;
        p3d p3dVar5;
        double dC;
        double d;
        double d2;
        List listW0;
        float f12;
        f3d f3dVar;
        Object next4;
        int size;
        double d3;
        ArrayList arrayList7;
        Iterator it4;
        double d4;
        ArrayList arrayList8;
        Iterator it5;
        List listI1;
        double size2;
        double d5;
        double d6;
        ArrayList arrayListC;
        Iterator it6;
        int i3;
        double d7;
        double size3;
        int i4;
        List list2;
        ArrayList arrayListT1;
        int size4;
        int i5;
        f3d f3dVar2;
        double dB2;
        int size5;
        ArrayList arrayListU;
        List listW1;
        List list3;
        List list4;
        ArrayList arrayList9;
        Iterator it7;
        int size6;
        int i6;
        int size7;
        List listL0;
        Object next5;
        ArrayList arrayList10;
        Iterator it8;
        Float fQ1;
        float f13;
        ArrayList arrayListU2;
        int size8;
        int i7;
        double d8;
        float fAbs;
        Iterator it9;
        float f14;
        int i8;
        float f15;
        float f16;
        switch (this.b) {
            case 0:
                return c();
            case 1:
                return d();
            case 2:
                return e();
            default:
                l0d l0dVar = this.a;
                ArrayList arrayList11 = l0dVar.e;
                float f17 = l0dVar.h;
                arrayList11.getClass();
                p3d p3dVar6 = (p3d) zs1.f1(arrayList11);
                int i9 = 1;
                ru3 ru3Var = ru3.I;
                if (p3dVar6 == null || (p3dVar = (p3d) zs1.o1(arrayList11)) == null) {
                    f = 0.05f;
                    list = ru3Var;
                } else {
                    ArrayList arrayListO0 = ny7.o0(p3dVar6);
                    int i10 = 0;
                    int i11 = 0;
                    while (i10 < arrayList11.size()) {
                        i10 += 5;
                        int iMin = Math.min(arrayList11.size(), i10);
                        float f18 = nbh.f(arrayList11, me8.V(i11, iMin));
                        if (f18 > 0.1f || iMin == arrayList11.size()) {
                            if (f18 > 0.1f || iMin == arrayList11.size()) {
                                while (f18 > 0.05f && (i = iMin - 2) > i11) {
                                    iMin = Math.max(i11, i);
                                    f18 = nbh.f(arrayList11, me8.V(i11, iMin));
                                }
                                arrayListO0.add(arrayList11.get(iMin - 1));
                                i11 = iMin;
                            }
                        }
                    }
                    f = 0.05f;
                    list = arrayListO0;
                    if (nbh.c(p3dVar6, p3dVar) < 60.0f) {
                        arrayListO0.set(arrayListO0.size() - 1, p3dVar6);
                        list = arrayListO0;
                    }
                }
                if (list.size() < 3) {
                    m0dVar = null;
                } else {
                    az5 az5Var3 = new az5(list, x76.p(zs1.c1(list), zs1.m1(list)));
                    if (az5Var3.b) {
                        float fA = az5Var3.a(arrayList11);
                        ee eeVar = new ee(nbh.s(list), arrayList11, l0dVar);
                        List<f3d> list5 = (List) eeVar.J;
                        f3d f3dVar3 = (f3d) zs1.f1((List) eeVar.K);
                        f3d f3dVar4 = (f3d) zs1.o1((List) eeVar.K);
                        int i12 = 4;
                        m0dVar = null;
                        int i13 = 10;
                        if (f3dVar3 == null || f3dVar4 == null) {
                            arrayList = arrayList11;
                            f2 = fA;
                            str = "INTEROPTEST";
                            f3 = 0.0f;
                            az5Var = new az5(eeVar.u(), false);
                        } else {
                            boolean zP = x76.p(f3dVar3.a, f3dVar4.b);
                            if (zP) {
                                i9 = 1;
                                f12 = 0.15f;
                            } else {
                                f12 = 0.15f;
                                while (true) {
                                    if (((List) eeVar.K).size() <= i9 || (f3dVar = (f3d) zs1.o1((List) eeVar.K)) == null) {
                                        i9 = i9;
                                    } else {
                                        f3 = 0.0f;
                                        f3d f3dVar5 = (f3d) zs1.f1((List) eeVar.K);
                                        if (f3dVar5 == null) {
                                            i9 = i9;
                                        } else {
                                            Iterator it10 = ((List) eeVar.K).iterator();
                                            if (it10.hasNext()) {
                                                next4 = it10.next();
                                                if (it10.hasNext()) {
                                                    float fG = mbh.g((f3d) next4);
                                                    do {
                                                        Object next6 = it10.next();
                                                        float fG2 = mbh.g((f3d) next6);
                                                        if (Float.compare(fG, fG2) < 0) {
                                                            fG = fG2;
                                                            next4 = next6;
                                                        }
                                                    } while (it10.hasNext());
                                                }
                                            } else {
                                                next4 = null;
                                            }
                                            f3d f3dVar6 = (f3d) next4;
                                            if (f3dVar6 != null) {
                                                float fG3 = mbh.g(f3dVar6);
                                                float fG4 = mbh.g(f3dVar);
                                                float fG5 = mbh.g(f3dVar5);
                                                if (fG4 < 40.0f || fG4 / fG3 < 0.15f) {
                                                    eeVar.r(((List) eeVar.K).size() - 1);
                                                } else if (fG5 < 40.0f || fG5 / fG3 < 0.15f) {
                                                    eeVar.r(0);
                                                }
                                                i9 = i9;
                                            }
                                        }
                                    }
                                }
                                while (true) {
                                    size = ((List) eeVar.K).size();
                                    if (size >= i12) {
                                        List list6 = (List) eeVar.K;
                                        arrayList10 = new ArrayList(bt1.H0(list6, i13));
                                        it8 = list6.iterator();
                                        while (it8.hasNext()) {
                                            arrayList10.add(Float.valueOf(mbh.g((f3d) it8.next())));
                                        }
                                        fQ1 = zs1.q1(arrayList10);
                                        if (fQ1 != null) {
                                            float fFloatValue = fQ1.floatValue();
                                            f13 = ((float) ((l0d) eeVar.M).j) / size;
                                            d3 = 2.0d;
                                            List listJ1 = zs1.J1(ny7.a0((List) eeVar.K), new wh(eeVar, 6));
                                            arrayListU2 = eeVar.u();
                                            if (arrayListU2.size() < 3) {
                                                f2 = fA;
                                                fAbs = f3;
                                            } else {
                                                i7 = 0;
                                                d8 = 0.0d;
                                                for (size8 = arrayListU2.size(); i7 < size8; size8 = size8) {
                                                    int i14 = i7 + 1;
                                                    int size9 = i14 % arrayListU2.size();
                                                    d8 = ((((p3d) arrayListU2.get(size9)).b * ((p3d) arrayListU2.get(i7)).a) + d8) - (((p3d) arrayListU2.get(i7)).b * ((p3d) arrayListU2.get(size9)).a);
                                                    i7 = i14;
                                                    fA = fA;
                                                }
                                                f2 = fA;
                                                fAbs = (float) Math.abs(d8 / 2.0d);
                                            }
                                            it9 = listJ1.iterator();
                                            while (true) {
                                                if (it9.hasNext()) {
                                                    int iIntValue = ((Number) it9.next()).intValue();
                                                    f3d f3dVar7 = (f3d) ((List) eeVar.K).get(iIntValue);
                                                    f3d f3dVar8 = (f3d) ((List) eeVar.K).get((iIntValue + 1) % ((List) eeVar.K).size());
                                                    p3d p3dVar7 = f3dVar7.a;
                                                    p3d p3dVar8 = f3dVar7.b;
                                                    arrayList = arrayList11;
                                                    p3d p3dVar9 = f3dVar8.b;
                                                    float fC = nbh.c(p3dVar7, p3dVar8);
                                                    float fC2 = nbh.c(p3dVar8, p3dVar9);
                                                    float fC3 = nbh.c(p3dVar9, p3dVar7);
                                                    float f19 = ((fC + fC2) + fC3) / 2.0f;
                                                    float f20 = (f19 - fC3) * (f19 - fC2) * (f19 - fC) * f19;
                                                    float f21 = fAbs;
                                                    Iterator it11 = it9;
                                                    float fSqrt = (float) Math.sqrt(f20);
                                                    float fD = nbh.d(p3dVar8, f3dVar7.a, f3dVar8.b);
                                                    f14 = fSqrt / f21;
                                                    if (f13 < 0.2f) {
                                                        i8 = i9;
                                                    } else {
                                                        i8 = 0;
                                                    }
                                                    if (i8 != 0) {
                                                        f15 = 0.2f;
                                                    } else {
                                                        f15 = f12;
                                                    }
                                                    if (i8 != 0) {
                                                        f16 = f12;
                                                    } else {
                                                        f16 = 0.1f;
                                                    }
                                                    if (f14 < f15 || fD / fFloatValue >= f16) {
                                                        fAbs = f21;
                                                        arrayList11 = arrayList;
                                                        it9 = it11;
                                                    } else {
                                                        eeVar.r(iIntValue);
                                                    }
                                                } else {
                                                    arrayList = arrayList11;
                                                }
                                            }
                                            if (size <= ((List) eeVar.K).size()) {
                                                arrayList11 = arrayList;
                                                fA = f2;
                                                i12 = 4;
                                                i13 = 10;
                                            }
                                        }
                                    }
                                    arrayList = arrayList11;
                                    f2 = fA;
                                    d3 = 2.0d;
                                }
                                List list7 = (List) eeVar.K;
                                arrayList7 = new ArrayList(bt1.H0(list7, 10));
                                it4 = list7.iterator();
                                while (it4.hasNext()) {
                                    arrayList7.add(Float.valueOf(mbh.g((f3d) it4.next())));
                                }
                                d4 = 6.283185307179586d;
                                if (((List) eeVar.K).size() < 4) {
                                    d7 = 6.283185307179586d;
                                    size3 = 0.0d;
                                } else {
                                    List list8 = (List) eeVar.K;
                                    arrayList8 = new ArrayList(bt1.H0(list8, 10));
                                    it5 = list8.iterator();
                                    while (it5.hasNext()) {
                                        arrayList8.add(Float.valueOf(mbh.g((f3d) it5.next())));
                                    }
                                    listI1 = zs1.I1(arrayList8);
                                    if (((List) eeVar.K).size() != 4 && ((Number) listI1.get(0)).floatValue() / ((Number) listI1.get(listI1.size() - 1)).floatValue() < 0.5d) {
                                        i4 = i9;
                                        if (((Number) listI1.get(i4)).floatValue() / ((Number) listI1.get(listI1.size() - i4)).floatValue() <= 0.5d) {
                                            d7 = 6.283185307179586d;
                                            size3 = 0.0d;
                                        }
                                    }
                                    size2 = 6.283185307179586d / ((double) ((List) eeVar.K).size());
                                    if (((List) eeVar.K).size() == 4) {
                                        d5 = 5.0d;
                                    } else {
                                        d5 = 4.0d;
                                    }
                                    d6 = size2 / d5;
                                    arrayListC = mbh.c((List) eeVar.K);
                                    if (arrayListC.isEmpty()) {
                                        i3 = 0;
                                    } else {
                                        it6 = arrayListC.iterator();
                                        i3 = 0;
                                        while (it6.hasNext()) {
                                            double d9 = d4;
                                            if (Math.abs(size2 - ((double) Math.abs(((Number) it6.next()).floatValue()))) >= d6 && (i3 = i3 + 1) < 0) {
                                                ny7.D0();
                                                throw null;
                                            }
                                            d4 = d9;
                                        }
                                    }
                                    d7 = d4;
                                    size3 = ((double) i3) / ((double) ((List) eeVar.K).size());
                                }
                                double size10 = d7 / ((double) ((List) eeVar.K).size());
                                if (zP || 4 > (size7 = ((List) eeVar.K).size()) || size7 >= 7 || size3 < 0.5d) {
                                    list2 = (List) eeVar.K;
                                    for (f3d f3dVar9 : list5) {
                                        arrayListT1 = zs1.T1(list2);
                                        size4 = list2.size();
                                        for (i5 = 0; i5 < size4; i5++) {
                                            f3dVar2 = (f3d) list2.get(i5);
                                            dB2 = mbh.b(f3dVar2, f3dVar9);
                                            if (Math.abs(dB2) < 0.2243994752564138d) {
                                                p3d p3dVar10 = f3dVar2.a;
                                                double dCos = Math.cos(dB2);
                                                double dSin = Math.sin(dB2);
                                                p3d p3dVarC = ee.C(p3dVar10, dCos, dSin, f3dVar2.a);
                                                p3d p3dVarC2 = ee.C(p3dVar10, dCos, dSin, f3dVar2.b);
                                                arrayListT1.set(i5, new f3d(p3dVarC, p3dVarC2));
                                                size5 = (i5 + 1) % list2.size();
                                                if (size5 == i5 && nbh.c(f3dVar2.b, ((f3d) list2.get(size5)).a) < 10.0d) {
                                                    arrayListT1.set(size5, new f3d(p3dVarC2, ((f3d) list2.get(size5)).b));
                                                }
                                            }
                                        }
                                        list2 = arrayListT1;
                                    }
                                    eeVar.K = list2;
                                } else {
                                    if (((List) eeVar.K).size() == 4) {
                                        Float fQ2 = zs1.q1(arrayList7);
                                        if (fQ2 != null) {
                                            float fFloatValue2 = fQ2.floatValue();
                                            Float fU1 = zs1.u1(arrayList7);
                                            if (fU1 != null) {
                                                double dFloatValue = fU1.floatValue() / fFloatValue2;
                                                List list9 = (List) eeVar.K;
                                                listL0 = dFloatValue > 0.75d ? ny7.l0(Double.valueOf(((double) (mbh.g((f3d) ((List) eeVar.K).get(1)) + mbh.g((f3d) list9.get(0)))) / d3)) : ny7.m0(Double.valueOf(mbh.g((f3d) list9.get(0))), Double.valueOf(mbh.g((f3d) ((List) eeVar.K).get(1))));
                                            }
                                        }
                                    } else {
                                        listL0 = ny7.l0(Double.valueOf(zs1.Q0(arrayList7)));
                                    }
                                    ArrayList arrayList12 = new ArrayList();
                                    arrayList12.add(ee.G((f3d) ((List) eeVar.K).get(0), ((Number) listL0.get(0)).doubleValue()));
                                    f3d f3dVarG = (f3d) arrayList12.get(0);
                                    int size11 = ((List) eeVar.K).size();
                                    int i15 = 1;
                                    while (i15 < size11) {
                                        f3d f3dVar10 = (f3d) ((List) eeVar.K).get(i15);
                                        p3d p3dVar11 = f3dVarG.b;
                                        p3d p3dVar12 = f3dVarG.a;
                                        p3dVar11.getClass();
                                        p3dVar12.getClass();
                                        int i16 = size11;
                                        double d10 = 3.141592653589793d - size10;
                                        double dCos2 = Math.cos(d10);
                                        double dSin2 = Math.sin(d10);
                                        int i17 = i15;
                                        f3d f3dVar11 = new f3d(ee.C(p3dVar11, dCos2, dSin2, p3dVar11), ee.C(p3dVar11, dCos2, dSin2, p3dVar12));
                                        double d11 = -d10;
                                        double dCos3 = Math.cos(d11);
                                        double dSin3 = Math.sin(d11);
                                        f3d f3dVar12 = new f3d(ee.C(p3dVar11, dCos3, dSin3, p3dVar11), ee.C(p3dVar11, dCos3, dSin3, p3dVar12));
                                        if (Math.abs(mbh.b(f3dVar10, f3dVar11)) >= Math.abs(mbh.b(f3dVar10, f3dVar12))) {
                                            f3dVar11 = f3dVar12;
                                        }
                                        f3dVarG = listL0.size() > 1 ? ee.G(f3dVar11, ((Number) listL0.get(i17 % listL0.size())).doubleValue()) : f3dVar11;
                                        arrayList12.add(f3dVarG);
                                        i15 = i17 + 1;
                                        size11 = i16;
                                    }
                                    eeVar.K = arrayList12;
                                    f3d f3dVarI = mbh.i((f3d) arrayList12.get(0));
                                    Iterator it12 = list5.iterator();
                                    if (it12.hasNext()) {
                                        next5 = it12.next();
                                        if (it12.hasNext()) {
                                            double dAbs = Math.abs(mbh.b(f3dVarI, (f3d) next5));
                                            do {
                                                Object next7 = it12.next();
                                                double dAbs2 = Math.abs(mbh.b(f3dVarI, (f3d) next7));
                                                if (Double.compare(dAbs, dAbs2) > 0) {
                                                    next5 = next7;
                                                    dAbs = dAbs2;
                                                }
                                            } while (it12.hasNext());
                                        }
                                    } else {
                                        next5 = null;
                                    }
                                    f3d f3dVar13 = (f3d) next5;
                                    if (f3dVar13 != null) {
                                        double dB3 = mbh.b(f3dVarI, f3dVar13);
                                        if (Math.abs(dB3) < 0.3141592653589793d) {
                                            p3d p3dVar13 = ((f3d) ((List) eeVar.K).get(0)).a;
                                            ArrayList<p3d> arrayListU3 = eeVar.u();
                                            ArrayList arrayList13 = new ArrayList(bt1.H0(arrayListU3, 10));
                                            for (p3d p3dVar14 : arrayListU3) {
                                                double d12 = p3dVar14.a;
                                                double d13 = p3dVar13.a;
                                                double d14 = dB3;
                                                double d15 = p3dVar13.b;
                                                double d16 = d12 - d13;
                                                double d17 = p3dVar14.b - d15;
                                                arrayList13.add(new p3d(((Math.cos(d14) * d16) + d13) - (Math.sin(d14) * d17), (Math.cos(d14) * d17) + (Math.sin(d14) * d16) + d15));
                                                dB3 = d14;
                                            }
                                            double d18 = dB3;
                                            eeVar.K = nbh.s(arrayList13);
                                            List<p3d> list10 = (List) eeVar.L;
                                            ArrayList arrayList14 = new ArrayList(bt1.H0(list10, 10));
                                            for (p3d p3dVar15 : list10) {
                                                double d19 = p3dVar15.a;
                                                double d20 = p3dVar13.a;
                                                double d21 = p3dVar13.b;
                                                double d22 = d19 - d20;
                                                double d23 = p3dVar15.b - d21;
                                                arrayList14.add(new p3d(((Math.cos(d18) * d22) + d20) - (Math.sin(d18) * d23), (Math.cos(d18) * d23) + (Math.sin(d18) * d22) + d21));
                                            }
                                            eeVar.L = arrayList14;
                                        }
                                    }
                                }
                                if (zP && !((List) eeVar.K).isEmpty()) {
                                    f3d f3dVar14 = (f3d) ((List) eeVar.K).get(0);
                                    List list11 = (List) eeVar.K;
                                    f3d f3dVar15 = (f3d) list11.get(list11.size() - 1);
                                    ArrayList arrayListT2 = zs1.T1((List) eeVar.K);
                                    arrayListT2.set(arrayListT2.size() - 1, new f3d(f3dVar15.a, f3dVar14.a));
                                    eeVar.K = arrayListT2;
                                }
                                arrayListU = eeVar.u();
                                listW1 = arrayListU;
                                if (zP && !arrayListU.isEmpty()) {
                                    listW1 = arrayListU;
                                    listW1 = zs1.W0(1, arrayListU);
                                }
                                listW1 = arrayListU;
                                list3 = (List) eeVar.K;
                                list3.getClass();
                                if (list3.size() == 3 || !mbh.d(list3)) {
                                    list4 = (List) eeVar.K;
                                    list4.getClass();
                                    if (mbh.f(list4)) {
                                        arrayList9 = new ArrayList(bt1.H0(list4, 10));
                                        it7 = list4.iterator();
                                        while (it7.hasNext()) {
                                            arrayList9.add(Float.valueOf(mbh.g((f3d) it7.next())));
                                        }
                                        size6 = list4.size();
                                        i6 = 1;
                                        while (true) {
                                            if (i6 >= size6) {
                                                str = "INTEROPTEST";
                                                az5Var = new bz5(str, new ty5(), listW1, 1);
                                            } else if (Math.abs(((Number) arrayList9.get(i6)).floatValue() - ((Number) arrayList9.get(i6 - 1)).floatValue()) <= ((Number) arrayList9.get(i6)).floatValue() * f) {
                                                i6++;
                                            } else if (mbh.f((List) eeVar.K)) {
                                                str = "INTEROPTEST";
                                                az5Var = new bz5(str, new ty5(), listW1, 0);
                                            } else {
                                                str = "INTEROPTEST";
                                                az5Var = new az5(listW1, zP);
                                            }
                                        }
                                    } else if (mbh.f((List) eeVar.K)) {
                                        str = "INTEROPTEST";
                                        az5Var = new bz5(str, new ty5(), listW1, 0);
                                    } else {
                                        str = "INTEROPTEST";
                                        az5Var = new az5(listW1, zP);
                                    }
                                } else {
                                    p3d p3dVar16 = (p3d) listW1.get(0);
                                    p3d p3dVar17 = (p3d) listW1.get(1);
                                    p3d p3dVar18 = (p3d) listW1.get(2);
                                    p3dVar16.getClass();
                                    p3dVar17.getClass();
                                    p3dVar18.getClass();
                                    az5Var = new uz5("INTEROPTEST", new ty5(), p3dVar16, p3dVar17, p3dVar18);
                                    str = "INTEROPTEST";
                                }
                            }
                            f3 = 0.0f;
                            while (true) {
                                size = ((List) eeVar.K).size();
                                if (size >= i12) {
                                    List list12 = (List) eeVar.K;
                                    arrayList10 = new ArrayList(bt1.H0(list12, i13));
                                    it8 = list12.iterator();
                                    while (it8.hasNext()) {
                                        arrayList10.add(Float.valueOf(mbh.g((f3d) it8.next())));
                                    }
                                    fQ1 = zs1.q1(arrayList10);
                                    if (fQ1 != null) {
                                        float fFloatValue3 = fQ1.floatValue();
                                        f13 = ((float) ((l0d) eeVar.M).j) / size;
                                        d3 = 2.0d;
                                        List listJ2 = zs1.J1(ny7.a0((List) eeVar.K), new wh(eeVar, 6));
                                        arrayListU2 = eeVar.u();
                                        if (arrayListU2.size() < 3) {
                                            f2 = fA;
                                            fAbs = f3;
                                        } else {
                                            i7 = 0;
                                            d8 = 0.0d;
                                            while (i7 < size8) {
                                                int i18 = i7 + 1;
                                                int size12 = i18 % arrayListU2.size();
                                                d8 = ((((p3d) arrayListU2.get(size12)).b * ((p3d) arrayListU2.get(i7)).a) + d8) - (((p3d) arrayListU2.get(i7)).b * ((p3d) arrayListU2.get(size12)).a);
                                                i7 = i18;
                                                fA = fA;
                                            }
                                            f2 = fA;
                                            fAbs = (float) Math.abs(d8 / 2.0d);
                                        }
                                        it9 = listJ2.iterator();
                                        while (true) {
                                            if (it9.hasNext()) {
                                                int iIntValue2 = ((Number) it9.next()).intValue();
                                                f3d f3dVar16 = (f3d) ((List) eeVar.K).get(iIntValue2);
                                                f3d f3dVar17 = (f3d) ((List) eeVar.K).get((iIntValue2 + 1) % ((List) eeVar.K).size());
                                                p3d p3dVar19 = f3dVar16.a;
                                                p3d p3dVar20 = f3dVar16.b;
                                                arrayList = arrayList11;
                                                p3d p3dVar21 = f3dVar17.b;
                                                float fC4 = nbh.c(p3dVar19, p3dVar20);
                                                float fC5 = nbh.c(p3dVar20, p3dVar21);
                                                float fC6 = nbh.c(p3dVar21, p3dVar19);
                                                float f110 = ((fC4 + fC5) + fC6) / 2.0f;
                                                float f22 = (f110 - fC6) * (f110 - fC5) * (f110 - fC4) * f110;
                                                float f23 = fAbs;
                                                Iterator it13 = it9;
                                                float fSqrt2 = (float) Math.sqrt(f22);
                                                float fD2 = nbh.d(p3dVar20, f3dVar16.a, f3dVar17.b);
                                                f14 = fSqrt2 / f23;
                                                if (f13 < 0.2f) {
                                                    i8 = i9;
                                                } else {
                                                    i8 = 0;
                                                }
                                                if (i8 != 0) {
                                                    f15 = 0.2f;
                                                } else {
                                                    f15 = f12;
                                                }
                                                if (i8 != 0) {
                                                    f16 = f12;
                                                } else {
                                                    f16 = 0.1f;
                                                }
                                                if (f14 < f15) {
                                                }
                                                fAbs = f23;
                                                arrayList11 = arrayList;
                                                it9 = it13;
                                            } else {
                                                arrayList = arrayList11;
                                            }
                                        }
                                        if (size <= ((List) eeVar.K).size()) {
                                            arrayList11 = arrayList;
                                            fA = f2;
                                            i12 = 4;
                                            i13 = 10;
                                        }
                                    }
                                }
                                arrayList = arrayList11;
                                f2 = fA;
                                d3 = 2.0d;
                            }
                            List list13 = (List) eeVar.K;
                            arrayList7 = new ArrayList(bt1.H0(list13, 10));
                            it4 = list13.iterator();
                            while (it4.hasNext()) {
                                arrayList7.add(Float.valueOf(mbh.g((f3d) it4.next())));
                            }
                            d4 = 6.283185307179586d;
                            if (((List) eeVar.K).size() < 4) {
                                d7 = 6.283185307179586d;
                                size3 = 0.0d;
                            } else {
                                List list14 = (List) eeVar.K;
                                arrayList8 = new ArrayList(bt1.H0(list14, 10));
                                it5 = list14.iterator();
                                while (it5.hasNext()) {
                                    arrayList8.add(Float.valueOf(mbh.g((f3d) it5.next())));
                                }
                                listI1 = zs1.I1(arrayList8);
                                if (((List) eeVar.K).size() != 4) {
                                    i4 = i9;
                                    if (((Number) listI1.get(i4)).floatValue() / ((Number) listI1.get(listI1.size() - i4)).floatValue() <= 0.5d) {
                                        d7 = 6.283185307179586d;
                                        size3 = 0.0d;
                                    }
                                }
                                size2 = 6.283185307179586d / ((double) ((List) eeVar.K).size());
                                if (((List) eeVar.K).size() == 4) {
                                    d5 = 5.0d;
                                } else {
                                    d5 = 4.0d;
                                }
                                d6 = size2 / d5;
                                arrayListC = mbh.c((List) eeVar.K);
                                if (arrayListC.isEmpty()) {
                                    i3 = 0;
                                } else {
                                    it6 = arrayListC.iterator();
                                    i3 = 0;
                                    while (it6.hasNext()) {
                                        double d24 = d4;
                                        if (Math.abs(size2 - ((double) Math.abs(((Number) it6.next()).floatValue()))) >= d6) {
                                        }
                                        d4 = d24;
                                    }
                                }
                                d7 = d4;
                                size3 = ((double) i3) / ((double) ((List) eeVar.K).size());
                            }
                            double size13 = d7 / ((double) ((List) eeVar.K).size());
                            if (zP) {
                                list2 = (List) eeVar.K;
                                while (r3.hasNext()) {
                                    arrayListT1 = zs1.T1(list2);
                                    size4 = list2.size();
                                    while (i5 < size4) {
                                        f3dVar2 = (f3d) list2.get(i5);
                                        dB2 = mbh.b(f3dVar2, f3dVar9);
                                        if (Math.abs(dB2) < 0.2243994752564138d) {
                                            p3d p3dVar110 = f3dVar2.a;
                                            double dCos4 = Math.cos(dB2);
                                            double dSin4 = Math.sin(dB2);
                                            p3d p3dVarC3 = ee.C(p3dVar110, dCos4, dSin4, f3dVar2.a);
                                            p3d p3dVarC4 = ee.C(p3dVar110, dCos4, dSin4, f3dVar2.b);
                                            arrayListT1.set(i5, new f3d(p3dVarC3, p3dVarC4));
                                            size5 = (i5 + 1) % list2.size();
                                            if (size5 == i5) {
                                            }
                                        }
                                    }
                                    list2 = arrayListT1;
                                }
                                eeVar.K = list2;
                            } else {
                                list2 = (List) eeVar.K;
                                while (r3.hasNext()) {
                                    arrayListT1 = zs1.T1(list2);
                                    size4 = list2.size();
                                    while (i5 < size4) {
                                        f3dVar2 = (f3d) list2.get(i5);
                                        dB2 = mbh.b(f3dVar2, f3dVar9);
                                        if (Math.abs(dB2) < 0.2243994752564138d) {
                                            p3d p3dVar111 = f3dVar2.a;
                                            double dCos5 = Math.cos(dB2);
                                            double dSin5 = Math.sin(dB2);
                                            p3d p3dVarC5 = ee.C(p3dVar111, dCos5, dSin5, f3dVar2.a);
                                            p3d p3dVarC6 = ee.C(p3dVar111, dCos5, dSin5, f3dVar2.b);
                                            arrayListT1.set(i5, new f3d(p3dVarC5, p3dVarC6));
                                            size5 = (i5 + 1) % list2.size();
                                            if (size5 == i5) {
                                            }
                                        }
                                    }
                                    list2 = arrayListT1;
                                }
                                eeVar.K = list2;
                            }
                            if (zP) {
                                f3d f3dVar18 = (f3d) ((List) eeVar.K).get(0);
                                List list15 = (List) eeVar.K;
                                f3d f3dVar19 = (f3d) list15.get(list15.size() - 1);
                                ArrayList arrayListT3 = zs1.T1((List) eeVar.K);
                                arrayListT3.set(arrayListT3.size() - 1, new f3d(f3dVar19.a, f3dVar18.a));
                                eeVar.K = arrayListT3;
                            }
                            arrayListU = eeVar.u();
                            listW1 = arrayListU;
                            if (zP) {
                                listW1 = arrayListU;
                                listW1 = zs1.W0(1, arrayListU);
                            }
                            listW1 = arrayListU;
                            list3 = (List) eeVar.K;
                            list3.getClass();
                            if (list3.size() == 3) {
                                list4 = (List) eeVar.K;
                                list4.getClass();
                                if (mbh.f(list4)) {
                                    arrayList9 = new ArrayList(bt1.H0(list4, 10));
                                    it7 = list4.iterator();
                                    while (it7.hasNext()) {
                                        arrayList9.add(Float.valueOf(mbh.g((f3d) it7.next())));
                                    }
                                    size6 = list4.size();
                                    i6 = 1;
                                    while (true) {
                                        if (i6 >= size6) {
                                            str = "INTEROPTEST";
                                            az5Var = new bz5(str, new ty5(), listW1, 1);
                                        } else if (Math.abs(((Number) arrayList9.get(i6)).floatValue() - ((Number) arrayList9.get(i6 - 1)).floatValue()) <= ((Number) arrayList9.get(i6)).floatValue() * f) {
                                            i6++;
                                        } else if (mbh.f((List) eeVar.K)) {
                                            str = "INTEROPTEST";
                                            az5Var = new bz5(str, new ty5(), listW1, 0);
                                        } else {
                                            str = "INTEROPTEST";
                                            az5Var = new az5(listW1, zP);
                                        }
                                    }
                                } else if (mbh.f((List) eeVar.K)) {
                                    str = "INTEROPTEST";
                                    az5Var = new bz5(str, new ty5(), listW1, 0);
                                } else {
                                    str = "INTEROPTEST";
                                    az5Var = new az5(listW1, zP);
                                }
                            } else {
                                list4 = (List) eeVar.K;
                                list4.getClass();
                                if (mbh.f(list4)) {
                                    arrayList9 = new ArrayList(bt1.H0(list4, 10));
                                    it7 = list4.iterator();
                                    while (it7.hasNext()) {
                                        arrayList9.add(Float.valueOf(mbh.g((f3d) it7.next())));
                                    }
                                    size6 = list4.size();
                                    i6 = 1;
                                    while (true) {
                                        if (i6 >= size6) {
                                            str = "INTEROPTEST";
                                            az5Var = new bz5(str, new ty5(), listW1, 1);
                                        } else if (Math.abs(((Number) arrayList9.get(i6)).floatValue() - ((Number) arrayList9.get(i6 - 1)).floatValue()) <= ((Number) arrayList9.get(i6)).floatValue() * f) {
                                            i6++;
                                        } else if (mbh.f((List) eeVar.K)) {
                                            str = "INTEROPTEST";
                                            az5Var = new bz5(str, new ty5(), listW1, 0);
                                        } else {
                                            str = "INTEROPTEST";
                                            az5Var = new az5(listW1, zP);
                                        }
                                    }
                                } else if (mbh.f((List) eeVar.K)) {
                                    str = "INTEROPTEST";
                                    az5Var = new bz5(str, new ty5(), listW1, 0);
                                } else {
                                    str = "INTEROPTEST";
                                    az5Var = new az5(listW1, zP);
                                }
                            }
                        }
                        List list16 = az5Var.e;
                        if (list16.size() >= 3) {
                            y3d y3dVarB = nbh.b(list16);
                            p3d p3dVar22 = y3dVarB.a;
                            p3d p3dVar23 = y3dVarB.b;
                            if (Math.abs(p3dVar23.a - p3dVar22.a) >= f17 && Math.abs(p3dVar23.b - p3dVar22.b) >= f17) {
                                float size14 = l0dVar.i / az5Var.g().size();
                                List listG = az5Var.g();
                                ArrayList arrayList15 = new ArrayList(bt1.H0(listG, 10));
                                Iterator it14 = listG.iterator();
                                while (it14.hasNext()) {
                                    arrayList15.add(Float.valueOf(mbh.g((f3d) it14.next())));
                                }
                                float fFloatValue4 = ((Number) zs1.I1(arrayList15).get(az5Var.g().size() / 2)).floatValue();
                                ArrayList arrayListC2 = mbh.c(az5Var.g());
                                if (arrayListC2.isEmpty()) {
                                    i2 = 0;
                                } else {
                                    Iterator it15 = arrayListC2.iterator();
                                    i2 = 0;
                                    while (it15.hasNext()) {
                                        float fAbs2 = Math.abs((((Number) it15.next()).floatValue() * 180.0f) / 3.1415927f);
                                        if (fAbs2 >= 85.0f && fAbs2 <= 95.0f && (i2 = i2 + 1) < 0) {
                                            ny7.D0();
                                            throw null;
                                        }
                                    }
                                }
                                float f24 = 20.0f;
                                float f25 = 1.0f;
                                if (i2 >= 4 && size14 > 20.0f) {
                                    return new m0d(Math.min(1.0f, f2 * 1.1f), new p3d(0.0d, 0.0d), az5Var);
                                }
                                if (arrayList.size() < 2 || (p3dVar2 = (p3d) zs1.f1(arrayList)) == null || (p3dVar3 = (p3d) zs1.o1(arrayList)) == null) {
                                    rf0Var = null;
                                } else {
                                    List listW2 = arrayList;
                                    while (listW2.size() >= 2 && x76.p(listW2.get(listW2.size() - 1), listW2.get(listW2.size() - 2))) {
                                        listW2 = zs1.W0(1, listW2);
                                    }
                                    rf0Var = new rf0(listW2, p3dVar2, p3dVar3);
                                }
                                if (rf0Var != null) {
                                    boolean z = nbh.c((p3d) rf0Var.J, (p3d) rf0Var.K) < 60.0f;
                                    List listB = rf0.b((List) rf0Var.I);
                                    while (true) {
                                        lo3 lo3Var = (lo3) zs1.X1(listB).iterator();
                                        Iterator it16 = lo3Var.J;
                                        if (it16.hasNext()) {
                                            next = lo3Var.next();
                                            if (it16.hasNext()) {
                                                double dB4 = ((gv0) ((sw5) next).b).a.b();
                                                while (true) {
                                                    Object next8 = lo3Var.next();
                                                    f4 = f24;
                                                    az5Var2 = az5Var;
                                                    double dB5 = ((gv0) ((sw5) next8).b).a.b();
                                                    if (Double.compare(dB4, dB5) > 0) {
                                                        dB4 = dB5;
                                                        next = next8;
                                                    }
                                                    if (it16.hasNext()) {
                                                        f24 = f4;
                                                        az5Var = az5Var2;
                                                    }
                                                }
                                            } else {
                                                f4 = f24;
                                                az5Var2 = az5Var;
                                            }
                                        } else {
                                            f4 = f24;
                                            az5Var2 = az5Var;
                                            next = null;
                                        }
                                        sw5 sw5Var = (sw5) next;
                                        ix9 ix9Var = sw5Var != null ? new ix9(Integer.valueOf(sw5Var.a), sw5Var.b) : null;
                                        if (ix9Var != null) {
                                            Object obj = ix9Var.I;
                                            if (((gv0) ix9Var.J).a.b() < 60.0d) {
                                                Number number = (Number) obj;
                                                ix9 ix9VarC = rf0.c(number.intValue(), listB);
                                                if (ix9VarC != null) {
                                                    Object obj2 = ix9VarC.J;
                                                    if (((gv0) obj2).c < 0.5f) {
                                                        ArrayList arrayList16 = new ArrayList(listB);
                                                        arrayList16.set(number.intValue(), obj2);
                                                        arrayList16.remove(((Number) ix9VarC.I).intValue());
                                                        f24 = f4;
                                                        listB = arrayList16;
                                                        az5Var = az5Var2;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if (z && (gv0Var = (gv0) zs1.o1(listB)) != null) {
                                        List list17 = gv0Var.b;
                                        gv0 gv0Var2 = (gv0) zs1.f1(listB);
                                        if (gv0Var2 == null) {
                                            arrayList2 = listB;
                                        } else {
                                            p3d p3dVar24 = gv0Var2.a.a;
                                            lo3 lo3Var2 = (lo3) zs1.X1(list17).iterator();
                                            Iterator it17 = lo3Var2.J;
                                            if (it17.hasNext()) {
                                                next2 = lo3Var2.next();
                                                if (it17.hasNext()) {
                                                    float fC7 = nbh.c((p3d) ((sw5) next2).b, p3dVar24);
                                                    do {
                                                        Object next9 = lo3Var2.next();
                                                        float fC8 = nbh.c((p3d) ((sw5) next9).b, p3dVar24);
                                                        if (Float.compare(fC7, fC8) > 0) {
                                                            next2 = next9;
                                                            fC7 = fC8;
                                                        }
                                                    } while (it17.hasNext());
                                                }
                                            } else {
                                                next2 = null;
                                            }
                                            sw5 sw5Var2 = (sw5) next2;
                                            if (sw5Var2 == null) {
                                                arrayList2 = listB;
                                            } else {
                                                gv0 gv0VarE = rf0.e(zs1.z1(list17.subList(0, sw5Var2.a + 1), ny7.l0(p3dVar24)));
                                                if (gv0VarE != null) {
                                                    arrayList2 = listB;
                                                    ArrayList arrayList17 = new ArrayList(listB);
                                                    arrayList17.set(arrayList17.size() - 1, gv0VarE);
                                                    arrayList2 = arrayList17;
                                                }
                                            }
                                        }
                                    } else {
                                        arrayList2 = listB;
                                    }
                                    arrayList2 = listB;
                                    while (true) {
                                        r11 = arrayList2;
                                        u46 u46VarA0 = ny7.a0(r11);
                                        ArrayList arrayList18 = new ArrayList();
                                        Iterator it18 = u46VarA0.iterator();
                                        while (((t46) it18).K) {
                                            int iNextInt = ((t46) it18).nextInt();
                                            ix9 ix9VarC2 = rf0.c(iNextInt, r11);
                                            ix9 ix9Var2 = ix9VarC2 != null ? new ix9(Integer.valueOf(iNextInt), ix9VarC2) : null;
                                            if (ix9Var2 != null) {
                                                arrayList18.add(ix9Var2);
                                            }
                                        }
                                        Iterator it19 = arrayList18.iterator();
                                        if (it19.hasNext()) {
                                            next3 = it19.next();
                                            if (it19.hasNext()) {
                                                float f26 = ((gv0) ((ix9) ((ix9) next3).J).J).c;
                                                do {
                                                    Object next10 = it19.next();
                                                    float f27 = ((gv0) ((ix9) ((ix9) next10).J).J).c;
                                                    if (Float.compare(f26, f27) > 0) {
                                                        next3 = next10;
                                                        f26 = f27;
                                                    }
                                                } while (it19.hasNext());
                                            }
                                        } else {
                                            next3 = null;
                                        }
                                        ix9 ix9Var3 = (ix9) next3;
                                        if (ix9Var3 != null) {
                                            ix9 ix9Var4 = (ix9) ix9Var3.J;
                                            if (((gv0) ix9Var4.J).c < 1.0f) {
                                                arrayList2 = new ArrayList((Collection) r11);
                                                arrayList2.set(((Number) ix9Var3.I).intValue(), ix9Var4.J);
                                                arrayList2.remove(((Number) ix9Var4.I).intValue());
                                            }
                                        }
                                    }
                                    while (!z && r11.size() >= 2) {
                                        gv0 gv0Var3 = (gv0) zs1.f1(r11);
                                        gv0 gv0Var4 = (gv0) zs1.o1(r11);
                                        if (gv0Var3 != null && gv0Var3.a.b() < 15.0d) {
                                            listW0 = zs1.V0(r11, 1);
                                        } else {
                                            if (gv0Var4 == null || gv0Var4.a.b() >= 15.0d) {
                                                if (r11.isEmpty()) {
                                                    gy5Var = null;
                                                } else {
                                                    arrayList3 = new ArrayList(bt1.H0(r11, 10));
                                                    it = r11.iterator();
                                                    while (it.hasNext()) {
                                                        arrayList3.add(((gv0) it.next()).a);
                                                    }
                                                    gy5Var = new gy5(str, new ty5(), new j4a(arrayList3), z);
                                                }
                                                if (gy5Var != null) {
                                                    arrayList4 = gy5Var.e.a;
                                                    it2 = arrayList4.iterator();
                                                    dB = 0.0d;
                                                    while (it2.hasNext()) {
                                                        dB += ((fp2) it2.next()).b();
                                                    }
                                                    if (arrayList4.size() <= 6) {
                                                        arrayList6 = new ArrayList(bt1.H0(arrayList4, 10));
                                                        it3 = arrayList4.iterator();
                                                        while (it3.hasNext()) {
                                                            fp2 fp2Var = (fp2) it3.next();
                                                            fp2Var.getClass();
                                                            p3d p3dVar25 = fp2Var.a;
                                                            p3d p3dVar26 = fp2Var.d;
                                                            p3dVar25.getClass();
                                                            p3dVar26.getClass();
                                                            double dAtan2 = Math.atan2(0.0d, 1.0d) - Math.atan2(p3dVar26.b - p3dVar25.b, p3dVar26.a - p3dVar25.a);
                                                            f01 f01Var = new f01(3, 3);
                                                            float f28 = f25;
                                                            double dCos6 = Math.cos(dAtan2);
                                                            double dSin6 = Math.sin(dAtan2);
                                                            f01Var.y(dCos6, 0, 0);
                                                            float f29 = size14;
                                                            float f30 = fFloatValue4;
                                                            Iterator it20 = it3;
                                                            f01Var.y(-dSin6, 0, 1);
                                                            f01Var.y(0.0d, 0, 2);
                                                            f01Var.y(dSin6, 1, 0);
                                                            f01Var.y(dCos6, 1, 1);
                                                            f01Var.y(0.0d, 1, 2);
                                                            f01Var.y(0.0d, 2, 0);
                                                            f01Var.y(0.0d, 2, 1);
                                                            f01Var.y(1.0d, 2, 2);
                                                            fp2VarA = fp2Var.a(f01Var);
                                                            p3dVar4 = fp2VarA.a;
                                                            p3dVar5 = fp2VarA.d;
                                                            p3dVar4.getClass();
                                                            p3dVar5.getClass();
                                                            dC = ((double) nbh.c(p3dVar4, p3dVar5)) * 0.001d;
                                                            d = 0.001d;
                                                            d2 = 0.0d;
                                                            while (d < 1.0d) {
                                                                d2 = (((double) nbh.d(fp2VarA.c(d), p3dVar4, p3dVar5)) * dC) + d2;
                                                                d += 0.001d;
                                                                fp2VarA = fp2VarA;
                                                            }
                                                            arrayList6.add(Float.valueOf(((float) Math.sqrt(d2)) * ((float) (fp2Var.b() / dB))));
                                                            size14 = f29;
                                                            it3 = it20;
                                                            f25 = f28;
                                                            fFloatValue4 = f30;
                                                        }
                                                        f5 = size14;
                                                        f6 = fFloatValue4;
                                                        f7 = f25;
                                                        fH = mbh.h(arrayList6);
                                                    } else {
                                                        f5 = size14;
                                                        f6 = fFloatValue4;
                                                        f7 = 1.0f;
                                                        arrayList5 = new ArrayList(bt1.H0(arrayList4, 10));
                                                        for (fp2 fp2Var2 : arrayList4) {
                                                            arrayList5.add(Float.valueOf(((float) t4j.d(fp2Var2)) * ((float) (fp2Var2.b() / dB))));
                                                        }
                                                        fH = mbh.h(arrayList5);
                                                    }
                                                }
                                                if (f5 < 30.0f) {
                                                    f8 = 0.8f;
                                                } else {
                                                    f8 = f7;
                                                }
                                                if ((f6 >= f4 || f5 < f4) && az5Var2.g().size() >= 5) {
                                                }
                                                fMin = Math.min(0.3f, (f5 / 100.0f) * 0.3f) * az5Var2.g().size();
                                                fMax = f7;
                                                while (fMin > ((float) l0dVar.j) && fMax > f3) {
                                                    float f31 = f3;
                                                    fMax = Math.max(f31, fMax - 0.2f);
                                                    fMin = Math.max(f31, fMin - f7);
                                                }
                                                f9 = f8 * fMax * f2;
                                                if (fH >= 3.0f || az5Var2.g().size() <= 4) {
                                                    f10 = 0.0f;
                                                    fMax2 = Math.max(0.0f, f9);
                                                } else {
                                                    if (fH < 4.0f) {
                                                        f11 = 0.95f;
                                                    } else if (fH < 5.0f) {
                                                        f11 = 0.85f;
                                                    } else {
                                                        f11 = fH < 6.0f ? 0.75f : 0.4f;
                                                    }
                                                    fMax2 = f9 * f11;
                                                    f10 = 0.0f;
                                                }
                                                return new m0d(Math.max(f10, fMax2), new p3d(0.0d, 0.0d), az5Var2);
                                            }
                                            listW0 = zs1.W0(1, r11);
                                        }
                                        r11 = listW0;
                                    }
                                    if (r11.isEmpty()) {
                                        gy5Var = null;
                                    } else {
                                        arrayList3 = new ArrayList(bt1.H0(r11, 10));
                                        it = r11.iterator();
                                        while (it.hasNext()) {
                                            arrayList3.add(((gv0) it.next()).a);
                                        }
                                        gy5Var = new gy5(str, new ty5(), new j4a(arrayList3), z);
                                    }
                                    if (gy5Var != null) {
                                        arrayList4 = gy5Var.e.a;
                                        it2 = arrayList4.iterator();
                                        dB = 0.0d;
                                        while (it2.hasNext()) {
                                            dB += ((fp2) it2.next()).b();
                                        }
                                        if (arrayList4.size() <= 6) {
                                            arrayList6 = new ArrayList(bt1.H0(arrayList4, 10));
                                            it3 = arrayList4.iterator();
                                            while (it3.hasNext()) {
                                                fp2 fp2Var3 = (fp2) it3.next();
                                                fp2Var3.getClass();
                                                p3d p3dVar27 = fp2Var3.a;
                                                p3d p3dVar28 = fp2Var3.d;
                                                p3dVar27.getClass();
                                                p3dVar28.getClass();
                                                double dAtan3 = Math.atan2(0.0d, 1.0d) - Math.atan2(p3dVar28.b - p3dVar27.b, p3dVar28.a - p3dVar27.a);
                                                f01 f01Var2 = new f01(3, 3);
                                                float f210 = f25;
                                                double dCos7 = Math.cos(dAtan3);
                                                double dSin7 = Math.sin(dAtan3);
                                                f01Var2.y(dCos7, 0, 0);
                                                float f211 = size14;
                                                float f32 = fFloatValue4;
                                                Iterator it21 = it3;
                                                f01Var2.y(-dSin7, 0, 1);
                                                f01Var2.y(0.0d, 0, 2);
                                                f01Var2.y(dSin7, 1, 0);
                                                f01Var2.y(dCos7, 1, 1);
                                                f01Var2.y(0.0d, 1, 2);
                                                f01Var2.y(0.0d, 2, 0);
                                                f01Var2.y(0.0d, 2, 1);
                                                f01Var2.y(1.0d, 2, 2);
                                                fp2VarA = fp2Var3.a(f01Var2);
                                                p3dVar4 = fp2VarA.a;
                                                p3dVar5 = fp2VarA.d;
                                                p3dVar4.getClass();
                                                p3dVar5.getClass();
                                                dC = ((double) nbh.c(p3dVar4, p3dVar5)) * 0.001d;
                                                d = 0.001d;
                                                d2 = 0.0d;
                                                while (d < 1.0d) {
                                                    d2 = (((double) nbh.d(fp2VarA.c(d), p3dVar4, p3dVar5)) * dC) + d2;
                                                    d += 0.001d;
                                                    fp2VarA = fp2VarA;
                                                }
                                                arrayList6.add(Float.valueOf(((float) Math.sqrt(d2)) * ((float) (fp2Var3.b() / dB))));
                                                size14 = f211;
                                                it3 = it21;
                                                f25 = f210;
                                                fFloatValue4 = f32;
                                            }
                                            f5 = size14;
                                            f6 = fFloatValue4;
                                            f7 = f25;
                                            fH = mbh.h(arrayList6);
                                        } else {
                                            f5 = size14;
                                            f6 = fFloatValue4;
                                            f7 = 1.0f;
                                            arrayList5 = new ArrayList(bt1.H0(arrayList4, 10));
                                            while (r2.hasNext()) {
                                                arrayList5.add(Float.valueOf(((float) t4j.d(fp2Var2)) * ((float) (fp2Var2.b() / dB))));
                                            }
                                            fH = mbh.h(arrayList5);
                                        }
                                    }
                                    if (f5 < 30.0f) {
                                        f8 = 0.8f;
                                    } else {
                                        f8 = f7;
                                    }
                                    f8 = f6 >= f4 ? 0.3f : 0.3f;
                                    fMin = Math.min(0.3f, (f5 / 100.0f) * 0.3f) * az5Var2.g().size();
                                    fMax = f7;
                                    while (fMin > ((float) l0dVar.j)) {
                                        float f33 = f3;
                                        fMax = Math.max(f33, fMax - 0.2f);
                                        fMin = Math.max(f33, fMin - f7);
                                    }
                                    f9 = f8 * fMax * f2;
                                    if (fH >= 3.0f) {
                                        f10 = 0.0f;
                                        fMax2 = Math.max(0.0f, f9);
                                    } else {
                                        f10 = 0.0f;
                                        fMax2 = Math.max(0.0f, f9);
                                    }
                                    return new m0d(Math.max(f10, fMax2), new p3d(0.0d, 0.0d), az5Var2);
                                }
                                f4 = 20.0f;
                                az5Var2 = az5Var;
                                f5 = size14;
                                f6 = fFloatValue4;
                                f7 = 1.0f;
                                fH = 1.0f;
                                if (f5 < 30.0f) {
                                    f8 = 0.8f;
                                } else {
                                    f8 = f7;
                                }
                                if (f6 >= f4) {
                                }
                                fMin = Math.min(0.3f, (f5 / 100.0f) * 0.3f) * az5Var2.g().size();
                                fMax = f7;
                                while (fMin > ((float) l0dVar.j)) {
                                    float f34 = f3;
                                    fMax = Math.max(f34, fMax - 0.2f);
                                    fMin = Math.max(f34, fMin - f7);
                                }
                                f9 = f8 * fMax * f2;
                                if (fH >= 3.0f) {
                                    f10 = 0.0f;
                                    fMax2 = Math.max(0.0f, f9);
                                } else {
                                    f10 = 0.0f;
                                    fMax2 = Math.max(0.0f, f9);
                                }
                                return new m0d(Math.max(f10, fMax2), new p3d(0.0d, 0.0d), az5Var2);
                            }
                        }
                    } else {
                        m0dVar = null;
                    }
                }
                return m0dVar;
        }
    }
}
