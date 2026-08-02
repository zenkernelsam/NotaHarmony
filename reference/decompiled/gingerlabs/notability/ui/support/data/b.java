package com.gingerlabs.notability.ui.support.data;

import defpackage.ru3;
import defpackage.s8g;
import defpackage.vtc;
import defpackage.x76;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0005\b\u0082\b\u0018\u00002\u00020\u0001R \u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00030\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0004\u0010\u0005\u001a\u0004\b\u0004\u0010\u0006¨\u0006\b"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/b;", "", "", "Ls8g;", "a", "Ljava/util/List;", "()Ljava/util/List;", "results", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class b {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("results")
    private final List<s8g> results = ru3.I;

    /* JADX INFO: renamed from: a, reason: from getter */
    public final List getResults() {
        return this.results;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        return (obj instanceof b) && x76.p(this.results, ((b) obj).results);
    }

    public final int hashCode() {
        return this.results.hashCode();
    }

    public final String toString() {
        return "ZendeskArticlesResponse(results=" + this.results + ")";
    }
}
