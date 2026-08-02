package defpackage;

import com.google.android.gms.common.api.Api;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public final class ms1 {
    public final mvf a;
    public final js1 b;
    public final js1 c;
    public final yc4 d;
    public final vy5 e;
    public float f;
    public dr4 g;
    public final ArrayList h;
    public final ArrayList i;

    public ms1(fh2 fh2Var, yg2 yg2Var, mvf mvfVar, js1 js1Var) {
        fh2Var.getClass();
        this.a = mvfVar;
        this.b = js1Var;
        this.c = js1Var;
        p7j p7jVar = jp3.J;
        dr4 dr4Var = new dr4(0.15f, sdg.s0(8L, np3.MILLISECONDS), true);
        yc4 yc4Var = new yc4();
        yc4Var.I = ns1.a;
        d30 d30Var = new d30(22, false);
        d30Var.J = dr4Var;
        yc4Var.J = d30Var;
        this.d = yc4Var;
        this.e = new vy5(js1Var);
        this.f = 1.0f;
        vi2.A(fh2Var, yg2Var, null, new w40(this, null, 1), 2);
        this.h = new ArrayList();
        this.i = new ArrayList();
    }

    public final void a() {
        vy5 vy5Var = this.e;
        vy5Var.g();
        js1 js1Var = vy5Var.b;
        rm5 rm5Var = js1Var.l;
        if (rm5Var == null) {
            return;
        }
        if (rm5Var == null) {
            yz3.l("active ink should be set");
            return;
        }
        tz5 tz5Var = js1Var.m;
        vi2.A(js1Var.k, null, null, new gs1(js1Var, tz5Var == tz5.WHOLE_ERASER || tz5Var == tz5.PARTIAL_ERASER, rm5Var, (ce2) null, 0), 3);
        js1Var.e();
    }

    /* JADX WARN: Code duplicated, block: B:59:0x01a9  */
    public final ix9 b(ns1[] ns1VarArr, ns1 ns1Var) {
        ccd ccdVar;
        yc4 yc4Var;
        ArrayList arrayListB;
        ArrayList arrayList = this.h;
        arrayList.clear();
        ArrayList arrayList2 = this.i;
        arrayList2.clear();
        ArrayList arrayList3 = new ArrayList();
        int length = ns1VarArr.length;
        int i = 0;
        bq5 bq5Var = null;
        while (true) {
            ccdVar = ccd.J;
            yc4Var = this.d;
            if (i >= length) {
                break;
            }
            List listAsList = Arrays.asList(yc4.a(yc4Var, ns1VarArr[i], false));
            listAsList.getClass();
            z4 z4VarH = ccdVar.h(listAsList);
            if (ns1Var != null) {
                List listAsList2 = Arrays.asList(yc4.a(yc4Var, ns1Var, true));
                listAsList2.getClass();
                z4 z4VarH2 = ccdVar.h(listAsList2);
                if (z4VarH2 != null) {
                    ccdVar = z4VarH2;
                }
            }
            le2 le2Var = new le2(z4VarH, ccdVar);
            bq5 bq5VarA = le2Var.a();
            bq5 bq5VarB = le2Var.b();
            zs1.O0(arrayList3, bq5VarA);
            i++;
            bq5Var = bq5VarB;
        }
        boolean zIsEmpty = arrayList3.isEmpty();
        vy5 vy5Var = this.e;
        if (!zIsEmpty || (bq5Var != null && (!bq5Var.isEmpty()))) {
            bq5<ke2> bq5VarQ = xs7.Q(arrayList3);
            if (bq5Var == null) {
                bq5Var = ccdVar;
            }
            if (((ns1) yc4Var.I) == ns1.a) {
                yz3.l("CollabInked.updateCurrentStroke called with empty motion event");
                return null;
            }
            ArrayList arrayList4 = vy5Var.j;
            bq5VarQ.getClass();
            bq5Var.getClass();
            arrayList.getClass();
            ArrayList arrayList5 = new ArrayList(bt1.H0(bq5VarQ, 10));
            for (ke2 ke2VarB : bq5VarQ) {
                Double d = vy5Var.n;
                if (d == null) {
                    vy5Var.n = Double.valueOf(ke2VarB.f());
                } else if (ke2VarB.f() != d.doubleValue()) {
                    vy5Var.o = false;
                }
                if (!vy5Var.o) {
                    ke2VarB = ke2VarB.b();
                }
                arrayList5.add(ke2VarB);
            }
            int i2 = 0;
            for (Object obj : arrayList5) {
                int i3 = i2 + 1;
                if (i2 < 0) {
                    ny7.E0();
                    throw null;
                }
                arrayList4.size();
                ((ke2) obj).getClass();
                i2 = i3;
            }
            arrayList4.addAll(arrayList5);
            boolean zP = x76.p(vy5Var.k, bq5Var);
            vy5Var.k = bq5Var;
            if (!arrayList5.isEmpty() || !zP) {
                arrayList5.isEmpty();
                int size = arrayList4.size() - arrayList5.size();
                Object objO1 = zs1.o1((ArrayList) vy5Var.q.K);
                u46 u46VarV = me8.V(size, arrayList4.size());
                ArrayList arrayList6 = new ArrayList();
                Iterator it = u46VarV.iterator();
                while (((t46) it).K) {
                    Object next = ((t46) it).next();
                    ke2 ke2Var = (ke2) arrayList4.get(((Number) next).intValue());
                    ke2 ke2Var2 = (ke2) objO1;
                    if (ke2Var2 != null) {
                        double d2 = ((double) vy5Var.a) * 2.0d;
                        if (Math.rint(ke2Var.g() * d2) != Math.rint(ke2Var2.g() * d2) || Math.rint(ke2Var.h() * d2) != Math.rint(ke2Var2.h() * d2)) {
                            arrayList6.add(next);
                        } else if (Math.rint(vy5Var.b() * xqh.c(ke2Var2.f())) != Math.rint(vy5Var.b() * xqh.c(ke2Var.f()))) {
                            arrayList6.add(next);
                        }
                    } else {
                        arrayList6.add(next);
                    }
                    objO1 = ke2Var;
                }
                ho0 ho0Var = vy5Var.q;
                ArrayList arrayList7 = (ArrayList) ho0Var.K;
                int i4 = 0;
                for (Object obj2 : arrayList6) {
                    int i5 = i4 + 1;
                    if (i4 < 0) {
                        ny7.E0();
                        throw null;
                    }
                    ((LinkedHashMap) ho0Var.M).put(Integer.valueOf(((Number) obj2).intValue()), Integer.valueOf(arrayList7.size() + i4));
                    i4 = i5;
                }
                ArrayList arrayList8 = new ArrayList(bt1.H0(arrayList6, 10));
                Iterator it2 = arrayList6.iterator();
                while (it2.hasNext()) {
                    arrayList8.add((ke2) ((vy5) ho0Var.J).j.get(((Number) it2.next()).intValue()));
                }
                arrayList7.addAll(arrayList8);
                ((ArrayList) ho0Var.L).addAll(arrayList6);
                double d3 = (0.5d / ((((dd4.d(vy5Var.b() * ((double) vy5Var.a)) - 2.6d) / 15.4d) * 1.5d) + 1.0d)) / ((double) vy5Var.a);
                ic0 ic0Var = (ic0) zs1.o1((ArrayList) vy5Var.p.c);
                a81 a81VarK = ic0Var != null ? ic0Var.k(null, ic0Var.l) : null;
                ur3 ur3Var = vy5Var.h;
                ho0 ho0Var2 = vy5Var.q;
                if (ur3Var != null) {
                    arrayListB = ur3Var.b((ArrayList) ho0Var2.K, vy5Var.k);
                } else {
                    ArrayList arrayList9 = (ArrayList) ho0Var2.N;
                    arrayList9.clear();
                    zs1.O0(arrayList9, (ArrayList) ho0Var2.K);
                    zs1.O0(arrayList9, ((vy5) ho0Var2.J).k);
                    arrayListB = arrayList9;
                }
                vy5Var.i = ur3Var != null ? arrayListB : null;
                int iA = ur3Var != null ? ur3Var.a() : Api.BaseClientBuilder.API_PRIORITY_OTHER;
                if (vy5Var.g) {
                    iA = t8j.b(arrayListB, Math.min(iA, ((ArrayList) vy5Var.q.K).size()), t8j.e(vy5Var.b()));
                }
                int i6 = iA;
                yy5 yy5Var = vy5Var.r;
                yy5 yy5VarF = sqh.f(arrayListB, d3, yy5Var != null ? yy5Var.b() : 0, a81VarK, vy5Var.u, i6);
                vy5Var.r = yy5VarF;
                ArrayList arrayList10 = new ArrayList();
                ic0 ic0VarE = vy5Var.e(yy5VarF.a());
                if (ic0VarE != null) {
                    vy5Var.p.b(ic0VarE, vy5Var.a());
                    arrayList10.add(vy5Var.d(ic0VarE));
                }
                ic0 ic0VarE2 = vy5Var.e(yy5VarF.c());
                hy5 hy5VarD = ic0VarE2 == null ? null : vy5Var.d(ic0VarE2);
                vy5Var.b.b(vy5Var, arrayList10, hy5VarD != null ? ny7.l0(hy5VarD) : ru3.I, arrayList, arrayList2, vy5Var.u);
            }
        }
        this.c.c(vy5Var, arrayList, arrayList2);
        if (arrayList.isEmpty()) {
            arrayList = null;
        }
        if (arrayList2.isEmpty()) {
            arrayList2 = null;
        }
        return new ix9(arrayList, arrayList2);
    }
}
