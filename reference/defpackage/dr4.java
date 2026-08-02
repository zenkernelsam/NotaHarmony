package defpackage;

/* JADX INFO: loaded from: classes.dex */
public final class dr4 {
    public final boolean a;
    public final long b;
    public final float c;

    public dr4(float f, long j, boolean z) {
        this.a = z;
        this.b = j;
        this.c = f;
        p7j p7jVar = jp3.J;
        if (j <= 0) {
            c1c.h("smoothingWindow must be positive, was ".concat(jp3.o(j)));
            throw null;
        }
        if (f > 0.0f) {
            return;
        }
        r14.f("maxForceChangePerPoint must be positive, was ", f);
        throw null;
    }

    public final boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof dr4)) {
            return false;
        }
        dr4 dr4Var = (dr4) obj;
        return this.a == dr4Var.a && jp3.d(this.b, dr4Var.b) && Float.compare(this.c, dr4Var.c) == 0;
    }

    public final int hashCode() {
        int iHashCode = Boolean.hashCode(this.a) * 31;
        p7j p7jVar = jp3.J;
        return Float.hashCode(this.c) + nt6.e(this.b, iHashCode, 31);
    }

    public final String toString() {
        String strO = jp3.o(this.b);
        StringBuilder sb = new StringBuilder("ForceSmootherConfig(enabled=");
        sb.append(this.a);
        sb.append(", smoothingWindow=");
        sb.append(strO);
        sb.append(", maxForceChangePerPoint=");
        return ya.k(sb, this.c, ")");
    }
}
