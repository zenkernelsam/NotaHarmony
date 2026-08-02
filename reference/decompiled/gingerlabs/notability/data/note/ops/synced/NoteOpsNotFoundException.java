package com.gingerlabs.notability.data.note.ops.synced;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002B\u0007¢\u0006\u0004\b\u0003\u0010\u0004¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/data/note/ops/synced/NoteOpsNotFoundException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "<init>", "()V", "ops"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoteOpsNotFoundException extends Exception {
    public NoteOpsNotFoundException() {
        super("Not found (404)");
    }
}
