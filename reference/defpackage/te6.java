package defpackage;

import android.content.Context;
import android.os.SystemClock;
import android.view.View;
import androidx.credentials.playservices.controllers.identitycredentials.signalcredentialstate.SignalCredentialStateController;
import java.util.Iterator;
import java.util.List;
import java.util.WeakHashMap;

/* JADX INFO: loaded from: classes.dex */
public final class te6 implements uu8, c14, vg2, br1, qcg, w02, jch {
    public static final /* synthetic */ te6 J = new te6(17);
    public static final /* synthetic */ te6 K = new te6(18);
    public static final /* synthetic */ te6 L = new te6(19);
    public static final /* synthetic */ te6 M = new te6(20);
    public static final /* synthetic */ te6 N = new te6(21);
    public static final /* synthetic */ te6 O = new te6(22);
    public static final /* synthetic */ te6 P = new te6(23);
    public static final /* synthetic */ te6 Q = new te6(24);
    public static final /* synthetic */ te6 R = new te6(25);
    public static final /* synthetic */ te6 S = new te6(26);
    public static final /* synthetic */ te6 T = new te6(27);
    public static final /* synthetic */ te6 U = new te6(28);
    public static final /* synthetic */ te6 V = new te6(29);
    public final /* synthetic */ int I;

    public /* synthetic */ te6(int i) {
        this.I = i;
    }

    public static final long i(int i, List list) {
        t0c t0cVar = t0c.L;
        int size = list.size();
        int i2 = i;
        for (int i3 = 0; i3 < size; i3++) {
            int i4 = ((s0c) list.get(i3)).c;
            if (i2 < i4) {
                return (((long) i3) << 32) | (((long) i2) & 4294967295L);
            }
            i2 -= i4;
        }
        throw new IllegalStateException(("visibleIndex " + i + " out of bounds for " + list.size() + " runs").toString());
    }

    public static final ew j(int i, String str) {
        WeakHashMap weakHashMap = l2g.x;
        return new ew(i, str);
    }

    public static final spf l(int i, String str) {
        WeakHashMap weakHashMap = l2g.x;
        return new spf(new q26(0, 0, 0, 0), str);
    }

    public static l2g m(s32 s32Var) {
        ay4 ay4Var = (ay4) s32Var;
        View view = (View) ay4Var.k(ep.f);
        l2g l2gVarP = p(view);
        boolean zI = ay4Var.i(l2gVarP) | ay4Var.i(view);
        Object objS = ay4Var.S();
        if (zI || objS == q32.a) {
            objS = new ruc(25, l2gVarP, view);
            ay4Var.p0(objS);
        }
        ny7.e(l2gVarP, (ov4) objS, ay4Var);
        return l2gVarP;
    }

    public static int n(Iterable iterable, double d) {
        double dR = 0.0d;
        if (d <= 0.0d) {
            return 0;
        }
        double d2 = d * 0.5d * 0.5d * 0.5d;
        Iterator it = iterable.iterator();
        while (it.hasNext()) {
            ic0 ic0Var = (ic0) it.next();
            if (!ic0Var.v() && ic0Var.b.b != 0) {
                dR += ic0Var.r();
            }
        }
        int iCeil = (int) Math.ceil((dR / d2) * 2.0d);
        if (iCeil < 1) {
            return 1;
        }
        return iCeil;
    }

    public static l2g p(View view) {
        l2g l2gVar;
        WeakHashMap weakHashMap = l2g.x;
        synchronized (weakHashMap) {
            try {
                Object l2gVar2 = weakHashMap.get(view);
                if (l2gVar2 == null) {
                    l2gVar2 = new l2g(view);
                    weakHashMap.put(view, l2gVar2);
                }
                l2gVar = (l2g) l2gVar2;
            } catch (Throwable th) {
                throw th;
            }
        }
        return l2gVar;
    }

    public static void q(Iterable iterable, double d, skd skdVar, long j, a81 a81Var) {
        Iterator it = iterable.iterator();
        long j2 = j;
        a81 a81Var2 = a81Var;
        while (it.hasNext()) {
            xaa xaaVar = new xaa((ic0) it.next(), d, j2, a81Var2, null, 16);
            xaaVar.b(skdVar);
            j2 = xaaVar.g;
            a81Var2 = xaaVar.f;
        }
    }

    @Override // defpackage.uu8
    public boolean a(ja8 ja8Var) {
        return false;
    }

    @Override // defpackage.uu8
    public int b() {
        return 8;
    }

    @Override // defpackage.qcg
    public /* synthetic */ Object c() {
        return new udg();
    }

    @Override // defpackage.uu8
    public boolean d(ja8 ja8Var) {
        return yji.f(qzg.i(sdg.m0(ja8Var), false));
    }

    @Override // defpackage.br1
    public long e() {
        return SystemClock.elapsedRealtime();
    }

    @Override // defpackage.uu8
    public void f(tt6 tt6Var, long j, ig5 ig5Var, int i, boolean z) {
        b63 b63Var = tt6Var.o0;
        zu8 zu8Var = (zu8) b63Var.M;
        hwb hwbVar = zu8.x0;
        ((zu8) b63Var.M).g1(zu8.B0, zu8Var.Y0(j, true), ig5Var, 1, z);
    }

    @Override // defpackage.uu8
    public boolean g(ig5 ig5Var, tt6 tt6Var) {
        return false;
    }

    @Override // defpackage.uu8
    public boolean h(tt6 tt6Var) {
        sqc sqcVarW = tt6Var.w();
        boolean z = false;
        if (sqcVarW != null && sqcVarW.L) {
            z = true;
        }
        return !z;
    }

    @Override // defpackage.w02
    public Object k(h8e h8eVar) {
        return new w88();
    }

    public juc o(Context context) {
        juc jucVar;
        synchronized (this) {
            try {
                if (juc.P == null) {
                    juc.P = new juc(context);
                }
                jucVar = juc.P;
                if (jucVar == null) {
                    throw new IllegalStateException("Required value was null.");
                }
            } catch (Throwable th) {
                throw th;
            }
        }
        return jucVar;
    }

    @Override // defpackage.jch
    public Object zza() {
        switch (this.I) {
            case 17:
                List list = pxh.a;
                l4h.J.get();
                return (String) m4h.a.c(14, "measurement.edpb.events_cached_in_no_data_mode", "_f,_v,_cmp").get();
            case 18:
                List list2 = pxh.a;
                l4h.J.get();
                return Integer.valueOf((int) ((Long) m4h.a.b(100000L, 20, "measurement.store.max_stored_events_per_app").get()).longValue());
            case 19:
                List list3 = pxh.a;
                l4h.J.get();
                return (Long) m4h.a.b(21600000L, 52, "measurement.sgtm.upload.retry_max_wait").get();
            case 20:
                List list4 = pxh.a;
                l4h.J.get();
                return (Long) m4h.a.b(SignalCredentialStateController.MAX_RETRY_TIME, 48, "measurement.sgtm.upload.min_delay_after_background").get();
            case 21:
                List list5 = pxh.a;
                l4h.J.get();
                return (Long) m4h.a.b(500L, 28, "measurement.upload.minimum_delay").get();
            case 22:
                List list6 = pxh.a;
                l4h.J.get();
                return Integer.valueOf((int) ((Long) m4h.a.b(6L, 76, "measurement.upload.retry_count").get()).longValue());
            case 23:
                List list7 = pxh.a;
                s5h.J.get();
                return (String) t5h.a.c(5, "measurement.test.string_flag", "---").get();
            case 24:
                List list8 = pxh.a;
                l4h.J.get();
                return Integer.valueOf((int) ((Long) m4h.a.b(500L, 19, "measurement.upload.max_event_parameter_value_length").get()).longValue());
            case 25:
                List list9 = pxh.a;
                l4h.J.get();
                return (String) m4h.a.c(60, "measurement.rb.attribution.uri_scheme", "https").get();
            case 26:
                List list10 = pxh.a;
                l4h.J.get();
                return Integer.valueOf((int) ((Long) m4h.a.b(65536L, 75, "measurement.upload.max_batch_size").get()).longValue());
            case 27:
                List list11 = pxh.a;
                l4h.J.get();
                return Integer.valueOf((int) ((Long) m4h.a.b(3000L, 30, "measurement.rb.attribution.notify_app_delay_millis").get()).longValue());
            case am5.CALCULATE_TIME_SINCE_LAST_ATTEMPTED_OPTIMIZE_FIELD_NUMBER /* 28 */:
                List list12 = pxh.a;
                return Boolean.valueOf(q6h.b());
            default:
                List list13 = pxh.a;
                l4h.J.get();
                return Integer.valueOf((int) ((Long) m4h.a.b(1000L, 70, "measurement.upload.max_events_per_bundle").get()).longValue());
        }
    }
}
