package com.gingerlabs.notability.core.model;

import defpackage.ak2;
import defpackage.bt1;
import defpackage.g4j;
import defpackage.ic5;
import defpackage.ix3;
import defpackage.ixc;
import defpackage.lfa;
import defpackage.lsc;
import defpackage.n65;
import defpackage.nt6;
import defpackage.ny7;
import defpackage.r65;
import defpackage.rm5;
import defpackage.uhb;
import defpackage.uv9;
import defpackage.vv7;
import defpackage.vw3;
import defpackage.we7;
import defpackage.wea;
import defpackage.x76;
import defpackage.xi7;
import defpackage.yfb;
import defpackage.z29;
import defpackage.zs1;
import java.util.AbstractList;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/* JADX INFO: loaded from: classes2.dex */
public abstract class b {
    public static final we7 a(z29 z29Var) {
        we7 we7VarS = ny7.S();
        wea weaVar = z29Var.H;
        lfa lfaVar = z29Var.E;
        ak2 ak2Var = z29Var.D;
        for (vw3 vw3Var : lfaVar.I.values()) {
            r65 r65Var = (r65) (!(vw3Var instanceof r65) ? null : vw3Var);
            if (r65Var != null && !x76.K(vw3Var.getId(), ak2Var)) {
                we7VarS.add(r65Var);
            }
        }
        for (Map.Entry entry : (ixc) weaVar.entrySet()) {
            rm5 rm5Var = (rm5) entry.getKey();
            vw3 vw3Var2 = (vw3) entry.getValue();
            if (!x76.K(rm5Var, ak2Var) && lfaVar.I.get(rm5Var) == null) {
                we7VarS.add((r65) vw3Var2);
            }
        }
        return ny7.E(we7VarS);
    }

    public static final ArrayList b(z29 z29Var, ArrayList arrayList, a aVar) {
        z29Var.getClass();
        LinkedHashMap linkedHashMap = aVar.i;
        Iterator it = arrayList.iterator();
        while (it.hasNext()) {
            rm5 rm5Var = (rm5) it.next();
            ic5 ic5VarS = x76.S(z29Var, rm5Var);
            if (ic5VarS != null) {
                if (linkedHashMap.get(new uv9(ic5VarS.j())) == null) {
                    uhb uhbVar = (uhb) nt6.i(ic5VarS.j(), z29Var.h);
                    if (uhbVar != null) {
                        linkedHashMap.put(new uv9(ic5VarS.j()), uhbVar);
                    }
                }
                ((ix3) ic5VarS).u(aVar);
            } else {
                n65 n65VarV = xi7.v(rm5Var, z29Var);
                if (n65VarV != null) {
                    Iterator it2 = n65VarV.M().iterator();
                    while (it2.hasNext()) {
                        if (aVar.f.get((rm5) it2.next()) == null) {
                            throw new CopyPasteException.InvalidArguments("Copying a group must include all of a Group's members, who must come before the Group in the entities to copy collection");
                        }
                    }
                    ((ix3) n65VarV).u(aVar);
                } else {
                    yfb yfbVar = (yfb) z29Var.J.get(rm5Var);
                    if (yfbVar != null) {
                        yfbVar.u(aVar);
                    }
                }
            }
        }
        return aVar.e;
    }

    public static final void c(AbstractList abstractList, a aVar) {
        int iC0 = vv7.c0(bt1.H0(abstractList, 10));
        if (iC0 < 16) {
            iC0 = 16;
        }
        LinkedHashMap linkedHashMap = new LinkedHashMap(iC0);
        for (Object obj : abstractList) {
            linkedHashMap.put(((r65) obj).getId(), obj);
        }
        LinkedHashSet linkedHashSet = new LinkedHashSet();
        LinkedHashSet linkedHashSet2 = new LinkedHashSet();
        Iterator it = abstractList.iterator();
        while (it.hasNext()) {
            d(linkedHashSet, linkedHashSet2, linkedHashMap, aVar, (r65) it.next());
        }
    }

    public static final void d(LinkedHashSet linkedHashSet, LinkedHashSet linkedHashSet2, LinkedHashMap linkedHashMap, a aVar, r65 r65Var) throws CopyPasteException.Consistency {
        if (linkedHashSet.contains(r65Var.getId())) {
            return;
        }
        if (!linkedHashSet2.add(r65Var.getId())) {
            throw new CopyPasteException.Consistency("Cycle in group dependencies at " + r65Var.getId());
        }
        Iterator it = r65Var.M().iterator();
        while (it.hasNext()) {
            r65 r65Var2 = (r65) linkedHashMap.get((rm5) it.next());
            if (r65Var2 != null) {
                d(linkedHashSet, linkedHashSet2, linkedHashMap, aVar, r65Var2);
            }
        }
        linkedHashSet2.remove(r65Var.getId());
        List listM = r65Var.M();
        ArrayList arrayList = new ArrayList();
        Iterator it2 = listM.iterator();
        while (it2.hasNext()) {
            rm5 rm5Var = (rm5) aVar.f.get((rm5) it2.next());
            if (rm5Var != null) {
                arrayList.add(rm5Var);
            }
        }
        if (!arrayList.isEmpty()) {
            a.b(aVar, g4j.a(arrayList), r65Var.getId(), null, null, 12);
        }
        linkedHashSet.add(r65Var.getId());
    }

    public static final boolean e(LinkedHashMap linkedHashMap, LinkedHashSet linkedHashSet, LinkedHashMap linkedHashMap2, Set set, z29 z29Var, r65 r65Var) throws CopyPasteException.Consistency {
        boolean zS0;
        rm5 id = r65Var.getId();
        Object objValueOf = linkedHashMap.get(id);
        if (objValueOf == null) {
            if (!linkedHashSet.add(r65Var.getId())) {
                throw new CopyPasteException.Consistency("Cycle in group dependencies at " + r65Var.getId());
            }
            List<rm5> listM = r65Var.M();
            boolean z = false;
            if (listM == null || !listM.isEmpty()) {
                for (rm5 rm5Var : listM) {
                    r65 r65Var2 = (r65) linkedHashMap2.get(rm5Var);
                    if (r65Var2 != null) {
                        zS0 = e(linkedHashMap, linkedHashSet, linkedHashMap2, set, z29Var, r65Var2);
                    } else {
                        Set set2 = set;
                        z29Var.getClass();
                        ic5 ic5VarS = x76.S(z29Var, rm5Var);
                        lsc lscVarJ = ic5VarS != null ? ic5VarS.j() : null;
                        zS0 = zs1.S0(set2, lscVarJ != null ? new uv9(lscVarJ) : null);
                    }
                    if (zS0) {
                        z = true;
                        break;
                    }
                }
            }
            linkedHashSet.remove(r65Var.getId());
            objValueOf = Boolean.valueOf(z);
            linkedHashMap.put(id, objValueOf);
        }
        return ((Boolean) objValueOf).booleanValue();
    }
}
