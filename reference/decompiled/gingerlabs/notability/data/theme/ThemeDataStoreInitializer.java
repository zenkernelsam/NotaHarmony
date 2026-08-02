package com.gingerlabs.notability.data.theme;

import android.content.Context;
import com.gingerlabs.notability.app.NbApplication;
import defpackage.bjf;
import defpackage.e50;
import defpackage.ey5;
import defpackage.ru3;
import defpackage.vi2;
import defpackage.w45;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\b\u0012\u0004\u0012\u00020\u00020\u0001B\u0007¢\u0006\u0004\b\u0003\u0010\u0004¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/data/theme/ThemeDataStoreInitializer;", "Ley5;", "Lbjf;", "<init>", "()V", "theme"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class ThemeDataStoreInitializer implements ey5 {
    @Override // defpackage.ey5
    public final Object create(Context context) {
        context.getClass();
        Context applicationContext = context.getApplicationContext();
        if (applicationContext instanceof NbApplication) {
            vi2.A(w45.I, null, null, new e50((NbApplication) applicationContext, null, 3), 3);
        }
        return bjf.a;
    }

    @Override // defpackage.ey5
    public final List dependencies() {
        return ru3.I;
    }
}
