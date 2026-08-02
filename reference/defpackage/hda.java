package defpackage;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Matrix;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.MotionEvent;
import android.view.WindowInsetsAnimation;
import androidx.ink.strokes.StrokeInput;
import com.google.android.gms.common.api.internal.RemoteCall;
import com.google.android.gms.tasks.SuccessContinuation;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.google.android.play.core.assetpacks.b;
import com.google.android.play.core.assetpacks.n;
import com.google.firebase.remoteconfig.FirebaseRemoteConfigClientException;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.lang.ref.Reference;
import java.lang.ref.ReferenceQueue;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import kotlin.reflect.jvm.internal.impl.types.a;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/* JADX INFO: loaded from: classes.dex */
public final class hda implements ka1, i84, fac, ws1, SuccessContinuation, ffe, qcg, RemoteCall {
    public final /* synthetic */ int I;
    public Object J;
    public Object K;

    public hda(int i) {
        this.I = i;
        switch (i) {
            case 4:
                this.J = new s70();
                break;
            case 10:
                this.J = new ArrayList();
                break;
            case 15:
                ConcurrentLinkedQueue concurrentLinkedQueue = new ConcurrentLinkedQueue();
                for (int i2 = 0; i2 < 15; i2++) {
                    concurrentLinkedQueue.add(new StrokeInput());
                }
                this.J = concurrentLinkedQueue;
                this.K = new float[2];
                break;
            case 17:
                this.J = new ConcurrentHashMap();
                this.K = new AtomicInteger(0);
                break;
            case 19:
                this.J = new ga6(11);
                this.K = new zq7(16);
                break;
            case 22:
                this.J = new mi8(0, new Reference[16]);
                this.K = new ReferenceQueue();
                break;
            case 23:
                this.J = new zq7(10);
                this.K = new LinkedHashMap();
                break;
            default:
                this.J = new Handler(Looper.getMainLooper());
                this.K = new CountDownLatch(1);
                break;
        }
    }

    public static eef b(List list) {
        return list.isEmpty() ? eef.K : new eef(list);
    }

    public static float r(int i, int i2, MotionEvent motionEvent, int i3) {
        return i3 == motionEvent.getHistorySize() ? motionEvent.getAxisValue(i, i2) : motionEvent.getHistoricalAxisValue(i, i2, i3);
    }

    public void A(umd umdVar, f6b f6bVar) {
        umdVar.getClass();
        t4g t4gVar = (t4g) this.K;
        t4gVar.a.execute(new mu(this, umdVar, f6bVar, 18));
    }

    public void B(umd umdVar, int i) {
        umdVar.getClass();
        t4g t4gVar = (t4g) this.K;
        t4gVar.a.execute(new hpd((vua) this.J, umdVar, false, i));
    }

    /* JADX WARN: Code duplicated, block: B:26:0x00a9  */
    /* JADX WARN: Code duplicated, block: B:47:0x0125  */
    /* JADX WARN: Code duplicated, block: B:71:0x01aa  */
    public ixc C(a aVar, List list, fa6 fa6Var) {
        ykf ykfVarH;
        ixc ixcVar = new ixc();
        Iterator it = list.iterator();
        if (it.hasNext()) {
            tq6 tq6Var = (tq6) it.next();
            om1 om1VarO = tq6Var.L().o();
            if (om1VarO instanceof mb8) {
                Set setE = fa6Var.e();
                ykf ykfVarU = tq6Var.U();
                if (ykfVarU instanceof pi4) {
                    pi4 pi4Var = (pi4) ykfVarU;
                    a8d a8dVarQ0 = pi4Var.q0();
                    if (!a8dVarQ0.L().getParameters().isEmpty() && a8dVarQ0.L().o() != null) {
                        List<eff> parameters = a8dVarQ0.L().getParameters();
                        parameters.getClass();
                        ArrayList arrayList = new ArrayList(bt1.H0(parameters, 10));
                        for (eff effVar : parameters) {
                            kff nmdVar = (kff) zs1.g1(effVar.getIndex(), tq6Var.z());
                            boolean z = setE != null && setE.contains(effVar);
                            if (nmdVar == null || z) {
                                nmdVar = new nmd(effVar);
                            } else {
                                tff tffVarG = aVar.g();
                                tq6 tq6VarB = nmdVar.b();
                                tq6VarB.getClass();
                                if (tffVarG.e(tq6VarB) == null) {
                                    nmdVar = new nmd(effVar);
                                }
                            }
                            arrayList.add(nmdVar);
                        }
                        a8dVarQ0 = fli.h(a8dVarQ0, arrayList, null, 2);
                    }
                    a8d a8dVarR0 = pi4Var.r0();
                    if (!a8dVarR0.L().getParameters().isEmpty() && a8dVarR0.L().o() != null) {
                        List<eff> parameters2 = a8dVarR0.L().getParameters();
                        parameters2.getClass();
                        ArrayList arrayList2 = new ArrayList(bt1.H0(parameters2, 10));
                        for (eff effVar2 : parameters2) {
                            kff nmdVar2 = (kff) zs1.g1(effVar2.getIndex(), tq6Var.z());
                            boolean z2 = setE != null && setE.contains(effVar2);
                            if (nmdVar2 == null || z2) {
                                nmdVar2 = new nmd(effVar2);
                            } else {
                                tff tffVarG2 = aVar.g();
                                tq6 tq6VarB2 = nmdVar2.b();
                                tq6VarB2.getClass();
                                if (tffVarG2.e(tq6VarB2) == null) {
                                    nmdVar2 = new nmd(effVar2);
                                }
                            }
                            arrayList2.add(nmdVar2);
                        }
                        a8dVarR0 = fli.h(a8dVarR0, arrayList2, null, 2);
                    }
                    ykfVarH = vi2.r(a8dVarQ0, a8dVarR0);
                } else {
                    if (!(ykfVarU instanceof a8d)) {
                        yz3.t();
                        return null;
                    }
                    a8d a8dVar = (a8d) ykfVarU;
                    if (a8dVar.L().getParameters().isEmpty() || a8dVar.L().o() == null) {
                        ykfVarH = a8dVar;
                    } else {
                        List<eff> parameters3 = a8dVar.L().getParameters();
                        parameters3.getClass();
                        ArrayList arrayList3 = new ArrayList(bt1.H0(parameters3, 10));
                        for (eff effVar3 : parameters3) {
                            kff nmdVar3 = (kff) zs1.g1(effVar3.getIndex(), tq6Var.z());
                            boolean z3 = setE != null && setE.contains(effVar3);
                            if (nmdVar3 == null || z3) {
                                nmdVar3 = new nmd(effVar3);
                            } else {
                                tff tffVarG3 = aVar.g();
                                tq6 tq6VarB3 = nmdVar3.b();
                                tq6VarB3.getClass();
                                if (tffVarG3.e(tq6VarB3) == null) {
                                    nmdVar3 = new nmd(effVar3);
                                }
                            }
                            arrayList3.add(nmdVar3);
                        }
                        ykfVarH = fli.h(a8dVar, arrayList3, null, 2);
                    }
                }
                ixcVar.add(aVar.i(jli.c(ykfVarH, ykfVarU), cqf.OUT_VARIANCE));
            } else if (om1VarO instanceof eff) {
                Set setE2 = fa6Var.e();
                if (setE2 == null || !setE2.contains(om1VarO)) {
                    List upperBounds = ((eff) om1VarO).getUpperBounds();
                    upperBounds.getClass();
                    ixcVar.addAll(C(aVar, upperBounds, fa6Var));
                } else {
                    ixcVar.add(o(fa6Var));
                }
            }
        }
        return ur2.n(ixcVar);
    }

    public umd D(m4g m4gVar) {
        umd umdVarF;
        synchronized (this.K) {
            umdVarF = ((z51) this.J).f(m4gVar);
        }
        return umdVarF;
    }

    public void E(int i) {
        int i2 = i + 1;
        ArrayList arrayList = (ArrayList) this.J;
        if (i2 >= arrayList.size()) {
            return;
        }
        Object obj = arrayList.get(i);
        obj.getClass();
        qsc qscVar = (qsc) obj;
        Object obj2 = arrayList.get(i2);
        obj2.getClass();
        qsc qscVar2 = (qsc) obj2;
        if (qscVar.a(qscVar2)) {
            qscVar.d += qscVar2.d;
            arrayList.remove(i2);
        }
    }

    public boolean a(m4g m4gVar) {
        boolean zContainsKey;
        synchronized (this.K) {
            zContainsKey = ((z51) this.J).I.containsKey(m4gVar);
        }
        return zContainsKey;
    }

    /* JADX WARN: Multi-variable type inference failed */
    @Override // com.google.android.gms.common.api.internal.RemoteCall
    public /* synthetic */ void accept(Object obj, Object obj2) {
        int i = nki.a;
        pii piiVar = new pii((TaskCompletionSource) obj2);
        ((sli) ((xli) obj).getService()).O(piiVar, (String) this.J, (String[]) this.K);
    }

    @Override // defpackage.qcg
    public Object c() {
        switch (this.I) {
            case 26:
                ocg ocgVar = (ocg) this.K;
                return new ieg((b) ((ocg) this.J).c(), (jeg) ocgVar.c());
            default:
                return new n((b) ((ocg) this.J).c(), new ocg(new scg((mcg) this.K, 0)));
        }
    }

    @Override // defpackage.ffe
    public vh1 d() {
        return (owf) this.J;
    }

    @Override // defpackage.fac
    public Object e(Object obj) {
        return ((ov4) this.K).invoke(obj);
    }

    public sz1 f(Collection collection) {
        boolean z;
        sz1 sz1VarI0 = ((i7d) this.J).I0(collection);
        Duration duration = (Duration) this.K;
        sz1VarI0.d(duration.toMillis(), TimeUnit.MILLISECONDS);
        synchronized (sz1VarI0.d) {
            z = sz1VarI0.a != null;
        }
        if (!z) {
            TimeoutException timeoutException = new TimeoutException("Storage write timed out after " + duration.toMillis() + "ms");
            sz1 sz1Var = new sz1();
            sz1Var.a(timeoutException);
            return sz1Var;
        }
        if (sz1VarI0.c()) {
            return sz1.e;
        }
        Throwable thB = sz1VarI0.b();
        if (thB == null) {
            return sz1.f;
        }
        sz1 sz1Var2 = new sz1();
        sz1Var2.a(thB);
        return sz1Var2;
    }

    @Override // defpackage.ws1
    public Collection g() {
        ArrayList arrayList = (ArrayList) this.J;
        if (arrayList.isEmpty()) {
            return Collections.EMPTY_LIST;
        }
        km0 km0Var = ((bm0) this.K).b;
        if (arrayList.size() == 1) {
            return ((nfc) arrayList.get(0)).a();
        }
        ArrayList arrayList2 = new ArrayList();
        Iterator it = arrayList.iterator();
        while (it.hasNext()) {
            arrayList2.addAll(((nfc) it.next()).a());
        }
        return Collections.unmodifiableList(arrayList2);
    }

    @Override // defpackage.n1b
    public Object get() {
        o06 o06Var = new o06(14);
        te6 te6Var = new te6(13);
        Object obj = ((n1b) this.J).get();
        n1b n1bVar = (n1b) this.K;
        return new i3c(o06Var, te6Var, ik0.f, (rbc) obj, n1bVar);
    }

    @Override // defpackage.fac
    public Object h(z8c z8cVar, Object obj) {
        return ((cw4) this.J).invoke(z8cVar, obj);
    }

    public int i(nsc nscVar) {
        ArrayList arrayList = (ArrayList) this.J;
        int size = arrayList.size() - 1;
        int i = 0;
        while (true) {
            int i2 = -1;
            if (i > size) {
                return -1;
            }
            int i3 = (i + size) / 2;
            Object obj = arrayList.get(i3);
            obj.getClass();
            qsc qscVar = (qsc) obj;
            int iA1 = nscVar.a1() - qscVar.b;
            if (iA1 != 0 || (iA1 = (nscVar.m() & 65535) - (65535 & qscVar.a)) != 0) {
                i2 = iA1;
            } else if (Integer.compareUnsigned(nscVar.C(), qscVar.c) >= 0) {
                i2 = Integer.compareUnsigned(nscVar.C(), qscVar.c + qscVar.d) >= 0 ? 1 : 0;
            }
            if (i2 < 0) {
                size = i3 - 1;
            } else {
                if (i2 <= 0) {
                    return i3;
                }
                i = i3 + 1;
            }
        }
    }

    @Override // defpackage.ffe
    public vh1 j() {
        return (owf) this.K;
    }

    /* JADX WARN: Code duplicated, block: B:39:0x00e1 A[PHI: r11 r13 r15
  0x00e1: PHI (r11v6 java.lang.Integer) = (r11v5 java.lang.Integer), (r11v10 java.lang.Integer) binds: [B:54:0x010a, B:36:0x00d6] A[DONT_GENERATE, DONT_INLINE]
  0x00e1: PHI (r13v9 java.lang.Integer) = (r13v7 java.lang.Integer), (r13v5 java.lang.Integer) binds: [B:54:0x010a, B:36:0x00d6] A[DONT_GENERATE, DONT_INLINE]
  0x00e1: PHI (r15v17 boolean) = (r15v11 boolean), (r15v20 boolean) binds: [B:54:0x010a, B:36:0x00d6] A[DONT_GENERATE, DONT_INLINE]] */
    @Override // defpackage.ka1
    public void k(w91 w91Var, ytb ytbVar) {
        ghd ghdVarH;
        t9d t9dVarC;
        int iIntValue;
        int i;
        int i2;
        int i3;
        boolean z;
        String strSubstring;
        try {
            jgd jgdVarA = ((ocb) this.J).a(ytbVar);
            xc5 xc5Var = ytbVar.N;
            int size = xc5Var.size();
            int i4 = 0;
            int i5 = 0;
            boolean z2 = false;
            boolean z3 = false;
            boolean z4 = false;
            boolean z5 = false;
            Integer numO0 = null;
            Integer numO1 = null;
            while (i5 < size) {
                boolean z6 = true;
                if (xc5Var.d(i5).equalsIgnoreCase("Sec-WebSocket-Extensions")) {
                    String strH = xc5Var.h(i5);
                    int i6 = i4;
                    while (i6 < strH.length()) {
                        xc5 xc5Var2 = xc5Var;
                        int iE = sbg.e(strH, ',', i6, i4, 4);
                        int iC = sbg.c(strH, ';', i6, iE);
                        int iH = sbg.h(i6, strH, iC);
                        String strSubstring2 = strH.substring(iH, sbg.i(iH, strH, iC));
                        i6 = iC + 1;
                        if (strSubstring2.equalsIgnoreCase("permessage-deflate")) {
                            if (z2) {
                                z5 = z6;
                            }
                            while (i6 < iE) {
                                int iC2 = sbg.c(strH, ';', i6, iE);
                                int iC3 = sbg.c(strH, '=', i6, iC2);
                                int iH2 = sbg.h(i6, strH, iC3);
                                String strSubstring3 = strH.substring(iH2, sbg.i(iH2, strH, iC3));
                                if (iC3 < iC2) {
                                    int iH3 = sbg.h(iC3 + 1, strH, iC2);
                                    strSubstring = strH.substring(iH3, sbg.i(iH3, strH, iC2));
                                    i2 = iE;
                                    i3 = size;
                                    if (strSubstring.length() >= 2 && ard.n0(strSubstring, "\"", false) && tqd.x0("\"", strSubstring)) {
                                        z = z6;
                                        strSubstring = nt6.k(z ? 1 : 0, strSubstring, z ? 1 : 0);
                                    } else {
                                        z = z6;
                                    }
                                } else {
                                    i2 = iE;
                                    i3 = size;
                                    z = z6;
                                    strSubstring = null;
                                }
                                int i7 = iC2 + 1;
                                if (strSubstring3.equalsIgnoreCase("client_max_window_bits")) {
                                    if (numO0 != null) {
                                        z5 = z;
                                    }
                                    numO0 = strSubstring != null ? ard.o0(10, strSubstring) : null;
                                    if (numO0 == null) {
                                        z5 = z;
                                        z6 = z5 ? 1 : 0;
                                    } else {
                                        z6 = z;
                                    }
                                } else if (strSubstring3.equalsIgnoreCase("client_no_context_takeover")) {
                                    if (z3) {
                                        z5 = z;
                                    }
                                    if (strSubstring != null) {
                                        z5 = z;
                                    }
                                    z3 = z;
                                    z6 = z3 ? 1 : 0;
                                } else {
                                    if (strSubstring3.equalsIgnoreCase("server_max_window_bits")) {
                                        if (numO1 != null) {
                                            z5 = z;
                                        }
                                        numO1 = strSubstring != null ? ard.o0(10, strSubstring) : null;
                                        if (numO1 != null) {
                                            z6 = z;
                                        }
                                    } else if (strSubstring3.equalsIgnoreCase("server_no_context_takeover")) {
                                        if (z4) {
                                            z5 = z;
                                        }
                                        if (strSubstring != null) {
                                            z5 = z;
                                        }
                                        z4 = z;
                                        z6 = z4 ? 1 : 0;
                                    }
                                    z5 = z;
                                    z6 = z5 ? 1 : 0;
                                }
                                i6 = i7;
                                iE = i2;
                                size = i3;
                            }
                            i = size;
                            z2 = z6 ? 1 : 0;
                            z6 = z2 ? 1 : 0;
                        } else {
                            i = size;
                            z5 = z6 ? 1 : 0;
                            z6 = z5 ? 1 : 0;
                        }
                        xc5Var = xc5Var2;
                        size = i;
                        i4 = 0;
                    }
                }
                i5++;
                xc5Var = xc5Var;
                size = size;
                i4 = 0;
            }
            int i8 = 1;
            ((ocb) this.J).d = new eyf(z2, numO0, z3, numO1, z4, z5);
            if (z5 || numO0 != null || (numO1 != null && (8 > (iIntValue = numO1.intValue()) || iIntValue >= 16))) {
                ocb ocbVar = (ocb) this.J;
                synchronized (ocbVar) {
                    ocbVar.p.clear();
                    ocbVar.b(1010, "unexpected Sec-WebSocket-Extensions in response header");
                }
            }
            String str = ubg.b + " WebSocket " + ((qrb) this.K).a.g();
            ocb ocbVar2 = (ocb) this.J;
            d30 d30Var = new d30(jgdVarA);
            eyf eyfVar = ocbVar2.d;
            eyfVar.getClass();
            synchronized (ocbVar2) {
                try {
                    ocbVar2.m = str;
                    ocbVar2.n = d30Var;
                    ocbVar2.k = new oyf((obb) d30Var.L, ocbVar2.b, eyfVar.a, eyfVar.c, ocbVar2.e);
                    ocbVar2.i = new vbb(ocbVar2);
                    long j = ocbVar2.c;
                    if (j != 0) {
                        long nanos = TimeUnit.MILLISECONDS.toNanos(j);
                        xae xaeVar = ocbVar2.l;
                        String strConcat = str.concat(" ping");
                        wu wuVar = new wu(ocbVar2, nanos, i8);
                        xaeVar.getClass();
                        xaeVar.d(new wae(strConcat, wuVar), nanos);
                    }
                    if (!ocbVar2.p.isEmpty()) {
                        ocbVar2.e();
                    }
                } catch (Throwable th) {
                    throw th;
                }
            }
            ocbVar2.j = new nyf((pbb) d30Var.K, ocbVar2, eyfVar.a, eyfVar.e);
            ocb ocbVar3 = (ocb) this.J;
            try {
                ocbVar3.a.f(ocbVar3, ytbVar);
                while (ocbVar3.s == -1) {
                    nyf nyfVar = ocbVar3.j;
                    nyfVar.getClass();
                    nyfVar.a();
                }
            } catch (Exception e) {
                ocb.c(ocbVar3, e, null, 6);
            } finally {
                ocbVar3.d();
            }
        } catch (IOException e2) {
            ocb.c((ocb) this.J, e2, ytbVar, 4);
            sbg.b(ytbVar);
            jgd jgdVar = ytbVar.P;
            if (jgdVar != null && (t9dVarC = jgdVar.c()) != null) {
                sbg.b(t9dVarC);
            }
            jgd jgdVar2 = ytbVar.P;
            if (jgdVar2 == null || (ghdVarH = jgdVar2.h()) == null) {
                return;
            }
            sbg.b(ghdVarH);
        }
    }

    public pm0 m(o52 o52Var) throws FirebaseRemoteConfigClientException {
        String string;
        JSONArray jSONArray = o52Var.g;
        long j = o52Var.f;
        HashSet hashSet = new HashSet();
        for (int i = 0; i < jSONArray.length(); i++) {
            try {
                JSONObject jSONObject = jSONArray.getJSONObject(i);
                String string2 = jSONObject.getString("rolloutId");
                JSONArray jSONArray2 = jSONObject.getJSONArray("affectedParameterKeys");
                if (jSONArray2.length() > 1) {
                    Log.w("FirebaseRemoteConfig", String.format("Rollout has multiple affected parameter keys.Only the first key will be included in RolloutsState. rolloutId: %s, affectedParameterKeys: %s", string2, jSONArray2));
                }
                String strOptString = jSONArray2.optString(0, "");
                o52 o52VarC = ((m52) this.J).c();
                String string3 = null;
                if (o52VarC == null) {
                    string = null;
                } else {
                    try {
                        string = o52VarC.b.getString(strOptString);
                    } catch (JSONException unused) {
                        string = null;
                    }
                }
                if (string == null) {
                    o52 o52VarC2 = ((m52) this.K).c();
                    if (o52VarC2 != null) {
                        try {
                            string3 = o52VarC2.b.getString(strOptString);
                        } catch (JSONException unused2) {
                        }
                    }
                    string = string3 != null ? string3 : "";
                }
                mm0 mm0VarA = v0c.a();
                mm0VarA.d(string2);
                mm0VarA.f(jSONObject.getString("variantId"));
                mm0VarA.b(strOptString);
                mm0VarA.c(string);
                mm0VarA.e(j);
                hashSet.add(mm0VarA.a());
            } catch (JSONException e) {
                throw new FirebaseRemoteConfigClientException("Exception parsing rollouts metadata to create RolloutsState.", e);
            }
        }
        return new pm0(hashSet);
    }

    public File n() {
        if (((File) this.J) == null) {
            synchronized (this) {
                try {
                    if (((File) this.J) == null) {
                        String str = "PersistedInstallation." + ((we4) this.K).d() + ".json";
                        we4 we4Var = (we4) this.K;
                        we4Var.a();
                        File file = new File(we4Var.a.getNoBackupFilesDir(), str);
                        this.J = file;
                        if (file.exists()) {
                            return (File) this.J;
                        }
                        we4 we4Var2 = (we4) this.K;
                        we4Var2.a();
                        File file2 = new File(we4Var2.a.getFilesDir(), str);
                        if (file2.exists() && !file2.renameTo((File) this.J)) {
                            Log.e("PersistedInstallation", "Unable to move the file from back up to non back up directory", new IOException("Unable to move the file from back up to non back up directory"));
                            return file2;
                        }
                    }
                } catch (Throwable th) {
                    throw th;
                }
            }
        }
        return (File) this.J;
    }

    public ykf o(fa6 fa6Var) {
        ykf ykfVarM;
        a8d a8dVarB = fa6Var.b();
        return (a8dVarB == null || (ykfVarM = ili.m(a8dVarB)) == null) ? (az3) ((p7e) this.J).getValue() : ykfVarM;
    }

    public tq6 p(eff effVar, fa6 fa6Var) {
        effVar.getClass();
        fa6Var.getClass();
        return (tq6) ((qk7) this.K).invoke(new jff(effVar, fa6Var));
    }

    public int q(String str) {
        int iIntValue;
        ConcurrentHashMap concurrentHashMap = (ConcurrentHashMap) this.J;
        qff qffVar = new qff(this, 0);
        concurrentHashMap.getClass();
        Integer num = (Integer) concurrentHashMap.get(str);
        if (num != null) {
            return num.intValue();
        }
        synchronized (concurrentHashMap) {
            try {
                Integer num2 = (Integer) concurrentHashMap.get(str);
                if (num2 != null) {
                    iIntValue = num2.intValue();
                } else {
                    Object objInvoke = qffVar.invoke(str);
                    concurrentHashMap.putIfAbsent(str, Integer.valueOf(((Number) objInvoke).intValue()));
                    iIntValue = ((Number) objInvoke).intValue();
                }
            } catch (Throwable th) {
                throw th;
            }
        }
        return iIntValue;
    }

    public void s(gm0 gm0Var) {
        try {
            JSONObject jSONObject = new JSONObject();
            jSONObject.put("Fid", gm0Var.a);
            jSONObject.put("Status", tg2.E(gm0Var.b));
            jSONObject.put("AuthToken", gm0Var.c);
            jSONObject.put("RefreshToken", gm0Var.d);
            jSONObject.put("TokenCreationEpochInSecs", gm0Var.f);
            jSONObject.put("ExpiresInSecs", gm0Var.e);
            jSONObject.put("FisError", gm0Var.g);
            we4 we4Var = (we4) this.K;
            we4Var.a();
            File fileCreateTempFile = File.createTempFile("PersistedInstallation", "tmp", we4Var.a.getFilesDir());
            FileOutputStream fileOutputStream = new FileOutputStream(fileCreateTempFile);
            fileOutputStream.write(jSONObject.toString().getBytes("UTF-8"));
            fileOutputStream.close();
            if (fileCreateTempFile.renameTo(n())) {
            } else {
                throw new IOException("unable to rename the tmpfile to PersistedInstallation");
            }
        } catch (IOException | JSONException unused) {
        }
    }

    public void t(MotionEvent motionEvent, int i, Matrix matrix, long j, float f, Boolean bool, Boolean bool2, Boolean bool3, fi8 fi8Var) {
        matrix.getClass();
        fi8Var.getClass();
        fi8Var.i();
        int historySize = motionEvent.getHistorySize();
        if (historySize < 0) {
            return;
        }
        int i2 = 0;
        while (true) {
            int i3 = i2;
            StrokeInput strokeInputV = v(motionEvent, i, i3, matrix, j, f, bool, bool2, bool3);
            try {
                fi8Var.h(strokeInputV);
            } catch (Throwable unused) {
            }
            ((ConcurrentLinkedQueue) this.J).offer(strokeInputV);
            if (i3 == historySize) {
                return;
            } else {
                i2 = i3 + 1;
            }
        }
    }

    @Override // com.google.android.gms.tasks.SuccessContinuation
    public Task then(Object obj) throws Throwable {
        FileWriter fileWriter;
        t52 t52Var = (t52) this.K;
        JSONObject jSONObject = (JSONObject) ((vj2) ((d30) this.J).L).I.submit(new d03(this, 3)).get();
        FileWriter fileWriter2 = null;
        if (jSONObject != null) {
            qyc qycVarZ = ((vt7) t52Var.L).z(jSONObject);
            ar7 ar7Var = (ar7) t52Var.N;
            long j = qycVarZ.c;
            ar7Var.getClass();
            if (Log.isLoggable("FirebaseCrashlytics", 2)) {
                Log.v("FirebaseCrashlytics", "Writing settings to cache file...", null);
            }
            try {
                jSONObject.put("expires_at", j);
                fileWriter = new FileWriter((File) ar7Var.J);
                try {
                    try {
                        fileWriter.write(jSONObject.toString());
                        fileWriter.flush();
                    } catch (Throwable th) {
                        th = th;
                        fileWriter2 = fileWriter;
                        qy1.f(fileWriter2, "Failed to close settings writer.");
                        throw th;
                    }
                } catch (Exception e) {
                    e = e;
                    Log.e("FirebaseCrashlytics", "Failed to cache settings", e);
                }
            } catch (Exception e2) {
                e = e2;
                fileWriter = null;
            } catch (Throwable th2) {
                th = th2;
                qy1.f(fileWriter2, "Failed to close settings writer.");
                throw th;
            }
            qy1.f(fileWriter, "Failed to close settings writer.");
            t52.l("Loaded settings: ", jSONObject);
            String str = ((wyc) t52Var.K).f;
            SharedPreferences.Editor editorEdit = ((Context) t52Var.J).getSharedPreferences("com.google.firebase.crashlytics", 0).edit();
            editorEdit.putString("existing_instance_identifier", str);
            editorEdit.apply();
            ((AtomicReference) t52Var.Q).set(qycVarZ);
            ((TaskCompletionSource) ((AtomicReference) t52Var.R).get()).trySetResult(qycVarZ);
        }
        return Tasks.forResult(null);
    }

    public String toString() {
        switch (this.I) {
            case 24:
                return "Bounds{lower=" + ((g26) this.J) + " upper=" + ((g26) this.K) + "}";
            default:
                return super.toString();
        }
    }

    @Override // defpackage.ka1
    public void u(w91 w91Var, IOException iOException) {
        ocb.c((ocb) this.J, iOException, null, 6);
    }

    /* JADX WARN: Code duplicated, block: B:15:0x004e  */
    public StrokeInput v(MotionEvent motionEvent, int i, int i2, Matrix matrix, long j, float f, Boolean bool, Boolean bool2, Boolean bool3) {
        x16 x16Var;
        float[] fArr = (float[]) this.K;
        fArr[0] = r(0, i, motionEvent, i2);
        fArr[1] = r(1, i, motionEvent, i2);
        matrix.mapPoints(fArr);
        float f2 = fArr[0];
        float f3 = fArr[1];
        long eventTime = (i2 == motionEvent.getHistorySize() ? motionEvent.getEventTime() : motionEvent.getHistoricalEventTime(i2)) - j;
        int toolType = motionEvent.getToolType(i);
        if (toolType == 2) {
            x16Var = x16.g;
        } else if (toolType == 3) {
            x16Var = x16.e;
        } else if (toolType != 4) {
            x16Var = x16.f;
        } else {
            x16Var = x16.g;
        }
        x16 x16Var2 = x16Var;
        float f4 = -1.0f;
        float fU = (motionEvent.getToolType(i) != 2 || x76.p(bool, Boolean.FALSE) || (bool == null && (motionEvent.getDevice() == null || motionEvent.getDevice().getMotionRange(2, motionEvent.getSource()) == null))) ? -1.0f : me8.u(r(2, i, motionEvent, i2), 0.0f, 1.0f);
        float fU2 = (motionEvent.getToolType(i) != 2 || x76.p(bool2, Boolean.FALSE) || (bool2 == null && (motionEvent.getDevice() == null || motionEvent.getDevice().getMotionRange(25, motionEvent.getSource()) == null))) ? -1.0f : me8.u(r(25, i, motionEvent, i2), 0.0f, 1.5707964f);
        if (motionEvent.getToolType(i) == 2 && !x76.p(bool3, Boolean.FALSE) && (bool3 != null || (motionEvent.getDevice() != null && motionEvent.getDevice().getMotionRange(8, motionEvent.getSource()) != null))) {
            float fR = (r(8, i, motionEvent, i2) + 7.853982f) % 6.2831855f;
            if (fR != 0.0f && Math.signum(fR) != Math.signum(6.2831855f)) {
                fR += 6.2831855f;
            }
            f4 = fR;
        }
        float f5 = f4;
        x16Var2.getClass();
        StrokeInput strokeInput = (StrokeInput) ((ConcurrentLinkedQueue) this.J).poll();
        if (strokeInput == null) {
            strokeInput = new StrokeInput();
        }
        StrokeInput strokeInput2 = strokeInput;
        strokeInput2.a(f2, f3, eventTime, x16Var2, f, fU, fU2, f5);
        return strokeInput2;
    }

    public void w(q66 q66Var, String str) {
        if (q66Var == null || q66Var.b.isEmpty() || str == null) {
            return;
        }
        ((s70) this.J).b(q66Var, str);
    }

    public gm0 x() {
        JSONObject jSONObject;
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        byte[] bArr = new byte[16384];
        try {
            FileInputStream fileInputStream = new FileInputStream(n());
            while (true) {
                try {
                    int i = fileInputStream.read(bArr, 0, 16384);
                    if (i < 0) {
                        break;
                    }
                    byteArrayOutputStream.write(bArr, 0, i);
                } catch (Throwable th) {
                    try {
                        fileInputStream.close();
                        throw th;
                    } catch (Throwable th2) {
                        th.addSuppressed(th2);
                        throw th;
                    }
                }
            }
            jSONObject = new JSONObject(byteArrayOutputStream.toString());
            fileInputStream.close();
        } catch (IOException | JSONException unused) {
            jSONObject = new JSONObject();
        }
        String strOptString = jSONObject.optString("Fid", null);
        int iOptInt = jSONObject.optInt("Status", 0);
        String strOptString2 = jSONObject.optString("AuthToken", null);
        String strOptString3 = jSONObject.optString("RefreshToken", null);
        long jOptLong = jSONObject.optLong("TokenCreationEpochInSecs", 0L);
        long jOptLong2 = jSONObject.optLong("ExpiresInSecs", 0L);
        String strOptString4 = jSONObject.optString("FisError", null);
        int i2 = gm0.h;
        byte b = (byte) (((byte) (0 | 2)) | 1);
        int i3 = tg2.F(5)[iOptInt];
        if (i3 == 0) {
            yz3.u("Null registrationStatus");
            return null;
        }
        byte b2 = (byte) (((byte) (b | 2)) | 1);
        if (b2 == 3 && i3 != 0) {
            return new gm0(strOptString, i3, strOptString2, strOptString3, jOptLong2, jOptLong, strOptString4);
        }
        StringBuilder sb = new StringBuilder();
        if (i3 == 0) {
            sb.append(" registrationStatus");
        }
        if ((b2 & 1) == 0) {
            sb.append(" expiresInSecs");
        }
        if ((b2 & 2) == 0) {
            sb.append(" tokenCreationEpochInSecs");
        }
        yz3.l(tg2.p("Missing required properties:", sb));
        return null;
    }

    public umd y(m4g m4gVar) {
        umd umdVar;
        synchronized (this.K) {
            umdVar = (umd) ((z51) this.J).I.remove(m4gVar);
        }
        return umdVar;
    }

    public void z(nsc nscVar, int i) {
        int i2;
        ArrayList arrayList = (ArrayList) this.J;
        nscVar.getClass();
        qsc qscVar = (qsc) this.K;
        if (qscVar != null && qscVar.e == i && qscVar.b(nscVar)) {
            qscVar.d++;
            return;
        }
        int i3 = i(nscVar);
        if (i3 >= 0) {
            Object obj = arrayList.get(i3);
            obj.getClass();
            if (((qsc) obj).e == i) {
                return;
            }
            Object obj2 = arrayList.get(i3);
            obj2.getClass();
            qsc qscVar2 = (qsc) obj2;
            int iC = nscVar.C() - qscVar2.c;
            int i4 = qscVar2.d;
            if (i4 == 1) {
                qscVar2.e = i;
            } else if (iC == 0) {
                qscVar2.c = nscVar.C() + 1;
                qscVar2.d--;
                arrayList.add(i3, new qsc(nscVar.m(), nscVar.a1(), nscVar.C(), 1, i));
            } else if (iC == i4 - 1) {
                qscVar2.d = i4 - 1;
                arrayList.add(i3 + 1, new qsc(nscVar.m(), nscVar.a1(), nscVar.C(), 1, i));
            } else {
                qscVar2.d = iC;
                arrayList.add(i3 + 1, new qsc(nscVar.m(), nscVar.a1(), nscVar.C(), 1, i));
                arrayList.add(i3 + 2, new qsc(nscVar.m(), nscVar.a1(), nscVar.C() + 1, (i4 - iC) - 1, qscVar2.e));
            }
            this.K = null;
            return;
        }
        short sM = nscVar.m();
        int iA1 = nscVar.a1();
        int iC2 = nscVar.C();
        int size = arrayList.size();
        int i5 = 0;
        while (i5 < size) {
            int i6 = (i5 + size) / 2;
            Object obj3 = arrayList.get(i6);
            obj3.getClass();
            qsc qscVar3 = (qsc) obj3;
            int i7 = qscVar3.b;
            if (iA1 != i7) {
                i2 = iA1 - i7;
            } else {
                int i8 = sM & 65535;
                int i9 = 65535 & qscVar3.a;
                i2 = i8 != i9 ? i8 - i9 : iC2 - qscVar3.c;
            }
            if (i2 <= 0) {
                size = i6;
            } else {
                i5 = i6 + 1;
            }
        }
        if (i5 > 0) {
            int i10 = i5 - 1;
            Object obj4 = arrayList.get(i10);
            obj4.getClass();
            qsc qscVar4 = (qsc) obj4;
            if (qscVar4.e == i && qscVar4.b(nscVar)) {
                qscVar4.d++;
                E(i10);
                this.K = null;
                return;
            }
        }
        if (i5 < arrayList.size()) {
            Object obj5 = arrayList.get(i5);
            obj5.getClass();
            qsc qscVar5 = (qsc) obj5;
            if (qscVar5.e == i && qscVar5.a == nscVar.m() && qscVar5.b == nscVar.a1() && qscVar5.c == nscVar.C() + 1) {
                qscVar5.c = nscVar.C();
                qscVar5.d++;
                if (i5 > 0) {
                    E(i5 - 1);
                }
                this.K = null;
                return;
            }
        }
        qsc qscVar6 = new qsc(nscVar.m(), nscVar.a1(), nscVar.C(), 1, i);
        arrayList.add(i5, qscVar6);
        this.K = qscVar6;
    }

    public /* synthetic */ hda(int i, boolean z) {
        this.I = i;
    }

    public /* synthetic */ hda(Object obj, int i) {
        this.I = i;
        this.K = obj;
    }

    public /* synthetic */ hda(Object obj, boolean z, int i) {
        this.I = i;
        this.J = obj;
    }

    public hda(ez5 ez5Var) {
        this.I = 18;
        wk7 wk7Var = new wk7("Type parameter upper bound erasure results");
        this.J = new p7e(new b6(this, 15));
        this.K = wk7Var.b(new p1(this, 19));
    }

    public /* synthetic */ hda(int i, Object obj, Object obj2) {
        this.I = i;
        this.J = obj;
        this.K = obj2;
    }

    public hda(i7d i7dVar, uf6 uf6Var, Duration duration) {
        this.I = 12;
        this.J = i7dVar;
        this.K = duration;
    }

    public hda(vua vuaVar, t4g t4gVar) {
        this.I = 25;
        vuaVar.getClass();
        t4gVar.getClass();
        this.J = vuaVar;
        this.K = t4gVar;
    }

    public hda(o1b o1bVar) {
        this.I = 1;
        this.K = Collections.synchronizedMap(new HashMap());
        this.J = o1bVar;
    }

    public hda(nwf nwfVar) {
        this.I = 21;
        owf owfVar = nwfVar.J;
        owf owfVar2 = nwfVar.I;
        this.J = nwfVar.c() ? owfVar2 : owfVar;
        this.K = nwfVar.c() ? owfVar : owfVar2;
    }

    public hda(z51 z51Var) {
        this.I = 16;
        this.J = z51Var;
        this.K = new Object();
    }

    public hda(t52 t52Var, d30 d30Var) {
        this.I = 11;
        this.K = t52Var;
        this.J = d30Var;
    }

    public hda(WindowInsetsAnimation.Bounds bounds) {
        this.I = 24;
        this.J = g26.d(bounds.getLowerBound());
        this.K = g26.d(bounds.getUpperBound());
    }
}
