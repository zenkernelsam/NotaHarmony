package defpackage;

import com.gingerlabs.notability.R;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes2.dex */
public abstract class sqh {
    public static final n12 a = new n12(new d22(26), false, -625053231);
    public static final n12 b = new n12(new d22(27), false, 341640457);

    public static final void a(Function0 function0, Function0 function1, s32 s32Var, int i) {
        int i2;
        int i3;
        ay4 ay4Var = (ay4) s32Var;
        ay4Var.h0(-1367321480);
        if ((i & 6) == 0) {
            i2 = i | (ay4Var.i(function0) ? 4 : 2);
        } else {
            i2 = i;
        }
        if ((i & 48) == 0) {
            i2 |= ay4Var.i(function1) ? 32 : 16;
        }
        int i4 = i2;
        if (ay4Var.X(i4 & 1, (i4 & 19) != 18)) {
            ka8 ka8VarF = kad.f(ha8.I, 1.0f);
            bp.d0(ay4Var).getClass();
            k2c k2cVarA = i2c.a(new g70(32.0f, true, new b9(hr1.X, 1)), hr1.T, ay4Var, 48);
            int iHashCode = Long.hashCode(ay4Var.T);
            jda jdaVarM = ay4Var.m();
            ka8 ka8VarC0 = h76.C0(ay4Var, ka8VarF);
            l32.c.getClass();
            s42 s42Var = k32.b;
            ay4Var.j0();
            if (ay4Var.S) {
                ay4Var.l(s42Var);
            } else {
                ay4Var.s0();
            }
            qy1.c0(ay4Var, k32.f, k2cVarA);
            qy1.c0(ay4Var, k32.e, jdaVarM);
            qy1.c0(ay4Var, k32.g, Integer.valueOf(iHashCode));
            qy1.Z(ay4Var, k32.h);
            qy1.c0(ay4Var, k32.d, ka8VarC0);
            um8 um8Var = um8.J;
            i3 = 4;
            pvi.b(function1, null, false, false, null, um8Var, rm8.L, null, null, 0L, yph.a, ay4Var, ((i4 >> 3) & 14) | 1769472, 926);
            boolean z = ((i4 & 14) == 4) | ((i4 & 112) == 32);
            Object objS = ay4Var.S();
            if (z || objS == q32.a) {
                objS = new dc(function0, function1, 24);
                ay4Var.p0(objS);
            }
            pvi.b((Function0) objS, null, false, false, null, um8Var, rm8.I, null, null, 0L, yph.b, ay4Var, 1769472, 926);
            ay4Var.r(true);
        } else {
            i3 = 4;
            ay4Var.a0();
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new ib3(i, i3, function0, function1);
        }
    }

    public static final void b(Function0 function0, s32 s32Var, int i) {
        int i2;
        ay4 ay4Var = (ay4) s32Var;
        ay4Var.h0(-1327780526);
        if ((i & 6) == 0) {
            i2 = (ay4Var.i(function0) ? 4 : 2) | i;
        } else {
            i2 = i;
        }
        if (ay4Var.X(i2 & 1, (i2 & 3) != 2)) {
            ha8 ha8Var = ha8.I;
            ka8 ka8VarF = kad.f(ha8Var, 1.0f);
            k2c k2cVarA = i2c.a(j70.f, hr1.T, ay4Var, 54);
            int iHashCode = Long.hashCode(ay4Var.T);
            jda jdaVarM = ay4Var.m();
            ka8 ka8VarC0 = h76.C0(ay4Var, ka8VarF);
            l32.c.getClass();
            s42 s42Var = k32.b;
            ay4Var.j0();
            if (ay4Var.S) {
                ay4Var.l(s42Var);
            } else {
                ay4Var.s0();
            }
            qy1.c0(ay4Var, k32.f, k2cVarA);
            qy1.c0(ay4Var, k32.e, jdaVarM);
            qy1.c0(ay4Var, k32.g, Integer.valueOf(iHashCode));
            qy1.Z(ay4Var, k32.h);
            qy1.c0(ay4Var, k32.d, ka8VarC0);
            String strU = xi7.U(ay4Var, R.string.ui_templates__templates);
            ir8.a(ay4Var).getClass();
            ske.b(strU, ha8Var, 0L, null, 0L, null, null, null, 0L, null, 0L, 0, false, 0, 0, null, zle.I, ay4Var, 48, 0, 131068);
            ay4Var = ay4Var;
            rvi.b(function0, null, false, null, 0L, ay4Var, i2 & 14, 30);
            ay4Var.r(true);
        } else {
            ay4Var.a0();
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new r8(function0, i, 10);
        }
    }

    public static final void c(ka8 ka8Var, n12 n12Var, s32 s32Var, int i) {
        ay4 ay4Var = (ay4) s32Var;
        ay4Var.h0(1244466000);
        int i2 = 2;
        int i3 = (ay4Var.g(ka8Var) ? 4 : 2) | i;
        byte b2 = 0;
        int i4 = 1;
        if (ay4Var.X(i3 & 1, (i3 & 19) != 18)) {
            wdc wdcVarS0 = bp.s0(ay4Var);
            long j = du1.b(ay4Var).b.d;
            boolean zF = ay4Var.f(j);
            Object objS = ay4Var.S();
            if (zF || objS == q32.a) {
                objS = new t87(j, i2, b2);
                ay4Var.p0(objS);
            }
            cw4 cw4Var = (cw4) objS;
            ka8Var.getClass();
            wdcVarS0.getClass();
            ka8 ka8VarT0 = bp.t0(cw4Var == null ? ka8Var : tz0.L(ka8Var, wdcVarS0, new iy2(1, cw4Var)), wdcVarS0, true);
            bp.d0(ay4Var).getClass();
            ka8 ka8VarE0 = s4g.e0(ka8VarT0, 0.0f, 0.0f, 0.0f, 8.0f, 7);
            bp.d0(ay4Var).getClass();
            ax1 ax1VarA = zw1.a(new g70(24.0f, true, new sf(false)), hr1.V, ay4Var, 0);
            int iHashCode = Long.hashCode(ay4Var.T);
            jda jdaVarM = ay4Var.m();
            ka8 ka8VarC0 = h76.C0(ay4Var, ka8VarE0);
            l32.c.getClass();
            s42 s42Var = k32.b;
            ay4Var.j0();
            if (ay4Var.S) {
                ay4Var.l(s42Var);
            } else {
                ay4Var.s0();
            }
            qy1.c0(ay4Var, k32.f, ax1VarA);
            qy1.c0(ay4Var, k32.e, jdaVarM);
            qy1.c0(ay4Var, k32.g, Integer.valueOf(iHashCode));
            qy1.Z(ay4Var, k32.h);
            qy1.c0(ay4Var, k32.d, ka8VarC0);
            f92.t(6, n12Var, ay4Var, true);
        } else {
            ay4Var.a0();
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new wlc(ka8Var, n12Var, i, i4);
        }
    }

    public static final void d(Function0 function0, s32 s32Var, int i) {
        Function0 function1;
        function0.getClass();
        ay4 ay4Var = (ay4) s32Var;
        ay4Var.h0(1983795702);
        if (ay4Var.X(i & 1, (i & 3) != 2)) {
            function1 = function0;
            ati.a(function1, new ld3(3, false, false), tz0.I(860287935, new km9(7, function0), ay4Var), ay4Var, 438, 0);
        } else {
            function1 = function0;
            ay4Var.a0();
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new km9(function1, i, 8);
        }
    }

    public static final void e(Function0 function0, s32 s32Var, int i) {
        int i2;
        boolean z;
        function0.getClass();
        ay4 ay4Var = (ay4) s32Var;
        ay4Var.h0(-1082034721);
        if ((i & 6) == 0) {
            i2 = (ay4Var.i(function0) ? 4 : 2) | i;
        } else {
            i2 = i;
        }
        if (ay4Var.X(i2 & 1, (i2 & 3) != 2)) {
            ouf oufVarB = u68.b(ay4Var);
            wbe wbeVar = (wbe) ((er0) ccg.b(dlb.a.b(wbe.class), oufVarB, null, (iuf) ay4Var.k(u68.a), oufVarB instanceof hc5 ? ((hc5) oufVarB).getDefaultViewModelCreationExtras() : an2.b, ay4Var));
            ci8 ci8VarH = qy1.h(wbeVar.g(), ay4Var);
            boolean zI = ay4Var.i(wbeVar);
            Object objS = ay4Var.S();
            rab rabVar = q32.a;
            if (zI || objS == rabVar) {
                objS = new sbe(wbeVar, null, 0);
                ay4Var.p0(objS);
            }
            ny7.k(ay4Var, (cw4) objS, null);
            Object objS2 = ay4Var.S();
            if (objS2 == rabVar) {
                objS2 = lmi.T(lbe.I);
                ay4Var.p0(objS2);
            }
            ci8 ci8Var = (ci8) objS2;
            ha8 ha8Var = ha8.I;
            ka8 ka8VarO = p5c.o(ay4Var, kad.d(ha8Var, 1.0f), 24.0f);
            bp.d0(ay4Var).getClass();
            ax1 ax1VarA = zw1.a(new g70(16.0f, true, new sf(false)), hr1.W, ay4Var, 48);
            int iHashCode = Long.hashCode(ay4Var.T);
            jda jdaVarM = ay4Var.m();
            ka8 ka8VarC0 = h76.C0(ay4Var, ka8VarO);
            l32.c.getClass();
            s42 s42Var = k32.b;
            ay4Var.j0();
            if (ay4Var.S) {
                ay4Var.l(s42Var);
            } else {
                ay4Var.s0();
            }
            qy1.c0(ay4Var, k32.f, ax1VarA);
            qy1.c0(ay4Var, k32.e, jdaVarM);
            qy1.c0(ay4Var, k32.g, Integer.valueOf(iHashCode));
            qy1.Z(ay4Var, k32.h);
            qy1.c0(ay4Var, k32.d, ka8VarC0);
            b(function0, ay4Var, i2 & 14);
            n12 n12VarI = tz0.I(1574533808, new gw1(ci8Var, 13, (byte) 0), ay4Var);
            n12 n12VarI2 = tz0.I(145246168, new gud(5, wbeVar, ci8VarH), ay4Var);
            qa4 qa4Var = qa4.a;
            boolean zA = qa4.a(fa4.T0);
            bx1 bx1Var = bx1.a;
            if (zA) {
                ay4Var.g0(-1941909051);
                int iOrdinal = ((lbe) ci8Var.getValue()).ordinal();
                if (iOrdinal == 0) {
                    z = false;
                    ay4Var.g0(491548982);
                    c(bx1Var.a(1.0f, ha8Var, true), tz0.I(1545516802, new gud(6, n12VarI, n12VarI2), ay4Var), ay4Var, 48);
                    ay4Var.r(false);
                } else {
                    if (iOrdinal != 1) {
                        throw b7d.m(ay4Var, 491547101, false);
                    }
                    ay4Var.g0(491554843);
                    c(bx1Var.a(1.0f, ha8Var, true), tz0.I(230791403, new zg(n12VarI, 15), ay4Var), ay4Var, 48);
                    z = false;
                    ay4Var.r(false);
                }
                ay4Var.r(z);
            } else {
                ay4Var.g0(491561636);
                c(bx1Var.a(1.0f, ha8Var, true), tz0.I(-1822637549, new zg(n12VarI2, 16), ay4Var), ay4Var, 48);
                ay4Var.r(false);
            }
            boolean zI2 = ay4Var.i(wbeVar);
            Object objS3 = ay4Var.S();
            if (zI2 || objS3 == rabVar) {
                e95 e95Var = new e95(0, wbeVar, wbe.class, "onUpdateNoteBackground", "onUpdateNoteBackground()Lkotlinx/coroutines/Job;", 8, 4);
                ay4Var.p0(e95Var);
                objS3 = e95Var;
            }
            a((Function0) objS3, function0, ay4Var, (i2 << 3) & 112);
            ay4Var.r(true);
        } else {
            ay4Var.a0();
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new r8(function0, i, 11);
        }
    }

    /* JADX WARN: Code duplicated, block: B:117:0x0233 A[EDGE_INSN: B:117:0x0233->B:92:0x0233 BREAK  A[LOOP:3: B:54:0x01a2->B:91:0x022f, LOOP_LABEL: LOOP:3: B:54:0x01a2->B:91:0x022f], SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:118:0x0233 A[EDGE_INSN: B:118:0x0233->B:92:0x0233 BREAK  A[LOOP:3: B:54:0x01a2->B:91:0x022f], SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:120:0x0233 A[EDGE_INSN: B:120:0x0233->B:92:0x0233 BREAK  A[LOOP:3: B:54:0x01a2->B:91:0x022f, LOOP_LABEL: LOOP:3: B:54:0x01a2->B:91:0x022f], SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:128:? A[LOOP:6: B:71:0x01e1->B:128:?, LOOP_END, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:70:0x01dd  */
    /* JADX WARN: Code duplicated, block: B:73:0x01e7  */
    /* JADX WARN: Code duplicated, block: B:75:0x01f4  */
    /* JADX WARN: Code duplicated, block: B:76:0x01f7  */
    /* JADX WARN: Code duplicated, block: B:81:0x01fe  */
    /* JADX WARN: Code duplicated, block: B:83:0x0214  */
    /* JADX WARN: Code duplicated, block: B:86:0x021b  */
    /* JADX WARN: Code duplicated, block: B:89:0x0225  */
    public static yy5 f(ArrayList arrayList, double d, int i, a81 a81Var, a81 a81Var2, int i2) {
        Iterator it;
        boolean z;
        List listSubList;
        Iterator it2;
        ArrayList arrayList2;
        ix9 ix9Var;
        a81Var2.getClass();
        ArrayList arrayList3 = new ArrayList();
        ArrayList arrayList4 = new ArrayList();
        int i3 = i;
        int i4 = 0;
        while (true) {
            boolean z2 = true;
            if (i4 >= arrayList.size()) {
                int size = arrayList3.size();
                int i5 = 0;
                while (i5 < size) {
                    a81 a81VarJ = i5 > 0 ? ((gp2) arrayList3.get(i5 - 1)).j(1.0d, a81Var2) : a81Var;
                    if (a81VarJ != null) {
                        gp2 gp2Var = (gp2) arrayList3.get(i5);
                        gp2 gp2Var2 = (gp2) arrayList3.get(i5);
                        a81 a81Var3 = gp2Var.b;
                        a81 a81Var4 = gp2Var.a;
                        double d2 = a81Var3.a - a81Var4.a;
                        double d3 = a81Var3.b - a81Var4.b;
                        double d4 = a81VarJ.a;
                        double d5 = a81VarJ.b;
                        double dSqrt = Math.sqrt((d5 * d5) + (d4 * d4));
                        if (dSqrt == 0.0d) {
                            a81Var2.a = d2;
                            a81Var2.b = d3;
                        } else {
                            double d6 = d4 / dSqrt;
                            double d7 = d5 / dSqrt;
                            double d8 = (d3 * d7) + (d2 * d6);
                            a81Var2.a = d6 * d8;
                            a81Var2.b = d7 * d8;
                        }
                        gp2Var2.b = a81Var2.d(a81Var4);
                    } else {
                        i5 = i5;
                    }
                    i5++;
                    z2 = z2;
                }
                boolean z3 = z2;
                int size2 = arrayList3.size() - 1;
                int i6 = 0;
                int i7 = 0;
                loop3: while (i6 < size2) {
                    ng4 ng4Var = (ng4) arrayList4.get(i6);
                    int i8 = ng4Var.c;
                    int i9 = ng4Var.d;
                    List listSubList2 = arrayList.subList(i8, i9 + 1);
                    if (listSubList2 == null || !listSubList2.isEmpty()) {
                        Iterator it3 = listSubList2.iterator();
                        while (it3.hasNext()) {
                            if (((ke2) it3.next()).h) {
                                break loop3;
                            }
                        }
                        if (listSubList2 != null || !listSubList2.isEmpty()) {
                            it = listSubList2.iterator();
                            while (it.hasNext()) {
                                if ((((ke2) it.next()).i & ke2.j) == 0) {
                                    z = z3;
                                } else {
                                    z = false;
                                }
                                if (!z) {
                                    break loop3;
                                }
                            }
                            if (i9 >= i2) {
                                break;
                            }
                            i6++;
                            ng4 ng4Var2 = (ng4) arrayList4.get(i6);
                            listSubList = arrayList.subList(ng4Var2.c + 1, ng4Var2.d + 1);
                            if (listSubList == null && listSubList.isEmpty()) {
                                break;
                            }
                            it2 = listSubList.iterator();
                            do {
                                if (!it2.hasNext()) {
                                    break loop3;
                                }
                            } while (((ke2) it2.next()).h);
                            i7++;
                        } else {
                            if (i9 >= i2) {
                                break;
                                break;
                            }
                            i6++;
                            ng4 ng4Var3 = (ng4) arrayList4.get(i6);
                            listSubList = arrayList.subList(ng4Var3.c + 1, ng4Var3.d + 1);
                            if (listSubList == null) {
                                it2 = listSubList.iterator();
                                do {
                                    if (!it2.hasNext()) {
                                        break loop3;
                                        break loop3;
                                    }
                                } while (((ke2) it2.next()).h);
                                i7++;
                            } else {
                                it2 = listSubList.iterator();
                                do {
                                    if (!it2.hasNext()) {
                                        break loop3;
                                        break loop3;
                                    }
                                } while (((ke2) it2.next()).h);
                                i7++;
                            }
                        }
                    } else if (listSubList2 != null) {
                        it = listSubList2.iterator();
                        while (it.hasNext()) {
                            if ((((ke2) it.next()).i & ke2.j) == 0) {
                                z = z3;
                            } else {
                                z = false;
                            }
                            if (!z) {
                                break loop3;
                                break loop3;
                            }
                        }
                        if (i9 >= i2) {
                            break;
                            break;
                        }
                        i6++;
                        ng4 ng4Var4 = (ng4) arrayList4.get(i6);
                        listSubList = arrayList.subList(ng4Var4.c + 1, ng4Var4.d + 1);
                        if (listSubList == null) {
                            it2 = listSubList.iterator();
                            do {
                                if (!it2.hasNext()) {
                                    break loop3;
                                    break loop3;
                                }
                            } while (((ke2) it2.next()).h);
                            i7++;
                        } else {
                            it2 = listSubList.iterator();
                            do {
                                if (!it2.hasNext()) {
                                    break loop3;
                                    break loop3;
                                }
                            } while (((ke2) it2.next()).h);
                            i7++;
                        }
                    } else {
                        it = listSubList2.iterator();
                        while (it.hasNext()) {
                            if ((((ke2) it.next()).i & ke2.j) == 0) {
                                z = z3;
                            } else {
                                z = false;
                            }
                            if (!z) {
                                break loop3;
                                break loop3;
                            }
                        }
                        if (i9 >= i2) {
                            break;
                            break;
                        }
                        i6++;
                        ng4 ng4Var5 = (ng4) arrayList4.get(i6);
                        listSubList = arrayList.subList(ng4Var5.c + 1, ng4Var5.d + 1);
                        if (listSubList == null) {
                            it2 = listSubList.iterator();
                            do {
                                if (!it2.hasNext()) {
                                    break loop3;
                                    break loop3;
                                }
                            } while (((ke2) it2.next()).h);
                            i7++;
                        } else {
                            it2 = listSubList.iterator();
                            do {
                                if (!it2.hasNext()) {
                                    break loop3;
                                    break loop3;
                                }
                            } while (((ke2) it2.next()).h);
                            i7++;
                        }
                    }
                }
                ArrayList<ix9> arrayListY1 = zs1.Y1(arrayList3, arrayList4);
                ArrayList arrayList5 = new ArrayList(bt1.H0(arrayListY1, 10));
                for (ix9 ix9Var2 : arrayListY1) {
                    arrayList5.add(new eq2((gp2) ix9Var2.I, (ng4) ix9Var2.J));
                }
                return new yy5(i7, arrayList5);
            }
            int size3 = arrayList.size();
            int i10 = size3 - 1;
            gp2 gp2VarH = h(i3, arrayList, d, a81Var2, i10);
            int i11 = i10;
            if (gp2VarH != null) {
                ix9Var = new ix9(new ng4(Math.max(0, i3 - 5), Math.min(arrayList.size() - 1, size3 + 4), i3, i11), gp2VarH);
                arrayList2 = arrayList;
            } else {
                int i12 = i3 + 1;
                int i13 = i3;
                wy5 wy5Var = new wy5(i13, arrayList, d, a81Var2);
                arrayList2 = arrayList;
                if (wy5Var.invoke(Integer.valueOf(i12)) == null) {
                    yz3.r("Failed requirement.");
                    return null;
                }
                if (wy5Var.invoke(Integer.valueOf(i11)) != null) {
                    yz3.r("Failed requirement.");
                    return null;
                }
                if (i11 <= i12) {
                    yz3.r("Failed requirement.");
                    return null;
                }
                gp2 gp2Var3 = null;
                while (i11 > i12 + 1) {
                    int i14 = (i11 + i12) / 2;
                    gp2 gp2Var4 = (gp2) wy5Var.invoke(Integer.valueOf(i14));
                    if (gp2Var4 != null) {
                        i12 = i14;
                        gp2Var3 = gp2Var4;
                    } else {
                        i11 = i14;
                    }
                }
                if (gp2Var3 == null) {
                    gp2Var3 = (gp2) wy5Var.invoke(Integer.valueOf(i12));
                }
                if (gp2Var3 == null) {
                    yz3.l("eval from before should return not null value");
                    return null;
                }
                ix9Var = new ix9(new ng4(Math.max(0, i13 - 5), Math.min(arrayList2.size() - 1, i12 + 5), i13, i12), gp2Var3);
            }
            ng4 ng4Var6 = (ng4) ix9Var.I;
            gp2 gp2VarG = (gp2) ix9Var.J;
            if (ng4Var6.d < arrayList2.size() - 1) {
                int i15 = ng4Var6.c;
                int i16 = (ng4Var6.d + i15) / 2;
                ng4 ng4Var7 = new ng4(Math.max(0, i15 - 5), Math.min(arrayList2.size() - 1, i16 + 5), i15, i16);
                if ((i16 - i15) + 1 >= 4 && arrayList2.size() - i16 >= 4) {
                    gp2VarG = g(arrayList2, ng4Var7);
                    ng4Var6 = ng4Var7;
                }
            }
            arrayList3.add(gp2VarG);
            arrayList4.add(ng4Var6);
            i3 = ng4Var6.d;
            i4 = i3 + 1;
        }
    }

    public static gp2 g(ArrayList arrayList, ng4 ng4Var) {
        int i;
        int i2;
        int i3;
        int i4;
        int i5 = ng4Var.a;
        int i6 = ng4Var.b;
        int i7 = ng4Var.d;
        int i8 = ng4Var.c;
        if (i5 > i8) {
            yz3.r("Failed requirement.");
            return null;
        }
        if (i6 < i7) {
            yz3.r("Failed requirement.");
            return null;
        }
        int i9 = (i6 - i5) + 1;
        gg8 gg8Var = new gg8(i9);
        gg8 gg8Var2 = new gg8(i9);
        double[] dArrCopyOf = i9 == 0 ? w76.a : new double[i9];
        if (i5 <= i6) {
            int i10 = 0;
            while (true) {
                ke2 ke2Var = (ke2) arrayList.get(i5);
                i = 2;
                gg8Var.a(ke2Var.a);
                gg8Var2.a(ke2Var.b);
                int i11 = i10;
                double d = i8;
                i2 = 3;
                double d2 = (((double) i5) - d) / (((double) i7) - d);
                i4 = i11 + 1;
                if (dArrCopyOf.length < i4) {
                    dArrCopyOf = Arrays.copyOf(dArrCopyOf, Math.max(i4, (dArrCopyOf.length * 3) / 2));
                }
                dArrCopyOf[i11] = d2;
                if (i5 == i6) {
                    break;
                }
                i5++;
                i10 = i4;
            }
            i3 = i4;
        } else {
            i = 2;
            i2 = 3;
            i3 = 0;
        }
        ke2 ke2Var2 = (ke2) arrayList.get(i8);
        a81 a81Var = new a81(ke2Var2.a, ke2Var2.b);
        ke2 ke2Var3 = (ke2) arrayList.get(i7);
        a81 a81Var2 = new a81(ke2Var3.a, ke2Var3.b);
        int i12 = gg8Var.b;
        if (i12 == 1) {
            return new gp2(new a81(gg8Var.b(0), gg8Var2.b(0)), new a81(gg8Var.b(0), gg8Var2.b(0)), new a81(gg8Var.b(0), gg8Var2.b(0)), new a81(gg8Var.b(0), gg8Var2.b(0)));
        }
        if (i12 == i) {
            a81 a81Var3 = new a81(gg8Var.b(0), gg8Var2.b(0));
            double dB = gg8Var.b(1);
            double dB2 = gg8Var2.b(1);
            a81 a81Var4 = new a81(dB, dB2);
            double d3 = a81Var3.a;
            double d4 = dB * 0.3333333333333333d;
            double d5 = a81Var3.b;
            return new gp2(a81Var3, new a81(d4 + (d3 * 0.6666666666666666d), (dB2 * 0.3333333333333333d) + (d5 * 0.6666666666666666d)), new a81((dB * 0.6666666666666666d) + (d3 * 0.3333333333333333d), (dB2 * 0.6666666666666666d) + (d5 * 0.3333333333333333d)), a81Var4);
        }
        if (i12 == i2) {
            a81 a81Var5 = new a81(gg8Var.b(0), gg8Var2.b(0));
            double dB3 = (gg8Var.b(1) * 2.0d) - ((gg8Var.b(2) + gg8Var.b(0)) * 0.5d);
            double dB4 = (gg8Var2.b(1) * 2.0d) - ((gg8Var2.b(2) + gg8Var2.b(0)) * 0.5d);
            a81 a81Var6 = new a81(gg8Var.b(2), gg8Var2.b(2));
            kv8 kv8Var = n2b.b;
            cj6[] cj6VarArr = n2b.a;
            double d6 = dB3 * 0.6666666666666666d;
            double d7 = dB4 * 0.6666666666666666d;
            return new gp2(a81Var5, new a81((a81Var5.a * 0.3333333333333333d) + d6, (a81Var5.b * 0.3333333333333333d) + d7), new a81((a81Var6.a * 0.3333333333333333d) + d6, (a81Var6.b * 0.3333333333333333d) + d7), a81Var6);
        }
        double d8 = 0.0d;
        double d9 = 0.0d;
        double d10 = 0.0d;
        double d11 = 0.0d;
        double d12 = 0.0d;
        double d13 = 0.0d;
        int i13 = 0;
        double d14 = 0.0d;
        while (i13 < i12) {
            if (i13 < 0 || i13 >= i3) {
                r14.l("Index must be between 0 and size");
                return null;
            }
            double d15 = dArrCopyOf[i13];
            double d16 = 1.0d - d15;
            double d17 = d16 * d16 * d16;
            double d18 = 3.0d * d16;
            double d19 = d16 * d18 * d15;
            double d20 = d18 * d15 * d15;
            double d21 = d15 * d15 * d15;
            double dB5 = (gg8Var.b(i13) - (a81Var.a * d17)) - (a81Var2.a * d21);
            double dB6 = (gg8Var2.b(i13) - (d17 * a81Var.b)) - (d21 * a81Var2.b);
            d8 = (d19 * d19) + d8;
            d14 = (d19 * d20) + d14;
            d9 = (d20 * d20) + d9;
            d11 = (d19 * dB5) + d11;
            d12 = (d19 * dB6) + d12;
            d10 = (dB5 * d20) + d10;
            d13 = (d20 * dB6) + d13;
            i13++;
            dArrCopyOf = dArrCopyOf;
        }
        double d22 = (d8 * d9) - (d14 * d14);
        if (d22 <= 1.0E-9d * d8 * d9) {
            return i(a81Var, a81Var2);
        }
        double dA = f92.A(d14, d10, d9 * d11, d22);
        double dA2 = f92.A(d14, d13, d9 * d12, d22);
        double dA3 = f92.A(d14, d11, d8 * d10, d22);
        double dA4 = f92.A(d14, d12, d8 * d13, d22);
        return (Math.abs(dA) > Double.MAX_VALUE || Math.abs(dA2) > Double.MAX_VALUE || Math.abs(dA3) > Double.MAX_VALUE || Math.abs(dA4) > Double.MAX_VALUE) ? i(a81Var, a81Var2) : new gp2(a81Var, new a81(dA, dA2), new a81(dA3, dA4), a81Var2);
    }

    public static final gp2 h(int i, ArrayList arrayList, double d, a81 a81Var, int i2) {
        int size = arrayList.size();
        int iMax = Math.max(0, i - 5);
        int iMin = Math.min(size - 1, i2 + 5);
        ng4 ng4Var = new ng4(iMax, iMin, i, i2);
        if (iMax > i) {
            yz3.r("Failed requirement.");
            return null;
        }
        if (iMin < i2) {
            yz3.r("Failed requirement.");
            return null;
        }
        int i3 = (i2 - i) + 1;
        if (i3 <= 200) {
            gp2 gp2VarG = g(arrayList, ng4Var);
            if (i3 > 2 && i <= i2) {
                double d2 = 0.0d;
                int i4 = i;
                while (true) {
                    double d3 = i;
                    a81 a81VarC = gp2VarG.c((((double) i4) - d3) / (((double) i2) - d3), a81Var);
                    ke2 ke2Var = (ke2) arrayList.get(i4);
                    double dL0 = w76.l0(a81VarC.a - ke2Var.a, a81VarC.b - ke2Var.b);
                    if (dL0 > 1.0E-12d && Math.abs(dL0) <= Double.MAX_VALUE && dL0 > d2) {
                        if (dL0 > d) {
                            break;
                        }
                        d2 = dL0;
                    }
                    if (i4 != i2) {
                        i4++;
                    }
                }
            }
            return gp2VarG;
        }
        return null;
    }

    public static gp2 i(a81 a81Var, a81 a81Var2) {
        double d = a81Var2.a;
        double d2 = a81Var.a;
        double d3 = (d - d2) / 3.0d;
        double d4 = a81Var2.b;
        double d5 = a81Var.b;
        double d6 = (d4 - d5) / 3.0d;
        return new gp2(a81Var, new a81(d2 + d3, d5 + d6), new a81(d - d3, d4 - d6), a81Var2);
    }
}
