package com.gingerlabs.notability.ui.support.data;

import com.google.android.gms.common.Scopes;
import defpackage.nt6;
import defpackage.vtc;
import defpackage.x76;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0002\b\t\b\u0082\b\u0018\u00002\u00020\u0001R\u001c\u0010\u0007\u001a\u0004\u0018\u00010\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0003\u0010\u0004\u001a\u0004\b\u0005\u0010\u0006R\u001a\u0010\n\u001a\u00020\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\b\u0010\u0004\u001a\u0004\b\t\u0010\u0006¨\u0006\u000b"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/f;", "", "", "a", "Ljava/lang/String;", "getName", "()Ljava/lang/String;", "name", "b", "getEmail", Scopes.EMAIL, "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class f {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("name")
    private final String name;

    /* JADX INFO: renamed from: b, reason: from kotlin metadata */
    @vtc(Scopes.EMAIL)
    private final String email;

    public f(String str, String str2) {
        str2.getClass();
        this.name = str;
        this.email = str2;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof f)) {
            return false;
        }
        f fVar = (f) obj;
        return x76.p(this.name, fVar.name) && x76.p(this.email, fVar.email);
    }

    public final int hashCode() {
        String str = this.name;
        return this.email.hashCode() + ((str == null ? 0 : str.hashCode()) * 31);
    }

    public final String toString() {
        return nt6.r("ZendeskRequester(name=", this.name, ", email=", this.email, ")");
    }
}
