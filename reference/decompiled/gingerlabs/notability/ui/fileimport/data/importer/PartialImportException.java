package com.gingerlabs.notability.ui.fileimport.data.importer;

import defpackage.f92;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/ui/fileimport/data/importer/PartialImportException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "data"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class PartialImportException extends Exception {
    public final List I;

    public PartialImportException(List list, Throwable th) {
        super(f92.j(list.size(), "Import partially succeeded: ", " notes created"), th);
        this.I = list;
    }
}
