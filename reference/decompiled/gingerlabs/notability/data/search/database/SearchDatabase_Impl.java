package com.gingerlabs.notability.data.search.database;

import com.gingerlabs.notability.data.search.database.SearchDatabase_Impl;
import defpackage.dgc;
import defpackage.dlb;
import defpackage.elb;
import defpackage.i86;
import defpackage.lh6;
import defpackage.m17;
import defpackage.mw5;
import defpackage.p7e;
import defpackage.ps3;
import defpackage.ru3;
import defpackage.rw5;
import defpackage.t84;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import kotlin.Metadata;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/search/database/SearchDatabase_Impl;", "Lcom/gingerlabs/notability/data/search/database/SearchDatabase;", "<init>", "()V", "search"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class SearchDatabase_Impl extends SearchDatabase {
    public final p7e l;
    public final p7e m;
    public final p7e n;

    public SearchDatabase_Impl() {
        final int i = 0;
        this.l = new p7e(new Function0(this) { // from class: egc
            public final /* synthetic */ SearchDatabase_Impl J;

            {
                this.J = this;
            }

            @Override // kotlin.jvm.functions.Function0
            public final Object invoke() {
                int i2 = i;
                SearchDatabase_Impl searchDatabase_Impl = this.J;
                switch (i2) {
                    case 0:
                        return new rw5(searchDatabase_Impl);
                    case 1:
                        return new mw5(searchDatabase_Impl);
                    default:
                        return new t84(searchDatabase_Impl);
                }
            }
        });
        final int i2 = 1;
        this.m = new p7e(new Function0(this) { // from class: egc
            public final /* synthetic */ SearchDatabase_Impl J;

            {
                this.J = this;
            }

            @Override // kotlin.jvm.functions.Function0
            public final Object invoke() {
                int i3 = i2;
                SearchDatabase_Impl searchDatabase_Impl = this.J;
                switch (i3) {
                    case 0:
                        return new rw5(searchDatabase_Impl);
                    case 1:
                        return new mw5(searchDatabase_Impl);
                    default:
                        return new t84(searchDatabase_Impl);
                }
            }
        });
        final int i3 = 2;
        this.n = new p7e(new Function0(this) { // from class: egc
            public final /* synthetic */ SearchDatabase_Impl J;

            {
                this.J = this;
            }

            @Override // kotlin.jvm.functions.Function0
            public final Object invoke() {
                int i4 = i3;
                SearchDatabase_Impl searchDatabase_Impl = this.J;
                switch (i4) {
                    case 0:
                        return new rw5(searchDatabase_Impl);
                    case 1:
                        return new mw5(searchDatabase_Impl);
                    default:
                        return new t84(searchDatabase_Impl);
                }
            }
        });
    }

    @Override // defpackage.h1c
    public final List e(LinkedHashMap linkedHashMap) {
        ArrayList arrayList = new ArrayList();
        arrayList.add(new dgc(0));
        return arrayList;
    }

    @Override // defpackage.h1c
    public final i86 f() {
        return new i86(this, new LinkedHashMap(), new LinkedHashMap(), "IndexedTitle", "IndexedNote", "FailedIndexedNote");
    }

    @Override // defpackage.h1c
    public final ps3 g() {
        return new m17(this);
    }

    @Override // defpackage.h1c
    public final Set k() {
        return new LinkedHashSet();
    }

    @Override // defpackage.h1c
    public final LinkedHashMap l() {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        elb elbVar = dlb.a;
        lh6 lh6VarB = elbVar.b(rw5.class);
        ru3 ru3Var = ru3.I;
        linkedHashMap.put(lh6VarB, ru3Var);
        linkedHashMap.put(elbVar.b(mw5.class), ru3Var);
        linkedHashMap.put(elbVar.b(t84.class), ru3Var);
        return linkedHashMap;
    }

    @Override // com.gingerlabs.notability.data.search.database.SearchDatabase
    public final t84 u() {
        return (t84) this.n.getValue();
    }

    @Override // com.gingerlabs.notability.data.search.database.SearchDatabase
    public final mw5 v() {
        return (mw5) this.m.getValue();
    }

    @Override // com.gingerlabs.notability.data.search.database.SearchDatabase
    public final rw5 w() {
        return (rw5) this.l.getValue();
    }
}
