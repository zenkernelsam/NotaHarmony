package com.gingerlabs.notability.ui.support.data;

import defpackage.f92;
import defpackage.vtc;
import defpackage.x76;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0002\b\u0005\b\u0082\b\u0018\u00002\u00020\u0001R\u001a\u0010\u0006\u001a\u00020\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0003\u0010\u0004\u001a\u0004\b\u0003\u0010\u0005¨\u0006\u0007"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/j;", "", "", "a", "Ljava/lang/String;", "()Ljava/lang/String;", "token", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class j {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("token")
    private final String token;

    /* JADX INFO: renamed from: a, reason: from getter */
    public final String getToken() {
        return this.token;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        return (obj instanceof j) && x76.p(this.token, ((j) obj).token);
    }

    public final int hashCode() {
        return this.token.hashCode();
    }

    public final String toString() {
        return f92.m("ZendeskUpload(token=", this.token, ")");
    }
}
