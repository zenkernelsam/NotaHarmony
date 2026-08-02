package defpackage;

import android.graphics.BlendMode;
import android.graphics.Canvas;
import android.graphics.DashPathEffect;
import android.graphics.Paint;
import android.graphics.Path;
import android.util.LruCache;
import java.util.List;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes.dex */
public abstract class pzf {
    public final uaa a;
    public Function0 b;
    public Function0 c;
    public Function0 d;
    public Function0 e;
    public final Paint f;
    public final Paint g;
    public final Paint h;
    public final Paint i;
    public final Paint j;
    public final LruCache k;
    public final LruCache l;
    public final qae m;
    public final Paint n;

    public pzf(uaa uaaVar) {
        uaaVar.getClass();
        this.a = uaaVar;
        Paint paint = new Paint();
        BlendMode blendMode = BlendMode.SRC_OVER;
        paint.setBlendMode(blendMode);
        this.f = paint;
        Paint paint2 = new Paint();
        paint2.setBlendMode(blendMode);
        paint2.setStyle(Paint.Style.FILL);
        this.g = paint2;
        Paint paint3 = new Paint();
        paint3.setBlendMode(blendMode);
        Paint.Style style = Paint.Style.STROKE;
        paint3.setStyle(style);
        Paint.Cap cap = Paint.Cap.ROUND;
        paint3.setStrokeCap(cap);
        Paint.Join join = Paint.Join.ROUND;
        paint3.setStrokeJoin(join);
        this.h = paint3;
        Paint paint4 = new Paint();
        paint4.setBlendMode(blendMode);
        paint4.setStyle(style);
        paint4.setStrokeCap(Paint.Cap.BUTT);
        paint4.setStrokeJoin(join);
        this.i = paint4;
        Paint paint5 = new Paint();
        paint5.setBlendMode(blendMode);
        paint5.setStyle(style);
        paint5.setStrokeCap(cap);
        paint5.setStrokeJoin(Paint.Join.MITER);
        this.j = paint5;
        this.k = new LruCache(8);
        this.l = new LruCache(8);
        this.m = new qae();
        Paint paint6 = new Paint();
        paint6.setBlendMode(blendMode);
        this.n = paint6;
    }

    public final void d(Canvas canvas) {
        Function0 function0 = this.b;
        if (function0 == null) {
            x76.d0("scrollOffset");
            throw null;
        }
        long j = ((fdc) function0.invoke()).a;
        Function0 function1 = this.c;
        if (function1 == null) {
            x76.d0("zoom");
            throw null;
        }
        float fFloatValue = ((Number) function1.invoke()).floatValue();
        Function0 function2 = this.d;
        if (function2 == null) {
            x76.d0("docSize");
            throw null;
        }
        long j2 = ((pg3) function2.invoke()).a;
        int width = canvas.getWidth();
        int height = canvas.getHeight();
        int i = (int) (4294967295L & j);
        Function0 function3 = this.e;
        if (function3 == null) {
            x76.d0("viewportRect");
            throw null;
        }
        v46 v46Var = ((gdc) function3.invoke()).a;
        int i2 = v46Var.c - v46Var.a;
        int i3 = v46Var.d - v46Var.b;
        if (i < 0) {
            int i4 = -i;
            if (i4 <= i3) {
                i3 = i4;
            }
        } else {
            i3 = 0;
        }
        int iC = (i2 - ((int) (pg3.c(j2) * fFloatValue))) / 2;
        int i5 = iC > 0 ? iC : 0;
        if (iC > 0) {
            i2 -= iC;
        }
        if (i2 < i5) {
            i2 = i5;
        }
        int iB = (height - ((int) (pg3.b(j2) * fFloatValue))) + i;
        int i6 = iB > 0 ? height - iB : height;
        if (i6 < i3) {
            i6 = i3;
        }
        if (i3 > 0 || i5 > 0 || i2 < width || i6 < height) {
            canvas.clipRect(i5, i3, i2, i6);
        }
        canvas.translate(-((int) (j >> 32)), -i);
        canvas.scale(fFloatValue, fFloatValue);
    }

    public final void e(Canvas canvas, vzf vzfVar, Path path, List list, List list2, Path path2, Float f) {
        canvas.getClass();
        vzfVar.getClass();
        list.getClass();
        list2.getClass();
        if (!vzfVar.e()) {
            if (path == null || path.isEmpty()) {
                return;
            }
            g(canvas, path, vzfVar.d(), vzfVar.b(), vzfVar.c(), vzfVar.a(), f, path2);
            return;
        }
        int iB = vzfVar.b();
        if (list.isEmpty() && list2.isEmpty()) {
            return;
        }
        int iSave = canvas.save();
        try {
            d(canvas);
            if (!list.isEmpty()) {
                uaa.h(this.a, canvas, list, iB, BlendMode.SRC_OVER, 0.0f, null, 48);
                iB = iB;
            }
            if (!list2.isEmpty()) {
                uaa.h(this.a, canvas, list2, iB, BlendMode.SRC_OVER, 0.0f, null, 48);
            }
        } finally {
            canvas.restoreToCount(iSave);
        }
    }

    public final void f(Canvas canvas, daa daaVar, List list, int i) throws Throwable {
        Canvas canvas2;
        Throwable th;
        canvas.getClass();
        list.getClass();
        if (daaVar == null && list.isEmpty()) {
            return;
        }
        int iSave = canvas.save();
        try {
            d(canvas);
            if (daaVar != null) {
                try {
                    int iSave2 = canvas.save();
                    try {
                        canvas.translate(daaVar.b().left, daaVar.b().top);
                        canvas.scale(1.0f / daaVar.c(), 1.0f / daaVar.c());
                        canvas.drawBitmap(daaVar.a(), 0.0f, 0.0f, this.n);
                        canvas.restoreToCount(iSave2);
                    } catch (Throwable th2) {
                        canvas.restoreToCount(iSave2);
                        throw th2;
                    }
                } catch (Throwable th3) {
                    th = th3;
                    canvas2 = canvas;
                    canvas2.restoreToCount(iSave);
                    throw th;
                }
            }
            if (list.isEmpty()) {
                canvas2 = canvas;
            } else {
                canvas2 = canvas;
                try {
                    uaa.h(this.a, canvas2, list, i, BlendMode.SRC_OVER, 0.0f, null, 48);
                } catch (Throwable th4) {
                    th = th4;
                    th = th;
                    canvas2.restoreToCount(iSave);
                    throw th;
                }
            }
            canvas2.restoreToCount(iSave);
        } catch (Throwable th5) {
            th = th5;
            canvas2 = canvas;
        }
    }

    public final void g(Canvas canvas, Path path, boolean z, int i, sz5 sz5Var, float f, Float f2, Path path2) {
        Paint paint;
        canvas.getClass();
        path.getClass();
        sz5Var.getClass();
        if (sz5Var == sz5.DASH) {
            if (f2 != null) {
                f = f2.floatValue();
            }
            paint = this.i;
            paint.setStrokeWidth(f);
            Float fValueOf = Float.valueOf(f);
            LruCache lruCache = this.k;
            DashPathEffect dashPathEffect = (DashPathEffect) lruCache.get(fValueOf);
            if (dashPathEffect == null) {
                dashPathEffect = new DashPathEffect(new float[]{2.0f * f, 1.0f * f}, 0.0f);
                lruCache.put(Float.valueOf(f), dashPathEffect);
            }
            paint.setPathEffect(dashPathEffect);
        } else if (sz5Var == sz5.DOTS) {
            if (f2 != null) {
                f = f2.floatValue();
            }
            paint = this.j;
            paint.setStrokeWidth(f);
            Float fValueOf2 = Float.valueOf(f);
            LruCache lruCache2 = this.l;
            DashPathEffect dashPathEffect2 = (DashPathEffect) lruCache2.get(fValueOf2);
            if (dashPathEffect2 == null) {
                dashPathEffect2 = new DashPathEffect(new float[]{0.001f * f, 2.0f * f}, 0.0f);
                lruCache2.put(Float.valueOf(f), dashPathEffect2);
            }
            paint.setPathEffect(dashPathEffect2);
        } else if (f2 != null) {
            float fFloatValue = f2.floatValue();
            Paint paint2 = this.h;
            paint2.setStrokeWidth(fFloatValue);
            paint = paint2;
        } else {
            paint = this.f;
        }
        if (z) {
            i = yw1.e(i, 107);
        }
        paint.setColor(i);
        Paint paint3 = this.g;
        int iSave = canvas.save();
        try {
            d(canvas);
            if (path2 != null) {
                paint3.setColor(paint.getColor());
                h76.l0(canvas, path, paint, path2, paint3);
            } else {
                canvas.drawPath(path, paint);
            }
        } finally {
            canvas.restoreToCount(iSave);
        }
    }

    public final void h(Canvas canvas, Path path, iae iaeVar, int i, int i2, float f, float f2) {
        canvas.getClass();
        path.getClass();
        iaeVar.getClass();
        int iSave = canvas.save();
        try {
            d(canvas);
            qae qaeVar = this.m;
            Function0 function0 = this.c;
            if (function0 == null) {
                x76.d0("zoom");
                throw null;
            }
            qaeVar.a(canvas, path, iaeVar, i, i2, ((Number) function0.invoke()).floatValue(), f, f2);
            canvas.restoreToCount(iSave);
        } catch (Throwable th) {
            canvas.restoreToCount(iSave);
            throw th;
        }
    }

    public final void i(Function0 function0, Function0 function1, Function0 function2, Function0 function3) {
        function0.getClass();
        function1.getClass();
        function3.getClass();
        this.b = function0;
        this.c = function1;
        this.d = function2;
        this.e = function3;
    }
}
