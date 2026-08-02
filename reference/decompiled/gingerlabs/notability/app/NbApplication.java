package com.gingerlabs.notability.app;

import android.app.Application;
import android.content.Context;
import android.os.Process;
import android.os.StrictMode;
import com.gingerlabs.notability.data.handwritingrecognition.HandwritingPackDownloadWorker;
import com.gingerlabs.notability.data.library.state.LibraryStateUploaderWorker;
import com.gingerlabs.notability.data.library.state.notes.NoteOpsUpdaterWorker;
import com.gingerlabs.notability.data.note.assets.NoteAssetDownloadWorker;
import com.gingerlabs.notability.data.note.assets.NoteAssetUploadWorker;
import defpackage.acb;
import defpackage.ba0;
import defpackage.bp;
import defpackage.bu2;
import defpackage.ce2;
import defpackage.cu2;
import defpackage.d79;
import defpackage.db9;
import defpackage.dl;
import defpackage.dlb;
import defpackage.du2;
import defpackage.dw;
import defpackage.e62;
import defpackage.el;
import defpackage.elb;
import defpackage.f30;
import defpackage.fl;
import defpackage.gf4;
import defpackage.gre;
import defpackage.ha5;
import defpackage.hu2;
import defpackage.ia5;
import defpackage.ii;
import defpackage.ja9;
import defpackage.jnb;
import defpackage.k79;
import defpackage.kbb;
import defpackage.lh6;
import defpackage.lm4;
import defpackage.lm8;
import defpackage.m1b;
import defpackage.mf3;
import defpackage.mm8;
import defpackage.mua;
import defpackage.ns7;
import defpackage.nu7;
import defpackage.nua;
import defpackage.o03;
import defpackage.o9d;
import defpackage.oi2;
import defpackage.p7e;
import defpackage.pa4;
import defpackage.pa7;
import defpackage.pua;
import defpackage.q34;
import defpackage.qa4;
import defpackage.qk4;
import defpackage.r3b;
import defpackage.rg;
import defpackage.rp9;
import defpackage.sgb;
import defpackage.sk;
import defpackage.t23;
import defpackage.t40;
import defpackage.tyd;
import defpackage.us7;
import defpackage.v39;
import defpackage.v68;
import defpackage.vi2;
import defpackage.w20;
import defpackage.w40;
import defpackage.wba;
import defpackage.ws7;
import defpackage.x41;
import defpackage.xs7;
import defpackage.y72;
import defpackage.y7b;
import defpackage.yl2;
import defpackage.z20;
import defpackage.z7b;
import java.util.concurrent.Executor;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0010\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u00012\u00020\u0002B\u0007¢\u0006\u0004\b\u0003\u0010\u0004¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/app/NbApplication;", "Landroid/app/Application;", "Lo9d;", "<init>", "()V", "app"}, k = 1, mv = {2, 3, 0}, xi = 48)
public class NbApplication extends Application implements o9d {
    public static final /* synthetic */ int J = 0;
    public final z20 I = new z20(this);

    @Override // defpackage.o9d
    public final acb a(Context context) {
        context.getClass();
        return (acb) this.I.j.invoke();
    }

    public final pa7 b() {
        return (pa7) this.I.i0.invoke();
    }

    public final e62 c() {
        t23 t23Var = mf3.a;
        Executor executorL = hu2.l(ns7.a.N);
        w20 w20Var = new w20();
        t23 t23Var2 = mf3.a;
        w20Var.I = hu2.l(t23Var2);
        w20Var.L = hu2.l(t23Var2);
        t23Var2.getClass();
        w20Var.J = t23Var2;
        z20 z20Var = this.I;
        z20Var.getClass();
        nu7 nu7Var = new nu7(5);
        elb elbVar = dlb.a;
        lh6 lh6VarB = elbVar.b(HandwritingPackDownloadWorker.class);
        m1b m1bVar = z20Var.R0;
        m1bVar.getClass();
        nu7Var.put(lh6VarB, new ha5(new ia5(m1bVar), 0));
        lh6 lh6VarB2 = elbVar.b(LibraryStateUploaderWorker.class);
        m1b m1bVar2 = z20Var.c0;
        m1bVar2.getClass();
        nu7Var.put(lh6VarB2, new ha5(new ia5(m1bVar2), 1));
        lh6 lh6VarB3 = elbVar.b(NoteAssetUploadWorker.class);
        m1b m1bVar3 = z20Var.U;
        m1bVar3.getClass();
        nu7Var.put(lh6VarB3, new ha5(new yl2(m1bVar3), 3));
        lh6 lh6VarB4 = elbVar.b(NoteOpsUpdaterWorker.class);
        m1b m1bVar4 = z20Var.X;
        m1b m1bVar5 = z20Var.b0;
        m1b m1bVar6 = z20Var.d0;
        m1b m1bVar7 = z20Var.e0;
        m1bVar4.getClass();
        m1bVar5.getClass();
        m1bVar6.getClass();
        m1bVar7.getClass();
        nu7Var.put(lh6VarB4, new ha5(new d79(m1bVar4, m1bVar5, m1bVar6, m1bVar7), 4));
        lh6 lh6VarB5 = elbVar.b(NoteAssetDownloadWorker.class);
        m1b m1bVar8 = z20Var.U;
        m1bVar8.getClass();
        nu7Var.put(lh6VarB5, new ha5(new yl2(m1bVar8), 2));
        w20Var.K = new v68(nu7Var.b());
        w20Var.M = new mm8(executorL, 0);
        w20Var.N = new mm8(executorL, 1);
        w20Var.P = new mm8(executorL, 2);
        w20Var.O = new mm8(executorL, 3);
        return new e62(w20Var);
    }

    @Override // android.app.Application
    public final void onCreate() {
        StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.LAX);
        StrictMode.setVmPolicy(StrictMode.VmPolicy.LAX);
        super.onCreate();
        nua nuaVar = nua.d;
        int i = 0;
        int i2 = 1;
        if (nuaVar.c.compareAndSet(false, true)) {
            nuaVar.a();
            gre greVar = new gre(new mua(nuaVar, i));
            greVar.setDaemon(true);
            greVar.setName("ProcessFreezeDetector");
            greVar.start();
        }
        p7e p7eVar = x41.a;
        ((sk) this.I.q0.invoke()).a();
        fl flVar = (fl) this.I.r0.invoke();
        ce2 ce2Var = null;
        flVar.a.a(new dl(flVar, (ce2) null));
        int i3 = 6;
        int i4 = 3;
        bp.g0(new qk4(new dw(flVar.b.c, i3), new el(flVar, ce2Var, i), i4), flVar.c);
        ((tyd) this.I.C0.invoke()).a();
        ((v39) this.I.y0.invoke()).a();
        oi2 oi2Var = (oi2) this.I.s0.invoke();
        oi2Var.getClass();
        gf4 gf4Var = gf4.a;
        gf4.b = new t40(oi2Var, 9);
        vi2.A(oi2Var.b, null, null, new w40(oi2Var, ce2Var, i4), 3);
        du2 du2Var = (du2) this.I.t0.invoke();
        xs7.e = du2Var.b;
        pua puaVar = pua.P;
        int i5 = 2;
        bp.g0(new qk4(bp.k0(new bu2(new dw(ba0.s(puaVar.N), i5), i), new bu2(new rg(i5, i5, ce2Var), 16)), new cu2(du2Var, ce2Var, i), i4), du2Var.a);
        pa4 pa4Var = (pa4) this.I.v0.invoke();
        pa4Var.getClass();
        int i6 = 5;
        dw dwVar = new dw(qa4.f, i6);
        int i7 = 4;
        bu2 bu2Var = new bu2(new dw(ba0.s(puaVar.N), i7), i2);
        kbb kbbVar = jnb.f;
        bp.g0(new qk4(bp.N(bp.k0(dwVar, kbbVar, bu2Var), pa4.b), new cu2(pa4Var, ce2Var, i2), i4), pa4Var.a);
        q34 q34Var = (q34) this.I.u0.invoke();
        q34Var.getClass();
        bp.g0(new qk4(new qk4(kbbVar, new rg(i5, i4, ce2Var)), new w40(q34Var, ce2Var, i6), i4), q34Var.a);
        ws7 ws7Var = (ws7) this.I.w0.invoke();
        ws7Var.getClass();
        puaVar.N.a(new us7(ws7Var, i));
        wba wbaVar = (wba) this.I.B0.invoke();
        wbaVar.getClass();
        bp.g0(new qk4(bp.k0(new bu2(new ja9(ba0.s(puaVar.N), 7), 11), bp.A0(wbaVar.c, new lm4(i4, i7, ce2Var))), new el(wbaVar, ce2Var, 22), i4), wbaVar.a);
        db9 db9Var = (db9) this.I.C1.invoke();
        bp.g0(new qk4(db9Var.b.r, new k79(db9Var, ce2Var, i7), i4), db9Var.a);
        y7b y7bVar = (y7b) this.I.n1.invoke();
        y72 y72Var = y7bVar.e;
        y72Var.a();
        int i8 = 8;
        int i9 = 13;
        bp.g0(new qk4(bp.N(new qk4(bp.k0(new bu2(new rp9(new dw(y72Var.a, i3), i2), 12), new bu2(new ja9(ba0.s(puaVar.N), i8), i9)), new rg(i5, i8, ce2Var)), z7b.a), new r3b(y7bVar, ce2Var, i2), i4), y7bVar.a);
        sgb sgbVar = (sgb) this.I.B2.invoke();
        f30 f30Var = sgbVar.b;
        t23 t23Var = mf3.a;
        vi2.A(f30Var, o03.K, null, new cu2(sgbVar, ce2Var, i9), 2);
        ((lm8) this.I.p0.invoke()).c(new ii(Process.myPid()));
    }
}
