package defpackage;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Matrix;
import android.view.MotionEvent;
import android.webkit.WebSettings;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.playservices.controllers.identitycredentials.createpublickeycredential.CreatePublicKeyCredentialController;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.core.common.logging.a;
import com.google.android.gms.common.internal.ImagesContract;
import com.google.android.gms.fido.u2f.api.common.ClientData;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.concurrent.Executor;
import kotlin.jvm.functions.Function0;
import org.json.JSONObject;

/* JADX INFO: loaded from: classes2.dex */
public final /* synthetic */ class ys0 implements Function0 {
    public final /* synthetic */ int I;
    public final /* synthetic */ Object J;
    public final /* synthetic */ Object K;
    public final /* synthetic */ Object L;
    public final /* synthetic */ Object M;

    public /* synthetic */ ys0(rn3 r1, a83 r2, hld r3, hld r4, hld r5) {
        this.I = 15;
        this.K = r1;
        this.L = r2;
        this.M = r3;
        this.J = r4;
    }

    /* JADX DEBUG: Multi-variable search result rejected for r6v16, resolved type: java.lang.Object[] */
    /* JADX DEBUG: Multi-variable search result rejected for r6v17, resolved type: java.lang.Object[] */
    /* JADX DEBUG: Multi-variable search result rejected for r6v18, resolved type: java.lang.Object[] */
    /* JADX DEBUG: Multi-variable search result rejected for r6v19, resolved type: java.lang.Object[] */
    /* JADX DEBUG: Multi-variable search result rejected for r6v20, resolved type: java.lang.Object[] */
    /* JADX WARN: Multi-variable type inference failed */
    @Override // kotlin.jvm.functions.Function0
    public final Object invoke() {
        int r2 = 5;
        int r3 = 1;
        int r4 = 0;
        d11 r6 = null;
        Object[] r7 = 0;
        Object[] r8 = 0;
        Object[] r9 = 0;
        Object[] r10 = 0;
        Object[] r11 = 0;
        switch(this.I) {
            case 0: goto L148;
            case 1: goto L138;
            case 2: goto L137;
            case 3: goto L119;
            case 4: goto L113;
            case 5: goto L111;
            case 6: goto L98;
            case 7: goto L93;
            case 8: goto L88;
            case 9: goto L72;
            case 10: goto L70;
            case 11: goto L68;
            case 12: goto L66;
            case 13: goto L64;
            case 14: goto L56;
            case 15: goto L54;
            case 16: goto L46;
            case 17: goto L12;
            default: goto L4;
        };
    L4:
        cxe r1 = (cxe) this.K;
        Matrix r5 = (Matrix) this.L;
        ci8 r12 = (ci8) this.J;
        ci8 r0 = (ci8) this.M;
        fz9 r13 = r1.L.c;
        hvf r14 = (hvf) r12.getValue();
        float r15 = r13.k();
        v46 r16 = ur2.e(w76.w0(r13.n()), r13.o());
        long r17 = fdc.a(r16.a, r16.b);
        long r18 = ((zj9) r0.getValue()).a;
        r14.getClass();
        if (r14.g == false) goto L8;
        float r19 = r15 / r14.a;
        long r20 = r14.q;
        r6 = new d11(r19, ((((int) (r20 >> 32)) - Float.intBitsToFloat((int) (r18 >> 32))) * r19) - ((int) (r17 >> 32)), ((((int) (r20 & 4294967295L)) - Float.intBitsToFloat((int) (r18 & 4294967295L))) * r19) - ((int) (r17 & 4294967295L)));
    L8:
        if (r6 != null) goto L10;
        r5.reset();
    L11:
        return r5;
    L10:
        r5.getClass();
        float r21 = r6.a;
        r5.setScale(r21, r21);
        r5.postTranslate(r6.b, r6.c);
        goto L11
    L12:
        MotionEvent r22 = (MotionEvent) this.K;
        cxe r23 = (cxe) this.L;
        uc8 r24 = r23.Y;
        MotionEvent r25 = (MotionEvent) this.M;
        t0f r26 = (t0f) this.J;
        bjf r27 = bjf.a;
        if (r22.getAction() != 0) goto L44;
        q1f r28 = (q1f) r23.O.l.I.getValue();
        if (r28 == null) goto L45;
        MotionEvent r29 = MotionEvent.obtain(r22);
        r29.getClass();
        float r30 = dxe.a;
        Iterator r31 = r28.b.b.iterator();
    L19:
        if (r31.hasNext() == false) goto L23;
        Object r32 = r31.next();
        if (((m0f) r32).a != r28.a.b) goto L19;
    L24:
        m0f r33 = (m0f) r32;
        if (r26 == null) goto L41;
        if (r33 == null) goto L28;
        t0f r34 = r33.c;
    L29:
        if (r34 == r26) goto L41;
        Iterator r35 = lgi.b(r28).iterator();
    L32:
        if (r35.hasNext() == false) goto L36;
        Object r36 = r35.next();
        if (((m0f) r36).c != r26) goto L32;
    L37:
        m0f r37 = (m0f) r36;
        if (r37 != null) goto L40;
        ArrayList r38 = a.a;
        a.c(cl7.k0, "No tool found for tool type", null, new z94(r26));
        goto L41
    L40:
        r33 = r37;
    L42:
        r24.getClass();
        qm4.d(r24.a, new oc8(r29, r25, new tc8(r29.getX(), r29.getY(), r29.getEventTime(), r29.getPressure(), r29.getAxisValue(25)), r33));
        goto L45
    L36:
        r36 = null;
        goto L37
    L28:
        r34 = null;
    L41:
        if (r33 != null) goto L42;
        yz3.l("No selected tool found");
        return null;
    L23:
        r32 = null;
    L45:
        return r27;
    L44:
        MotionEvent r39 = MotionEvent.obtain(r22);
        r39.getClass();
        r24.getClass();
        qm4.d(r24.a, new nc8(r39, r25, new tc8(r39.getX(), r39.getY(), r39.getEventTime(), r39.getPressure(), r39.getAxisValue(25))));
        goto L45
    L46:
        iof r40 = (iof) this.L;
        rqd r41 = (rqd) this.M;
        ov4 r42 = (ov4) this.J;
        Function0 r43 = (Function0) this.K;
        if (r40 == null) goto L50;
        if (r41 == null) goto L50;
        r42.invoke(new tt5(r40));
    L53:
        return bjf.a;
    L50:
        if (r40 != null) goto L53;
        r43.invoke();
        goto L53
    L54:
        rn3 r44 = (rn3) this.K;
        a83 r45 = (a83) this.L;
        hld r46 = (hld) this.M;
        hld r47 = (hld) this.J;
        r44.c.setValue(r45);
        r44.d = r46;
        r44.e = r47;
        return bjf.a;
    L56:
        b5d r48 = (b5d) this.L;
        fh2 r49 = (fh2) this.M;
        jw r50 = (jw) this.J;
        Function0 r51 = (Function0) this.K;
        if (r48.c() != c5d.J) goto L61;
        qu7 r52 = r48.d.e();
        if (r52.a.containsKey(c5d.K) == false) goto L61;
        vi2.A(r49, null, null, new g88(r50, r11 == true ? 1 : 0, 2), 3);
        vi2.A(r49, null, null, new k98(r48, r10 == true ? 1 : 0, r4), 3);
    L63:
        return bjf.a;
    L61:
        vi2.A(r49, null, null, new k98(r48, r9 == true ? 1 : 0, r3), 3).d1(new tk3(r2, r51));
        goto L63
    L64:
        b5d r53 = (b5d) this.K;
        hld r54 = (hld) this.L;
        hld r55 = (hld) this.M;
        hld r56 = (hld) this.J;
        r53.e = r54;
        r53.f = r55;
        r53.c = r56;
        return bjf.a;
    L66:
        vi2.A((fh2) this.M, null, null, new ns5((sq1) this.K, (String) this.L, (ab4) this.J, null, 12), 3);
        return bjf.a;
    L68:
        vi2.A((fh2) this.M, null, null, new ns5((sq1) this.K, (String) this.L, (sv5) this.J, null, 13), 3);
        return bjf.a;
    L70:
        ov4 r57 = (ov4) this.K;
        lo4 r58 = (lo4) this.L;
        ci8 r59 = (ci8) this.J;
        ci8 r60 = (ci8) this.M;
        r59.setValue(null);
        r60.setValue(null);
        r57.invoke(r58);
        return bjf.a;
    L72:
        a77 r61 = (a77) this.K;
        fr r62 = (fr) this.L;
        String r63 = (String) this.M;
        m6 r64 = (m6) this.J;
        vyf r65 = r61.I;
        kf5 r66 = new kf5(r64, r2);
        r65.getClass();
        r65.L = r66;
        WebSettings r67 = r65.getSettings();
        r67.setJavaScriptEnabled(true);
        r67.setMediaPlaybackRequiresUserGesture(false);
        r67.setCacheMode(-1);
        r65.addJavascriptInterface(r65.N, "YouTubePlayerBridge");
        r65.addJavascriptInterface(r65.J, "YouTubePlayerCallbacks");
        InputStream r68 = r65.getResources().openRawResource(R.raw.ayp_youtube_player);
        r68.getClass();
        String r69 = zs1.k1(rkb.U(new BufferedReader(new InputStreamReader(r68, "utf-8"))), "\n", null, null, null, 62);     // Catch: Throwable -> L80 Exception -> L82
        r68.close();
        if (r63 == null) goto L77;
        String r70 = b7d.h('\'', "'", r63);
    L78:
        String r71 = ard.l0(ard.l0(r69, "<<injectedVideoId>>", r70), "<<injectedPlayerVars>>", r62.toString());
        String r72 = ((JSONObject) r62.J).getString(ClientData.KEY_ORIGIN);
        r72.getClass();
        r65.loadDataWithBaseURL(r72, r71, "text/html", "utf-8", null);
        r65.setWebChromeClient(new uyf(r65));
        return bjf.a;
    L77:
        r70 = "undefined";
        goto L78
    L80:
        th = move-exception;
        throw th;     // Catch: Throwable -> L85
    L85:
        th = move-exception;
        w76.q(r68, th);
        throw th;
    L83:
        throw new RuntimeException("Can't parse HTML file.");     // Catch: Throwable -> L80
    L88:
        f37 r73 = (f37) this.K;
        f37 r74 = (f37) this.L;
        ov4 r75 = (ov4) this.M;
        ((ci8) this.J).setValue(Boolean.FALSE);
        if (r73 == r74) goto L92;
        r75.invoke(r73);
    L92:
        return bjf.a;
    L93:
        mke r76 = (mke) this.K;
        fz9 r77 = (fz9) this.L;
        fh2 r78 = (fh2) this.M;
        aw2 r110 = (aw2) this.J;
        long r79 = r76.b(goi.a(Float.MAX_VALUE, Float.MAX_VALUE));
        r77.getClass();
        r78.getClass();
        dmd r80 = r77.A;
        if (r80 == null) goto L96;
        r80.a(null);
    L96:
        dmd r81 = vi2.A(r78, null, null, new yy9(r77, r79, r110, null, 2), 3);
        r77.A = r81;
        r81.d1(new o59(12, r77, r81));
        return bjf.a;
    L98:
        nfd r82 = (nfd) this.K;
        List r83 = (List) this.L;
        ov4 r84 = (ov4) this.M;
        ci8 r85 = (ci8) this.J;
        ArrayList r86 = new ArrayList(bt1.H0(r82, 10));
        ListIterator r87 = r82.listIterator();
    L99:
        ve7 r88 = (ve7) r87;
        if (r88.hasNext() == false) goto L102;
        r86.add(((xs5) r88.next()).J.a);
        goto L99
    L102:
        ArrayList r89 = new ArrayList(bt1.H0(r83, 10));
        Iterator r90 = r83.iterator();
    L104:
        if (r90.hasNext() == false) goto L107;
        r89.add(((xs5) r90.next()).J.a);
        goto L104
    L107:
        if (r86.equals(r89) == true) goto L109;
        r84.invoke(r86);
    L109:
        r85.setValue(Boolean.FALSE);
        return bjf.a;
    L111:
        ((ew4) this.K).invoke((sz9) ((ci8) this.J).getValue(), new ugf(((ugf) ((ci8) this.L).getValue()).I), kr3.b.get((int) ((i2a) this.M).h()));
        return bjf.a;
    L113:
        Function0 r91 = (Function0) this.K;
        vu2 r92 = (vu2) this.L;
        ov4 r93 = (ov4) this.M;
        Long r94 = ard.q0((String) ((ci8) this.J).getValue());
        if (r94 != null) goto L116;
        r91.invoke();
    L118:
        return bjf.a;
    L116:
        r93.invoke(Long.valueOf(me8.x(r94.longValue(), r92.b.longValue(), r92.c.longValue())));
        goto L118
    L119:
        String r95 = (String) this.K;
        fh2 r96 = (fh2) this.M;
        Context r97 = (Context) this.L;
        nmf r98 = (nmf) this.J;
        if (r95 == null) goto L135;
        r97.getClass();
        SharedPreferences.Editor r99 = r97.getApplicationContext().getSharedPreferences("backend_override", 0).edit();
        if (tqd.E0(r95) == false) goto L124;
        r99.remove(ImagesContract.URL);
    L125:
        r99.commit();
        String r100 = tqd.d1(r95).toString();
        if (r100 != null) goto L128;
    L132:
        r100 = "https://notability.com";
    L133:
        j1c.k = r100;
        vi2.A(r96, null, null, new ru2(r98, r8 == true ? 1 : 0, r4), 3);
        goto L135
    L128:
        if (r100.length() > 0) goto L131;
        r100 = null;
    L131:
        if (r100 != null) goto L133;
    L124:
        r99.putString(ImagesContract.URL, tqd.d1(r95).toString());
    L135:
        return bjf.a;
    L138:
        hm2 r101 = (hm2) this.K;
        String r102 = (String) this.L;
        rg8 r103 = (rg8) this.M;
        ci8 r104 = (ci8) this.J;
        int r111 = ((j2a) r103).h();
        String r112 = (String) r104.getValue();
        r101.getClass();
        r102.getClass();
        knd r105 = r101.O;
        if (r105.getValue() != null) goto L147;
        if (r101.L != null) goto L144;
        jof r106 = oo4.b;
        jof r113 = j1c.q();
    L145:
        r105.k(null, cm2.a);
        v72.E(r101.h(), new gm2(r101, r102, r111, r112, r113, null));
        goto L147
    L144:
        r113 = null;
    L147:
        return bjf.a;
    L148:
        Function0 r107 = (Function0) this.K;
        f4f r108 = (f4f) this.L;
        fh2 r109 = (fh2) this.M;
        ci8 r114 = (ci8) this.J;
        if (r107 == null) goto L151;
        r107.invoke();
    L155:
        return bjf.a;
    L151:
        if (r108.b() == false) goto L155;
        vi2.A(r109, null, null, new xq(r108, r7 == true ? 1 : 0, r3), 3);
        r114.setValue(Boolean.FALSE);
        goto L155
    L137:
        return CreatePublicKeyCredentialController.j((CreatePublicKeyCredentialController) this.K, (Exception) this.L, (Executor) this.M, (CredentialManagerCallback) this.J);
    }

    public /* synthetic */ ys0(fh2 r1, sq1 r2, String r3, ox0 r4, int r5) {
        this.I = r5;
        this.M = r1;
        this.K = r2;
        this.L = r3;
        this.J = r4;
    }

    public /* synthetic */ ys0(ew4 r2, ci8 r3, ci8 r4, i2a r5) {
        this.I = 5;
        this.K = r2;
        this.J = r3;
        this.L = r4;
        this.M = r5;
    }

    public /* synthetic */ ys0(Object r1, Object r2, ci8 r3, ci8 r4, int r5) {
        this.I = r5;
        this.K = r1;
        this.L = r2;
        this.J = r3;
        this.M = r4;
    }

    public /* synthetic */ ys0(Object r1, Object r2, Object r3, Object r4, int r5) {
        this.I = r5;
        this.K = r1;
        this.L = r2;
        this.M = r3;
        this.J = r4;
    }

    public /* synthetic */ ys0(Object r1, Object r2, Object r3, Function0 r4, int r5) {
        this.I = r5;
        this.L = r1;
        this.M = r2;
        this.J = r3;
        this.K = r4;
    }

    public /* synthetic */ ys0(String r2, fh2 r3, Context r4, nmf r5) {
        this.I = 3;
        this.K = r2;
        this.M = r3;
        this.L = r4;
        this.J = r5;
    }
}
