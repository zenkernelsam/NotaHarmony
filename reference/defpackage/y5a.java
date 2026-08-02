package defpackage;

import android.graphics.Path;
import android.graphics.RectF;
import android.os.Build;
import androidx.graphics.path.PathIteratorPreApi34Impl;
import com.gingerlabs.notability.core.common.logging.a;
import java.util.ArrayList;
import java.util.List;

/* JADX INFO: loaded from: classes2.dex */
public final class y5a extends nzf {
    public final an5 M;
    public final Path N;
    public volatile Path O;
    public final Path P;
    public Path Q;
    public boolean R;
    public Object S;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public y5a(ms1 ms1Var, fu5 fu5Var, uc8 uc8Var, oqb oqbVar, fh2 fh2Var, t1d t1dVar, tif tifVar, iof iofVar, lm8 lm8Var, f0g f0gVar, an5 an5Var) {
        super(ms1Var, fu5Var, uc8Var, oqbVar, fh2Var, t1dVar, tifVar, iofVar, lm8Var, f0gVar);
        uc8Var.getClass();
        oqbVar.getClass();
        fh2Var.getClass();
        tifVar.getClass();
        iofVar.getClass();
        lm8Var.getClass();
        f0gVar.getClass();
        an5Var.getClass();
        this.M = an5Var;
        this.N = new Path();
        this.P = new Path();
    }

    public static void v(Path path, Path path2) {
        Path path3;
        path.getClass();
        a5a z4aVar = Build.VERSION.SDK_INT >= 34 ? new z4a(path, 2, 0.25f) : new PathIteratorPreApi34Impl(path, 2, 0.25f);
        float[] fArr = new float[8];
        while (z4aVar.a()) {
            switch (z4aVar.b(fArr).ordinal()) {
                case 0:
                case 5:
                case 6:
                    continue;
                case 1:
                    path3 = path2;
                    path3.lineTo(fArr[2], fArr[3]);
                    break;
                case 2:
                    path3 = path2;
                    path3.quadTo(fArr[2], fArr[3], fArr[4], fArr[5]);
                    break;
                case 3:
                    path3 = path2;
                    ArrayList arrayList = a.a;
                    a.c(cl7.INK, "Unexpected conic segment in center path", null, null);
                    break;
                case 4:
                    path2.cubicTo(fArr[2], fArr[3], fArr[4], fArr[5], fArr[6], fArr[7]);
                    continue;
                default:
                    yz3.t();
                    return;
            }
            path2 = path3;
        }
    }

    @Override // defpackage.nzf
    public final rf0 h() {
        Path path = new Path(this.N);
        Path path2 = this.O;
        return new rf0(path, path2 != null ? new Path(path2) : null, null);
    }

    @Override // defpackage.nzf
    public final Object i() {
        return this.S;
    }

    @Override // defpackage.nzf
    public final void j() {
        this.N.reset();
        this.O = null;
        this.P.reset();
        this.Q = null;
        this.R = false;
        this.S = null;
    }

    @Override // defpackage.nzf
    public final void l() {
        this.R = false;
    }

    /* JADX WARN: Code duplicated, block: B:20:0x0041  */
    /* JADX WARN: Code duplicated, block: B:40:0x0099  */
    @Override // defpackage.nzf
    public final void n(List list, List list2, qzf qzfVar) {
        xw0 xw0VarA;
        Path pathR;
        xw0 xw0VarA2;
        Path pathR2;
        xw0 xw0VarA3;
        xw0 xw0VarA4;
        double d = qzfVar.a;
        sz5 sz5Var = qzfVar.e;
        boolean z = sz5Var == sz5.DASH || sz5Var == sz5.DOTS;
        RectF rectF = null;
        if (z) {
            if (list != null) {
                xw0 xw0Var = xw0.f;
                xw0VarA4 = w4a.a(kx0.d(list, null), 0.0d);
            } else {
                xw0VarA4 = null;
            }
            if (xw0VarA4 != null) {
                pathR = xw0VarA4.r();
                yla ylaVar = this.p;
                if (ylaVar == null) {
                    yz3.r("Can't offset path with null origin");
                    return;
                }
                pathR.offset(ylaVar.c(), ylaVar.d());
            } else {
                pathR = null;
            }
        } else {
            if (list != null) {
                xw0 xw0Var2 = xw0.f;
                xw0VarA = w4a.a(kx0.d(list, null), 0.0d);
            } else {
                xw0VarA = null;
            }
            if (xw0VarA != null) {
                pathR = w4a.b(xw0VarA, d).r();
                yla ylaVar2 = this.p;
                if (ylaVar2 == null) {
                    yz3.r("Can't offset path with null origin");
                    return;
                }
                pathR.offset(ylaVar2.c(), ylaVar2.d());
            } else {
                pathR = null;
            }
        }
        if (z) {
            if (list2 != null) {
                xw0 xw0Var3 = xw0.f;
                xw0VarA3 = w4a.a(kx0.d(list2, null), 0.0d);
            } else {
                xw0VarA3 = null;
            }
            if (xw0VarA3 != null) {
                pathR2 = xw0VarA3.r();
                yla ylaVar3 = this.p;
                if (ylaVar3 == null) {
                    yz3.r("Can't offset path with null origin");
                    return;
                }
                pathR2.offset(ylaVar3.c(), ylaVar3.d());
            } else {
                pathR2 = null;
            }
        } else {
            if (list2 != null) {
                xw0 xw0Var4 = xw0.f;
                xw0VarA2 = w4a.a(kx0.d(list2, null), 0.0d);
            } else {
                xw0VarA2 = null;
            }
            if (xw0VarA2 != null) {
                pathR2 = w4a.b(xw0VarA2, d).r();
                yla ylaVar4 = this.p;
                if (ylaVar4 == null) {
                    yz3.r("Can't offset path with null origin");
                    return;
                }
                pathR2.offset(ylaVar4.c(), ylaVar4.d());
            } else {
                pathR2 = null;
            }
        }
        if (pathR != null) {
            RectF rectF2 = this.t;
            aqi.b(pathR, rectF2);
            this.r.union(rectF2);
            this.s.union(rectF2);
            if (z && this.R) {
                v(pathR, this.P);
            } else {
                this.P.addPath(pathR);
                if (z) {
                    this.R = true;
                }
            }
        }
        if (this.C) {
            pathR2 = null;
        }
        this.Q = pathR2;
        if (pathR2 != null) {
            rectF = this.t;
            aqi.b(pathR2, rectF);
        }
        u(rectF);
        this.N.reset();
        this.N.addPath(this.P);
        Path path = this.Q;
        if (path != null) {
            if (z && this.R) {
                v(path, this.N);
            } else {
                this.N.addPath(path);
            }
        }
        if (this.j.i) {
            this.j.b(this.N);
        }
    }

    @Override // defpackage.nzf
    public final void p(qzf qzfVar) {
        if (qzfVar.c == d1d.K) {
            Object obj = this.M.b.get();
            this.S = obj;
            if (obj == null) {
                this.N.reset();
                this.r.set(this.s);
            }
        }
    }

    @Override // defpackage.nzf
    public final void s(b0d b0dVar, Path path, Path path2, pc3 pc3Var, float f, float f2, RectF rectF) {
        b0dVar.getClass();
        rectF.getClass();
        this.N.reset();
        this.P.reset();
        this.Q = null;
        this.N.addPath(path);
        this.P.addPath(path);
        this.O = path2;
        if (this.j.i) {
            f0g f0gVar = this.j;
            Path path3 = this.N;
            float f3 = pc3Var.k;
            f0gVar.getClass();
            path3.getClass();
            if (f0gVar.i) {
                f0gVar.n = path2 != null ? new Path(path2) : null;
                f0gVar.o = Float.valueOf(f3);
                f0gVar.b(path3);
            }
        }
    }

    public final Path w() {
        return this.O;
    }

    public final Path x() {
        return this.N;
    }

    public final yla y() {
        return this.p;
    }
}
