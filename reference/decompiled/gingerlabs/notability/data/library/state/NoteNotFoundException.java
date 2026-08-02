package com.gingerlabs.notability.data.library.state;

import defpackage.f92;
import defpackage.iof;
import java.io.IOException;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0000\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/data/library/state/NoteNotFoundException;", "Ljava/io/IOException;", "state"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoteNotFoundException extends IOException {
    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public NoteNotFoundException(iof iofVar) {
        super(f92.m("Note ", iofVar.toString(), " not found on server (404)"));
        iofVar.getClass();
    }
}
