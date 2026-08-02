package defpackage;

import android.graphics.Path;
import android.graphics.RectF;
import androidx.ink.geometry.ImmutableBox;
import java.util.List;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes2.dex */
public final class s78 implements yt5 {
    public static final float t = (float) Math.sqrt(2.0d);
    public final f0g a;
    public final Function0 b;
    public final Function0 c;
    public volatile Path d;
    public volatile vzf e;
    public volatile List f;
    public volatile List g;
    public volatile Path h;
    public volatile Float i;
    public final RectF j;
    public final RectF k;
    public final RectF l;
    public final RectF m;
    public boolean n;
    public List o;
    public final RectF p;
    public boolean q;
    public final RectF r;
    public boolean s;

    public s78(f0g f0gVar, Function0 function0, Function0 function1) {
        f0gVar.getClass();
        function0.getClass();
        function1.getClass();
        this.a = f0gVar;
        this.b = function0;
        this.c = function1;
        ru3 ru3Var = ru3.I;
        this.f = ru3Var;
        this.g = ru3Var;
        this.j = new RectF();
        this.k = new RectF();
        this.l = new RectF();
        this.m = new RectF();
        this.p = new RectF();
        this.r = new RectF();
    }

    public static boolean h(List list, RectF rectF) {
        if (list.isEmpty()) {
            return false;
        }
        int size = list.size();
        float f = Float.NEGATIVE_INFINITY;
        float f2 = Float.POSITIVE_INFINITY;
        float f3 = Float.POSITIVE_INFINITY;
        float f4 = Float.NEGATIVE_INFINITY;
        for (int i = 0; i < size; i++) {
            faa faaVar = (faa) list.get(i);
            float f5 = faaVar.d * t;
            float f6 = faaVar.a;
            float f7 = f6 - f5;
            if (f7 < f2) {
                f2 = f7;
            }
            float f8 = faaVar.b;
            float f9 = f8 - f5;
            if (f9 < f3) {
                f3 = f9;
            }
            float f10 = f6 + f5;
            if (f10 > f) {
                f = f10;
            }
            float f11 = f8 + f5;
            if (f11 > f4) {
                f4 = f11;
            }
        }
        rectF.set(f2, f3, f, f4);
        return true;
    }

    @Override // defpackage.yt5
    public final void a() {
        this.m.setEmpty();
    }

    @Override // defpackage.yt5
    public final void b(Object obj) {
        this.n = false;
        this.s = false;
        this.d = null;
        this.e = null;
        ru3 ru3Var = ru3.I;
        this.f = ru3Var;
        this.g = ru3Var;
        this.h = null;
        this.i = null;
        this.l.setEmpty();
        this.m.setEmpty();
        this.o = null;
        this.q = false;
    }

    @Override // defpackage.yt5
    public final void cancel() {
        this.n = true;
        this.d = null;
        ru3 ru3Var = ru3.I;
        this.f = ru3Var;
        this.g = ru3Var;
        this.h = null;
        this.i = null;
        this.m.set(this.l);
        this.l.setEmpty();
    }

    @Override // defpackage.yt5
    public final ImmutableBox d() {
        RectF rectF = this.m;
        if (rectF.isEmpty()) {
            return null;
        }
        return new ImmutableBox(rectF.left, rectF.top, rectF.right, rectF.bottom);
    }

    @Override // defpackage.yt5
    public final void e(fi8 fi8Var, esd esdVar) {
        fi8Var.getClass();
        esdVar.getClass();
    }

    @Override // defpackage.yt5
    public final Object f() {
        vzf vzfVar;
        if (!this.s || (vzfVar = this.e) == null) {
            return null;
        }
        if (vzfVar.e) {
            return new k78(null, this.f, vzfVar, null, null);
        }
        Path path = this.d;
        Path path2 = path != null ? new Path(path) : null;
        ru3 ru3Var = ru3.I;
        Path path3 = this.h;
        return new k78(path2, ru3Var, vzfVar, path3 != null ? new Path(path3) : null, this.i);
    }

    @Override // defpackage.yt5
    public final void finishInput() {
        this.s = true;
    }

    /* JADX WARN: Code duplicated, block: B:40:0x00f4  */
    @Override // defpackage.yt5
    public final void g() {
        if (this.s) {
            return;
        }
        vzf vzfVar = this.a.k;
        this.e = vzfVar;
        Path path = null;
        if (vzfVar == null || !vzfVar.e) {
            ru3 ru3Var = ru3.I;
            this.f = ru3Var;
            this.g = ru3Var;
            Path path2 = this.a.n;
            this.h = path2;
            this.i = this.a.o;
            f0g f0gVar = this.a;
            if (f0gVar.i && f0gVar.p) {
                if ((f0gVar.d.get() & 4) != 0) {
                    f0gVar.c = f0gVar.d.getAndSet(f0gVar.c) & 3;
                }
                path = f0gVar.a[f0gVar.c];
            }
            this.d = path;
            if (path != null && !path.isEmpty()) {
                path.computeBounds(this.j, false);
                if (path2 != null && !path2.isEmpty()) {
                    path2.computeBounds(this.k, false);
                    this.j.union(this.k);
                }
                float fFloatValue = ((Number) this.c.invoke()).floatValue();
                long j = ((fdc) this.b.invoke()).a;
                RectF rectF = this.m;
                RectF rectF2 = this.j;
                float f = (int) (j >> 32);
                float f2 = (int) (j & 4294967295L);
                rectF.set((rectF2.left * fFloatValue) - f, (rectF2.top * fFloatValue) - f2, (rectF2.right * fFloatValue) - f, (rectF2.bottom * fFloatValue) - f2);
                if (!this.l.isEmpty()) {
                    this.m.union(this.l);
                }
                this.l.set(this.m);
            }
            this.m.set(this.l);
            this.l.setEmpty();
            return;
        }
        this.d = null;
        this.h = null;
        this.i = null;
        List list = this.a.l;
        List list2 = this.a.m;
        this.f = list;
        this.g = list2;
        RectF rectF3 = this.j;
        RectF rectF4 = this.r;
        RectF rectF5 = this.p;
        if (list != this.o) {
            this.q = h(list, rectF5);
            this.o = list;
        }
        boolean zH = h(list2, rectF4);
        boolean z = this.q;
        if (z && zH) {
            rectF3.set(rectF5);
            rectF3.union(rectF4);
        } else {
            if (!z) {
                if (zH) {
                    rectF3.set(rectF4);
                }
                this.m.set(this.l);
                this.l.setEmpty();
                return;
            }
            rectF3.set(rectF5);
        }
        float fFloatValue2 = ((Number) this.c.invoke()).floatValue();
        long j2 = ((fdc) this.b.invoke()).a;
        RectF rectF6 = this.m;
        RectF rectF7 = this.j;
        float f3 = (int) (j2 >> 32);
        float f4 = (int) (j2 & 4294967295L);
        rectF6.set((rectF7.left * fFloatValue2) - f3, (rectF7.top * fFloatValue2) - f4, (rectF7.right * fFloatValue2) - f3, (rectF7.bottom * fFloatValue2) - f4);
        if (!this.l.isEmpty()) {
            this.m.union(this.l);
        }
        this.l.set(this.m);
    }

    @Override // defpackage.yt5
    public final boolean m() {
        return this.n;
    }
}
