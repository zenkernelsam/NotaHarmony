package com.gingerlabs.notability.app.initializers;

import android.content.Context;
import android.os.Looper;
import com.gingerlabs.notability.app.NbApplication;
import com.gingerlabs.notability.core.common.logging.a;
import com.gingerlabs.notability.core.user.UserDataStoreInitializer;
import com.gingerlabs.notability.data.settings.NoteEditorSettingsInitializer;
import com.gingerlabs.notability.data.stylus.haptic.HapticPreferencesInitializer;
import com.gingerlabs.notability.data.theme.ThemeDataStoreInitializer;
import com.google.android.gms.common.internal.ImagesContract;
import defpackage.bjf;
import defpackage.ey5;
import defpackage.f38;
import defpackage.gf4;
import defpackage.gi9;
import defpackage.j1c;
import defpackage.ln9;
import defpackage.nmf;
import defpackage.ny7;
import defpackage.pua;
import defpackage.qj7;
import defpackage.tmf;
import defpackage.tqd;
import defpackage.us7;
import defpackage.xi7;
import defpackage.za4;
import java.util.ArrayList;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\b\u0012\u0004\u0012\u00020\u00020\u0001B\u0007¢\u0006\u0004\b\u0003\u0010\u0004¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/app/initializers/LoggingInitializer;", "Ley5;", "Lbjf;", "<init>", "()V", "app"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class LoggingInitializer implements ey5 {
    @Override // defpackage.ey5
    public final Object create(Context context) {
        context.getClass();
        String string = context.getApplicationContext().getSharedPreferences("backend_override", 0).getString(ImagesContract.URL, null);
        String string2 = string != null ? tqd.d1(string).toString() : null;
        if (string2 != null && string2.length() != 0) {
            j1c.k = string2;
        }
        Context applicationContext = context.getApplicationContext();
        applicationContext.getClass();
        NbApplication nbApplication = (NbApplication) applicationContext;
        ArrayList arrayList = a.a;
        gf4 gf4Var = gf4.a;
        ArrayList arrayList2 = a.a;
        arrayList2.add(gf4Var);
        arrayList2.add(new gi9((ln9) nbApplication.I.P.invoke()));
        qj7 qj7Var = (qj7) nbApplication.I.L0.invoke();
        qj7Var.getClass();
        arrayList2.add(qj7Var);
        za4 za4Var = (za4) nbApplication.I.K0.invoke();
        za4Var.getClass();
        arrayList2.add(za4Var);
        f38 f38Var = (f38) nbApplication.I.J2.invoke();
        f38Var.getClass();
        pua.P.N.a(new us7(f38Var, 1));
        tmf tmfVar = (tmf) ((nmf) nbApplication.I.g.invoke()).f().getValue();
        a.h(tmfVar != null ? tmfVar.a : null);
        if (!xi7.e) {
            xi7.e = true;
            final Thread.UncaughtExceptionHandler defaultUncaughtExceptionHandler = Thread.getDefaultUncaughtExceptionHandler();
            final Thread thread = Looper.getMainLooper().getThread();
            thread.getClass();
            Thread.setDefaultUncaughtExceptionHandler(new Thread.UncaughtExceptionHandler() { // from class: hja
                @Override // java.lang.Thread.UncaughtExceptionHandler
                public final void uncaughtException(Thread thread2, Throwable th) {
                    thread2.getClass();
                    th.getClass();
                    if (thread2 == thread || !w0j.c(th, new ija(0))) {
                        Thread.UncaughtExceptionHandler uncaughtExceptionHandler = defaultUncaughtExceptionHandler;
                        if (uncaughtExceptionHandler != null) {
                            uncaughtExceptionHandler.uncaughtException(thread2, th);
                            return;
                        }
                        return;
                    }
                    ArrayList arrayList3 = a.a;
                    jm7 jm7Var = jm7.L;
                    cl7 cl7Var = cl7.APP;
                    if (a.a(jm7Var, cl7Var)) {
                        try {
                            bl7 bl7Var = new bl7();
                            bl7Var.put("thread.name", thread2.getName());
                            a.e(jm7Var, cl7Var, "Swallowed Play Services certificate SecurityException", th, xs7.R(bl7Var));
                        } catch (Exception e) {
                            a.g(cl7Var, "Swallowed Play Services certificate SecurityException", e);
                        }
                    }
                }
            });
        }
        return bjf.a;
    }

    @Override // defpackage.ey5
    public final List dependencies() {
        return ny7.m0(UserDataStoreInitializer.class, ThemeDataStoreInitializer.class, NoteEditorSettingsInitializer.class, HapticPreferencesInitializer.class);
    }
}
