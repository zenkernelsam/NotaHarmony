package com.gingerlabs.notability.core.model;

import androidx.recyclerview.widget.RecyclerView;
import defpackage.ama;
import defpackage.ar1;
import defpackage.c9e;
import defpackage.cl7;
import defpackage.de2;
import defpackage.gh2;
import defpackage.ix9;
import defpackage.jp5;
import defpackage.lsc;
import defpackage.me8;
import defpackage.mea;
import defpackage.nv9;
import defpackage.ny7;
import defpackage.pcb;
import defpackage.qy1;
import defpackage.rkb;
import defpackage.rm5;
import defpackage.sdj;
import defpackage.tni;
import defpackage.u29;
import defpackage.um9;
import defpackage.uv9;
import defpackage.w3a;
import defpackage.wbf;
import defpackage.wv9;
import defpackage.wz0;
import defpackage.x3a;
import defpackage.x76;
import defpackage.xzb;
import defpackage.yla;
import defpackage.yz0;
import defpackage.yz3;
import defpackage.zm9;
import defpackage.zrc;
import defpackage.zz0;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;

/* JADX INFO: loaded from: classes2.dex */
public final class c {
    public final ArrayList a;
    public final ar1 b;
    public final lsc c;
    public final yla d;
    public final LinkedHashMap e;
    public final LinkedHashMap f;
    public final LinkedHashMap g;
    public ArrayList h;

    public c(List list, ar1 ar1Var, lsc lscVar, yla ylaVar) {
        System.currentTimeMillis();
        list.getClass();
        ar1Var.getClass();
        this.a = new ArrayList(list);
        this.b = ar1Var;
        this.c = lscVar;
        this.d = ylaVar;
        this.e = new LinkedHashMap();
        this.f = new LinkedHashMap();
        this.g = new LinkedHashMap();
        this.h = new ArrayList();
    }

    public static /* synthetic */ Object b(c cVar, u29 u29Var, c9e c9eVar, pcb pcbVar, rm5 rm5Var, rm5 rm5Var2, rm5 rm5Var3, x3a x3aVar, int i) {
        if ((i & 4) != 0) {
            pcbVar = null;
        }
        if ((i & 8) != 0) {
            rm5Var = null;
        }
        if ((i & 16) != 0) {
            rm5Var2 = null;
        }
        if ((i & 32) != 0) {
            rm5Var3 = null;
        }
        return cVar.a(u29Var, c9eVar, pcbVar, rm5Var, rm5Var2, rm5Var3, x3aVar);
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    public final Object a(u29 u29Var, c9e c9eVar, pcb pcbVar, rm5 rm5Var, rm5 rm5Var2, rm5 rm5Var3, de2 de2Var) {
        w3a w3aVar;
        if (de2Var instanceof w3a) {
            w3aVar = (w3a) de2Var;
            int i = w3aVar.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                w3aVar.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                w3aVar = new w3a(this, de2Var);
            }
        } else {
            w3aVar = new w3a(this, de2Var);
        }
        Object objW = w3aVar.I;
        int i2 = w3aVar.K;
        if (i2 == 0) {
            ny7.F0(objW);
            ar1 ar1Var = this.b;
            rm5 rm5VarB = me8.b(ar1Var.c.getAndIncrement(), ar1Var.a);
            if (rm5Var != null) {
                this.f.put(new uv9(tni.g(rm5Var, 0)), new uv9(tni.g(rm5VarB, 0)));
            } else if (rm5Var2 != null) {
                this.e.put(rm5Var2, rm5VarB);
            } else if (rm5Var3 != null) {
                this.g.put(rm5Var3, rm5VarB);
            }
            um9 um9VarA = zm9.a(rm5VarB, c9eVar, System.currentTimeMillis(), pcbVar);
            this.h.add(um9VarA);
            Collection collectionL0 = ny7.l0(um9VarA);
            w3aVar.K = 1;
            objW = u29Var.w(collectionL0, w3aVar);
            Object obj = gh2.I;
            if (objW == obj) {
                return obj;
            }
        } else {
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            ny7.F0(objW);
        }
        Set set = (Set) objW;
        if (set != null) {
            return set;
        }
        yz3.l("Paste should not run during initial load");
        return null;
    }

    /* JADX WARN: Code duplicated, block: B:212:0x0762 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:27:0x0115  */
    /* JADX WARN: Code duplicated, block: B:7:0x0017  */
    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r25v5 */
    /* JADX WARN: Type inference failed for: r25v6, types: [pcb] */
    /* JADX WARN: Type inference failed for: r25v7 */
    /* JADX WARN: Type inference failed for: r3v105 */
    /* JADX WARN: Type inference failed for: r3v106, types: [pcb] */
    /* JADX WARN: Type inference failed for: r3v110 */
    /* JADX WARN: Type inference failed for: r3v75 */
    /* JADX WARN: Type inference failed for: r3v76, types: [pcb] */
    /* JADX WARN: Type inference failed for: r3v80 */
    /* JADX WARN: Type inference failed for: r3v86 */
    /* JADX WARN: Type inference failed for: r3v87, types: [pcb] */
    /* JADX WARN: Type inference failed for: r3v91 */
    /* JADX WARN: Type inference failed for: r6v12 */
    /* JADX WARN: Type inference failed for: r6v13 */
    /* JADX WARN: Type inference failed for: r6v15 */
    /* JADX WARN: Type inference failed for: r6v17 */
    /* JADX WARN: Type inference failed for: r6v20 */
    /* JADX WARN: Type inference failed for: r6v22 */
    /* JADX WARN: Type inference failed for: r6v42 */
    /* JADX WARN: Type inference failed for: r6v47 */
    /* JADX WARN: Type inference failed for: r6v48 */
    /* JADX WARN: Type inference failed for: r6v50 */
    /* JADX WARN: Type inference failed for: r9v0 */
    /* JADX WARN: Type inference failed for: r9v10 */
    /* JADX WARN: Type inference failed for: r9v11 */
    /* JADX WARN: Type inference failed for: r9v12 */
    /* JADX WARN: Type inference failed for: r9v13 */
    /* JADX WARN: Type inference failed for: r9v14 */
    /* JADX WARN: Type inference failed for: r9v3 */
    /* JADX WARN: Type inference failed for: r9v4, types: [java.io.Serializable, um9] */
    /* JADX WARN: Type inference failed for: r9v6 */
    /* JADX WARN: Type inference failed for: r9v7 */
    /* JADX WARN: Type inference failed for: r9v8 */
    /* JADX WARN: Type inference failed for: r9v9 */
    /* JADX WARN: Unsupported multi-entry loop pattern (BACK_EDGE: B:147:0x056a -> B:46:0x0207). Please report as a decompilation issue!!! */
    /* JADX WARN: Unsupported multi-entry loop pattern (BACK_EDGE: B:186:0x0762 -> B:187:0x0773). Please report as a decompilation issue!!! */
    /* JADX WARN: Unsupported multi-entry loop pattern (BACK_EDGE: B:31:0x0136 -> B:187:0x0773). Please report as a decompilation issue!!! */
    /* JADX WARN: Unsupported multi-entry loop pattern (BACK_EDGE: B:56:0x0264 -> B:57:0x026c). Please report as a decompilation issue!!! */
    /*  JADX ERROR: JadxOverflowException in pass: RegionMakerVisitor
        jadx.core.utils.exceptions.JadxOverflowException: Regions stack size limit reached
        	at jadx.core.utils.ErrorsCounter.addError(ErrorsCounter.java:59)
        	at jadx.core.utils.ErrorsCounter.error(ErrorsCounter.java:31)
        	at jadx.core.dex.attributes.nodes.NotificationAttrNode.addError(NotificationAttrNode.java:19)
        */
    public final java.io.Serializable c(defpackage.u29 r39, defpackage.de2 r40) {
        /*
            Method dump skipped, instruction units count: 2028
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: com.gingerlabs.notability.core.model.c.c(u29, de2):java.io.Serializable");
    }

    public final wz0 d(wz0 wz0Var, xzb xzbVar) throws CopyPasteException.IncompatibleContent, CopyPasteException.Consistency {
        rm5 rm5VarB = me8.b(wz0Var.c().d(), wz0Var.c().c());
        int iOrdinal = wz0Var.d().ordinal();
        if (iOrdinal == 0 || iOrdinal == 1) {
            rm5 rm5Var = (rm5) this.g.get(rm5VarB);
            if (rm5Var != null) {
                return qy1.a(tni.g(rm5Var, wz0Var.c().C()), wz0Var.d());
            }
            throw new CopyPasteException.Consistency("Missing text mapping, something went wrong in our code earlier in the copy/paste process");
        }
        if (iOrdinal == 2) {
            throw new CopyPasteException.IncompatibleContent("Copy cannot include references to start of doc");
        }
        if (iOrdinal != 3) {
            yz3.t();
            return null;
        }
        lsc lscVarF = f(wz0Var.c());
        if (((zrc) xzbVar.getText().d().get(lscVarF)) == null) {
            throw new CopyPasteException.Consistency("Cannot find new char node");
        }
        zrc zrcVarO = sdj.O(xzbVar.getText(), lscVarF, null, 6);
        return zrcVarO != null ? qy1.a(zrcVarO.d(new jp5()), zz0.BEFORE) : (wz0) yz0.b.getValue();
    }

    public final ix9 e(rm5 rm5Var) throws CopyPasteException.Consistency {
        if (rm5Var == null) {
            return new ix9(null, null);
        }
        rm5 rm5Var2 = (rm5) this.e.get(rm5Var);
        if (rm5Var2 != null) {
            return new ix9(rm5Var2, null);
        }
        throw new CopyPasteException.Consistency("Missing entity remapped entity id");
    }

    public final lsc f(lsc lscVar) throws CopyPasteException.Consistency {
        if (lscVar == null) {
            throw new CopyPasteException.Consistency("Cannot rebase a nil SeqId");
        }
        rm5 rm5Var = (rm5) this.g.get(me8.b(lscVar.d(), lscVar.c()));
        if (rm5Var != null) {
            return tni.g(rm5Var, lscVar.C());
        }
        throw new CopyPasteException.Consistency("Missing text mapping, either the wrong paste order or something went wrong in our code earlier in the process");
    }

    public final ix9 g(u29 u29Var, lsc lscVar, yla ylaVar) throws CopyPasteException.MissingPosition {
        ix9 ix9Var;
        uv9 uv9Var = (uv9) this.f.get(new uv9(lscVar));
        lsc lscVar2 = uv9Var != null ? uv9Var.a : null;
        if (lscVar2 != null) {
            return new ix9(new uv9(lscVar2), ylaVar);
        }
        yla ylaVar2 = this.d;
        if (ylaVar2 == null) {
            throw CopyPasteException.MissingPosition.I;
        }
        float fD = ylaVar.d() + ylaVar2.d();
        List list = u29Var.u;
        list.getClass();
        wbf wbfVarO = x76.O(fD, list);
        if (wbfVarO != null) {
            ix9Var = new ix9(new uv9(((nv9) wbfVarO.J).v()), (yla) wbfVarO.K);
        } else {
            ix9Var = null;
        }
        if (ix9Var == null) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            com.gingerlabs.notability.core.common.logging.a.c(cl7.MODEL, "Did not find page for height", null, null);
            return new ix9(new uv9(((wv9) ((mea) u29Var.m().i).get(0)).g), ylaVar2);
        }
        lsc lscVar3 = ((uv9) ix9Var.I).a;
        yla ylaVar3 = (yla) ix9Var.J;
        uv9 uv9Var2 = new uv9(lscVar3);
        yla ylaVarA = ama.a(ylaVar2, ylaVar);
        if (ylaVar3 != null) {
            ylaVarA = rkb.g(ylaVarA.c() - ylaVar3.c(), ylaVarA.d() - ylaVar3.d());
        }
        return new ix9(uv9Var2, ylaVarA);
    }
}
