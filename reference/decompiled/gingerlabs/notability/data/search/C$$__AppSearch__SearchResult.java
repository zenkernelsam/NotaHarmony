package com.gingerlabs.notability.data.search;

import defpackage.a05;
import defpackage.b05;
import defpackage.c05;
import defpackage.k40;
import defpackage.q40;
import defpackage.r0b;
import defpackage.s40;
import defpackage.sg3;
import defpackage.yz3;
import java.util.Collections;
import java.util.List;

/* JADX INFO: renamed from: com.gingerlabs.notability.data.search.$$__AppSearch__SearchResult, reason: invalid class name */
/* JADX INFO: loaded from: classes2.dex */
public final class C$$__AppSearch__SearchResult implements sg3 {
    @Override // defpackage.sg3
    public final s40 a() {
        k40 k40Var = new k40("SearchResult");
        q40 q40Var = new q40("text");
        q40Var.b(3);
        q40Var.e(1);
        q40Var.c(2);
        q40Var.d(0);
        k40Var.a(q40Var.a());
        q40 q40Var2 = new q40("pageId");
        q40Var2.b(2);
        q40Var2.e(0);
        q40Var2.c(0);
        q40Var2.d(0);
        k40Var.a(q40Var2.a());
        return k40Var.b();
    }

    @Override // defpackage.sg3
    public final Object b(a05 a05Var) {
        c05 c05Var = a05Var.a;
        String str = c05Var.J;
        int i = c05Var.N;
        String str2 = c05Var.I;
        String[] strArrF = a05Var.f("text");
        String str3 = null;
        String str4 = (strArrF == null || strArrF.length == 0) ? null : strArrF[0];
        String[] strArrF2 = a05Var.f("pageId");
        if (strArrF2 != null && strArrF2.length != 0) {
            str3 = strArrF2[0];
        }
        return new SearchResult(i, str, str4, str2, str3);
    }

    @Override // defpackage.sg3
    public final a05 c(Object obj) {
        SearchResult searchResult = (SearchResult) obj;
        r0b r0bVar = new r0b(searchResult.d, searchResult.a, "SearchResult");
        int i = searchResult.c;
        if (i < 0) {
            yz3.r("Document score cannot be negative.");
            return null;
        }
        ((b05) r0bVar.I).f = i;
        String str = searchResult.b;
        if (str != null) {
            r0bVar.z("text", str);
        }
        String str2 = searchResult.e;
        if (str2 != null) {
            r0bVar.z("pageId", str2);
        }
        return r0bVar.i();
    }

    @Override // defpackage.sg3
    public final void d() {
        List list = Collections.EMPTY_LIST;
    }
}
