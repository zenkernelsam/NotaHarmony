package com.gingerlabs.notability.ui.support.data;

import defpackage.nu7;
import defpackage.vtc;
import defpackage.x76;
import java.util.Map;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u00008\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0010$\n\u0002\b\u0005\n\u0002\u0010\b\n\u0002\b\u0005\n\u0002\u0010\t\n\u0002\b\u0006\b\u0082\b\u0018\u00002\u00020\u0001R\u001a\u0010\u0007\u001a\u00020\u00028\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0003\u0010\u0004\u001a\u0004\b\u0005\u0010\u0006R\u001a\u0010\r\u001a\u00020\b8\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\t\u0010\n\u001a\u0004\b\u000b\u0010\fR\u001a\u0010\u0013\u001a\u00020\u000e8\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u000f\u0010\u0010\u001a\u0004\b\u0011\u0010\u0012R&\u0010\u0019\u001a\u000e\u0012\u0004\u0012\u00020\u0002\u0012\u0004\u0012\u00020\u00020\u00148\u0006X\u0087\u0004¢\u0006\f\n\u0004\b\u0015\u0010\u0016\u001a\u0004\b\u0017\u0010\u0018R\u001a\u0010\u001f\u001a\u00020\u001a8\u0006X\u0087D¢\u0006\f\n\u0004\b\u001b\u0010\u001c\u001a\u0004\b\u001d\u0010\u001eR\u001a\u0010%\u001a\u00020 8\u0006X\u0087D¢\u0006\f\n\u0004\b!\u0010\"\u001a\u0004\b#\u0010$¨\u0006&"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/e;", "", "", "a", "Ljava/lang/String;", "getSubject", "()Ljava/lang/String;", "subject", "Lcom/gingerlabs/notability/ui/support/data/c;", "b", "Lcom/gingerlabs/notability/ui/support/data/c;", "getComment", "()Lcom/gingerlabs/notability/ui/support/data/c;", "comment", "Lcom/gingerlabs/notability/ui/support/data/f;", "c", "Lcom/gingerlabs/notability/ui/support/data/f;", "getRequester", "()Lcom/gingerlabs/notability/ui/support/data/f;", "requester", "", "d", "Ljava/util/Map;", "getFields", "()Ljava/util/Map;", "fields", "", "e", "I", "getViaId", "()I", "viaId", "", "f", "J", "getTicketFormId", "()J", "ticketFormId", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
final /* data */ class e {

    /* JADX INFO: renamed from: a, reason: from kotlin metadata */
    @vtc("subject")
    private final String subject;

    /* JADX INFO: renamed from: b, reason: from kotlin metadata */
    @vtc("comment")
    private final c comment;

    /* JADX INFO: renamed from: c, reason: from kotlin metadata */
    @vtc("requester")
    private final f requester;

    /* JADX INFO: renamed from: d, reason: from kotlin metadata */
    @vtc("fields")
    private final Map<String, String> fields;

    /* JADX INFO: renamed from: e, reason: from kotlin metadata */
    @vtc("via_id")
    private final int viaId;

    /* JADX INFO: renamed from: f, reason: from kotlin metadata */
    @vtc("ticket_form_id")
    private final long ticketFormId;

    public e(String str, c cVar, f fVar, nu7 nu7Var) {
        str.getClass();
        this.subject = str;
        this.comment = cVar;
        this.requester = fVar;
        this.fields = nu7Var;
        this.viaId = 48;
        this.ticketFormId = 360000467551L;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof e)) {
            return false;
        }
        e eVar = (e) obj;
        return x76.p(this.subject, eVar.subject) && x76.p(this.comment, eVar.comment) && x76.p(this.requester, eVar.requester) && x76.p(this.fields, eVar.fields);
    }

    public final int hashCode() {
        return this.fields.hashCode() + (((((this.subject.hashCode() * 31) + this.comment.hashCode()) * 31) + this.requester.hashCode()) * 31);
    }

    public final String toString() {
        return "ZendeskRequest(subject=" + this.subject + ", comment=" + this.comment + ", requester=" + this.requester + ", fields=" + this.fields + ")";
    }
}
