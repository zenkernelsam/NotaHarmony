package com.gingerlabs.notability.app;

import android.app.ActivityManager;
import android.app.AlertDialog;
import android.app.ComponentCaller;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentSender;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.os.Build;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import androidx.recyclerview.widget.RecyclerView;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.app.MainActivity;
import com.gingerlabs.notability.core.common.logging.a;
import com.google.android.play.core.install.zza;
import defpackage.aod;
import defpackage.as7;
import defpackage.av3;
import defpackage.bjf;
import defpackage.bl7;
import defpackage.bs7;
import defpackage.cd3;
import defpackage.ce2;
import defpackage.cl7;
import defpackage.cm8;
import defpackage.cr3;
import defpackage.cs7;
import defpackage.cz6;
import defpackage.de2;
import defpackage.dlb;
import defpackage.dv2;
import defpackage.es7;
import defpackage.eyh;
import defpackage.gh2;
import defpackage.guf;
import defpackage.gv2;
import defpackage.h5j;
import defpackage.hm8;
import defpackage.idj;
import defpackage.ikd;
import defpackage.im8;
import defpackage.in;
import defpackage.iuf;
import defpackage.jm7;
import defpackage.jp3;
import defpackage.js7;
import defpackage.k50;
import defpackage.knd;
import defpackage.mdd;
import defpackage.n12;
import defpackage.np3;
import defpackage.ny7;
import defpackage.o1e;
import defpackage.ob5;
import defpackage.oh3;
import defpackage.okd;
import defpackage.or7;
import defpackage.ov4;
import defpackage.p7e;
import defpackage.p7j;
import defpackage.pkd;
import defpackage.pm7;
import defpackage.q02;
import defpackage.q68;
import defpackage.qy1;
import defpackage.r02;
import defpackage.rc6;
import defpackage.rdd;
import defpackage.rfi;
import defpackage.rzc;
import defpackage.s4g;
import defpackage.sa;
import defpackage.sdg;
import defpackage.sg9;
import defpackage.t26;
import defpackage.tr7;
import defpackage.tz0;
import defpackage.u26;
import defpackage.ub9;
import defpackage.ur7;
import defpackage.vi2;
import defpackage.vr7;
import defpackage.x76;
import defpackage.xj9;
import defpackage.xr7;
import defpackage.xs7;
import defpackage.xub;
import defpackage.yr7;
import defpackage.yub;
import defpackage.yz3;
import defpackage.z20;
import defpackage.zs1;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ConcurrentLinkedQueue;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0006²\u0006\f\u0010\u0005\u001a\u00020\u00048\nX\u008a\u0084\u0002"}, d2 = {"Lcom/gingerlabs/notability/app/MainActivity;", "Lq02;", "<init>", "()V", "Lhs7;", "uiState", "app"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MainActivity extends q02 {
    public static boolean W = true;
    public static final ConcurrentLinkedQueue X = new ConcurrentLinkedQueue();
    public static final long Y;
    public static final long Z;
    public boolean S;
    public ov4 T;
    public Boolean U;
    public final guf I = new guf(dlb.a.b(js7.class), new es7(this, 1), new es7(this, 0), new es7(this, 2));
    public final p7e J = new p7e(new tr7(this, 2));
    public final p7e K = new p7e(new tr7(this, 3));
    public final o1e L = s4g.m();
    public final as7 M = new as7(this);
    public final p7e N = new p7e(new tr7(this, 4));
    public final p7e O = new p7e(new tr7(this, 5));
    public final p7e P = new p7e(new tr7(this, 6));
    public final p7e Q = new p7e(new tr7(this, 7));
    public final p7e R = new p7e(new tr7(this, 0));
    public final ur7 V = new aod() { // from class: ur7
        @Override // defpackage.aod
        public final void a(Object obj) {
            boolean z = MainActivity.W;
            if (((zza) obj).a() == 11) {
                this.a.l();
            }
        }
    };

    static {
        p7j p7jVar = jp3.J;
        Y = sdg.r0(2, np3.SECONDS);
        Z = sdg.r0(150, np3.MILLISECONDS);
    }

    /* JADX WARN: Code duplicated, block: B:8:0x0014  */
    public static final Object g(MainActivity mainActivity, Set set, rdd rddVar, de2 de2Var) {
        bs7 bs7Var;
        if (de2Var instanceof bs7) {
            bs7Var = (bs7) de2Var;
            int i = bs7Var.L;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                bs7Var.L = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                bs7Var = new bs7(mainActivity, de2Var);
            }
        } else {
            bs7Var = new bs7(mainActivity, de2Var);
        }
        bs7 bs7Var2 = bs7Var;
        Object objL0 = bs7Var2.J;
        int i2 = bs7Var2.L;
        bjf bjfVar = bjf.a;
        int i3 = 1;
        ce2 ce2Var = null;
        gh2 gh2Var = gh2.I;
        if (i2 == 0) {
            ny7.F0(objL0);
            or7 or7Var = new or7(i3, ce2Var, mainActivity, set);
            bs7Var2.I = rddVar;
            bs7Var2.L = 1;
            objL0 = qy1.l0(Y, or7Var, bs7Var2);
            if (objL0 != gh2Var) {
            }
            return gh2Var;
        }
        if (i2 != 1) {
            if (i2 == 2) {
                ny7.F0(objL0);
                return bjfVar;
            }
            yz3.l("call to 'resume' before 'invoke' with coroutine");
            return null;
        }
        rddVar = bs7Var2.I;
        ny7.F0(objL0);
        if (objL0 == null) {
            ArrayList arrayList = a.a;
            a.d(jm7.J, cl7.APP, "New Window launch did not open a window");
            String string = mainActivity.getString(R.string.app__error_could_not_open_new_window);
            string.getClass();
            bs7Var2.I = null;
            bs7Var2.L = 2;
            if (rdd.b(rddVar, string, null, mdd.I, bs7Var2, 6) == gh2Var) {
                return gh2Var;
            }
        }
        return bjfVar;
    }

    public static final Set h(MainActivity mainActivity) {
        List<ActivityManager.AppTask> appTasks = ((ActivityManager) mainActivity.Q.getValue()).getAppTasks();
        appTasks.getClass();
        ArrayList arrayList = new ArrayList();
        Iterator<T> it = appTasks.iterator();
        while (it.hasNext()) {
            ActivityManager.RecentTaskInfo taskInfo = ((ActivityManager.AppTask) it.next()).getTaskInfo();
            Integer numValueOf = taskInfo != null ? Integer.valueOf(taskInfo.taskId) : null;
            if (numValueOf != null) {
                arrayList.add(numValueOf);
            }
        }
        return zs1.W1(arrayList);
    }

    @Override // defpackage.p02, android.app.Activity, android.view.Window.Callback
    public final boolean dispatchKeyEvent(KeyEvent keyEvent) {
        keyEvent.getClass();
        knd kndVar = dv2.a;
        if (!h5j.b(keyEvent) || !((gv2) this.N.getValue()).a()) {
            if (!cm8.a(keyEvent)) {
                hm8 hm8VarB = cm8.b(keyEvent);
                if (hm8VarB == null) {
                    return super.dispatchKeyEvent(keyEvent);
                }
                if (keyEvent.getAction() == 1) {
                    im8 im8Var = (im8) this.O.getValue();
                    im8Var.getClass();
                    im8Var.a.e(hm8VarB);
                }
            } else if (keyEvent.getAction() == 1) {
                Configuration configuration = getResources().getConfiguration();
                configuration.getClass();
                if (configuration.smallestScreenWidthDp >= 600) {
                    ov4 ov4Var = this.T;
                    if (ov4Var != null) {
                        ov4Var.invoke(null);
                        return true;
                    }
                    ArrayList arrayList = a.a;
                    a.d(jm7.J, cl7.APP, "New Window chord dropped: launcher not ready");
                }
                return true;
            }
        }
        return true;
    }

    @Override // android.app.Activity, android.view.Window.Callback
    public final boolean dispatchTouchEvent(MotionEvent motionEvent) {
        motionEvent.getClass();
        try {
            return super.dispatchTouchEvent(motionEvent);
        } catch (SecurityException e) {
            if (!xj9.b(e)) {
                throw e;
            }
            xj9.a(e);
            return false;
        }
    }

    @Override // defpackage.q02, defpackage.hc5
    public final iuf getDefaultViewModelProviderFactory() {
        return (q68) i().M2.invoke();
    }

    public final z20 i() {
        return (z20) this.K.getValue();
    }

    public final eyh j() {
        return (eyh) this.J.getValue();
    }

    public final js7 k() {
        return (js7) this.I.getValue();
    }

    public final void l() {
        if (this.S) {
            return;
        }
        this.S = true;
        new AlertDialog.Builder(this).setTitle(R.string.app__update_ready_title).setMessage(R.string.app__update_ready_message).setPositiveButton(R.string.app__update_action_restart, new vr7(this, 0)).setNegativeButton(R.string.app__update_action_later, new DialogInterface.OnClickListener() { // from class: wr7
            @Override // android.content.DialogInterface.OnClickListener
            public final void onClick(DialogInterface dialogInterface, int i) {
                boolean z = MainActivity.W;
                dialogInterface.dismiss();
            }
        }).show();
    }

    public final void m() {
        new AlertDialog.Builder(this).setTitle(R.string.app__update_required_title).setMessage(R.string.app__update_required_message).setCancelable(false).setPositiveButton(R.string.app__update_action_update, new vr7(this, 1)).setNegativeButton(R.string.app__update_action_exit, new vr7(this, 2)).show();
    }

    public final boolean n(k50 k50Var, int i, int i2) {
        try {
            eyh eyhVarJ = j();
            idj idjVarA = idj.a(i).a();
            eyhVarJ.getClass();
            eyh.c(k50Var, this, idjVarA, i2);
            return true;
        } catch (IntentSender.SendIntentException e) {
            ArrayList arrayList = a.a;
            a.c(cl7.APP, "AppUpdateStartFailed", e, null);
            return false;
        }
    }

    public final void o() {
        boolean z = ((sg9) i().v2.invoke()).a() && !x76.p(this.U, Boolean.FALSE);
        setShowWhenLocked(z);
        setTurnScreenOn(z);
    }

    public final void onActivityResult(int i, int i2, Intent intent, ComponentCaller componentCaller) {
        componentCaller.getClass();
        super.onActivityResult(i, i2, intent, componentCaller);
        if (i != 1123 || i2 == -1) {
            return;
        }
        ArrayList arrayList = a.a;
        a.c(cl7.APP, "AppUpdateFailed", null, new cr3(i2, 1));
        m();
    }

    @Override // defpackage.q02, android.app.Activity, android.content.ComponentCallbacks
    public final void onConfigurationChanged(Configuration configuration) {
        configuration.getClass();
        super.onConfigurationChanged(configuration);
        knd kndVar = ((pm7) i().O.invoke()).a;
        kndVar.getClass();
        kndVar.k(null, configuration);
    }

    @Override // defpackage.q02, defpackage.p02, android.app.Activity
    public final void onCreate(Bundle bundle) throws Throwable {
        String str;
        int i;
        jm7 jm7Var = jm7.K;
        cl7 cl7Var = cl7.TOOLBAR;
        in inVar = new in(this);
        q02 q02Var = (q02) inVar.J;
        Resources.Theme theme = q02Var.getTheme();
        theme.getClass();
        TypedValue typedValue = new TypedValue();
        int i2 = 1;
        if (theme.resolveAttribute(R.attr.postSplashScreenTheme, typedValue, true) && (i = typedValue.resourceId) != 0) {
            q02Var.setTheme(i);
        }
        if (Build.VERSION.SDK_INT < 33) {
            View decorView = q02Var.getWindow().getDecorView();
            decorView.getClass();
            ((ViewGroup) decorView).setOnHierarchyChangeListener((okd) inVar.M);
        }
        super.onCreate(bundle);
        if (bundle != null && bundle.containsKey("showWhenLockedPolicy")) {
            this.U = Boolean.valueOf(bundle.getBoolean("showWhenLockedPolicy"));
        }
        o();
        pm7 pm7Var = (pm7) i().O.invoke();
        Configuration configuration = getResources().getConfiguration();
        configuration.getClass();
        knd kndVar = pm7Var.a;
        kndVar.getClass();
        ce2 ce2Var = null;
        kndVar.k(null, configuration);
        inVar.K = new rc6();
        View viewFindViewById = ((q02) inVar.J).findViewById(android.R.id.content);
        ViewTreeObserver viewTreeObserver = viewFindViewById.getViewTreeObserver();
        if (((pkd) inVar.L) != null && viewTreeObserver.isAlive()) {
            viewTreeObserver.removeOnPreDrawListener((pkd) inVar.L);
        }
        pkd pkdVar = new pkd(inVar, viewFindViewById);
        inVar.L = pkdVar;
        viewTreeObserver.addOnPreDrawListener(pkdVar);
        t26 t26Var = ((u26) i().O0.invoke()).a;
        int i3 = 0;
        if (t26Var == t26.PlayStore) {
            j().b(this.V);
            j().a().addOnSuccessListener(new oh3(new yr7(this, 0), 11));
        } else {
            ArrayList arrayList = a.a;
            cl7 cl7Var2 = cl7.APP;
            if (a.a(jm7Var, cl7Var2)) {
                try {
                    bl7 bl7Var = new bl7();
                    bl7Var.put("install.source", t26Var.I);
                    a.e(jm7Var, cl7Var2, "Skipped Play update check", null, xs7.R(bl7Var));
                } catch (Exception e) {
                    a.g(cl7Var2, "Skipped Play update check", e);
                }
            }
        }
        vi2.A(tz0.v(this), null, null, new cs7(this, ce2Var, i3), 3);
        vi2.A(tz0.v(this), null, null, new cs7(this, ce2Var, i2), 3);
        ikd ikdVar = (ikd) i().q2.invoke();
        ikdVar.getClass();
        Object xubVar = bjf.a;
        if (ikdVar.c != null) {
            ArrayList arrayList2 = a.a;
            a.d(jm7.I, cl7Var, "Spen Quick Tools already initialized, skipping");
        } else {
            ikdVar.c = Integer.valueOf(System.identityHashCode(this));
            try {
                ikdVar.a();
            } catch (Throwable th) {
                xubVar = new xub(th);
            }
            Throwable thA = yub.a(xubVar);
            if (thA != null && ((thA instanceof Error) || (thA instanceof CancellationException))) {
                throw thA;
            }
            Throwable thA2 = yub.a(xubVar);
            if (thA2 == null) {
                ArrayList arrayList3 = a.a;
                if (a.a(jm7Var, cl7Var)) {
                    try {
                        bl7 bl7Var2 = new bl7();
                        bl7 bl7Var3 = new bl7();
                        bl7Var3.put("spen_quick_tools.is_available", ikdVar.a.getValue());
                        bl7Var3.put("spen_quick_tools.is_samsung_device", Boolean.valueOf(cd3.a()));
                        bl7Var2.putAll(bl7Var3);
                        a.e(jm7Var, cl7Var, "Spen Quick Tools initialized", null, xs7.R(bl7Var2));
                    } catch (Exception e2) {
                        a.g(cl7Var, "Spen Quick Tools initialized", e2);
                    }
                }
            } else {
                if ((thA2 instanceof Error) || (thA2 instanceof CancellationException)) {
                    throw thA2;
                }
                Exception exc = (Exception) thA2;
                ArrayList arrayList4 = a.a;
                jm7 jm7Var2 = jm7.L;
                if (a.a(jm7Var2, cl7Var)) {
                    try {
                        a.e(jm7Var2, cl7Var, "Spen Quick Tools init failed", exc, xs7.R(new bl7()));
                    } catch (Exception e3) {
                        a.g(cl7Var, "Spen Quick Tools init failed", e3);
                    }
                }
                knd kndVar2 = ikdVar.a;
                Boolean bool = Boolean.FALSE;
                kndVar2.getClass();
                kndVar2.k(null, bool);
            }
        }
        if (getIntent().getStringExtra("note_id") == null && (str = (String) X.poll()) != null) {
            getIntent().putExtra("note_id", str);
        }
        if (bundle == null) {
            js7 js7VarK = k();
            Intent intent = getIntent();
            intent.getClass();
            js7VarK.i(intent);
        }
        r02.a(this, new n12(new xr7(this, 2), true, -1985076133));
    }

    @Override // android.app.Activity
    public final void onDestroy() {
        if (((u26) i().O0.invoke()).a == t26.PlayStore) {
            j().d(this.V);
        }
        ob5 ob5Var = (ob5) i().p2.invoke();
        ob5Var.getClass();
        ce2 ce2Var = null;
        if (ob5Var.l) {
            Integer num = ob5Var.m;
            int iIdentityHashCode = System.identityHashCode(this);
            if (num != null && num.intValue() == iIdentityHashCode) {
                ob5Var.l = false;
                ob5Var.m = null;
                knd kndVar = ob5Var.f;
                Boolean bool = Boolean.FALSE;
                kndVar.getClass();
                kndVar.k(null, bool);
                av3 av3Var = av3.I;
                ob5Var.j = av3Var;
                ob5Var.k = av3Var;
                vi2.A(ob5Var.b, ob5Var.d, null, new ub9(11, ce2Var, ob5Var, this), 2);
            }
        }
        ikd ikdVar = (ikd) i().q2.invoke();
        ikdVar.getClass();
        Integer num2 = ikdVar.c;
        int iIdentityHashCode2 = System.identityHashCode(this);
        if (num2 != null && num2.intValue() == iIdentityHashCode2) {
            ikdVar.c = null;
            knd kndVar2 = ikdVar.a;
            Boolean bool2 = Boolean.FALSE;
            kndVar2.getClass();
            kndVar2.k(null, bool2);
        } else {
            ArrayList arrayList = a.a;
            a.d(jm7.I, cl7.TOOLBAR, "Spen Quick Tools release from non-owning Activity ignored");
        }
        super.onDestroy();
    }

    @Override // defpackage.q02, android.app.Activity
    public final void onNewIntent(Intent intent) {
        intent.getClass();
        super.onNewIntent(intent);
        setIntent(intent);
        k().i(intent);
    }

    @Override // android.app.Activity
    public final void onPause() {
        ((SensorManager) this.P.getValue()).unregisterListener((rzc) this.R.getValue());
        super.onPause();
    }

    @Override // android.app.Activity, android.view.Window.Callback
    public final void onProvideKeyboardShortcuts(List list, Menu menu, int i) {
        list.getClass();
        Resources resources = getResources();
        resources.getClass();
        list.addAll(rfi.b(resources));
        super.onProvideKeyboardShortcuts(list, menu, i);
    }

    @Override // android.app.Activity
    public final void onResume() {
        super.onResume();
        p7e p7eVar = this.P;
        Sensor defaultSensor = ((SensorManager) p7eVar.getValue()).getDefaultSensor(1);
        if (defaultSensor != null) {
            ((SensorManager) p7eVar.getValue()).registerListener((rzc) this.R.getValue(), defaultSensor, 3);
        }
        if (((u26) i().O0.invoke()).a == t26.PlayStore) {
            j().a().addOnSuccessListener(new sa(new cz6(this, 5), 7));
        }
    }

    @Override // defpackage.q02, defpackage.p02, android.app.Activity
    public final void onSaveInstanceState(Bundle bundle) {
        bundle.getClass();
        super.onSaveInstanceState(bundle);
        Boolean bool = this.U;
        if (bool != null) {
            bundle.putBoolean("showWhenLockedPolicy", bool.booleanValue());
        }
    }

    @Override // android.app.Activity
    public final void onStart() {
        super.onStart();
        o();
    }
}
