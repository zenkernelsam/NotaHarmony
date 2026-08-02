package com.gingerlabs.notability.data.library.state.folders;

import defpackage.tg2;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/data/library/state/folders/MaxFolderDepthExceededException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "state"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MaxFolderDepthExceededException extends Exception {
    public MaxFolderDepthExceededException(int i) {
        super(tg2.l(i, "Tried to add a new folder or move a folder to depth="));
    }
}
