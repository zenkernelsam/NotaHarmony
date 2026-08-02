package defpackage;

import android.graphics.BlendMode;
import android.graphics.Path;
import com.gingerlabs.notability.core.common.logging.a;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/* JADX INFO: loaded from: classes.dex */
public final class hz5 extends m3e implements cw4 {
    public int I;
    public int J;
    public final /* synthetic */ int K;
    public final /* synthetic */ Set L;
    public final /* synthetic */ oz5 M;
    public final /* synthetic */ Long N;
    public final /* synthetic */ ex8 O;
    public final /* synthetic */ boolean P;
    public final /* synthetic */ Map Q;
    public final /* synthetic */ Set R;
    public final /* synthetic */ Set S;
    public final /* synthetic */ BlendMode T;
    public final /* synthetic */ boolean U;
    public final /* synthetic */ Set V;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public hz5(int i, Set set, oz5 oz5Var, Long l, ex8 ex8Var, boolean z, Map map, Set set2, Set set3, BlendMode blendMode, boolean z2, Set set4, ce2 ce2Var) {
        super(2, ce2Var);
        this.K = i;
        this.L = set;
        this.M = oz5Var;
        this.N = l;
        this.O = ex8Var;
        this.P = z;
        this.Q = map;
        this.R = set2;
        this.S = set3;
        this.T = blendMode;
        this.U = z2;
        this.V = set4;
    }

    /* JADX WARN: Code duplicated, block: B:16:0x0045  */
    /* JADX WARN: Code duplicated, block: B:17:0x0050  */
    /* JADX WARN: Code duplicated, block: B:20:0x0056  */
    /* JADX WARN: Code duplicated, block: B:27:0x0067  */
    /* JADX WARN: Code duplicated, block: B:29:0x006a  */
    /* JADX WARN: Code duplicated, block: B:31:0x0075  */
    /* JADX WARN: Code duplicated, block: B:32:0x0077  */
    /* JADX WARN: Code duplicated, block: B:34:0x007f A[LOOP:0: B:33:0x007d->B:34:0x007f, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:36:0x00af  */
    /* JADX WARN: Code duplicated, block: B:41:0x00f1  */
    /* JADX WARN: Code duplicated, block: B:78:0x017e  */
    public static final xrd g(boolean z, oz5 oz5Var, Map map, Set set, Set set2, BlendMode blendMode, boolean z2, boolean z3, boolean z4, Set set3, ry5 ry5Var, ee0 ee0Var) throws Throwable {
        iae iaeVar;
        Path path;
        Path path2;
        xw0 xw0VarB;
        haa haaVar;
        haa haaVarT;
        Path pathN;
        Float f;
        ArrayList arrayList;
        float fFloatValue;
        int iFloatValue;
        ArrayList arrayList2;
        int i;
        tz5 tz5Var = tz5.TAPE;
        if (z && ry5Var.k == tz5.PENCIL) {
            zq7 zq7Var = oz5Var.r;
            if (!ry5Var.I()) {
                haa haaVar2 = (haa) zq7Var.c(ry5Var);
                if (haaVar2 == null) {
                    haaVarT = oz5Var.t(ry5Var);
                    zq7Var.d(ry5Var, haaVarT);
                } else {
                    haaVar = haaVar2;
                }
                if (set2.contains(ry5Var.getId())) {
                    pathN = ny7.N(ry5Var.Q());
                } else {
                    pathN = null;
                }
                f = ee0Var.b;
                if (f != null) {
                    fFloatValue = f.floatValue();
                    if (fFloatValue > 0.0f || fFloatValue >= 1.0f || ee0Var.a == null) {
                        f = null;
                    }
                    if (f != null) {
                        iFloatValue = (int) (haaVar.e * f.floatValue());
                        if (iFloatValue <= 0) {
                            arrayList2 = null;
                        } else {
                            arrayList2 = new ArrayList(iFloatValue);
                            for (i = 0; i < iFloatValue; i++) {
                                int i2 = i * 20;
                                arrayList2.add(new faa(haaVar.c.getFloat(i2), haaVar.c.getFloat(i2 + 4), haaVar.i(i), haaVar.c.getFloat(i2 + 12), haaVar.c(i)));
                            }
                        }
                        arrayList = arrayList2;
                    } else {
                        arrayList = null;
                    }
                } else {
                    arrayList = null;
                }
                return new wrd(oz5.h(ry5Var, map), haaVar, pathN, ry5Var.c0(), hu8.c(n5d.V(ry5Var.T()), z2), blendMode, set.contains(ry5Var.getId()), ry5Var.P(null), null, null, ee0Var.a, ee0Var.b, arrayList, 768);
            }
            haaVarT = oz5Var.t(ry5Var);
            haaVar = haaVarT;
            if (set2.contains(ry5Var.getId())) {
                pathN = ny7.N(ry5Var.Q());
            } else {
                pathN = null;
            }
            f = ee0Var.b;
            if (f != null) {
                fFloatValue = f.floatValue();
                if (fFloatValue > 0.0f) {
                    f = null;
                } else {
                    f = null;
                }
                if (f != null) {
                    iFloatValue = (int) (haaVar.e * f.floatValue());
                    if (iFloatValue <= 0) {
                        arrayList2 = null;
                    } else {
                        arrayList2 = new ArrayList(iFloatValue);
                        while (i < iFloatValue) {
                            int i3 = i * 20;
                            arrayList2.add(new faa(haaVar.c.getFloat(i3), haaVar.c.getFloat(i3 + 4), haaVar.i(i), haaVar.c.getFloat(i3 + 12), haaVar.c(i)));
                        }
                    }
                    arrayList = arrayList2;
                } else {
                    arrayList = null;
                }
            } else {
                arrayList = null;
            }
            return new wrd(oz5.h(ry5Var, map), haaVar, pathN, ry5Var.c0(), hu8.c(n5d.V(ry5Var.T()), z2), blendMode, set.contains(ry5Var.getId()), ry5Var.P(null), null, null, ee0Var.a, ee0Var.b, arrayList, 768);
        }
        List listU = ry5Var.U();
        List listW = ry5Var.W();
        if (z3) {
            iae iaeVarB0 = ry5Var.b0();
            if (iaeVarB0 == null) {
                if (ry5Var.k == tz5Var) {
                    iaeVarB0 = iae.STRIPES;
                } else {
                    iaeVar = null;
                }
            }
            iaeVar = iaeVarB0;
        } else {
            iaeVar = null;
        }
        if (!z4 || oz5.u.contains(ry5Var.Z()) || listU != null || listW != null) {
            long jH = oz5.h(ry5Var, map);
            Path pathN2 = ny7.N(ry5Var.Q());
            float fC0 = ry5Var.c0();
            int iC = hu8.c(n5d.V(ry5Var.T()), z2);
            boolean zContains = set.contains(ry5Var.getId());
            boolean zContains2 = set2.contains(ry5Var.getId());
            float[] fArrP = ry5Var.P(null);
            gt1 gt1VarV = ry5Var.V();
            return new vrd(jH, pathN2, fC0, iC, blendMode, zContains, zContains2, fArrP, gt1VarV != null ? Integer.valueOf(hu8.c(n5d.V(gt1VarV), z2)) : null, listU != null ? ny7.N(listU) : null, listW != null ? ny7.N(listW) : null, null, ry5Var.Z(), null, ee0Var.a, ee0Var.b, iaeVar, hu8.c(-1, z2), 10240);
        }
        Float f2 = ee0Var.b;
        if (f2 != null) {
            float fFloatValue2 = f2.floatValue();
            if (fFloatValue2 <= 0.0f || fFloatValue2 >= 1.0f) {
                f2 = null;
            }
            if (f2 != null) {
                float fFloatValue3 = f2.floatValue();
                pz5 pz5Var = oz5Var.a;
                xw0 xw0Var = xw0.f;
                s8d s8dVar = pz5Var.b;
                r8d r8dVar = kx0.a;
                if (fFloatValue3 >= 1.0f) {
                    xw0VarB = kx0.c(ry5Var, ry5Var.S(), s8dVar);
                } else if (fFloatValue3 <= 0.0f) {
                    xw0VarB = xw0.f;
                } else {
                    xw0 xw0VarB2 = qxi.b(kx0.d(ry5Var.Q(), s8dVar), fFloatValue3);
                    xw0VarB = xw0VarB2.a.isEmpty() ? xw0.f : w4a.b(w4a.a(xw0VarB2, 0.0d), ry5Var.c0());
                }
                Path pathR = xw0VarB.r();
                if (pathR.isEmpty()) {
                    pathR = null;
                }
                path = pathR;
            } else {
                path = null;
            }
        } else {
            path = null;
        }
        xw0 xw0VarD = oz5Var.a.d(ry5Var);
        if (ry5Var.k == tz5Var && set3.contains(ry5Var.getId())) {
            pz5 pz5Var2 = oz5Var.a;
            zq7 zq7Var2 = pz5Var2.d;
            Path path3 = (Path) zq7Var2.c(ry5Var);
            if (path3 == null) {
                path3 = new Path(pz5Var2.d(ry5Var).r());
                zq7Var2.d(ry5Var, path3);
            }
            path2 = path3;
        } else {
            path2 = null;
        }
        long jH2 = oz5.h(ry5Var, map);
        Path pathR2 = xw0VarD.r();
        Iterator it = xw0VarD.a.iterator();
        int i4 = 0;
        while (it.hasNext()) {
            i4 += ((i4a) it.next()).b.b;
        }
        return new urd(jH2, pathR2, set2.contains(ry5Var.getId()) ? ny7.N(ry5Var.Q()) : null, ry5Var.c0(), hu8.c(n5d.V(ry5Var.T()), z2), blendMode, set.contains(ry5Var.getId()), ry5Var.P(null), ee0Var.a, ee0Var.b, path, i4, iaeVar, hu8.c(-1, z2), path2);
    }

    @Override // defpackage.nq0
    public final ce2 create(Object obj, ce2 ce2Var) {
        return new hz5(this.K, this.L, this.M, this.N, this.O, this.P, this.Q, this.R, this.S, this.T, this.U, this.V, ce2Var);
    }

    @Override // defpackage.cw4
    public final Object invoke(Object obj, Object obj2) {
        return ((hz5) create((fh2) obj, (ce2) obj2)).invokeSuspend(bjf.a);
    }

    @Override // defpackage.nq0
    public final Object invokeSuspend(Object obj) {
        int i;
        Map mapK0;
        Object objG;
        hz5 hz5Var = this;
        final oz5 oz5Var = hz5Var.M;
        pz5 pz5Var = oz5Var.a;
        int i2 = hz5Var.J;
        if (i2 == 0) {
            ny7.F0(obj);
            int i3 = hz5Var.K;
            if (i3 < 1) {
                ArrayList arrayList = a.a;
                a.c(cl7.INK, "calculateForInks: non-positive parallelism", null, null);
                i3 = 1;
            }
            Set set = hz5Var.L;
            if (set.isEmpty()) {
                return su3.I;
            }
            int size = set.size();
            zq7 zq7Var = (zq7) ((ar7) pz5Var.c.K).J;
            if (size > 5000) {
                size = 5000;
            }
            n5d.F(zq7Var, size);
            Set<ry5> set2 = set;
            int i4 = 0;
            if (!(set2 instanceof Collection) || !set2.isEmpty()) {
                Iterator it = set2.iterator();
                while (it.hasNext()) {
                    if (((ry5) it.next()).I() && (i4 = i4 + 1) < 0) {
                        ny7.D0();
                        throw null;
                    }
                }
            }
            int i5 = i4;
            n5d.F((zq7) ((hda) pz5Var.c.J).J, i5);
            Long l = hz5Var.N;
            pcb pcbVar = l != null ? new pcb(l.longValue()) : null;
            ex8 ex8Var = hz5Var.O;
            List listN = ex8Var != null ? xs7.N(ex8Var) : null;
            if (listN == null) {
                listN = ru3.I;
            }
            qa4 qa4Var = qa4.a;
            final boolean zA = qa4.a(fa4.M);
            final boolean zA2 = qa4.a(fa4.s0);
            final List list = listN;
            final pcb pcbVar2 = pcbVar;
            boolean z = hz5Var.P;
            if (z) {
                ArrayList arrayList2 = new ArrayList(set);
                Collections.shuffle(arrayList2);
                int i6 = i3;
                final Map map = hz5Var.Q;
                final Set set3 = hz5Var.R;
                final Set set4 = hz5Var.S;
                final BlendMode blendMode = hz5Var.T;
                final boolean z2 = hz5Var.U;
                final boolean z3 = hz5Var.P;
                final Set set5 = hz5Var.V;
                i = i5;
                ov4 ov4Var = new ov4() { // from class: gz5
                    @Override // defpackage.ov4
                    public final Object invoke(Object obj2) {
                        ry5 ry5Var = (ry5) obj2;
                        rm5 id = ry5Var.getId();
                        oz5 oz5Var2 = oz5Var;
                        return new ix9(id, hz5.g(zA, oz5Var2, map, set3, set4, blendMode, z2, zA2, z3, set5, ry5Var, oz5.a(oz5Var2, ry5Var, pcbVar2, list)));
                    }
                };
                hz5Var.I = i;
                hz5Var.J = 1;
                objG = v72.G(arrayList2, i6, ov4Var, hz5Var);
                gh2 gh2Var = gh2.I;
                if (objG == gh2Var) {
                    return gh2Var;
                }
            } else {
                pcb pcbVar3 = pcbVar2;
                i = i5;
                boolean z4 = zA2;
                pz5Var = pz5Var;
                int iC0 = vv7.c0(bt1.H0(set2, 10));
                if (iC0 < 16) {
                    iC0 = 16;
                }
                LinkedHashMap linkedHashMap = new LinkedHashMap(iC0);
                for (ry5 ry5Var : set2) {
                    boolean z5 = z4;
                    LinkedHashMap linkedHashMap2 = linkedHashMap;
                    z4 = z5;
                    linkedHashMap2.put(ry5Var.getId(), g(zA, oz5Var, hz5Var.Q, hz5Var.R, hz5Var.S, hz5Var.T, hz5Var.U, z5, z, hz5Var.V, ry5Var, oz5.a(oz5Var, ry5Var, pcbVar3, list)));
                    linkedHashMap = linkedHashMap2;
                    pcbVar3 = pcbVar3;
                    hz5Var = this;
                }
                mapK0 = linkedHashMap;
            }
            ((zq7) ((hda) pz5Var.c.J).J).i(i);
            return mapK0;
        }
        if (i2 != 1) {
            yz3.l("call to 'resume' before 'invoke' with coroutine");
            return null;
        }
        int i7 = hz5Var.I;
        ny7.F0(obj);
        i = i7;
        objG = obj;
        mapK0 = vv7.k0((Iterable) objG);
        ((zq7) ((hda) pz5Var.c.J).J).i(i);
        return mapK0;
    }
}
