package com.gingerlabs.notability.data.library.state.folders;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/data/library/state/folders/InvalidFolderNameException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "state"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class InvalidFolderNameException extends Exception {
    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public InvalidFolderNameException(String str) {
        super("Tried to create a new folder or rename a folder with an invalid name=".concat(str));
        str.getClass();
    }
}
