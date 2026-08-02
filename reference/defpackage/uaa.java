package defpackage;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.BitmapShader;
import android.graphics.BlendMode;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffColorFilter;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.RuntimeShader;
import android.graphics.Shader;
import android.os.Build;
import android.os.SharedMemory;
import android.os.Trace;
import android.system.ErrnoException;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.core.common.logging.a;
import com.samsung.android.sdk.iap.lib.constants.HelperConstants;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicInteger;

/* JADX INFO: loaded from: classes.dex */
public final class uaa {
    public static volatile Bitmap j;
    public static volatile BitmapShader k;
    public static volatile dc5 m;
    public static volatile boolean o;
    public final Context a;
    public final kv8 b;
    public final kv8 c;
    public final kv8 d;
    public final kv8 e;
    public final ThreadLocal f = new ThreadLocal();
    public final ThreadLocal g = new ThreadLocal();
    public static final /* synthetic */ cj6[] i = {new pxa(uaa.class, "paint", "getPaint()Landroid/graphics/Paint;", 0), new pxa(uaa.class, "blitPaint", "getBlitPaint()Landroid/graphics/Paint;", 0), new pxa(uaa.class, "batchScratch", "getBatchScratch()Lcom/gingerlabs/notability/ui/renderer/pencil/PencilSplatRenderer$BatchScratch;", 0), new pxa(uaa.class, "colorFilterCache", "getColorFilterCache()Landroidx/collection/LruCache;", 0)};
    public static final ga6 h = new ga6(5);
    public static final Object l = new Object();
    public static final Object n = new Object();
    public static final ConcurrentLinkedQueue p = new ConcurrentLinkedQueue();
    public static final AtomicInteger q = new AtomicInteger(0);

    public uaa(Context context) {
        this.a = context;
        int i2 = 23;
        this.b = new kv8(new ks8(16), new g77(i2));
        this.c = new kv8(new ks8(17), new g77(i2));
        this.d = new kv8(taa.I, new g77(i2));
        this.e = new kv8(new ks8(18), new g77(i2));
    }

    public static Bitmap a(int i2, int i3, int[] iArr) throws ErrnoException {
        SharedMemory sharedMemoryCreate = SharedMemory.create("pencil-splat-f16", i2 * i3 * 8);
        sharedMemoryCreate.getClass();
        try {
            ByteBuffer byteBufferOrder = sharedMemoryCreate.mapReadWrite().order(ByteOrder.nativeOrder());
            try {
                for (int i4 : iArr) {
                    int iAlpha = Color.alpha(i4);
                    float fPow = iAlpha != 0 ? iAlpha != 255 ? (float) Math.pow(((double) iAlpha) / 255.0d, 1.5d) : 1.0f : 0.0f;
                    float fRed = (Color.red(i4) / 255.0f) * fPow;
                    float fGreen = (Color.green(i4) / 255.0f) * fPow;
                    float fBlue = (Color.blue(i4) / 255.0f) * fPow;
                    byteBufferOrder.putShort(aj4.a(fRed));
                    byteBufferOrder.putShort(aj4.a(fGreen));
                    byteBufferOrder.putShort(aj4.a(fBlue));
                    byteBufferOrder.putShort(aj4.a(fPow));
                }
                byteBufferOrder.rewind();
                Bitmap bitmapCreateBitmap = Bitmap.createBitmap(i2, i3, Bitmap.Config.RGBA_F16);
                bitmapCreateBitmap.getClass();
                bitmapCreateBitmap.copyPixelsFromBuffer(byteBufferOrder);
                SharedMemory.unmap(byteBufferOrder);
                try {
                    sharedMemoryCreate.close();
                    return bitmapCreateBitmap;
                } catch (RuntimeException e) {
                    String message = e.getMessage();
                    if (tqd.r0(message != null ? message : "", "Failed to interact with raw FileDescriptor", false)) {
                        return bitmapCreateBitmap;
                    }
                    throw e;
                }
            } catch (Throwable th) {
                SharedMemory.unmap(byteBufferOrder);
                throw th;
            }
        } catch (Throwable th2) {
            try {
                sharedMemoryCreate.close();
            } catch (RuntimeException e2) {
                String message2 = e2.getMessage();
                if (!tqd.r0(message2 != null ? message2 : "", "Failed to interact with raw FileDescriptor", false)) {
                    throw e2;
                }
            }
            throw th2;
        }
    }

    public static void e(List list, RectF rectF) {
        Iterator it = list.iterator();
        float f = Float.POSITIVE_INFINITY;
        float f2 = Float.NEGATIVE_INFINITY;
        float f3 = Float.NEGATIVE_INFINITY;
        float f4 = Float.POSITIVE_INFINITY;
        while (it.hasNext()) {
            faa faaVar = (faa) it.next();
            float fC = faaVar.c() * haa.k;
            float fD = faaVar.d() - fC;
            float fE = faaVar.e() - fC;
            float fD2 = faaVar.d() + fC;
            float fE2 = faaVar.e() + fC;
            if (fD < f) {
                f = fD;
            }
            if (fE < f4) {
                f4 = fE;
            }
            if (fD2 > f2) {
                f2 = fD2;
            }
            if (fE2 > f3) {
                f3 = fE2;
            }
        }
        rectF.set(f, f4, f2, f3);
    }

    public static void g(uaa uaaVar, Canvas canvas, haa haaVar, int i2, BlendMode blendMode, float f, tm5 tm5Var, int i3) {
        float f2 = (i3 & 16) != 0 ? 1.0f : f;
        tm5 tm5Var2 = (i3 & 32) != 0 ? null : tm5Var;
        uaaVar.getClass();
        canvas.getClass();
        haaVar.getClass();
        blendMode.getClass();
        if (haaVar.b()) {
            return;
        }
        BlendMode blendMode2 = BlendMode.SRC_OVER;
        if (blendMode != blendMode2) {
            uaaVar.l(canvas, haaVar, i2, blendMode, f2);
            return;
        }
        if (z(canvas)) {
            RectF rectF = uaaVar.p().b;
            rectF.set(haaVar.f, haaVar.g, haaVar.h, haaVar.i);
            float f3 = f2;
            if (uaaVar.y(canvas, rectF, new jaa(uaaVar, haaVar, i2, f3, 0))) {
                return;
            }
            uaaVar.l(canvas, haaVar, i2, blendMode2, f3);
            return;
        }
        RectF rectF2 = uaaVar.p().b;
        rectF2.set(haaVar.f, haaVar.g, haaVar.h, haaVar.i);
        oaa oaaVarO = uaaVar.o(canvas, rectF2, tm5Var2);
        if (oaaVarO == null) {
            uaaVar.l(canvas, haaVar, i2, blendMode2, f2);
            return;
        }
        try {
            Bitmap bitmap = oaaVarO.a;
            Matrix matrix = canvas.getMatrix();
            matrix.getClass();
            Canvas canvas2 = new Canvas(bitmap);
            canvas2.translate(-oaaVarO.b, -oaaVarO.c);
            canvas2.concat(matrix);
            uaaVar.l(canvas2, haaVar, i2, blendMode2, f2);
            uaaVar.b(canvas, matrix, oaaVarO.a, oaaVarO.b, oaaVarO.c);
            if (tm5Var2 != null) {
            }
        } finally {
            if (tm5Var2 != null) {
                tm5Var2.A(oaaVarO.a);
            }
        }
    }

    public static void h(uaa uaaVar, Canvas canvas, List list, int i2, BlendMode blendMode, float f, tm5 tm5Var, int i3) {
        float f2 = (i3 & 16) != 0 ? 1.0f : f;
        tm5 tm5Var2 = (i3 & 32) != 0 ? null : tm5Var;
        uaaVar.getClass();
        canvas.getClass();
        list.getClass();
        blendMode.getClass();
        if (list.isEmpty()) {
            return;
        }
        BlendMode blendMode2 = BlendMode.SRC_OVER;
        if (blendMode != blendMode2) {
            uaaVar.m(canvas, list, i2, blendMode, f2);
            return;
        }
        if (z(canvas)) {
            RectF rectF = uaaVar.p().b;
            e(list, rectF);
            float f3 = f2;
            if (uaaVar.y(canvas, rectF, new jaa(uaaVar, list, i2, f3, 1))) {
                return;
            }
            uaaVar.m(canvas, list, i2, blendMode2, f3);
            return;
        }
        RectF rectF2 = uaaVar.p().b;
        e(list, rectF2);
        oaa oaaVarO = uaaVar.o(canvas, rectF2, tm5Var2);
        if (oaaVarO == null) {
            uaaVar.m(canvas, list, i2, blendMode2, f2);
            return;
        }
        try {
            Bitmap bitmap = oaaVarO.a;
            Matrix matrix = canvas.getMatrix();
            matrix.getClass();
            Canvas canvas2 = new Canvas(bitmap);
            canvas2.translate(-oaaVarO.b, -oaaVarO.c);
            canvas2.concat(matrix);
            uaaVar.m(canvas2, list, i2, blendMode2, f2);
            uaaVar.b(canvas, matrix, oaaVarO.a, oaaVarO.b, oaaVarO.c);
            if (tm5Var2 != null) {
            }
        } finally {
            if (tm5Var2 != null) {
                tm5Var2.A(oaaVarO.a);
            }
        }
    }

    public static void n(Canvas canvas, float[] fArr, float[] fArr2, int[] iArr, short[] sArr, int i2, Paint paint) {
        int i3 = 0;
        while (i3 < i2) {
            int iMin = Math.min(i2, i3 + 16383);
            int i4 = iMin - i3;
            int i5 = i3 * 8;
            canvas.drawVertices(Canvas.VertexMode.TRIANGLES, i4 * 8, fArr, i5, fArr2, i5, iArr, i3 * 4, sArr, 0, i4 * 6, paint);
            i3 = iMin;
        }
    }

    public static RuntimeShader q(ThreadLocal threadLocal, String str) {
        RuntimeShader runtimeShaderA = null;
        if (Build.VERSION.SDK_INT < 33) {
            return null;
        }
        qaa qaaVar = (qaa) threadLocal.get();
        if (qaaVar != null) {
            return qaaVar.a();
        }
        try {
            iaa.b();
            runtimeShaderA = iaa.a(str);
        } catch (IllegalArgumentException e) {
            ArrayList arrayList = a.a;
            a.c(cl7.RENDERER, "Pencil RuntimeShader compile failed", e, null);
        }
        threadLocal.set(new qaa(runtimeShaderA));
        return runtimeShaderA;
    }

    public static boolean z(Canvas canvas) {
        return Build.VERSION.SDK_INT >= 34 && canvas.isHardwareAccelerated();
    }

    public final void b(Canvas canvas, Matrix matrix, Bitmap bitmap, int i2, int i3) {
        Bitmap bitmapCreateBitmap = Bitmap.createBitmap(bitmap.getWidth(), bitmap.getHeight(), Bitmap.Config.ARGB_8888);
        bitmapCreateBitmap.getClass();
        new Canvas(bitmapCreateBitmap).drawBitmap(bitmap, 0.0f, 0.0f, (Paint) v72.x(this.c, i[1]));
        c(canvas, matrix, new oaa(bitmapCreateBitmap, i2, i3));
    }

    public final void c(Canvas canvas, Matrix matrix, oaa oaaVar) {
        h76.Y("PencilSplatRenderer.blitLinearScratch");
        try {
            Matrix matrix2 = p().d;
            if (matrix.invert(matrix2)) {
                matrix2.preTranslate(oaaVar.b, oaaVar.c);
                canvas.drawBitmap(oaaVar.a, matrix2, (Paint) v72.x(this.c, i[1]));
            } else {
                ArrayList arrayList = a.a;
                a.d(jm7.L, cl7.RENDERER, "PencilSplatRenderer.blitLinearScratch matrix not invertible");
            }
        } finally {
            Trace.endSection();
        }
    }

    public final paa d(Canvas canvas, Matrix matrix, List list) {
        maa maaVarP = p();
        RectF rectF = maaVarP.a;
        RectF rectF2 = maaVarP.b;
        Matrix matrix2 = maaVarP.c;
        Rect rectF3 = f(canvas, matrix);
        Iterator it = list.iterator();
        boolean z = false;
        while (it.hasNext()) {
            caa caaVar = (caa) it.next();
            haa haaVar = caaVar.a;
            if (!haaVar.b()) {
                rectF2.set(haaVar.f, haaVar.g, haaVar.h, haaVar.i);
                matrix2.set(matrix);
                matrix2.preTranslate(caaVar.d, caaVar.e);
                Matrix matrix3 = caaVar.f;
                if (matrix3 != null) {
                    matrix2.preConcat(matrix3);
                }
                matrix2.mapRect(rectF2);
                if (z) {
                    rectF.union(rectF2);
                } else {
                    rectF.set(rectF2);
                    z = true;
                }
            }
        }
        if (z) {
            return t(rectF3, rectF);
        }
        return null;
    }

    public final Rect f(Canvas canvas, Matrix matrix) {
        canvas.getClass();
        Rect rect = p().f;
        if (!canvas.getClipBounds(rect)) {
            return null;
        }
        RectF rectF = p().g;
        rectF.set(rect);
        rectF.inset(-0.5f, -0.5f);
        matrix.mapRect(rectF);
        rectF.roundOut(rect);
        return rect;
    }

    public final void i(Canvas canvas, List list) {
        uaa uaaVar;
        Matrix matrix;
        List list2;
        h76.Y("PencilSplatRenderer.drawBatch.sw");
        try {
            Matrix matrix2 = canvas.getMatrix();
            matrix2.getClass();
            paa paaVarD = d(canvas, matrix2, list);
            if (paaVarD != null) {
                int i2 = paaVarD.a;
                int i3 = paaVarD.b;
                int i4 = paaVarD.c;
                int i5 = paaVarD.d;
                h76.Y("PencilSplatRenderer.drawBatch.alloc");
                try {
                    Bitmap bitmapA = qd7.a(i4, i5);
                    Trace.endSection();
                    if (bitmapA == null) {
                        bitmapA = null;
                        uaaVar = this;
                        matrix = matrix2;
                        list2 = list;
                    } else {
                        h76.Y("PencilSplatRenderer.drawBatch.stamps");
                        try {
                            uaaVar = this;
                            matrix = matrix2;
                            list2 = list;
                            uaaVar.x(new Canvas(bitmapA), list2, matrix, i2, i3);
                            Trace.endSection();
                        } catch (Throwable th) {
                            Trace.endSection();
                            throw th;
                        }
                    }
                    if (bitmapA == null) {
                        uaaVar.j(canvas, list2);
                    } else {
                        h76.Y("PencilSplatRenderer.drawBatch.blit");
                        try {
                            uaaVar.b(canvas, matrix, bitmapA, paaVarD.a, paaVarD.b);
                            Trace.endSection();
                        } finally {
                            Trace.endSection();
                        }
                    }
                } catch (Throwable th2) {
                    Trace.endSection();
                    throw th2;
                }
            }
        } catch (Throwable th3) {
            Trace.endSection();
            throw th3;
        }
    }

    public final void j(Canvas canvas, List list) throws Throwable {
        Canvas canvas2;
        Throwable th;
        Iterator it = list.iterator();
        while (it.hasNext()) {
            caa caaVar = (caa) it.next();
            if (!caaVar.a.b()) {
                int iSave = canvas.save();
                try {
                    canvas.translate(caaVar.d, caaVar.e);
                    Matrix matrix = caaVar.f;
                    if (matrix != null) {
                        try {
                            canvas.concat(matrix);
                        } catch (Throwable th2) {
                            th = th2;
                            canvas2 = canvas;
                            canvas2.restoreToCount(iSave);
                            throw th;
                        }
                    }
                    uaa uaaVar = this;
                    canvas2 = canvas;
                    try {
                        g(uaaVar, canvas2, caaVar.a, caaVar.b, BlendMode.SRC_OVER, caaVar.c, null, 32);
                        canvas2.restoreToCount(iSave);
                        this = uaaVar;
                        canvas = canvas2;
                    } catch (Throwable th3) {
                        th = th3;
                        th = th;
                        canvas2.restoreToCount(iSave);
                        throw th;
                    }
                } catch (Throwable th4) {
                    th = th4;
                    canvas2 = canvas;
                }
            }
        }
    }

    public final void k(Canvas canvas, haa haaVar, int i2, BlendMode blendMode, float f, float f2, RuntimeShader runtimeShader, RectF rectF) {
        int i3;
        int iD;
        haa haaVar2 = haaVar;
        ga6 ga6Var = h;
        if (haaVar2.b()) {
            return;
        }
        h76.Y("PencilSplatRenderer.drawSplatsDirect.buffer");
        try {
            saa saaVarE = ga6.e(ga6Var, this.a);
            try {
                int iA = saaVarE.a(haaVar2.e, f2);
                u(r(), i2, blendMode, f, runtimeShader);
                int i4 = haaVar2.e;
                int i5 = 0;
                int i6 = 0;
                while (i6 < i4) {
                    int iMin = Math.min(i4, i6 + iA);
                    int i7 = i4;
                    float[] fArr = saaVarE.a;
                    if (rectF == null) {
                        haaVar2.e(fArr, i5, i6, iMin);
                        int[] iArr = saaVarE.c;
                        if (runtimeShader != null) {
                            iArr.getClass();
                            haaVar2.h(i6, iMin);
                            haa.g(iArr.length, 0, i6, iMin, 4, "out");
                            for (int i8 = i6; i8 < iMin; i8++) {
                                int iV = me8.v((int) (haaVar2.c(i8) * 255.0f), i5, HelperConstants.PASSTHROGUH_MAX_LENGTH);
                                ByteBuffer byteBuffer = haa.j;
                                vi2.q((i8 - i6) * 4, (iV << 24) | 16777215, iArr);
                            }
                        } else {
                            iArr.getClass();
                            float f3 = ((i2 >>> 24) & HelperConstants.PASSTHROGUH_MAX_LENGTH) * f;
                            haaVar2.h(i6, iMin);
                            haa.g(iArr.length, 0, i6, iMin, 4, "out");
                            for (int i9 = i6; i9 < iMin; i9++) {
                                int iV2 = me8.v((int) (haaVar2.c(i9) * f3), i5, HelperConstants.PASSTHROGUH_MAX_LENGTH);
                                ByteBuffer byteBuffer2 = haa.j;
                                vi2.q((i9 - i6) * 4, (iV2 << 24) | 16777215, iArr);
                            }
                        }
                        iD = iMin - i6;
                        i3 = i5;
                    } else {
                        int i10 = i5;
                        int[] iArr2 = saaVarE.c;
                        int i11 = runtimeShader != null ? 1 : i10;
                        float f4 = rectF.left;
                        int i12 = i6;
                        float f5 = rectF.top;
                        float f6 = rectF.right;
                        int i13 = i11;
                        float f7 = rectF.bottom;
                        fArr.getClass();
                        iArr2.getClass();
                        i3 = i10;
                        iD = haaVar2.d(fArr, iArr2, 0, f4, f5, f6, f7, 16777215, i13 == 0 ? ((i2 >>> 24) & HelperConstants.PASSTHROGUH_MAX_LENGTH) * f : 255.0f, i12, iMin);
                        iMin = iMin;
                    }
                    int i14 = iD;
                    if (i14 > 0) {
                        n(canvas, saaVarE.a, saaVarE.b, saaVarE.c, saaVarE.d, i14, r());
                    }
                    haaVar2 = haaVar;
                    i6 = iMin;
                    i5 = i3;
                    i4 = i7;
                }
                ga6.j(ga6Var, saaVarE);
                Trace.endSection();
            } catch (Throwable th) {
                ga6.j(ga6Var, saaVarE);
                throw th;
            }
        } catch (Throwable th2) {
            Trace.endSection();
            throw th2;
        }
    }

    public final void l(Canvas canvas, haa haaVar, int i2, BlendMode blendMode, float f) {
        if (haaVar.b()) {
            return;
        }
        k(canvas, haaVar, i2, blendMode, f, w().getWidth(), (Build.VERSION.SDK_INT < 33 || !canvas.isHardwareAccelerated()) ? null : q(this.f, "\n      uniform shader splatTexture;\n      uniform half4 tintColor;\n      uniform half dimAlpha;\n      half4 main(float2 coord) {\n        return tintColor * splatTexture.eval(coord).a * dimAlpha;\n      }\n      "), null);
    }

    public final void m(Canvas canvas, List list, int i2, BlendMode blendMode, float f) {
        int size = list.size();
        if (size == 0) {
            return;
        }
        float width = w().getWidth();
        RuntimeShader runtimeShaderQ = (Build.VERSION.SDK_INT < 33 || !canvas.isHardwareAccelerated()) ? null : q(this.f, "\n      uniform shader splatTexture;\n      uniform half4 tintColor;\n      uniform half dimAlpha;\n      half4 main(float2 coord) {\n        return tintColor * splatTexture.eval(coord).a * dimAlpha;\n      }\n      ");
        float fAlpha = runtimeShaderQ != null ? 255.0f : Color.alpha(i2) * f;
        Context context = this.a;
        ga6 ga6Var = h;
        saa saaVarE = ga6.e(ga6Var, context);
        try {
            int iA = saaVarE.a(size, width);
            float[] fArr = saaVarE.a;
            int[] iArr = saaVarE.c;
            u(r(), i2, blendMode, f, runtimeShaderQ);
            int i3 = 0;
            while (i3 < size) {
                int iMin = Math.min(size, i3 + iA);
                int i4 = iMin - i3;
                int i5 = 0;
                while (i5 < i4) {
                    faa faaVar = (faa) list.get(i3 + i5);
                    float fC = faaVar.c();
                    float fCos = ((float) Math.cos(faaVar.b())) * fC;
                    float fSin = fC * ((float) Math.sin(faaVar.b()));
                    ByteBuffer byteBuffer = haa.j;
                    int[] iArr2 = iArr;
                    vi2.V(fArr, i5 * 8, faaVar.d(), faaVar.e(), fCos, fSin);
                    vi2.q(i5 * 4, (me8.v((int) (faaVar.a() * fAlpha), 0, HelperConstants.PASSTHROGUH_MAX_LENGTH) << 24) | 16777215, iArr2);
                    i5++;
                    iArr = iArr2;
                    i3 = i3;
                }
                int[] iArr3 = iArr;
                float[] fArr2 = fArr;
                n(canvas, fArr2, saaVarE.b, iArr3, saaVarE.d, i4, r());
                fArr = fArr2;
                i3 = iMin;
                iArr = iArr3;
            }
        } finally {
            ga6.j(ga6Var, saaVarE);
        }
    }

    public final oaa o(Canvas canvas, RectF rectF, tm5 tm5Var) {
        Bitmap bitmapA;
        Matrix matrix = canvas.getMatrix();
        matrix.getClass();
        Rect rectF2 = f(canvas, matrix);
        matrix.mapRect(rectF);
        paa paaVarT = t(rectF2, rectF);
        if (paaVarT == null) {
            return null;
        }
        if (tm5Var == null || (bitmapA = tm5Var.k(paaVarT.c, paaVarT.d)) == null) {
            bitmapA = qd7.a(paaVarT.c, paaVarT.d);
        }
        if (bitmapA == null) {
            return null;
        }
        return new oaa(bitmapA, paaVarT.a, paaVarT.b);
    }

    public final maa p() {
        return (maa) v72.x(this.d, i[2]);
    }

    public final Paint r() {
        return (Paint) v72.x(this.b, i[0]);
    }

    public final Bitmap s() {
        Bitmap bitmapDecodeResource = BitmapFactory.decodeResource(this.a.getResources(), R.drawable.ui_renderer__pencil_splat);
        if (bitmapDecodeResource.getWidth() != bitmapDecodeResource.getHeight()) {
            rc6.i(b7d.i("Pencil splat texture must be square, got ", "×", bitmapDecodeResource.getWidth(), bitmapDecodeResource.getHeight()));
            return null;
        }
        int width = bitmapDecodeResource.getWidth();
        int height = bitmapDecodeResource.getHeight();
        int i2 = width * height;
        int[] iArr = new int[i2];
        bitmapDecodeResource.getPixels(iArr, 0, width, 0, 0, width, height);
        bitmapDecodeResource.recycle();
        try {
            return a(width, height, iArr);
        } catch (RuntimeException e) {
            String message = e.getMessage();
            if (message == null) {
                message = "";
            }
            if (!tqd.r0(message, "only Bitmaps with 4 bytes", false)) {
                throw e;
            }
            int[] iArrCopyOf = Arrays.copyOf(iArr, i2);
            int length = iArrCopyOf.length;
            for (int i3 = 0; i3 < length; i3++) {
                int iAlpha = Color.alpha(iArrCopyOf[i3]);
                if (iAlpha != 0 && iAlpha != 255) {
                    iArrCopyOf[i3] = (me8.v((int) (Math.pow(((double) iAlpha) / 255.0d, 1.5d) * 255.0d), 0, HelperConstants.PASSTHROGUH_MAX_LENGTH) << 24) | (iArrCopyOf[i3] & 16777215);
                }
            }
            Bitmap bitmapCreateBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
            bitmapCreateBitmap.getClass();
            bitmapCreateBitmap.setPixels(iArrCopyOf, 0, width, 0, 0, width, height);
            return bitmapCreateBitmap;
        }
    }

    public final paa t(Rect rect, RectF rectF) {
        int iFloor = (int) Math.floor(rectF.left - 1.0f);
        int iFloor2 = (int) Math.floor(rectF.top - 1.0f);
        int iCeil = (int) Math.ceil(rectF.right + 1.0f);
        int iCeil2 = (int) Math.ceil(rectF.bottom + 1.0f);
        if (rect != null) {
            iFloor = Math.max(iFloor, rect.left - 1);
        }
        if (rect != null) {
            iFloor2 = Math.max(iFloor2, rect.top - 1);
        }
        if (rect != null) {
            iCeil = Math.min(iCeil, rect.right + 1);
        }
        if (rect != null) {
            iCeil2 = Math.min(iCeil2, rect.bottom + 1);
        }
        int i2 = iCeil - iFloor;
        int i3 = iCeil2 - iFloor2;
        if (i2 <= 0 || i3 <= 0) {
            return null;
        }
        paa paaVar = p().e;
        paaVar.a = iFloor;
        paaVar.b = iFloor2;
        paaVar.c = i2;
        paaVar.d = i3;
        return paaVar;
    }

    public final void u(Paint paint, int i2, BlendMode blendMode, float f, RuntimeShader runtimeShader) {
        paint.setBlendMode(blendMode);
        paint.setAlpha(HelperConstants.PASSTHROGUH_MAX_LENGTH);
        if (runtimeShader != null && Build.VERSION.SDK_INT >= 33) {
            runtimeShader.setInputShader("splatTexture", v());
            float fAlpha = Color.alpha(i2) / 255.0f;
            runtimeShader.setFloatUniform("tintColor", (Color.red(i2) / 255.0f) * fAlpha, (Color.green(i2) / 255.0f) * fAlpha, (Color.blue(i2) / 255.0f) * fAlpha, fAlpha);
            runtimeShader.setFloatUniform("dimAlpha", f);
            paint.setShader(runtimeShader);
            paint.setColorFilter(null);
            return;
        }
        paint.setShader(v());
        cj6[] cj6VarArr = i;
        cj6 cj6Var = cj6VarArr[3];
        kv8 kv8Var = this.e;
        PorterDuffColorFilter porterDuffColorFilter = (PorterDuffColorFilter) ((zq7) v72.x(kv8Var, cj6Var)).c(Integer.valueOf(i2));
        if (porterDuffColorFilter == null) {
            porterDuffColorFilter = new PorterDuffColorFilter(i2, PorterDuff.Mode.SRC_IN);
            ((zq7) v72.x(kv8Var, cj6VarArr[3])).d(Integer.valueOf(i2), porterDuffColorFilter);
        }
        paint.setColorFilter(porterDuffColorFilter);
    }

    public final BitmapShader v() {
        BitmapShader bitmapShader;
        BitmapShader bitmapShader2 = k;
        if (bitmapShader2 != null) {
            return bitmapShader2;
        }
        synchronized (l) {
            bitmapShader = k;
            if (bitmapShader == null) {
                Bitmap bitmapW = w();
                Shader.TileMode tileMode = Shader.TileMode.CLAMP;
                bitmapShader = new BitmapShader(bitmapW, tileMode, tileMode);
                k = bitmapShader;
            }
        }
        return bitmapShader;
    }

    public final Bitmap w() {
        Bitmap bitmapS;
        Bitmap bitmap = j;
        if (bitmap != null) {
            return bitmap;
        }
        synchronized (l) {
            bitmapS = j;
            if (bitmapS == null) {
                bitmapS = s();
                j = bitmapS;
            }
        }
        return bitmapS;
    }

    public final void x(Canvas canvas, List list, Matrix matrix, int i2, int i3) {
        float[] fArr;
        int i4;
        Paint paint;
        int i5;
        int[] iArr;
        int iD;
        int i6;
        uaa uaaVar = this;
        Canvas canvas2 = canvas;
        float width = uaaVar.w().getWidth();
        int i7 = Build.VERSION.SDK_INT;
        boolean z = i7 >= 33 && canvas2.isHardwareAccelerated();
        RuntimeShader runtimeShaderQ = z ? q(uaaVar.g, "\n      uniform shader splatTexture;\n      half4 main(float2 coord) {\n        return half4(splatTexture.eval(coord).a);\n      }\n      ") : null;
        if (runtimeShaderQ == null || i7 < 33) {
            RuntimeShader runtimeShaderQ2 = z ? q(uaaVar.f, "\n      uniform shader splatTexture;\n      uniform half4 tintColor;\n      uniform half dimAlpha;\n      half4 main(float2 coord) {\n        return tintColor * splatTexture.eval(coord).a * dimAlpha;\n      }\n      ") : null;
            int iSave = canvas2.save();
            try {
                canvas2.translate(-i2, -i3);
                canvas2.concat(matrix);
                Iterator it = list.iterator();
                while (it.hasNext()) {
                    caa caaVar = (caa) it.next();
                    if (!caaVar.a.b()) {
                        int iSave2 = canvas2.save();
                        try {
                            canvas2.translate(caaVar.d, caaVar.e);
                            Matrix matrix2 = caaVar.f;
                            if (matrix2 != null) {
                                canvas2.concat(matrix2);
                            }
                            uaaVar.k(canvas2, caaVar.a, caaVar.b, BlendMode.SRC_OVER, caaVar.c, width, runtimeShaderQ2, caaVar.g);
                            canvas2.restoreToCount(iSave2);
                        } catch (Throwable th) {
                            canvas2.restoreToCount(iSave2);
                            throw th;
                        }
                    }
                    uaaVar = this;
                }
                canvas2.restoreToCount(iSave);
                return;
            } catch (Throwable th2) {
                canvas2.restoreToCount(iSave);
                throw th2;
            }
        }
        Iterator it2 = list.iterator();
        int i8 = 0;
        while (it2.hasNext()) {
            i8 += ((caa) it2.next()).a.e;
        }
        if (i8 == 0) {
            return;
        }
        Context context = uaaVar.a;
        ga6 ga6Var = h;
        saa saaVarE = ga6.e(ga6Var, context);
        try {
            int iA = saaVarE.a(i8, width);
            float[] fArr2 = saaVarE.a;
            int[] iArr2 = saaVarE.c;
            Matrix matrix3 = uaaVar.p().c;
            Paint paintR = uaaVar.r();
            paintR.setBlendMode(BlendMode.SRC_OVER);
            paintR.setAlpha(HelperConstants.PASSTHROGUH_MAX_LENGTH);
            runtimeShaderQ.setInputShader("splatTexture", uaaVar.v());
            paintR.setShader(runtimeShaderQ);
            paintR.setColorFilter(null);
            int iSave3 = canvas2.save();
            try {
                canvas2.translate(-i2, -i3);
                canvas2.concat(matrix);
                Iterator it3 = list.iterator();
                int[] iArr3 = iArr2;
                int i9 = 0;
                while (it3.hasNext()) {
                    try {
                        caa caaVar2 = (caa) it3.next();
                        Matrix matrix4 = matrix3;
                        haa haaVar = caaVar2.a;
                        float f = caaVar2.c;
                        int i10 = caaVar2.b;
                        if (haaVar.b()) {
                            matrix3 = matrix4;
                        } else {
                            RectF rectF = caaVar2.g;
                            Matrix matrix5 = matrix4;
                            int i11 = 0;
                            boolean z2 = false;
                            while (i11 < haaVar.e) {
                                if (i9 != iA || i9 == 0) {
                                    fArr = fArr2;
                                    i4 = i10;
                                } else {
                                    fArr = fArr2;
                                    i4 = i10;
                                    n(canvas, fArr, saaVarE.b, iArr3, saaVarE.d, i9, paintR);
                                    i9 = 0;
                                }
                                int iMin = Math.min(haaVar.e - i11, iA - i9) + i11;
                                if (rectF == null) {
                                    haaVar.e(fArr, i9, i11, iMin);
                                    iArr3.getClass();
                                    float f2 = (((i4 >>> 24) & HelperConstants.PASSTHROGUH_MAX_LENGTH) / 255.0f) * f;
                                    float f3 = f2 * 255.0f;
                                    int iF = haa.f(i4, f2);
                                    haaVar.h(i11, iMin);
                                    int i12 = i11;
                                    int i13 = i9;
                                    haa.g(iArr3.length, i13, i12, iMin, 4, "out");
                                    int i14 = iMin;
                                    int i15 = i12;
                                    while (i15 < i14) {
                                        int i16 = i14;
                                        int iV = me8.v((int) (haaVar.c(i15) * f3), 0, HelperConstants.PASSTHROGUH_MAX_LENGTH);
                                        ByteBuffer byteBuffer = haa.j;
                                        vi2.q(((i13 + i15) - i12) * 4, (iV << 24) | iF, iArr3);
                                        i15++;
                                        paintR = paintR;
                                        i14 = i16;
                                    }
                                    i6 = i14;
                                    paint = paintR;
                                    iD = i6 - i12;
                                    i5 = i13;
                                    iArr = iArr3;
                                } else {
                                    int i17 = i11;
                                    int i18 = i9;
                                    paint = paintR;
                                    float f4 = rectF.left;
                                    float f5 = rectF.top;
                                    float f6 = rectF.right;
                                    float f7 = rectF.bottom;
                                    fArr.getClass();
                                    iArr3.getClass();
                                    float f8 = (((i4 >>> 24) & HelperConstants.PASSTHROGUH_MAX_LENGTH) / 255.0f) * f;
                                    i5 = i18;
                                    iArr = iArr3;
                                    iD = haaVar.d(fArr, iArr, i5, f4, f5, f6, f7, haa.f(i4, f8), f8 * 255.0f, i17, iMin);
                                    i6 = iMin;
                                }
                                int i19 = iD;
                                if (i19 > 0) {
                                    if (!z2) {
                                        matrix5.reset();
                                        matrix5.preTranslate(caaVar2.d, caaVar2.e);
                                        Matrix matrix6 = caaVar2.f;
                                        if (matrix6 != null) {
                                            matrix5.preConcat(matrix6);
                                        }
                                        z2 = true;
                                    }
                                    float[] fArr3 = fArr;
                                    int i20 = i5 * 8;
                                    matrix5.mapPoints(fArr3, i20, fArr3, i20, i19 * 4);
                                    fArr = fArr3;
                                    i9 = i5 + i19;
                                } else {
                                    i9 = i5;
                                }
                                paintR = paint;
                                matrix5 = matrix5;
                                fArr2 = fArr;
                                i10 = i4;
                                iArr3 = iArr;
                                i11 = i6;
                                f = f;
                                it3 = it3;
                            }
                            matrix3 = matrix5;
                        }
                    } catch (Throwable th3) {
                        th = th3;
                        canvas2 = canvas;
                        canvas2.restoreToCount(iSave3);
                        throw th;
                    }
                }
                int[] iArr4 = iArr3;
                float[] fArr4 = fArr2;
                Paint paint2 = paintR;
                if (i9 == 0) {
                    canvas2 = canvas;
                } else {
                    canvas2 = canvas;
                    n(canvas2, fArr4, saaVarE.b, iArr4, saaVarE.d, i9, paint2);
                }
                canvas2.restoreToCount(iSave3);
                ga6.j(ga6Var, saaVarE);
            } catch (Throwable th4) {
                th = th4;
            }
        } catch (Throwable th5) {
            ga6.j(ga6Var, saaVarE);
            throw th5;
        }
    }

    public final boolean y(Canvas canvas, RectF rectF, ov4 ov4Var) {
        Matrix matrix = canvas.getMatrix();
        matrix.getClass();
        Rect rectF2 = f(canvas, matrix);
        matrix.mapRect(rectF);
        paa paaVarT = t(rectF2, rectF);
        if (paaVarT == null) {
            return true;
        }
        Bitmap bitmapE = ga6.h(h, this.a).e(paaVarT.c, paaVarT.d, new dk7(paaVarT, matrix, ov4Var, 17));
        if (bitmapE == null) {
            return false;
        }
        c(canvas, matrix, new oaa(bitmapE, paaVarT.a, paaVarT.b));
        return true;
    }
}
