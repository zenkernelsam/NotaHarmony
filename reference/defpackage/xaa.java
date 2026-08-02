package defpackage;

import com.gingerlabs.notability.core.common.logging.a;
import java.util.ArrayList;

/* JADX INFO: loaded from: classes.dex */
public final class xaa {
    public final ic0 a;
    public final double b;
    public final long c;
    public final a81 d;
    public final ow5 e;
    public a81 f;
    public long g;
    public ow5 h;
    public boolean i;
    public float j;
    public float k;
    public final a81 l;
    public final gp2 m;
    public final m2b n;
    public final hd7 o;

    public xaa(ic0 ic0Var, double d, long j, a81 a81Var, ow5 ow5Var, int i) {
        a81Var = (i & 8) != 0 ? null : a81Var;
        ow5Var = (i & 16) != 0 ? null : ow5Var;
        ic0Var.getClass();
        this.a = ic0Var;
        this.b = d;
        this.c = j;
        this.d = a81Var;
        this.e = ow5Var;
        this.g = j;
        this.l = new a81();
        this.m = new gp2(new a81(), new a81(), new a81(), new a81());
        this.n = new m2b(new a81(), new a81(), new a81());
        this.o = new hd7(new a81(), new a81());
    }

    public static double c(double d) {
        return d * d * d * d * d;
    }

    public static double d(double d, double d2) {
        double dC = 1.0d - c(1.0d - (Math.min(d, 2.0d) / 2.0d));
        double dC2 = 1.0d - c(Math.min((d2 - 1.5707963267948966d) / (-0.9424777960769379d), 1.0d));
        return (dC * dC2) + ((1.0d - dC2) * 1.0d);
    }

    /* JADX WARN: Code duplicated, block: B:35:0x0085 A[PHI: r26
  0x0085: PHI (r26v2 double) = (r26v1 double), (r26v1 double), (r26v4 double), (r26v4 double) binds: [B:34:0x007b, B:29:0x0073, B:22:0x0055, B:24:0x005f] A[DONT_GENERATE, DONT_INLINE]] */
    /* JADX WARN: Code duplicated, block: B:37:0x0090 A[LOOP:2: B:13:0x0032->B:37:0x0090, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:61:0x0098 A[EDGE_INSN: B:61:0x0098->B:38:0x0098 BREAK  A[LOOP:2: B:13:0x0032->B:37:0x0090], SYNTHETIC] */
    public final ow5 a(ow5 ow5Var, a81 a81Var, double d) {
        cv0 cv0VarB;
        double d2;
        double d3 = 0.0d;
        if (d <= 0.0d) {
            return ow5Var;
        }
        ic0 ic0Var = this.a;
        ow5 ow5Var2 = ic0Var.l;
        if (ow5Var.a(ow5Var2) < 0) {
            double d4 = d * d;
            int i = ow5Var.a;
            double d5 = ow5Var.b;
            while (i < ic0Var.b.b) {
                cv0 cv0VarP = ic0Var.p(i, this.m, this.n, this.o);
                double d6 = 1.0d;
                while (true) {
                    double d7 = d6;
                    while (true) {
                        cv0VarB = (d5 == d3 && d7 == d6) ? cv0VarP : cv0VarP.b(d5, d7);
                        if (!(cv0VarB instanceof gp2)) {
                            d2 = d6;
                            if (cv0VarB instanceof m2b) {
                                if (w76.x(((m2b) cv0VarB).b, a81Var) < d4) {
                                    break;
                                }
                                if (d7 - d5 <= 0.1d) {
                                    break;
                                    break;
                                }
                                d7 = (d7 + d5) * 0.5d;
                                d6 = d2;
                                d3 = 0.0d;
                            } else {
                                if (cv0VarB instanceof hd7) {
                                    break;
                                }
                                ArrayList arrayList = a.a;
                                a.c(cl7.INK, "Unexpected pencil curve type in advanceBy", null, null);
                                if (d7 - d5 <= 0.1d) {
                                    break;
                                    break;
                                }
                                d7 = (d7 + d5) * 0.5d;
                                d6 = d2;
                                d3 = 0.0d;
                            }
                        } else {
                            gp2 gp2Var = (gp2) cv0VarB;
                            d2 = d6;
                            if (w76.x(gp2Var.b, a81Var) < d4 && w76.x(gp2Var.c, a81Var) < d4) {
                                break;
                            }
                            if (d7 - d5 <= 0.1d) {
                                break;
                            }
                            d7 = (d7 + d5) * 0.5d;
                            d6 = d2;
                            d3 = 0.0d;
                        }
                    }
                    if (w76.x(cv0VarB.l(), a81Var) >= d4) {
                        double d8 = d2;
                        double d9 = 0.0d;
                        for (int i2 = 0; i2 < 40 && d8 - d9 > 1.0E-4d; i2++) {
                            double d10 = (d9 + d8) * 0.5d;
                            if (w76.x(cv0VarB.c(d10, this.l), a81Var) < d4) {
                                d9 = d10;
                            } else {
                                d8 = d10;
                            }
                        }
                        return new ow5((d7 * d8) + ((d2 - d8) * d5), i);
                    }
                    if (d7 < d2) {
                        d6 = d2;
                        d5 = d7;
                        d3 = 0.0d;
                    }
                }
                i++;
                d3 = 0.0d;
                d5 = 0.0d;
            }
        }
        return ow5Var2;
    }

    public final void b(skd skdVar) {
        double d;
        ow5 ow5VarA;
        double d2 = this.b;
        if (d2 == 0.0d) {
            return;
        }
        ic0 ic0Var = this.a;
        if (ic0Var.b.b == 0 || ic0Var.v()) {
            return;
        }
        double d3 = d2 * 0.5d;
        double d4 = d3 * 0.5d;
        long j = this.c;
        if (j < 0) {
            j = -j;
        }
        a81 a81Var = new a81();
        ow5 ow5Var = this.e;
        if (ow5Var != null) {
            e(a81Var, ow5Var);
            fc0 fc0VarJ = ic0Var.J(ow5Var);
            d = 0.5d;
            ow5VarA = a(ow5Var, a81Var, ((d(fc0VarJ.d(), fc0VarJ.a()) * 0.5d) + 0.5d) * d4);
            e(a81Var, ow5VarA);
        } else {
            d = 0.5d;
            ow5VarA = ow5.c;
            a81 a81Var2 = this.d;
            if (a81Var2 != null) {
                a81Var.a = a81Var2.a;
                a81Var.b = a81Var2.b;
                ow5VarA = a(ow5VarA, a81Var, d4);
            }
            e(a81Var, ow5VarA);
        }
        a81 a81Var3 = new a81();
        this.i = false;
        ow5 ow5Var2 = null;
        while (ow5VarA.a(ic0Var.l) < 0) {
            fc0 fc0VarJ2 = ic0Var.J(ow5VarA);
            e(a81Var3, ow5VarA);
            double d5 = d2;
            a81 a81Var4 = a81Var;
            ow5 ow5Var3 = ow5Var;
            double dMin = ((Math.min(fc0VarJ2.d(), 2.0d) / 2.0d) * 0.97d) + 0.03d;
            double d6 = 2.0d;
            double dA = fc0VarJ2.a();
            double d7 = 0.6283185307179586d - dA;
            double d8 = d4;
            double dMax = Math.max(d7, 0.0d);
            int iFloor = (int) Math.floor((1.0d * dMax) / 0.025132741228718346d);
            int i = iFloor + 1;
            ow5 ow5Var4 = ow5VarA;
            double d9 = (((1.2d * d3) * d) / 1.0d) * ((double) iFloor);
            double d10 = (((dMax / 1.5707963267948966d) * (-0.48d)) + d) * d5;
            double dMin2 = Math.min(Math.max(d7, 0.0d) / 0.45331853071795863d, 1.0d);
            double d11 = (d(fc0VarJ2.d(), dA) * d) + d;
            double d12 = (1.0d - dMin2) + (0.1d * dMin2);
            double dB = fc0VarJ2.b();
            double dC = fc0VarJ2.c();
            double d13 = -dC;
            int i2 = 0;
            while (i2 < i) {
                long j2 = (j * 1118393071) % 1946926193;
                double d14 = dMin2;
                double d15 = j2 / 1.946926193E9d;
                long j3 = (j2 * 1118393071) % 1946926193;
                double d16 = (j3 / 1.946926193E9d) * 3.141592653589793d * d6;
                double dSqrt = Math.sqrt(d15);
                double dCos = Math.cos(d16) * dSqrt;
                double dSin = Math.sin(d16) * dSqrt;
                double d17 = 0.9d * dCos;
                double d18 = (d14 + dSin) * 1.0d;
                double d19 = a81Var3.a + (((d18 * dB) + (d17 * d13)) * d9);
                double d20 = dC;
                double d21 = a81Var3.b + (((d18 * dC) + (d17 * dB)) * d9);
                ic0 ic0Var2 = ic0Var;
                a81 a81Var5 = a81Var3;
                a81 a81Var6 = a81Var4;
                ow5 ow5Var5 = ow5Var4;
                int i3 = i;
                int i4 = i2;
                double d22 = d3;
                double dSqrt2 = i == 1 ? 1.0d : 1.0d - Math.sqrt((dSin * dSin) + (dCos * dCos));
                double d23 = d6;
                double d24 = d13;
                fc0 fc0Var = fc0VarJ2;
                double dC2 = f92.c(dSqrt2, 1.0d, 0.0d, 1.0d);
                j = (j3 * 1118393071) % 1946926193;
                double d25 = (j / 1.946926193E9d) * 3.141592653589793d * d23;
                float f = (float) d19;
                float f2 = (float) d21;
                if (Math.abs(f) <= Float.MAX_VALUE && Math.abs(f2) <= Float.MAX_VALUE) {
                    skdVar.a(f, f2, (float) d25, (float) (d10 * d11), (float) (dC2 * d12 * dMin));
                    this.i = true;
                    this.j = f;
                    this.k = f2;
                }
                i2 = i4 + 1;
                i = i3;
                d13 = d24;
                d3 = d22;
                dMin2 = d14;
                d6 = d23;
                fc0VarJ2 = fc0Var;
                dC = d20;
                ow5Var4 = ow5Var5;
                a81Var4 = a81Var6;
                ic0Var = ic0Var2;
                a81Var3 = a81Var5;
            }
            ic0 ic0Var3 = ic0Var;
            a81 a81Var7 = a81Var3;
            fc0 fc0Var2 = fc0VarJ2;
            a81 a81Var8 = a81Var4;
            ow5 ow5Var6 = ow5Var4;
            ow5VarA = a(ow5Var6, a81Var8, ((d(fc0Var2.d(), fc0Var2.a()) * d) + d) * d8);
            e(a81Var8, ow5VarA);
            ow5Var2 = ow5Var6;
            a81Var = a81Var8;
            ic0Var = ic0Var3;
            a81Var3 = a81Var7;
            d2 = d5;
            ow5Var = ow5Var3;
            d4 = d8;
        }
        ow5 ow5Var7 = ow5Var;
        if (this.i) {
            this.f = new a81(this.j, this.k);
        }
        this.h = ow5Var2 == null ? ow5Var7 : ow5Var2;
        this.g = j;
    }

    public final void e(a81 a81Var, ow5 ow5Var) {
        a81 a81VarX = this.a.x(a81Var, ow5Var);
        if (a81VarX != a81Var) {
            a81Var.a = a81VarX.a;
            a81Var.b = a81VarX.b;
        }
    }
}
