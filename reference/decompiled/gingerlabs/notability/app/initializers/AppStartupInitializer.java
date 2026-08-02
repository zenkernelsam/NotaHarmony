package com.gingerlabs.notability.app.initializers;

import android.content.ContentResolver;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import app.rive.runtime.kotlin.core.Rive;
import com.gingerlabs.notability.app.NbApplication;
import com.gingerlabs.notability.core.common.logging.a;
import defpackage.a50;
import defpackage.ad5;
import defpackage.bjf;
import defpackage.bl7;
import defpackage.bp;
import defpackage.c50;
import defpackage.cl7;
import defpackage.d50;
import defpackage.dv2;
import defpackage.e50;
import defpackage.ev2;
import defpackage.ey5;
import defpackage.ind;
import defpackage.ja4;
import defpackage.jm7;
import defpackage.knd;
import defpackage.mf3;
import defpackage.ns2;
import defpackage.ny7;
import defpackage.o03;
import defpackage.o1e;
import defpackage.oc;
import defpackage.p16;
import defpackage.pc5;
import defpackage.qa4;
import defpackage.qc5;
import defpackage.qk4;
import defpackage.qy1;
import defpackage.r3b;
import defpackage.rc5;
import defpackage.rk;
import defpackage.s4g;
import defpackage.sa6;
import defpackage.t23;
import defpackage.tz0;
import defpackage.ud2;
import defpackage.v0g;
import defpackage.vi2;
import defpackage.w40;
import defpackage.x40;
import defpackage.xs7;
import java.util.ArrayList;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\b\u0007\u0018\u00002\b\u0012\u0004\u0012\u00020\u00020\u0001:\u0001\u0005B\u0007¢\u0006\u0004\b\u0003\u0010\u0004¨\u0006\u0006"}, d2 = {"Lcom/gingerlabs/notability/app/initializers/AppStartupInitializer;", "Ley5;", "Lbjf;", "<init>", "()V", "p16", "app"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class AppStartupInitializer implements ey5 {
    public final ud2 a;

    public AppStartupInitializer() {
        t23 t23Var = mf3.a;
        o03 o03Var = o03.K;
        o1e o1eVarM = s4g.m();
        o03Var.getClass();
        this.a = tz0.a(qy1.V(o03Var, o1eVarM));
    }

    @Override // defpackage.ey5
    public final Object create(Context context) {
        cl7 cl7Var = cl7.APP;
        context.getClass();
        Context applicationContext = context.getApplicationContext();
        applicationContext.getClass();
        NbApplication nbApplication = (NbApplication) applicationContext;
        ad5.T = new oc(nbApplication, 1);
        try {
            Rive.init$default(Rive.INSTANCE, nbApplication, null, 2, null);
        } catch (Exception e) {
            ArrayList arrayList = a.a;
            a.c(cl7Var, "Failed to initialize Rive", null, new a50(0, e));
        } catch (UnsatisfiedLinkError e2) {
            ArrayList arrayList2 = a.a;
            jm7 jm7Var = jm7.M;
            if (a.a(jm7Var, cl7Var)) {
                try {
                    a.e(jm7Var, cl7Var, "Rive native library missing", e2, xs7.R(new bl7()));
                } catch (Exception e3) {
                    a.g(cl7Var, "Rive native library missing", e3);
                }
            }
        }
        vi2.A(this.a, null, null, new d50(2, 0, null), 3);
        knd kndVar = dv2.a;
        vi2.A(this.a, null, null, new e50(nbApplication, null, 0), 3);
        vi2.A(this.a, null, null, new c50(nbApplication, null, 3), 3);
        vi2.A(this.a, null, null, new c50(nbApplication, null, 0), 3);
        ja4 ja4Var = new ja4(nbApplication);
        p16 p16Var = new p16();
        p16Var.I = ja4Var;
        p16Var.J = (ind) ja4Var.g.getValue();
        qa4 qa4Var = qa4.a;
        ud2 ud2Var = this.a;
        ud2Var.getClass();
        sa6 sa6Var = qa4.e;
        if (sa6Var != null) {
            sa6Var.a(null);
        }
        qa4.c = p16Var;
        qa4.d = ud2Var;
        qa4.e = bp.g0(new qk4((ind) p16Var.J, new ns2(2, 2, null), 3), ud2Var);
        ev2 ev2Var = new ev2(nbApplication);
        ud2 ud2Var2 = this.a;
        ud2Var2.getClass();
        sa6 sa6Var2 = dv2.e;
        if (sa6Var2 != null) {
            sa6Var2.a(null);
        }
        dv2.c = ev2Var;
        dv2.d = ud2Var2;
        dv2.e = bp.g0(new qk4((ind) ev2Var.g.getValue(), new ns2(2, 1, null), 3), ud2Var2);
        vi2.A(this.a, null, null, new c50(nbApplication, null, 1), 3);
        if (rc5.b.compareAndSet(false, true)) {
            Context applicationContext2 = nbApplication.getApplicationContext();
            ContentResolver contentResolver = applicationContext2.getContentResolver();
            Uri uriFor = Settings.Secure.getUriFor("high_text_contrast_enabled");
            rc5.a(applicationContext2);
            contentResolver.registerContentObserver(uriFor, false, new qc5(applicationContext2, new Handler(Looper.getMainLooper()), 0));
        }
        ((Boolean) pc5.a.getValue()).getClass();
        x40 x40Var = (x40) nbApplication.I.E0.invoke();
        ud2 ud2Var3 = this.a;
        x40Var.getClass();
        ud2Var3.getClass();
        vi2.A(ud2Var3, null, null, new w40(x40Var, null, 0), 3);
        v0g v0gVar = (v0g) nbApplication.I.G0.invoke();
        ud2 ud2Var4 = this.a;
        v0gVar.getClass();
        ud2Var4.getClass();
        vi2.A(ud2Var4, null, null, new r3b(v0gVar, null, 17), 3);
        if (Build.VERSION.SDK_INT >= 35) {
            vi2.A(this.a, null, null, new rk(nbApplication, null, 2), 3);
        }
        return bjf.a;
    }

    @Override // defpackage.ey5
    public final List dependencies() {
        return ny7.l0(LoggingInitializer.class);
    }
}
