package defpackage;

import java.util.Iterator;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public final class gp2 implements pv8, y7f, cv0 {
    public final a81 a;
    public a81 b;
    public final a81 c;
    public final a81 d;
    public final a81 e;
    public final a81 f;
    public final m2b g;

    public gp2(a81 a81Var, a81 a81Var2, a81 a81Var3, a81 a81Var4) {
        a81Var.getClass();
        a81Var4.getClass();
        this.a = a81Var;
        this.b = a81Var2;
        this.c = a81Var3;
        this.d = a81Var4;
        kv8 kv8Var = hp2.b;
        cj6[] cj6VarArr = hp2.a;
        this.e = (a81) v72.x(kv8Var, cj6VarArr[0]);
        this.f = (a81) v72.x(hp2.c, cj6VarArr[1]);
        this.g = (m2b) v72.x(hp2.d, cj6VarArr[2]);
    }

    @Override // defpackage.cv0
    public final List a() {
        return ny7.m0(this.a, this.b, this.c, this.d);
    }

    @Override // defpackage.cv0
    public final a81 c(double d, a81 a81Var) {
        a81 a81Var2 = this.a;
        if (d == 0.0d) {
            return a81Var2;
        }
        a81 a81Var3 = this.d;
        if (d == 1.0d) {
            return a81Var3;
        }
        double d2 = 1.0d - d;
        double d3 = d2 * d2;
        double d4 = d * d;
        double d5 = d3 * d2;
        double d6 = d3 * d * 3.0d;
        double d7 = d2 * d4 * 3.0d;
        double d8 = d4 * d;
        a81 a81Var4 = a81Var == null ? new a81() : a81Var;
        double d9 = a81Var2.a * d5;
        a81 a81Var5 = this.b;
        double d10 = (a81Var5.a * d6) + d9;
        a81 a81Var6 = this.c;
        a81Var4.a = (a81Var3.a * d8) + (a81Var6.a * d7) + d10;
        a81Var4.b = (a81Var3.b * d8) + (a81Var6.b * d7) + (a81Var5.b * d6) + (a81Var2.b * d5);
        return a81Var4;
    }

    @Override // defpackage.cv0
    public final boolean d() {
        return q() != null;
    }

    /* JADX WARN: Code duplicated, block: B:14:0x005f  */
    /* JADX WARN: Code duplicated, block: B:55:0x012d A[PHI: r1
  0x012d: PHI (r1v8 double) = (r1v4 double), (r1v6 double), (r1v12 double) binds: [B:89:0x018c, B:78:0x0171, B:54:0x012b] A[DONT_GENERATE, DONT_INLINE]] */
    /* JADX WARN: Code duplicated, block: B:58:0x0136 A[PHI: r1
  0x0136: PHI (r1v7 double) = (r1v4 double), (r1v6 double), (r1v12 double) binds: [B:92:0x0191, B:81:0x0176, B:57:0x0134] A[DONT_GENERATE, DONT_INLINE]] */
    @Override // defpackage.cv0
    public final b01 e() {
        a81 a81Var;
        a81 a81Var2;
        double dB;
        a81 a81Var3 = this.b;
        a81 a81Var4 = this.a;
        a81Var4.getClass();
        a81 a81Var5 = this.d;
        a81Var5.getClass();
        a81 a81Var6 = new a81(Math.min(a81Var4.a, a81Var5.a), Math.min(a81Var4.b, a81Var5.b));
        a81 a81Var7 = new a81(Math.max(a81Var4.a, a81Var5.a), Math.max(a81Var4.b, a81Var5.b));
        int i = 0;
        while (i < 2) {
            double dB2 = a81Var6.b(i);
            double dB3 = a81Var7.b(i);
            double dB4 = a81Var3.b(i);
            a81 a81Var8 = this.c;
            double dB5 = a81Var8.b(i);
            if (dB4 < dB2 || dB4 > dB3 || dB5 < dB2 || dB5 > dB3) {
                gg8 gg8Var = bof.a;
                double dB6 = a81Var3.b(i) - a81Var4.b(i);
                double dB7 = a81Var8.b(i) - a81Var3.b(i);
                double dB8 = a81Var5.b(i) - a81Var8.b(i);
                double dG = p5c.g(dB7, 2.0d, dB6, dB8);
                if (Math.abs(dG) <= Double.MAX_VALUE) {
                    double dAbs = Math.abs(dG);
                    a81 a81Var9 = this.e;
                    if (dAbs > 1.0E-5d) {
                        double d = (dB7 * dB7) - (dB8 * dB6);
                        if (d >= 0.0d) {
                            double dSqrt = Math.sqrt(d);
                            double d2 = dB6 - dB7;
                            a81Var = a81Var3;
                            a81Var2 = a81Var4;
                            double d3 = (d2 + dSqrt) / dG;
                            double d4 = (d2 - dSqrt) / dG;
                            if (d3 < d4) {
                                if (d3 > 0.0d && d3 < 1.0d) {
                                    double dB9 = c(d3, a81Var9).b(i);
                                    if (dB9 < dB2) {
                                        a81Var6.e(dB9, i);
                                    } else if (dB9 > dB3) {
                                        a81Var7.e(dB9, i);
                                    }
                                }
                                if (d4 > 0.0d && d4 < 1.0d) {
                                    dB = c(d4, a81Var9).b(i);
                                    if (dB < dB2) {
                                        a81Var6.e(dB, i);
                                    } else if (dB > dB3) {
                                        a81Var7.e(dB, i);
                                    }
                                }
                            } else if (d3 > d4) {
                                if (d4 > 0.0d && d4 < 1.0d) {
                                    double dB10 = c(d4, a81Var9).b(i);
                                    if (dB10 < dB2) {
                                        a81Var6.e(dB10, i);
                                    } else if (dB10 > dB3) {
                                        a81Var7.e(dB10, i);
                                    }
                                }
                                if (d3 > 0.0d && d3 < 1.0d) {
                                    dB = c(d3, a81Var9).b(i);
                                    if (dB < dB2) {
                                        a81Var6.e(dB, i);
                                    } else if (dB > dB3) {
                                        a81Var7.e(dB, i);
                                    }
                                }
                            } else if (d3 > 0.0d && d3 < 1.0d) {
                                dB = c(d3, a81Var9).b(i);
                                if (dB < dB2) {
                                    a81Var6.e(dB, i);
                                } else if (dB > dB3) {
                                    a81Var7.e(dB, i);
                                }
                            }
                        }
                    } else if (dB6 != dB7) {
                        double d5 = (0.5d * dB6) / (dB6 - dB7);
                        if (d5 > 0.0d && d5 < 1.0d) {
                            double dB11 = c(d5, a81Var9).b(i);
                            if (dB11 < dB2) {
                                a81Var6.e(dB11, i);
                            } else if (dB11 > dB3) {
                                a81Var7.e(dB11, i);
                            }
                        }
                    }
                    a81Var = a81Var3;
                    a81Var2 = a81Var4;
                } else {
                    a81Var = a81Var3;
                    a81Var2 = a81Var4;
                }
            } else {
                a81Var = a81Var3;
                a81Var2 = a81Var4;
            }
            i++;
            a81Var3 = a81Var;
            a81Var4 = a81Var2;
        }
        return new b01(a81Var6, a81Var7);
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof gp2)) {
            return false;
        }
        gp2 gp2Var = (gp2) obj;
        return x76.p(this.a, gp2Var.a) && x76.p(this.b, gp2Var.b) && x76.p(this.c, gp2Var.c) && x76.p(this.d, gp2Var.d);
    }

    @Override // defpackage.z02
    public final xu0 f(xu0 xu0Var) {
        a81 a81Var = this.d;
        a81 a81Var2 = this.c;
        a81 a81Var3 = this.a;
        if (xu0Var == null) {
            return new su0(a81Var3.a, this.b.a, a81Var2.a, a81Var.a);
        }
        su0 su0Var = (su0) xu0Var;
        su0Var.e(a81Var3.a);
        su0Var.f(this.b.a);
        su0Var.g(a81Var2.a);
        su0Var.m(a81Var.a);
        return su0Var;
    }

    @Override // defpackage.cv0
    public final a81 g() {
        return this.a;
    }

    @Override // defpackage.cv0
    public final int getOrder() {
        return 3;
    }

    @Override // defpackage.sq5
    public final pdh h() {
        qq5 qq5VarA = cmi.a(this, 3, 2);
        qq5 qq5VarA2 = cmi.a(this, 3, 1);
        qq5 qq5VarA3 = cmi.a(this, 3, 0);
        qq5 qq5VarA4 = cmi.a(this, 2, 1);
        qq5 qq5VarA5 = cmi.a(this, 2, 0);
        qq5 qq5VarA6 = cmi.a(this, 1, 0);
        qq5 qq5VarD = qq5VarA3.d(qq5VarA4);
        return hp2.a(qq5VarA, qq5VarD.e(qq5VarA6).g(qq5VarA5.e(qq5VarA5))).h(hp2.a(qq5VarA2, qq5VarA2.e(qq5VarA6).g(qq5VarA5.e(qq5VarA3)))).j(hp2.a(qq5VarA3, qq5VarA2.e(qq5VarA5).g(qq5VarD.e(qq5VarA3))));
    }

    public final int hashCode() {
        return this.d.hashCode() + ((this.c.hashCode() + ((this.b.hashCode() + (this.a.hashCode() * 31)) * 31)) * 31);
    }

    @Override // defpackage.cv0
    public final wm i(a81 a81Var, wm wmVar) {
        double d;
        a81Var.getClass();
        gp2 gp2VarM = m(new z71(-a81Var.a, -a81Var.b));
        m2b m2bVar = this.g;
        a81 a81Var2 = m2bVar.a;
        a81 a81Var3 = gp2VarM.b;
        double d2 = a81Var3.a;
        a81 a81Var4 = gp2VarM.a;
        a81Var2.a = d2 - a81Var4.a;
        a81Var2.b = a81Var3.b - a81Var4.b;
        a81 a81Var5 = m2bVar.b;
        a81 a81Var6 = gp2VarM.c;
        a81Var5.a = a81Var6.a - a81Var3.a;
        a81Var5.b = a81Var6.b - a81Var3.b;
        a81 a81Var7 = m2bVar.c;
        a81 a81Var8 = gp2VarM.d;
        double d3 = a81Var8.a - a81Var6.a;
        a81Var7.a = d3;
        double d4 = a81Var8.b - a81Var6.b;
        a81Var7.b = d4;
        double d5 = a81Var4.a;
        double d6 = a81Var2.a;
        double d7 = d5 * 10.0d * d6;
        double d8 = a81Var4.b;
        double d9 = a81Var2.b;
        double d10 = d8 * 10.0d * d9;
        double d11 = d5 * 4.0d;
        double d12 = a81Var5.a;
        double d13 = d12 - d6;
        double d14 = a81Var3.a;
        double d15 = (d14 - d5) * 6.0d;
        double d16 = (d15 * d6) + (d11 * d13) + d7;
        double d17 = a81Var5.b;
        double d18 = d17 - d9;
        double d19 = a81Var3.b;
        double d20 = (d19 - d8) * 6.0d;
        double d21 = (d20 * d9) + (d8 * 4.0d * d18) + d10;
        double d22 = a81Var6.a;
        double dG = p5c.g(d12, 2.0d, d3, d6);
        double d23 = a81Var6.b;
        double dG2 = p5c.g(d17, 2.0d, d4, d9);
        double d24 = (dG2 * d8) + (d18 * d20) + (((d23 - (d19 * 2.0d)) + d8) * 3.0d * d9);
        double d25 = ((d16 * 2.0d) - d7) + (dG * d5) + (d13 * d15) + (((d22 - (d14 * 2.0d)) + d5) * 3.0d * d6);
        double d26 = ((d21 * 2.0d) - d10) + d24;
        double d27 = a81Var8.a;
        double d28 = d27 * 10.0d * d3;
        double d29 = a81Var8.b;
        double d30 = 10.0d * d29 * d4;
        double d31 = d3 - d12;
        double d32 = (d27 - d22) * 6.0d;
        double d33 = (d28 - ((d27 * 4.0d) * d31)) - (d32 * d3);
        double d34 = d4 - d17;
        double d35 = (d29 - d23) * 6.0d;
        double d36 = (d30 - ((4.0d * d29) * d34)) - (d35 * d4);
        double d37 = (dG2 * d29) + (d34 * d35) + (((d19 - (d23 * 2.0d)) + d29) * 3.0d * d4);
        double d38 = (d33 * 2.0d) - d28;
        double d39 = d38 + (dG * d27) + (d31 * d32) + (((d14 - (d22 * 2.0d)) + d27) * 3.0d * d3);
        double d40 = ((d36 * 2.0d) - d30) + d37;
        double dM0 = w76.m0(d5, d8);
        double dM1 = w76.m0(a81Var8.a, a81Var8.b);
        double d41 = 1.0d;
        double d42 = 0.0d;
        if (dM1 < dM0) {
            dM0 = dM1;
            d = 1.0d;
        } else {
            d = 0.0d;
        }
        wu0 wu0Var = new wu0(d7 + d10, d16 + d21, d25 + d26, d39 + d40, d33 + d36, d28 + d30);
        a81 a81Var9 = new a81();
        Iterator it = owi.c(wu0Var).iterator();
        while (it.hasNext()) {
            double dDoubleValue = ((Number) it.next()).doubleValue();
            if (dDoubleValue <= d42 || dDoubleValue >= d41) {
                break;
            }
            a81 a81VarC = gp2VarM.c(dDoubleValue, a81Var9);
            double dM2 = w76.m0(a81VarC.a, a81VarC.b);
            if (dM2 < dM0) {
                dM0 = dM2;
                d = dDoubleValue;
            }
            d41 = 1.0d;
            d42 = 0.0d;
        }
        return new wm(c(d, a81Var9), d);
    }

    @Override // defpackage.cv0
    public final a81 j(double d, a81 a81Var) {
        double d2 = 1.0d - d;
        a81 a81Var2 = this.b;
        double d3 = a81Var2.a;
        a81 a81Var3 = this.a;
        double d4 = (d3 - a81Var3.a) * 3.0d;
        double d5 = a81Var2.b;
        double d6 = (d5 - a81Var3.b) * 3.0d;
        a81 a81Var4 = this.c;
        double d7 = a81Var4.a;
        double d8 = (d7 - d3) * 3.0d;
        double d9 = a81Var4.b;
        double d10 = (d9 - d5) * 3.0d;
        a81 a81Var5 = this.d;
        double d11 = (a81Var5.a - d7) * 3.0d;
        double d12 = (a81Var5.b - d9) * 3.0d;
        double d13 = d2 * d2;
        double d14 = d2 * 2.0d * d;
        double d15 = d * d;
        a81 a81Var6 = a81Var == null ? new a81() : a81Var;
        a81Var6.a = (d11 * d15) + (d8 * d14) + (d4 * d13);
        a81Var6.b = (d12 * d15) + (d10 * d14) + (d6 * d13);
        return a81Var6;
    }

    @Override // defpackage.z02
    public final xu0 k(xu0 xu0Var) {
        a81 a81Var = this.d;
        a81 a81Var2 = this.c;
        a81 a81Var3 = this.a;
        if (xu0Var == null) {
            return new su0(a81Var3.b, this.b.b, a81Var2.b, a81Var.b);
        }
        su0 su0Var = (su0) xu0Var;
        su0Var.e(a81Var3.b);
        su0Var.f(this.b.b);
        su0Var.g(a81Var2.b);
        su0Var.m(a81Var.b);
        return su0Var;
    }

    @Override // defpackage.cv0
    public final a81 l() {
        return this.d;
    }

    @Override // defpackage.cv0
    public final ix9 o() {
        a81 a81Var = this.b;
        gg8 gg8Var = bof.a;
        a81 a81Var2 = this.a;
        a81 a81VarF = bof.f(a81Var2, a81Var, 0.5d, null);
        a81 a81Var3 = this.c;
        a81 a81VarF2 = bof.f(a81Var, a81Var3, 0.5d, null);
        a81 a81Var4 = this.d;
        a81 a81VarF3 = bof.f(a81Var3, a81Var4, 0.5d, null);
        a81 a81VarF4 = bof.f(a81VarF, a81VarF2, 0.5d, null);
        a81 a81VarF5 = bof.f(a81VarF2, a81VarF3, 0.5d, null);
        a81 a81VarF6 = bof.f(a81VarF4, a81VarF5, 0.5d, null);
        return new ix9(new gp2(a81Var2, a81VarF, a81VarF4, a81VarF6), new gp2(a81VarF6, a81VarF5, a81VarF3, a81Var4));
    }

    @Override // defpackage.y7f
    /* JADX INFO: renamed from: p, reason: merged with bridge method [inline-methods] */
    public final gp2 m(z71 z71Var) {
        return new gp2(this.a.a(z71Var), this.b.a(z71Var), this.c.a(z71Var), this.d.a(z71Var));
    }

    public final ix9 q() {
        double d;
        a81 a81Var = this.b;
        double d2 = a81Var.a;
        a81 a81Var2 = this.a;
        double d3 = a81Var2.a;
        double d4 = d2 - d3;
        double d5 = a81Var.b;
        double d6 = a81Var2.b;
        double d7 = d5 - d6;
        a81 a81Var3 = this.c;
        double d8 = a81Var3.a - d3;
        double d9 = a81Var3.b - d6;
        double d10 = (d4 * d9) - (d8 * d7);
        if (d10 == 0.0d) {
            return null;
        }
        a81 a81VarC = this.d.c(a81Var2);
        double d11 = 1.0d / d10;
        double d12 = a81VarC.a;
        double d13 = a81VarC.b;
        double d14 = ((d4 * d13) + ((-d7) * d12)) * d11;
        double d15 = (((d4 - d8) * d13) + ((d9 - d7) * d12)) * d11;
        if (d14 >= 1.0d) {
            return null;
        }
        double d16 = d14 * d14;
        double dG = p5c.g(12.0d, d15, (6.0d * d14) + ((-3.0d) * d16), 9.0d);
        if (dG <= 0.0d) {
            return null;
        }
        if (d14 <= 0.0d) {
            d = d14;
            if (d15 < f92.c(3.0d, d14, -d16, 3.0d)) {
                return null;
            }
        } else {
            d = d14;
            if (d15 < (Math.sqrt(((4.0d * d) - d16) * 3.0d) - d) / 2.0d) {
                return null;
            }
        }
        return new ix9(Double.valueOf(dG), new a81(d, d15));
    }

    @Override // defpackage.cv0
    /* JADX INFO: renamed from: r, reason: merged with bridge method [inline-methods] */
    public final gp2 b(double d, double d2) {
        if (d == 0.0d && d2 == 1.0d) {
            return this;
        }
        double d3 = (d2 - d) / 3.0d;
        a81 a81VarC = c(d, null);
        a81 a81VarC2 = c(d2, null);
        a81 a81VarJ = j(d, this.e);
        a81 a81Var = new a81((a81VarJ.a * d3) + a81VarC.a, (a81VarJ.b * d3) + a81VarC.b);
        a81 a81VarJ2 = j(d2, this.f);
        return new gp2(a81VarC, a81Var, new a81(a81VarC2.a - (a81VarJ2.a * d3), a81VarC2.b - (a81VarJ2.b * d3)), a81VarC2);
    }

    public final String toString() {
        return "CubicCurve(p0=" + this.a + ", p1=" + this.b + ", p2=" + this.c + ", p3=" + this.d + ")";
    }
}
