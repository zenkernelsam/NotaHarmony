package defpackage;

import android.graphics.BlendMode;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.PathMeasure;
import android.graphics.RectF;
import android.os.Trace;
import com.gingerlabs.notability.core.common.logging.a;
import com.google.android.gms.auth.blockstore.BlockstoreClient;
import com.google.android.gms.fido.fido2.api.common.UserVerificationMethods;
import com.samsung.android.sdk.iap.lib.constants.HelperConstants;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

/* JADX INFO: loaded from: classes.dex */
public final class oz5 {
    public final pz5 a;
    public final uaa b;
    public volatile gaa c;
    public final kv8 d = new kv8(new pu4(10), new g77(23));
    public final kv8 e = new kv8(new pu4(11), new g77(23));
    public final kv8 f = new kv8(new pu4(12), new g77(23));
    public final kv8 g = new kv8(new pu4(13), new g77(23));
    public final qae h = new qae();
    public final kv8 i = new kv8(new pu4(14), new g77(23));
    public final kv8 j = new kv8(new pu4(15), new g77(23));
    public final kv8 k = new kv8(new pu4(16), new g77(23));
    public final kv8 l = new kv8(new pu4(17), new g77(23));
    public final kv8 m = new kv8(new pu4(18), new g77(23));
    public final kv8 n = new kv8(new pu4(19), new g77(23));
    public final kv8 o = new kv8(mz5.I, new g77(23));
    public final kv8 p = new kv8(lz5.I, new g77(23));
    public final kv8 q = new kv8(kz5.I, new g77(23));
    public final zq7 r = new zq7(UserVerificationMethods.USER_VERIFY_ALL);
    public static final /* synthetic */ cj6[] t = {new pxa(oz5.class, "bezierPaint", "getBezierPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "bezierBlendPaint", "getBezierBlendPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "centralPathPaint", "getCentralPathPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "fillPaint", "getFillPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "tapeRevealPaint", "getTapeRevealPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "selectionPaint", "getSelectionPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "selectionPointPaint", "getSelectionPointPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "selectionPointContrastPaint", "getSelectionPointContrastPaint()Landroid/graphics/Paint;", 0), new pxa(oz5.class, "dashPathEffectCache", "getDashPathEffectCache()Ljava/util/HashMap;", 0), new pxa(oz5.class, "dotsPathEffectCache", "getDotsPathEffectCache()Ljava/util/HashMap;", 0), new pxa(oz5.class, "reusableBounds", "getReusableBounds()Landroid/graphics/RectF;", 0), new pxa(oz5.class, "playbackPathMeasure", "getPlaybackPathMeasure()Landroid/graphics/PathMeasure;", 0), new pxa(oz5.class, "playbackPath", "getPlaybackPath()Landroid/graphics/Path;", 0)};
    public static final ez5 s = new ez5(0);
    public static final Set u = a90.W0(new sz5[]{sz5.DASH, sz5.DOTS});
    public static final float v = 2.0f;

    public oz5(pz5 pz5Var, uaa uaaVar, gaa gaaVar) {
        this.a = pz5Var;
        this.b = uaaVar;
        this.c = gaaVar;
    }

    public static final ee0 a(oz5 oz5Var, ry5 ry5Var, pcb pcbVar, List list) {
        ry5Var.getClass();
        if (pcbVar == null || list.isEmpty()) {
            return ee0.c;
        }
        if (xs7.S(ry5Var.c(), list) == null) {
            return ee0.c;
        }
        ie0 ie0VarC = wvi.c(ry5Var, pcbVar.I);
        if (ie0VarC.equals(he0.a)) {
            return ee0.d;
        }
        if (ie0VarC.equals(ge0.a)) {
            return ee0.c;
        }
        if (ie0VarC instanceof fe0) {
            return new ee0(Float.valueOf(0.3f), Float.valueOf(((fe0) ie0VarC).a()));
        }
        yz3.t();
        return null;
    }

    /*  JADX ERROR: NullPointerException in pass: ConstructorVisitor
        java.lang.NullPointerException: Cannot invoke "jadx.core.dex.instructions.args.RegisterArg.sameRegAndSVar(jadx.core.dex.instructions.args.InsnArg)" because "resultArg" is null
        	at jadx.core.dex.visitors.MoveInlineVisitor.processMove(MoveInlineVisitor.java:52)
        	at jadx.core.dex.visitors.MoveInlineVisitor.moveInline(MoveInlineVisitor.java:41)
        	at jadx.core.dex.visitors.ConstructorVisitor.visit(ConstructorVisitor.java:43)
        */
    public static defpackage.fz5 b(
    /*  JADX ERROR: Method generation error
        jadx.core.utils.exceptions.JadxRuntimeException: Code variable not set in r20v0 ??
        	at jadx.core.dex.instructions.args.SSAVar.getCodeVar(SSAVar.java:236)
        	at jadx.core.codegen.MethodGen.addMethodArguments(MethodGen.java:215)
        	at jadx.core.codegen.MethodGen.addDefinition(MethodGen.java:150)
        	at jadx.core.codegen.ClassGen.addMethodCode(ClassGen.java:415)
        	at jadx.core.codegen.ClassGen.addMethod(ClassGen.java:345)
        	at jadx.core.codegen.ClassGen.lambda$addInnerClsAndMethods$3(ClassGen.java:299)
        	at java.base/java.util.stream.ForEachOps$ForEachOp$OfRef.accept(ForEachOps.java:183)
        	at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)
        	at java.base/java.util.stream.SortedOps$RefSortingSink.end(SortedOps.java:395)
        	at java.base/java.util.stream.Sink$ChainedReference.end(Sink.java:258)
        */
    /*  JADX ERROR: NullPointerException in pass: ConstructorVisitor
        java.lang.NullPointerException: Cannot invoke "jadx.core.dex.instructions.args.RegisterArg.sameRegAndSVar(jadx.core.dex.instructions.args.InsnArg)" because "resultArg" is null
        	at jadx.core.dex.visitors.MoveInlineVisitor.processMove(MoveInlineVisitor.java:52)
        	at jadx.core.dex.visitors.MoveInlineVisitor.moveInline(MoveInlineVisitor.java:41)
        */

    public static Object d(oz5 oz5Var, Set set, Set set2, Set set3, boolean z, Map map, BlendMode blendMode, boolean z2, Set set4, Long l, ex8 ex8Var, m3e m3eVar, int i) {
        return vi2.T(mf3.a, new hz5(me8.v(Runtime.getRuntime().availableProcessors() - 1, 1, 3), set, oz5Var, l, ex8Var, z, map, set2, set3, blendMode, z2, (i & UserVerificationMethods.USER_VERIFY_PATTERN) != 0 ? av3.I : set4, null), m3eVar);
    }

    public static Object e(oz5 oz5Var, Set set, Set set2, Set set3, boolean z, Map map, BlendMode blendMode, boolean z2, Long l, ex8 ex8Var, p8g p8gVar, int i) {
        return vi2.T(mf3.a, new jz5(me8.v(Runtime.getRuntime().availableProcessors() - 1, 1, 3), set, oz5Var, l, ex8Var, map, set3, z, (i & 32) != 0 ? BlendMode.SRC_OVER : blendMode, z2, set2, null), p8gVar);
    }

    public static long h(ry5 ry5Var, Map map) {
        return zj9.g(vi2.Q(ry5Var.i()), vi2.Q(l(ry5Var.j(), map)));
    }

    public static yla l(lsc lscVar, Map map) {
        uhb uhbVar = (uhb) nt6.i(lscVar, map);
        if (uhbVar != null) {
            return uhbVar.c();
        }
        ArrayList arrayList = a.a;
        a.c(cl7.RENDERER, "Page not found", null, new oc(lscVar, 22));
        return (yla) ama.a.getValue();
    }

    public static final void q(xrd xrdVar, Canvas canvas, oz5 oz5Var, Path path) {
        kv8 kv8Var = oz5Var.e;
        kv8 kv8Var2 = oz5Var.o;
        if (cd3.a()) {
            urd urdVar = (urd) xrdVar;
            if (((urdVar.g >> 24) & HelperConstants.PASSTHROGUH_MAX_LENGTH) != 255) {
                cj6[] cj6VarArr = t;
                path.computeBounds((RectF) v72.x(kv8Var2, cj6VarArr[10]), false);
                ((RectF) v72.x(kv8Var2, cj6VarArr[10])).inset(-3.0f, -3.0f);
                ((Paint) v72.x(kv8Var, cj6VarArr[1])).setBlendMode(urdVar.h);
                canvas.saveLayer((RectF) v72.x(kv8Var2, cj6VarArr[10]), (Paint) v72.x(kv8Var, cj6VarArr[1]));
                canvas.drawPath(path, oz5Var.i());
                canvas.restore();
                return;
            }
        }
        canvas.drawPath(path, oz5Var.i());
    }

    public static void s(Paint paint, int i, BlendMode blendMode, boolean z, Float f) {
        paint.setColor(i);
        paint.setBlendMode(blendMode);
        if (z) {
            paint.setAlpha(me8.v((int) (paint.getAlpha() * 0.2f), 0, HelperConstants.PASSTHROGUH_MAX_LENGTH));
        }
        if (f != null) {
            paint.setAlpha(me8.v((int) (paint.getAlpha() * f.floatValue()), 0, HelperConstants.PASSTHROGUH_MAX_LENGTH));
        }
    }

    public final wrd c(long j, b0d b0dVar, Float f, float f2, int i, boolean z, BlendMode blendMode, boolean z2, float[] fArr, Path path, Path path2, List list, Float f3, Float f4) {
        b0dVar.getClass();
        blendMode.getClass();
        fArr.getClass();
        return new wrd(j, e0d.b(b0dVar, f != null ? f.floatValue() : 1.0f, f2, 1544949492L, 0.0f, 0.0f, null, this.c), path, f2, hu8.c(i, z), blendMode, z2, fArr, list, path2, f3, f4, null, BlockstoreClient.MAX_SIZE);
    }

    public final void f(Canvas canvas, wrd wrdVar, float f, float f2, float f3) {
        Path path = wrdVar.e;
        if (path != null) {
            n().setStrokeWidth(Math.min(f, wrdVar.f / 2.0f));
            canvas.drawPath(path, n());
            Path path2 = wrdVar.l;
            if (path2 != null) {
                canvas.drawPath(path2, n());
            }
        }
        g(canvas, wrdVar.k, f2, f3);
    }

    public final void g(Canvas canvas, List list, float f, float f2) {
        Iterator it = list.iterator();
        while (it.hasNext()) {
            long j = ((ng3) it.next()).a;
            float fE = ng3.e(j);
            float f3 = ng3.f(j);
            cj6[] cj6VarArr = t;
            canvas.drawCircle(fE, f3, f, (Paint) v72.x(this.l, cj6VarArr[7]));
            canvas.drawCircle(ng3.e(j), ng3.f(j), f2, (Paint) v72.x(this.k, cj6VarArr[6]));
        }
    }

    public final Paint i() {
        return (Paint) v72.x(this.d, t[0]);
    }

    public final Paint j() {
        return (Paint) v72.x(this.f, t[2]);
    }

    public final Paint k() {
        return (Paint) v72.x(this.g, t[3]);
    }

    public final Path m() {
        return (Path) v72.x(this.q, t[12]);
    }

    public final Paint n() {
        return (Paint) v72.x(this.j, t[5]);
    }

    public final Paint o() {
        return (Paint) v72.x(this.i, t[4]);
    }

    public final dz5 p(xrd xrdVar, float f, a83 a83Var) {
        a83Var.getClass();
        int i = moc.f;
        return new dz5(xrdVar, this, a83Var, f, vi2.P(2.0f, a83Var, f), moc.a(f, a83Var), vi2.P(6.0f, a83Var, f));
    }

    public final Path r(xrd xrdVar) {
        Float fA = xrdVar.a();
        if (fA == null) {
            return xrdVar.c();
        }
        float fFloatValue = fA.floatValue();
        if (fFloatValue >= 1.0f) {
            return xrdVar.c();
        }
        if (fFloatValue <= 0.0f) {
            m().rewind();
            return m();
        }
        cj6[] cj6VarArr = t;
        cj6 cj6Var = cj6VarArr[11];
        kv8 kv8Var = this.p;
        ((PathMeasure) v72.x(kv8Var, cj6Var)).setPath(xrdVar.c(), false);
        float length = ((PathMeasure) v72.x(kv8Var, cj6VarArr[11])).getLength();
        if (length <= 0.0f) {
            return xrdVar.c();
        }
        m().rewind();
        ((PathMeasure) v72.x(kv8Var, cj6VarArr[11])).getSegment(0.0f, length * fFloatValue, m(), true);
        return m();
    }

    public final haa t(ry5 ry5Var) {
        xw0 xw0Var = xw0.f;
        xw0 xw0VarD = kx0.d(ry5Var.Q(), this.a.b);
        double dC0 = ry5Var.c0();
        hud hudVar = (hud) zs1.g1(0, ry5Var.a0());
        long jF = hudVar != null ? hudVar.f() : 1544949492L;
        a81 a81Var = null;
        if (hudVar != null) {
            yla ylaVarE = hudVar.e();
            if (ylaVarE.c() == 0.0f && ylaVarE.d() == 0.0f) {
                ylaVarE = null;
            }
            if (ylaVarE != null) {
                a81Var = new a81(ylaVarE.c(), ylaVarE.d());
            }
        }
        a81 a81Var2 = a81Var;
        List list = xw0VarD.a;
        ArrayList arrayList = new ArrayList();
        for (Object obj : list) {
            if (obj instanceof ic0) {
                arrayList.add(obj);
            }
        }
        haa haaVar = new haa(te6.n(arrayList, dC0), this.c);
        h76.Y("InkRenderer.buildPencilStrokeContent.walk");
        try {
            te6.q(arrayList, dC0, new nz5(haaVar), jF, a81Var2);
            return haaVar;
        } finally {
            Trace.endSection();
        }
    }
}
