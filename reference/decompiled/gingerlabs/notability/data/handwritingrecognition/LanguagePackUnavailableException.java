package com.gingerlabs.notability.data.handwritingrecognition;

import defpackage.ka5;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/data/handwritingrecognition/LanguagePackUnavailableException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "handwritingrecognition"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class LanguagePackUnavailableException extends Exception {
    public final ka5 I;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public LanguagePackUnavailableException(ka5 ka5Var) {
        super("No recognition assets available for ".concat(ka5Var.I), null);
        ka5Var.getClass();
        this.I = ka5Var;
    }

    /* JADX INFO: renamed from: a, reason: from getter */
    public final ka5 getI() {
        return this.I;
    }
}
