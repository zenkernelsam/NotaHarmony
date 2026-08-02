package com.gingerlabs.notability.core.retrofit;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/core/retrofit/HttpFailureException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "retrofit"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class HttpFailureException extends Exception {
    public final int I;
    public final String J;

    public HttpFailureException(int i, String str) {
        super("HTTP " + i + ": " + (str == null ? "" : str));
        this.I = i;
        this.J = str;
    }

    /* JADX INFO: renamed from: a, reason: from getter */
    public final String getJ() {
        return this.J;
    }
}
