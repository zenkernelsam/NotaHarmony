package defpackage;

import android.content.Context;
import android.graphics.Color;
import android.view.MotionEvent;
import androidx.recyclerview.widget.RecyclerView;
import com.gingerlabs.notability.core.common.logging.a;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/* JADX INFO: loaded from: classes.dex */
public final class cxe extends er0 implements d9g {
    public static final long N0 = 0;
    public static final long O0 = 0;
    public static final long P0 = 0;
    public static final /* synthetic */ int Q0 = 0;
    public final mbb A0;
    public final mbb B0;
    public final mbb C0;
    public final p7e D0;
    public final mbb E0;
    public boolean F0;
    public boolean G0;
    public lxe H0;
    public dmd I0;
    public Integer J0;
    public final Context K;
    public lxe K0;
    public final mvf L;
    public int L0;
    public final h89 M;
    public final mxe M0;
    public final oqb N;
    public final b3f O;
    public final kra P;
    public final hz8 Q;
    public final tfe R;
    public final fke S;
    public final qs7 T;
    public final nmc U;
    public final f8a V;
    public final h8e W;
    public final d30 X;
    public final uc8 Y;
    public final vr6 Z;
    public final j06 a0;
    public final j0d b0;
    public final qud c0;
    public final ob5 d0;
    public final kf2 e0;
    public final m9a f0;
    public final tif g0;
    public final r79 h0;
    public final q79 i0;
    public final uaa j0;
    public final st9 k0;
    public final lm8 l0;
    public final n19 m0;
    public final b19 n0;
    public final xba o0;
    public final pf3 p0;
    public final iof q0;
    public final mbb r0;
    public final mbb s0;
    public final mbb t0;
    public final mbb u0;
    public final mbb v0;
    public final mbb w0;
    public final ds6 x0;
    public final c3d y0;
    public final kbb z0;

    static {
        p7j r0 = jp3.J;
        np3 r1 = np3.M;
        N0 = sdg.r0(1, r1);
        O0 = sdg.r0(200, np3.L);
        P0 = sdg.r0(1, r1);
    }

    public cxe(Context r18, mvf r19, h89 r20, oqb r21, b3f r22, kra r23, hz8 r24, tfe r25, fke r26, qs7 r27, ls1 r28, xve r29, nmc r30, f8a r31, h8e r32, d30 r33, uc8 r34, vr6 r35, j06 r36, j0d r37, qud r38, ob5 r39, kf2 r40, m9a r41, tif r42, r79 r43, q79 r44, uaa r45, st9 r46, x99 r47, lm8 r48, n19 r49, b19 r50, xba r51, pf3 r52, iof r53) {
        mbb r7 = r47.g;
        mbb r8 = r47.e;
        r53.getClass();
        this.K = r18;
        this.L = r19;
        this.M = r20;
        this.N = r21;
        this.O = r22;
        this.P = r23;
        this.Q = r24;
        this.R = r25;
        this.S = r26;
        this.T = r27;
        this.U = r30;
        this.V = r31;
        this.W = r32;
        this.X = r33;
        this.Y = r34;
        this.Z = r35;
        this.a0 = r36;
        this.b0 = r37;
        this.c0 = r38;
        this.d0 = r39;
        this.e0 = r40;
        this.f0 = r41;
        this.g0 = r42;
        this.h0 = r43;
        this.i0 = r44;
        this.j0 = r45;
        this.k0 = r46;
        this.l0 = r48;
        this.m0 = r49;
        this.n0 = r50;
        this.o0 = r51;
        this.p0 = r52;
        this.q0 = r53;
        fh2 r10 = h();
        r10.getClass();
        ce2 r13 = null;
        if (r23.h == false) goto L6;
        vi2.A(r10, null, null, new w40(r23, r13, 29), 3);
    L6:
        int r11 = 10;
        ue0 r9 = new ue0(n7j.b2(r20), r11);
        thd r1 = new thd(r11);
        b1c r12 = bff.d;
        bff.w(2, r1);
        mbb r2 = bp.w0(bff.K(r9, r12, r1), h(), u4d.a(2, 5000), x9a.b);
        this.r0 = r2;
        this.s0 = bp.w0(bp.O(new f45(r2, 7)), h(), u4d.a(2, 5000), null);
        this.t0 = r50.e;
        int r14 = 8;
        dw r15 = new dw((mbb) r25.b().n.d.L, r14);
        q9e r6 = new q9e(18);
        bff.w(2, r6);
        cg3 r16 = bff.K(r15, r12, r6);
        fh2 r17 = h();
        ez5 r110 = u4d.a;
        mbb r54 = bp.w0(r16, r17, r110, null);
        this.u0 = r54;
        eh1 r55 = bp.A0(r25.r, new lm4(3, 7, r13));
        fh2 r111 = h();
        su3 r112 = su3.I;
        mbb r56 = bp.w0(r55, r111, r110, r112);
        this.v0 = r56;
        this.w0 = bp.w0(bp.A0(bp.O(new f45(r2, r14)), new v40(r13, this, 17)), h(), u4d.a(2, 5000), aaa.b);
        int r113 = 3;
        ce2 r114 = null;
        vwe r3 = new vwe(new jt2(null, new jt2(r54, r8, new we0(r113, 8, r114), 2), new we0(r113, 9, r114)), 0);
        t23 r115 = mf3.a;
        sj4 r4 = bp.X(r3, r115);
        fh2 r116 = h();
        ymd r117 = u4d.a(2, 5000);
        ru3 r57 = ru3.I;
        mbb r5 = bp.w0(r4, r116, r117, r57);
        ce2 r118 = null;
        jt2 r119 = new jt2(r56, r8, new we0(3, 10, r118), 2);
        int r58 = 1;
        mbb r59 = bp.w0(bp.X(new vwe(new jt2(r112, r119, new u99(3, r58, r118)), r58), r115), h(), u4d.a(2, 5000), r112);
        ls1.a(r28, h());
        this.x0 = new ds6();
        c3d r120 = d3d.b(0, 1, null, 5);
        this.y0 = r120;
        this.z0 = new kbb(r120);
        this.D0 = new p7e(new yve(this, 0));
        this.E0 = r25.u;
        a(r43);
        int r60 = 4;
        ce2 r121 = null;
        vi2.A(h(), null, null, new bwe(this, r121, r60), 3);
        vi2.A(h(), null, null, new bwe(this, r121, 5), 3);
        fh2 r61 = h();
        r61.getClass();
        vi2.A(r61, r115, null, new qve(r29, r121, 1), 2);
        knd r62 = r29.m;
        mbb r63 = bp.w0(new k99(new dw(r62, 8), 2), h(), r110, lwe.a);
        this.A0 = r63;
        sj4 r64 = bp.O(new f45(r63, 9));
        sj4 r65 = bp.O(new f45(r63, 10));
        qwe r122 = new qwe(this, r47, null);
        bu2 r123 = px1.a;
        r7.getClass();
        r8.getClass();
        mbb r66 = bp.w0(bp.X(px1.c(r7, r8, r65, px1.a, new nx1(r122, null)), r115), h(), u4d.a(2, 5000), r57);
        ewe r67 = new ewe(null);
        gm4 r124 = qm4.a;
        this.B0 = bp.w0(bp.X(bp.O(new xc3(7, new sj4[]{r66, r7, r8, r5, r59, r64}, r67)), r115), h(), u4d.a(2, 5000), new jgc(r57));
        ce2 r68 = null;
        this.C0 = bp.w0(bp.X(bp.A0(wfe.a, new jm4(r60, r68, this, r47)), r115), h(), u4d.a(2, 5000), null);
        vi2.A(h(), null, null, new bwe(this, r68, 6), 3);
        int r125 = 7;
        vi2.A(h(), null, null, new deb(r125, r68, this, r62), 3);
        vi2.A(h(), null, null, new bwe(this, r68, r125), 3);
        vi2.A(h(), r115, null, new bwe(this, r68, 8), 2);
        vi2.A(h(), ns7.a.N, null, new bwe(this, r68, 0), 2);
        vi2.A(h(), null, null, new bwe(this, r68, 1), 3);
        vi2.A(h(), null, null, new bwe(this, r68, 2), 3);
        vi2.A(h(), null, null, new bwe(this, r68, 3), 3);
        this.M0 = mxe.a;
    }

    @Override // defpackage.cuf
    public final void f() {
        j("navigate_back");
        c08 r0 = new c08(this.q0);
        y79 r2 = this.o0.a(r0);
        r2.d.a.clear();
        r2.b.invoke(r2.a);
        ps1.a();
    }

    @Override // defpackage.er0
    public final ind g() {
        return this.A0;
    }

    public final void i(MotionEvent r19, MotionEvent r20, t0f r21) {
        r19.getClass();
        r21.getClass();
        if (this.N.c() != null) goto L9;
        if (r20 == null) goto L6;
        r20.recycle();
    L6:
        l();
        return;
    L9:
        if (((Boolean) this.t0.I.getValue()).booleanValue() == true) goto L14;
        if (r20 == null) goto L12;
        r20.recycle();
    L12:
        l();
        return;
    L14:
        kra r0 = this.P;
        int r1 = r19.getAction();
        float r3 = r19.getX();
        float r4 = r19.getY();
        lxe r9 = null;
        if (r0.h == false) goto L26;
        if (r1 == 1) goto L21;
        if (r1 == 3) goto L21;
        if (r1 == 6) goto L21;
        hvf r2 = (hvf) r0.c.e.I.getValue();
        long r13 = Float.floatToRawIntBits(r3);
        ng3 r5 = new ng3(r2.a((((long) Float.floatToRawIntBits(r4)) & 4294967295L) | (r13 << 32)));
    L22:
        if (r5 == null) goto L24;
        r0.j = r5;
    L24:
        r0.i.j(r5);
    L21:
        r5 = null;
    L26:
        if (r21 != t0f.R) goto L43;
        vr6 r6 = this.Z;
        int r7 = r19.getAction();
        float r8 = r19.getX();
        float r10 = r19.getY();
        r6.getClass();
        if (r7 == 0) goto L37;
        if (r7 == 1) goto L36;
        if (r7 == 2) goto L35;
        if (r7 == 3) goto L34;
        if (r7 == 6) goto L36;
    L39:
        if (r20 == null) goto L41;
        r20.recycle();
    L41:
        l();
        return;
    L34:
        Object r11 = kr6.a;
    L38:
        r6.a.e(r11);
        goto L39
    L35:
        r11 = new mr6(r8, r10);
    L36:
        r11 = nr6.a;
        goto L38
    L37:
        r11 = new lr6(r8, r10);
        goto L38
    L43:
        j06 r12 = this.a0;
        int r14 = r19.getAction();
        float r15 = r19.getX();
        float r16 = r19.getY();
        c3d r17 = r12.a;
        if (((Number) r17.h().getValue()).intValue() == 0) goto L48;
        if (r14 != 0) goto L48;
        long r18 = Float.floatToRawIntBits(r15);
        r17.e(new zj9((Float.floatToRawIntBits(r16) & 4294967295L) | (r18 << 32)));
    L48:
        int r22 = r19.getAction();
        if (r22 == 0) goto L61;
        if (r22 == 1) goto L56;
        if (r22 == 2) goto L55;
        if (r22 == 3) goto L56;
        if (r22 == 6) goto L56;
    L62:
        ds6 r23 = this.x0;
        ys0 r24 = new ys0(r19, this, r20, r21, 17);
        r23.getClass();
        long r25 = vb8.b();
        r24.invoke();
        r23.h(lxe.a(r25));
        return;
    L55:
        this.T.b(os7.K);
    L56:
        this.G0 = false;
        if (afh.e(r19) == true) goto L60;
        r9 = this.M0.a();
    L60:
        this.H0 = r9;
        goto L62
    L61:
        this.G0 = true;
        this.H0 = null;
        this.J0 = Integer.valueOf(this.p0.a(this.L0));
        this.T.b(os7.J);
        goto L62
    }

    public final void j(String r10) {
        qs7 r0 = this.T;
        ds6 r1 = this.x0;
        fke r2 = this.S;
        nu7 r9 = this.o0.a(new c08(this.q0)).b();
        ArrayList r3 = a.a;
        cl7 r4 = cl7.U;
        jm7 r5 = jm7.K;
        if (a.a(r5, r4) == true) goto L45;
    L17:
        Object r11 = r1.a;
        monitor-enter(r11);
        r1.b = 0;     // Catch: Throwable -> L38
        r1.c = 0;     // Catch: Throwable -> L38
        r1.d = Long.MAX_VALUE;     // Catch: Throwable -> L38
        r1.e = Long.MIN_VALUE;     // Catch: Throwable -> L38
        a90.Q(r1.f, 0);     // Catch: Throwable -> L38
        monitor-exit(r11);
        ds6 r12 = r2.b;
        Object r6 = r12.a;
        monitor-enter(r6);
        r12.b = 0;     // Catch: Throwable -> L35
        r12.c = 0;     // Catch: Throwable -> L35
        r12.d = Long.MAX_VALUE;     // Catch: Throwable -> L35
        r12.e = Long.MIN_VALUE;     // Catch: Throwable -> L35
        a90.Q(r12.f, 0);     // Catch: Throwable -> L35
        monitor-exit(r6);
        ds6 r13 = r2.c;
        Object r7 = r13.a;
        monitor-enter(r7);
        r13.b = 0;     // Catch: Throwable -> L32
        r13.c = 0;     // Catch: Throwable -> L32
        r13.d = Long.MAX_VALUE;     // Catch: Throwable -> L32
        r13.e = Long.MIN_VALUE;     // Catch: Throwable -> L32
        a90.Q(r13.f, 0);     // Catch: Throwable -> L32
        monitor-exit(r7);
        r0.getClass();
        r0.e = qs7.a();
        return;
    L32:
        th = move-exception;
        throw th;
    L35:
        th = move-exception;
        throw th;
    L38:
        th = move-exception;
        throw th;
    L45:
        qz3 r8 = new qz3();     // Catch: Exception -> L8
        r8.b.put("note.close.reason", r10);     // Catch: Exception -> L8
        List r14 = ds6.g;     // Catch: Exception -> L8
        hu2.t0(r8, "ink.input", r1.g(ru3.I));     // Catch: Exception -> L8
        ds6 r15 = r2.b;     // Catch: Exception -> L8
        List r16 = ds6.g;     // Catch: Exception -> L8
        hu2.t0(r8, "text_input.main_body", r15.g(r16));     // Catch: Exception -> L8
        hu2.t0(r8, "text_input.text_boxes", r2.c.g(r16));     // Catch: Exception -> L8
        Iterator r17 = ((ou7) r9.entrySet()).iterator();     // Catch: Exception -> L8
    L6:
        if (r17.hasNext() == false) goto L10;
        Map.Entry r18 = (Map.Entry) r17.next();     // Catch: Exception -> L8
        String r19 = (String) r18.getKey();     // Catch: Exception -> L8
        r8.d(r18.getValue(), r19);     // Catch: Exception -> L8
        goto L6
    L10:
        Iterator r20 = ((ou7) r0.c().entrySet()).iterator();     // Catch: Exception -> L8
    L12:
        if (r20.hasNext() == false) goto L14;
        Map.Entry r110 = (Map.Entry) r20.next();     // Catch: Exception -> L8
        String r21 = (String) r110.getKey();     // Catch: Exception -> L8
        r8.d(r110.getValue(), r21);     // Catch: Exception -> L8
        goto L12
    L14:
        sz3 r22 = r8.b();     // Catch: Exception -> L8
        a.e(r5, r4, "close note", r22.a, r22.b);     // Catch: Exception -> L8
    L8:
        e = move-exception;
        a.g(r4, "close note", e);
        goto L17
    }

    public final Object k(ce2 r23) {
        if ((r23 instanceof owe) == false) goto L7;
        owe r2 = (owe) r23;
        int r3 = r2.L;
        if ((r3 & RecyclerView.UNDEFINED_DURATION) == 0) goto L7;
        r2.L = r3 - RecyclerView.UNDEFINED_DURATION;
    L8:
        Object r1 = r2.J;
        int r4 = r2.L;
        n19 r5 = this.m0;
        Float r6 = null;
        bjf r7 = bjf.a;
        if (r4 == 0) goto L14;
        if (r4 != 1) goto L12;
        j0f r8 = r2.I;
        ny7.F0(r1);
    L40:
        g0d r9 = (g0d) r1;
        if (r9 == null) goto L108;
        m0d r10 = r9.b();
        switch(r10.a().d().ordinal()) {
            case 0: goto L51;
            case 1: goto L51;
            case 2: goto L48;
            case 3: goto L48;
            case 4: goto L48;
            case 5: goto L48;
            case 6: goto L48;
            case 7: goto L48;
            default: goto L45;
        };
    L45:
        yz3.t();
        return null;
    L48:
        if (((k19) r5.f().getValue()).d == false) goto L108;
    L53:
        p3d r11 = cbh.b(r10);
        Object r12 = this.A0.I.getValue();
        if ((r12 instanceof kwe) == false) goto L56;
        kwe r13 = (kwe) r12;
    L57:
        if (r13 == null) goto L108;
        ex8 r14 = r13.a;
        if (r14 == null) goto L108;
        ix9 r15 = xi7.F(r14, (float) r11.a());
        if (r15 == null) goto L108;
        lsc r16 = ((uv9) r15.I).a;
        yla r17 = (yla) r15.J;
        sz5 r18 = dxe.a(r0f.e(r8));
        if (r18 != sz5.J) goto L68;
        r18 = null;
    L68:
        if (r18 != null) goto L70;
        r18 = sz5.K;
    L70:
        sz5 r19 = r18;
        if ((r8 instanceof lze) == false) goto L74;
        int r20 = yw1.e(r0f.d(r8), 107);
    L101:
        gt1 r110 = st1.d(Color.valueOf(r20));
        yla r111 = cbh.e(r11, r17);
        b0d r112 = cbh.a(r10, r11);
        qz5 r21 = r10.a();
        if ((r21 instanceof ly5) == false) goto L104;
        ly5 r22 = (ly5) r21;
    L105:
        if (r22 == null) goto L107;
        r6 = new Float(r22.g());
    L107:
        pc3 r24 = new pc3(r10, r11, r16, r17, r111, r112, r6, cbh.d(r8.g()), r19, r110, r0f.f(r8), r9.a());
        uc8 r0 = this.Y;
        r0.getClass();
        qm4.d(r0.a, new pc8(r24));
        goto L108
    L104:
        r22 = null;
        goto L105
    L74:
        if ((r8 instanceof jze) == false) goto L76;
    L100:
        r20 = r0f.d(r8);
        goto L101
    L76:
        if ((r8 instanceof nze) == true) goto L100;
        if ((r8 instanceof pze) == true) goto L100;
        if ((r8 instanceof rze) == true) goto L100;
        if ((r8 instanceof tze) == true) goto L100;
        if ((r8 instanceof uze) == true) goto L100;
        if ((r8 instanceof wze) == true) goto L100;
        if ((r8 instanceof yze) == true) goto L100;
        if ((r8 instanceof a0f) == true) goto L100;
        if ((r8 instanceof c0f) == true) goto L100;
        if ((r8 instanceof e0f) == true) goto L100;
        if ((r8 instanceof h0f) == true) goto L100;
        yz3.t();
        return null;
    L56:
        r13 = null;
        goto L57
    L51:
        if (((k19) r5.f().getValue()).c == true) goto L53;
    L108:
        return r7;
    L12:
        yz3.l("call to 'resume' before 'invoke' with coroutine");
        return null;
    L14:
        ny7.F0(r1);
        if (((k19) r5.f().getValue()).c == false) goto L17;
    L19:
        j0f r25 = (j0f) this.O.m.getValue();
        if (r25 == null) goto L108;
        boolean r26 = r25 instanceof tze;
        j0d r27 = this.b0;
        if (r26 == false) goto L36;
        Iterator r28 = ((List) r27.d.getValue()).iterator();
        if (r28.hasNext() == true) goto L27;
        Double r29 = null;
    L32:
        if (r29 == null) goto L36;
        if (Math.min(Math.max(0.6283185307179586d - r29.doubleValue(), 0.0d) / 0.45331853071795863d, 1.0d) <= 0.1d) goto L36;
    L27:
        double r30 = ((n0d) r28.next()).a();
    L29:
        if (r28.hasNext() == false) goto L31;
        r30 = Math.min(r30, ((n0d) r28.next()).a());
        goto L29
    L31:
        r29 = Double.valueOf(r30);
    L36:
        r2.I = r25;
        r2.L = 1;
        Object r31 = r27.a(r2);
        gh2 r32 = gh2.I;
        if (r31 != r32) goto L39;
        return r32;
    L39:
        r8 = r25;
        r1 = r31;
        goto L40
    L17:
        if (((k19) r5.f().getValue()).d == true) goto L19;
    L7:
        r2 = new owe(this, r23);
        goto L8
    }

    public final void l() {
        this.G0 = false;
        this.H0 = null;
        this.F0 = false;
        dmd r2 = this.I0;
        if (r2 == null) goto L6;
        r2.a(null);
        return;
    }

    public final void m() {
        int r0 = this.p0.a(this.L0);
        Integer r1 = this.J0;
        this.J0 = Integer.valueOf(r0);
        if (r1 != null) goto L5;
        return;
    L5:
        if (r1.intValue() == r0) goto L9;
        this.K0 = this.M0.a();
        return;
    }
}
