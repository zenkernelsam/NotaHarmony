package com.gingerlabs.notability.core.model;

import defpackage.ama;
import defpackage.ar1;
import defpackage.bt1;
import defpackage.c9e;
import defpackage.cl7;
import defpackage.h76;
import defpackage.ix9;
import defpackage.lhf;
import defpackage.lmi;
import defpackage.lsc;
import defpackage.me8;
import defpackage.nsc;
import defpackage.pcb;
import defpackage.rkb;
import defpackage.rm5;
import defpackage.tni;
import defpackage.uhb;
import defpackage.um9;
import defpackage.uv9;
import defpackage.wm9;
import defpackage.yla;
import defpackage.zm9;
import defpackage.zs1;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;

/* JADX INFO: loaded from: classes2.dex */
public final class a {
    public static final lsc k = tni.g(me8.b(0, -1), 0);
    public final ar1 a;
    public final long b;
    public final yla c;
    public final String d;
    public final ArrayList e;
    public final LinkedHashMap f;
    public final LinkedHashMap g;
    public final LinkedHashMap h;
    public final LinkedHashMap i;
    public rm5 j;

    public a(yla ylaVar, String str, int i) {
        ar1 ar1VarM = h76.M((short) 0);
        long jCurrentTimeMillis = System.currentTimeMillis();
        ylaVar = (i & 4) != 0 ? null : ylaVar;
        str = (i & 8) != 0 ? null : str;
        this.a = ar1VarM;
        this.b = jCurrentTimeMillis;
        this.c = ylaVar;
        this.d = str;
        this.e = new ArrayList();
        this.f = new LinkedHashMap();
        this.g = new LinkedHashMap();
        this.h = new LinkedHashMap();
        this.i = new LinkedHashMap();
    }

    public static rm5 b(a aVar, c9e c9eVar, rm5 rm5Var, lsc lscVar, pcb pcbVar, int i) {
        if ((i & 2) != 0) {
            rm5Var = null;
        }
        if ((i & 4) != 0) {
            lscVar = null;
        }
        if ((i & 8) != 0) {
            pcbVar = null;
        }
        aVar.getClass();
        ar1 ar1Var = aVar.a;
        rm5 rm5VarB = me8.b(ar1Var.c.getAndIncrement(), ar1Var.a);
        if (rm5Var != null) {
            aVar.f.put(rm5Var, rm5VarB);
        }
        if (lscVar != null) {
            aVar.g.put(new uv9(lscVar), new uv9(tni.g(rm5VarB, 0)));
        }
        um9 um9VarA = zm9.a(rm5VarB, c9eVar, aVar.b, pcbVar);
        aVar.e.add(um9VarA);
        return um9VarA.l();
    }

    public static void c(a aVar, List list) {
        list.getClass();
        ar1 ar1Var = aVar.a;
        ar1 ar1VarM = h76.M(ar1Var.a);
        long j = aVar.b;
        ArrayList arrayList = new ArrayList(bt1.H0(list, 10));
        Iterator it = list.iterator();
        while (it.hasNext()) {
            arrayList.add(new wm9((c9e) it.next(), null, false, null, 14));
        }
        List listT = lmi.t(ar1Var, ar1VarM, j, arrayList);
        zs1.O0(aVar.e, listT);
        um9 um9Var = (um9) zs1.f1(listT);
        if (um9Var != null) {
            um9Var.l();
        }
    }

    public static pcb e(long j) {
        pcb pcbVar = new pcb(j);
        if (lhf.a(j, 999999L)) {
            return pcbVar;
        }
        return null;
    }

    public final void a(nsc nscVar, lsc lscVar) {
        nscVar.getClass();
        this.h.put(nscVar, lscVar);
    }

    public final rm5 d() {
        return this.j;
    }

    public final ix9 f(lsc lscVar, yla ylaVar) throws CopyPasteException.MissingPosition {
        lscVar.getClass();
        ylaVar.getClass();
        uv9 uv9Var = (uv9) this.g.get(new uv9(lscVar));
        lsc lscVar2 = uv9Var != null ? uv9Var.a : null;
        if (lscVar2 != null) {
            return new ix9(new uv9(lscVar2), ylaVar);
        }
        yla ylaVar2 = this.c;
        if (ylaVar2 == null) {
            throw CopyPasteException.MissingPosition.I;
        }
        uhb uhbVar = (uhb) this.i.get(new uv9(lscVar));
        lsc lscVar3 = k;
        if (uhbVar != null) {
            yla ylaVarA = ama.a(ylaVar, rkb.g(uhbVar.c().c(), uhbVar.c().d()));
            return new ix9(new uv9(lscVar3), rkb.g(ylaVarA.c() - ylaVar2.c(), ylaVarA.d() - ylaVar2.d()));
        }
        ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
        com.gingerlabs.notability.core.common.logging.a.c(cl7.MODEL, "Could not find page frame for copy", null, null);
        return new ix9(new uv9(lscVar3), ylaVar);
    }

    public final void g(rm5 rm5Var) {
        this.j = rm5Var;
    }
}
