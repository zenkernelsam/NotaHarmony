package com.gingerlabs.notability.data.billing.client;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"com/gingerlabs/notability/data/billing/client/PlayBillingClient$BillingException", "Ljava/lang/RuntimeException;", "Lkotlin/RuntimeException;", "billing"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class PlayBillingClient$BillingException extends RuntimeException {
    public final int I;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public PlayBillingClient$BillingException(int i, String str) {
        super(str);
        str.getClass();
        this.I = i;
    }

    /* JADX INFO: renamed from: a, reason: from getter */
    public final int getI() {
        return this.I;
    }
}
