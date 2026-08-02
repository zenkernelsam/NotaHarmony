package com.gingerlabs.notability.core.network;

import defpackage.b7d;
import java.io.IOException;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/core/network/HttpStatusException;", "Ljava/io/IOException;", "network"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class HttpStatusException extends IOException {
    public final int I;
    public final String J;
    public final String K;

    public HttpStatusException(int i, String str, String str2, String str3, String str4) {
        str.getClass();
        str2.getClass();
        StringBuilder sb = new StringBuilder("HTTP request failed with code: ");
        sb.append(i);
        sb.append(" for url : ");
        super(b7d.j(sb, str2, " ", str));
        this.I = i;
        this.J = str3;
        this.K = str4;
    }

    /* JADX INFO: renamed from: a, reason: from getter */
    public final String getK() {
        return this.K;
    }

    /* JADX INFO: renamed from: b, reason: from getter */
    public final int getI() {
        return this.I;
    }

    /* JADX INFO: renamed from: c, reason: from getter */
    public final String getJ() {
        return this.J;
    }
}
