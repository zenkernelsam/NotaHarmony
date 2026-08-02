package com.gingerlabs.notability.ui.support.data;

import defpackage.vtc;
import defpackage.x76;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0002\b\u0005\n\u0002\u0010 \n\u0002\b\u0006\b\u0082\b\u0018\u00002\u00020\u0001R\u001a\u0010\u0007\u001a\u00020\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0003\u0010\u0004\u001a\u0004\b\u0005\u0010\u0006R \u0010\r\u001a\b\u0012\u0004\u0012\u00020\u00020\b8\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\t\u0010\n\u001a\u0004\b\u000b\u0010\f¨\u0006\u000e"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/c;", "", "", "a", "Ljava/lang/String;", "getBody", "()Ljava/lang/String;", "body", "", "b", "Ljava/util/List;", "getUploads", "()Ljava/util/List;", "uploads", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class c {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("body")
    private final String body;

    /* JADX INFO: renamed from: b, reason: from kotlin metadata */
    @vtc("uploads")
    private final List<String> uploads;

    public c(String str, List list) {
        list.getClass();
        this.body = str;
        this.uploads = list;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof c)) {
            return false;
        }
        c cVar = (c) obj;
        return x76.p(this.body, cVar.body) && x76.p(this.uploads, cVar.uploads);
    }

    public final int hashCode() {
        return this.uploads.hashCode() + (this.body.hashCode() * 31);
    }

    public final String toString() {
        return "ZendeskComment(body=" + this.body + ", uploads=" + this.uploads + ")";
    }
}
