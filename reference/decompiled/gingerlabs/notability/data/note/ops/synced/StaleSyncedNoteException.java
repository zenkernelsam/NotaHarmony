package com.gingerlabs.notability.data.note.ops.synced;

import defpackage.iof;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/data/note/ops/synced/StaleSyncedNoteException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "ops"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class StaleSyncedNoteException extends Exception {
    public final iof I;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public StaleSyncedNoteException(iof iofVar) {
        super("Synced note metadata not found: ".concat(iofVar.toString()));
        iofVar.getClass();
        this.I = iofVar;
    }
}
