package com.gingerlabs.notability.data.library.state.ntb;

import defpackage.f92;
import java.util.ArrayList;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\u000e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00060\u0001j\u0002`\u0002¨\u0006\u0003"}, d2 = {"Lcom/gingerlabs/notability/data/library/state/ntb/MissingAssetsException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "state"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MissingAssetsException extends Exception {
    public final ArrayList I;

    public MissingAssetsException(ArrayList arrayList) {
        super(f92.j(arrayList.size(), "Cannot export note: ", " asset(s) not downloaded locally"));
        this.I = arrayList;
    }
}
