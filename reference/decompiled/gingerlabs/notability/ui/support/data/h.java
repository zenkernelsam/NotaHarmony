package com.gingerlabs.notability.ui.support.data;

import defpackage.vtc;
import defpackage.x76;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0018\u0002\n\u0002\b\u0007\b\u0082\b\u0018\u00002\u00020\u0001:\u0001\bR\u001a\u0010\u0007\u001a\u00020\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0003\u0010\u0004\u001a\u0004\b\u0005\u0010\u0006¨\u0006\t"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/h;", "", "Lcom/gingerlabs/notability/ui/support/data/e;", "a", "Lcom/gingerlabs/notability/ui/support/data/e;", "getRequest", "()Lcom/gingerlabs/notability/ui/support/data/e;", "request", "com/gingerlabs/notability/ui/support/data/g", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class h {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("request")
    private final e request;

    public h(e eVar) {
        this.request = eVar;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        return (obj instanceof h) && x76.p(this.request, ((h) obj).request);
    }

    public final int hashCode() {
        return this.request.hashCode();
    }

    public final String toString() {
        return "ZendeskTicketRequest(request=" + this.request + ")";
    }
}
