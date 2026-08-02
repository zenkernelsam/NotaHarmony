package com.gingerlabs.notability.data.samsungbilling.client;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"com/gingerlabs/notability/data/samsungbilling/client/SamsungBillingClient$SamsungBillingException", "Ljava/lang/RuntimeException;", "Lkotlin/RuntimeException;", "samsung-billing"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class SamsungBillingClient$SamsungBillingException extends RuntimeException {
    public final int I;

    public SamsungBillingClient$SamsungBillingException(int i, String str) {
        super(str);
        this.I = i;
    }
}
