package com.gingerlabs.notability.ui.support.data;

import defpackage.ce2;
import defpackage.oy0;
import defpackage.pu9;
import defpackage.qx4;
import defpackage.tc5;
import defpackage.u2b;
import defpackage.vrb;
import defpackage.wc5;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000:\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\b\bb\u0018\u00002\u00020\u0001J.\u0010\b\u001a\u00020\u00072\b\b\u0001\u0010\u0003\u001a\u00020\u00022\b\b\u0001\u0010\u0004\u001a\u00020\u00022\b\b\u0001\u0010\u0006\u001a\u00020\u0005H§@¢\u0006\u0004\b\b\u0010\tJ\u001a\u0010\r\u001a\u00020\f2\b\b\u0001\u0010\u000b\u001a\u00020\nH§@¢\u0006\u0004\b\r\u0010\u000eJ$\u0010\u0013\u001a\u00020\u00122\b\b\u0001\u0010\u000f\u001a\u00020\u00022\b\b\u0003\u0010\u0011\u001a\u00020\u0010H§@¢\u0006\u0004\b\u0013\u0010\u0014J8\u0010\u0018\u001a\u00020\u00122\b\b\u0001\u0010\u0015\u001a\u00020\u00022\b\b\u0003\u0010\u0011\u001a\u00020\u00102\b\b\u0003\u0010\u0016\u001a\u00020\u00022\b\b\u0003\u0010\u0017\u001a\u00020\u0002H§@¢\u0006\u0004\b\u0018\u0010\u0019¨\u0006\u001aÀ\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/ui/support/data/a;", "", "", "filename", "contentType", "Lvrb;", "file", "Lcom/gingerlabs/notability/ui/support/data/k;", "d", "(Ljava/lang/String;Ljava/lang/String;Lvrb;Lce2;)Ljava/lang/Object;", "Lcom/gingerlabs/notability/ui/support/data/h;", "request", "Lcom/gingerlabs/notability/ui/support/data/i;", "c", "(Lcom/gingerlabs/notability/ui/support/data/h;Lce2;)Ljava/lang/Object;", "query", "", "perPage", "Lcom/gingerlabs/notability/ui/support/data/b;", "a", "(Ljava/lang/String;ILce2;)Ljava/lang/Object;", "sectionId", "sortBy", "createdAfter", "b", "(Ljava/lang/String;ILjava/lang/String;Ljava/lang/String;Lce2;)Ljava/lang/Object;", "support"}, k = 1, mv = {2, 3, 0}, xi = 48)
interface a {
    @qx4("global/zendesk/v2/help_center/articles/search.json")
    Object a(@u2b("query") String str, @u2b("per_page") int i, ce2<? super b> ce2Var);

    @qx4("global/zendesk/v2/help_center/articles/search.json")
    Object b(@u2b("section") String str, @u2b("per_page") int i, @u2b("sort_by") String str2, @u2b("created_after") String str3, ce2<? super b> ce2Var);

    @pu9("global/zendesk/v2/requests.json")
    @wc5({"Content-Encoding: identity"})
    Object c(@oy0 h hVar, ce2<? super i> ce2Var);

    @pu9("global/zendesk/v2/uploads.json")
    @wc5({"Content-Encoding: identity"})
    Object d(@u2b("filename") String str, @tc5("Content-Type") String str2, @oy0 vrb vrbVar, ce2<? super k> ce2Var);
}
