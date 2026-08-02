package com.gingerlabs.notability.data.search;

import defpackage.b7d;
import defpackage.f92;
import defpackage.nt6;
import defpackage.tg2;
import defpackage.x76;

/* JADX INFO: loaded from: classes2.dex */
public final class SearchResult {
    public final String a;
    public final String b;
    public final int c;
    public final String d;
    public final String e;

    public SearchResult(int i, String str, String str2, String str3, String str4) {
        str.getClass();
        str2.getClass();
        str3.getClass();
        this.a = str;
        this.b = str2;
        this.c = i;
        this.d = str3;
        this.e = str4;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof SearchResult)) {
            return false;
        }
        SearchResult searchResult = (SearchResult) obj;
        return x76.p(this.a, searchResult.a) && x76.p(this.b, searchResult.b) && this.c == searchResult.c && x76.p(this.d, searchResult.d) && x76.p(this.e, searchResult.e);
    }

    public final int hashCode() {
        int iE = b7d.e(f92.e(this.c, b7d.e(this.a.hashCode() * 31, this.b, 31), 31), this.d, 31);
        String str = this.e;
        return iE + (str == null ? 0 : str.hashCode());
    }

    public final String toString() {
        StringBuilder sbT = tg2.t("SearchResult(id=", this.a, ", text=", this.b, ", score=");
        sbT.append(this.c);
        sbT.append(", namespace=");
        sbT.append(this.d);
        sbT.append(", pageId=");
        return nt6.t(sbT, this.e, ")");
    }
}
