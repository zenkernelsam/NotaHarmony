package com.gingerlabs.notability.app;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import defpackage.hu2;
import defpackage.mf3;
import defpackage.mu;
import defpackage.o03;
import defpackage.t23;
import defpackage.x76;
import java.util.concurrent.Executor;
import java.util.concurrent.atomic.AtomicBoolean;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/app/AppUpgradeReceiver;", "Landroid/content/BroadcastReceiver;", "<init>", "()V", "app"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class AppUpgradeReceiver extends BroadcastReceiver {
    public static final Executor a;

    static {
        t23 t23Var = mf3.a;
        a = hu2.l(o03.K);
    }

    public static final void a(AtomicBoolean atomicBoolean, BroadcastReceiver.PendingResult pendingResult) {
        if (atomicBoolean.compareAndSet(false, true)) {
            pendingResult.finish();
        }
    }

    @Override // android.content.BroadcastReceiver
    public final void onReceive(Context context, Intent intent) {
        context.getClass();
        intent.getClass();
        if (x76.p(intent.getAction(), "android.intent.action.MY_PACKAGE_REPLACED")) {
            a.execute(new mu(context.getApplicationContext(), new AtomicBoolean(false), goAsync(), 1));
        }
    }
}
