package com.gingerlabs.notability.data.note.ops.synced;

import com.gingerlabs.notability.core.common.logging.a;
import defpackage.cl7;
import defpackage.iof;
import defpackage.p7;
import defpackage.p9;
import defpackage.um9;
import java.util.ArrayList;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002:\u0001\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/note/ops/synced/CorruptedSyncedOpException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "p9", "ops"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class CorruptedSyncedOpException extends Exception {
    public static final /* synthetic */ int I = 0;

    static {
        new p9(6);
    }

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public CorruptedSyncedOpException(iof iofVar, um9 um9Var, AssertionError assertionError) {
        super(p9.j(iofVar, um9Var), assertionError);
        iofVar.getClass();
        um9Var.getClass();
        ArrayList arrayList = a.a;
        a.c(cl7.SYNC, "Corrupted synced op", null, new p7(this, iofVar, um9Var, 14));
    }
}
