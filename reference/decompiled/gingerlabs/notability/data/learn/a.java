package com.gingerlabs.notability.data.learn;

import androidx.credentials.provider.CredentialEntry;
import defpackage.cl7;
import defpackage.e36;
import defpackage.gai;
import defpackage.j10;
import defpackage.p10;
import defpackage.q10;
import defpackage.ru3;
import defpackage.v72;
import defpackage.yj5;
import defpackage.zs1;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/* JADX INFO: loaded from: classes2.dex */
public abstract class a {
    public static final e36 a(Object obj) {
        e36 e36VarB = b(obj);
        if (e36VarB != null) {
            return e36VarB;
        }
        e36 e36Var = e36.K;
        return v72.p(999999999, -3217862419201L);
    }

    public static final e36 b(Object obj) {
        String str = obj instanceof String ? (String) obj : null;
        if (str == null) {
            return null;
        }
        try {
            e36 e36Var = e36.K;
            return gai.b(str).toInstant();
        } catch (IllegalArgumentException e) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            com.gingerlabs.notability.core.common.logging.a.c(cl7.LEARN, "Failed to parse DateTime", null, new p10(e, 0));
            return null;
        }
    }

    public static final void c(j10 j10Var) {
        j10Var.getClass();
        q10 q10Var = j10Var.b;
        q10Var.getClass();
        Collection collection = (List) q10Var.e;
        if (collection == null) {
            collection = ru3.I;
        }
        q10Var.e = zs1.A1(collection, new yj5("X-Nb-Skip-Gzip", CredentialEntry.TRUE_STRING));
    }
}
