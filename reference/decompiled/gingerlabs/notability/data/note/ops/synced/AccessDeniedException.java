package com.gingerlabs.notability.data.note.ops.synced;

import defpackage.y73;
import defpackage.z73;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/data/note/ops/synced/AccessDeniedException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "ops"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class AccessDeniedException extends Exception {
    public final z73 I;
    public final y73 J;
    public final String K;

    public AccessDeniedException(z73 z73Var, y73 y73Var, String str) {
        super("Access denied (403)");
        this.I = z73Var;
        this.J = y73Var;
        this.K = str;
    }
}
