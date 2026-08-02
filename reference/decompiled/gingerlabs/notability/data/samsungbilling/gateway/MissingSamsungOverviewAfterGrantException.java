package com.gingerlabs.notability.data.samsungbilling.gateway;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00060\u0001j\u0002`\u0002B\u0007¢\u0006\u0004\b\u0003\u0010\u0004¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/data/samsungbilling/gateway/MissingSamsungOverviewAfterGrantException;", "Ljava/lang/IllegalStateException;", "Lkotlin/IllegalStateException;", "<init>", "()V", "samsung-billing"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MissingSamsungOverviewAfterGrantException extends IllegalStateException {
    public MissingSamsungOverviewAfterGrantException() {
        super("No subscription overview after a validated Samsung purchase");
    }
}
