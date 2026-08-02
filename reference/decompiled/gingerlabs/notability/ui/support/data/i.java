package com.gingerlabs.notability.ui.support.data;

import defpackage.nt6;
import defpackage.vtc;
import defpackage.x76;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0002\b\u0007\b\u0082\b\u0018\u00002\u00020\u0001R\u001c\u0010\u0007\u001a\u0004\u0018\u00010\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0003\u0010\u0004\u001a\u0004\b\u0005\u0010\u0006R\u001c\u0010\b\u001a\u0004\u0018\u00010\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0005\u0010\u0004\u001a\u0004\b\u0003\u0010\u0006¨\u0006\t"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/i;", "", "", "a", "Ljava/lang/String;", "b", "()Ljava/lang/String;", "error", "description", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class i {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("error")
    private final String error;

    /* JADX INFO: renamed from: b, reason: from kotlin metadata */
    @vtc("description")
    private final String description;

    /* JADX INFO: renamed from: a, reason: from getter */
    public final String getDescription() {
        return this.description;
    }

    /* JADX INFO: renamed from: b, reason: from getter */
    public final String getError() {
        return this.error;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof i)) {
            return false;
        }
        i iVar = (i) obj;
        return x76.p(this.error, iVar.error) && x76.p(this.description, iVar.description);
    }

    public final int hashCode() {
        String str = this.error;
        int iHashCode = (str == null ? 0 : str.hashCode()) * 31;
        String str2 = this.description;
        return iHashCode + (str2 != null ? str2.hashCode() : 0);
    }

    public final String toString() {
        return nt6.r("ZendeskTicketResponse(error=", this.error, ", description=", this.description, ")");
    }
}
