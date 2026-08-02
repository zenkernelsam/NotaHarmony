package com.gingerlabs.notability.data.transcription;

import android.net.Uri;
import androidx.recyclerview.widget.RecyclerView;
import defpackage.a0;
import defpackage.ahb;
import defpackage.bhb;
import defpackage.bjf;
import defpackage.bl7;
import defpackage.c0;
import defpackage.ce2;
import defpackage.cl7;
import defpackage.d7f;
import defpackage.de2;
import defpackage.dlb;
import defpackage.e0;
import defpackage.e7f;
import defpackage.f0;
import defpackage.f6f;
import defpackage.fhb;
import defpackage.fjb;
import defpackage.fyd;
import defpackage.g;
import defpackage.g0;
import defpackage.gh2;
import defpackage.h;
import defpackage.h0;
import defpackage.i;
import defpackage.i0;
import defpackage.i55;
import defpackage.j;
import defpackage.jhb;
import defpackage.jm7;
import defpackage.k;
import defpackage.khb;
import defpackage.l;
import defpackage.m;
import defpackage.m0;
import defpackage.me8;
import defpackage.ny7;
import defpackage.ok2;
import defpackage.p6f;
import defpackage.q;
import defpackage.qy1;
import defpackage.r6f;
import defpackage.r7f;
import defpackage.r90;
import defpackage.s6f;
import defpackage.tg2;
import defpackage.tgb;
import defpackage.tqd;
import defpackage.ugb;
import defpackage.wgb;
import defpackage.ws3;
import defpackage.wvb;
import defpackage.x6f;
import defpackage.xs7;
import defpackage.xub;
import defpackage.y;
import defpackage.y6f;
import defpackage.y72;
import defpackage.yc4;
import defpackage.ygb;
import defpackage.yub;
import defpackage.yz3;
import defpackage.z;
import defpackage.zgb;
import java.io.IOException;
import java.net.ConnectException;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Locale;
import javax.net.ssl.SSLException;

/* JADX INFO: loaded from: classes.dex */
public final class a {
    public final g a;
    public final yc4 b;
    public final ws3 c;
    public final r7f d;
    public final y6f e;
    public final p6f f;
    public final y72 g;
    public final wvb h;

    public a(g gVar, yc4 yc4Var, ws3 ws3Var, r7f r7fVar, y6f y6fVar, p6f p6fVar, y72 y72Var, wvb wvbVar) {
        this.a = gVar;
        this.b = yc4Var;
        this.c = ws3Var;
        this.d = r7fVar;
        this.e = y6fVar;
        this.f = p6fVar;
        this.g = y72Var;
        this.h = wvbVar;
    }

    /* JADX WARN: Code duplicated, block: B:8:0x0017  */
    public static final Object a(a aVar, String str, String str2, de2 de2Var) {
        y yVar;
        q qVar;
        aVar.getClass();
        if (de2Var instanceof y) {
            yVar = (y) de2Var;
            int i = yVar.M;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                yVar.M = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                yVar = new y(aVar, de2Var);
            }
        } else {
            yVar = new y(aVar, de2Var);
        }
        y yVar2 = yVar;
        Object objF = yVar2.K;
        int i2 = yVar2.M;
        jm7 jm7Var = jm7.I;
        cl7 cl7Var = cl7.RECORDING;
        q qVarA = null;
        if (i2 == 0) {
            ny7.F0(objF);
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var = new bl7();
                    bl7Var.put("hash.prefix", tqd.b1(16, str2));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "checkExistingJob: fetching job from server", null, xs7.R(bl7Var));
                } catch (Exception e) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "checkExistingJob: fetching job from server", e);
                }
            }
            g gVar = aVar.a;
            yVar2.I = str;
            yVar2.J = str2;
            yVar2.M = 1;
            objF = gVar.f(str2, yVar2);
            gh2 gh2Var = gh2.I;
            if (objF == gh2Var) {
                return gh2Var;
            }
        } else {
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            str2 = yVar2.J;
            str = yVar2.I;
            ny7.F0(objF);
        }
        String str3 = str2;
        m mVar = (m) objF;
        ArrayList arrayList2 = com.gingerlabs.notability.core.common.logging.a.a;
        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
            try {
                bl7 bl7Var2 = new bl7();
                bl7Var2.put("result.kind", dlb.a.b(mVar.getClass()).p());
                com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "checkExistingJob: server result", null, xs7.R(bl7Var2));
            } catch (Exception e2) {
                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "checkExistingJob: server result", e2);
            }
        }
        if (mVar instanceof l) {
            ArrayList arrayList3 = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var3 = new bl7();
                    bl7Var3.put("job.status", ((l) mVar).a().d());
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "checkExistingJob: found existing job", null, xs7.R(bl7Var3));
                } catch (Exception e3) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "checkExistingJob: found existing job", e3);
                }
            }
            qVarA = ((l) mVar).a();
        } else {
            if (mVar instanceof k) {
                ArrayList arrayList4 = com.gingerlabs.notability.core.common.logging.a.a;
                com.gingerlabs.notability.core.common.logging.a.d(jm7Var, cl7Var, "checkExistingJob: job is processing");
                qVar = new q(str3, m0.L, null, null, null);
            } else if (mVar instanceof j) {
                ArrayList arrayList5 = com.gingerlabs.notability.core.common.logging.a.a;
                com.gingerlabs.notability.core.common.logging.a.d(jm7Var, cl7Var, "checkExistingJob: job not found, will proceed to create");
                qVar = new q(str3, m0.J, null, null, null);
            } else if (mVar instanceof h) {
                ArrayList arrayList6 = com.gingerlabs.notability.core.common.logging.a.a;
                jm7 jm7Var2 = jm7.M;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var2, cl7Var)) {
                    try {
                        bl7 bl7Var4 = new bl7();
                        bl7Var4.put("error.code", ((h) mVar).a());
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var2, cl7Var, "checkExistingJob: error from server", null, xs7.R(bl7Var4));
                    } catch (Exception e4) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "checkExistingJob: error from server", e4);
                    }
                }
                aVar.f((h) mVar);
            } else {
                if (!(mVar instanceof i)) {
                    yz3.t();
                    return null;
                }
                ArrayList arrayList7 = com.gingerlabs.notability.core.common.logging.a.a;
                jm7 jm7Var3 = jm7.L;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    try {
                        bl7 bl7Var5 = new bl7();
                        bl7Var5.put("error.message", ((i) mVar).a().getMessage());
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "checkExistingJob: network error", null, xs7.R(bl7Var5));
                    } catch (Exception e5) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "checkExistingJob: network error", e5);
                    }
                }
                aVar.d.c(str, c(((i) mVar).a()));
            }
            qVarA = qVar;
        }
        return qVarA;
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0016  */
    public static final Object b(a aVar, String str, String str2, Instant instant, long j, String str3, String str4, String str5, de2 de2Var) {
        z zVar;
        String str6;
        aVar.getClass();
        if (de2Var instanceof z) {
            zVar = (z) de2Var;
            int i = zVar.M;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                zVar.M = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                zVar = new z(aVar, de2Var);
            }
        } else {
            zVar = new z(aVar, de2Var);
        }
        Object objE = zVar.K;
        int i2 = zVar.M;
        if (i2 == 0) {
            ny7.F0(objE);
            str6 = str2;
            ok2 ok2Var = new ok2(str6, instant.toEpochMilli(), new Double(j), str3, str4, str5);
            g gVar = aVar.a;
            zVar.I = str;
            zVar.J = str6;
            zVar.M = 1;
            objE = gVar.e(ok2Var, zVar);
            gh2 gh2Var = gh2.I;
            if (objE == gh2Var) {
                return gh2Var;
            }
        } else {
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            String str7 = zVar.J;
            str = zVar.I;
            ny7.F0(objE);
            str6 = str7;
        }
        m mVar = (m) objE;
        if (mVar instanceof l) {
            return ((l) mVar).a();
        }
        if (mVar instanceof k) {
            return new q(str6, m0.L, null, null, null);
        }
        boolean z = mVar instanceof j;
        jm7 jm7Var = jm7.L;
        cl7 cl7Var = cl7.RECORDING;
        if (z) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            com.gingerlabs.notability.core.common.logging.a.d(jm7Var, cl7Var, "createJob: server returned not found");
            return null;
        }
        if (mVar instanceof h) {
            ArrayList arrayList2 = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var = new bl7();
                    bl7Var.put("error.code", ((h) mVar).a());
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "createJob: error from server", null, xs7.R(bl7Var));
                } catch (Exception e) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "createJob: error from server", e);
                }
            }
            aVar.f((h) mVar);
        } else {
            if (!(mVar instanceof i)) {
                yz3.t();
                return null;
            }
            ArrayList arrayList3 = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var2 = new bl7();
                    bl7Var2.put("error.message", ((i) mVar).a().getMessage());
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "createJob: network error", null, xs7.R(bl7Var2));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "createJob: network error", e2);
                }
            }
            aVar.d.c(str, c(((i) mVar).a()));
        }
        return null;
    }

    public static s6f c(Throwable th) {
        boolean z = th instanceof UnknownHostException;
        r6f r6fVar = r6f.J;
        if (z) {
            return new s6f(tg2.D("No network: ", th.getMessage()), true, r6fVar, 8);
        }
        if (th instanceof SocketTimeoutException) {
            return new s6f(tg2.D("Connection timed out: ", th.getMessage()), true, r6fVar, 8);
        }
        if (th instanceof ConnectException) {
            return new s6f(tg2.D("Connection failed: ", th.getMessage()), true, r6fVar, 8);
        }
        if (th instanceof SocketException) {
            return new s6f(tg2.D("Socket error: ", th.getMessage()), true, r6fVar, 8);
        }
        if (th instanceof SSLException) {
            return new s6f(tg2.D("SSL error: ", th.getMessage()), true, r6fVar, 8);
        }
        return th instanceof IOException ? new s6f(tg2.D("IO error: ", th.getMessage()), true, r6fVar, 8) : new s6f(tg2.D("Unknown error: ", th.getMessage()), false, null, 12);
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    /* JADX WARN: Multi-variable type inference failed */
    public final Object d(de2 de2Var) {
        a0 a0Var;
        if (de2Var instanceof a0) {
            a0Var = (a0) de2Var;
            int i = a0Var.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                a0Var.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                a0Var = new a0(this, de2Var);
            }
        } else {
            a0Var = new a0(this, de2Var);
        }
        Object objK0 = a0Var.I;
        int i2 = a0Var.K;
        Object[] objArr = 0;
        jm7 jm7Var = jm7.I;
        cl7 cl7Var = cl7.RECORDING;
        ce2 ce2Var = null;
        if (i2 == 0) {
            ny7.F0(objK0);
            y72 y72Var = this.g;
            y72Var.a();
            Boolean bool = (Boolean) y72Var.a.getValue();
            boolean zBooleanValue = bool.booleanValue();
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var = new bl7();
                    bl7Var.put("connected", bool);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "ensureNetworkAvailable: current connected value", null, xs7.R(bl7Var));
                } catch (Exception e) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "ensureNetworkAvailable: current connected value", e);
                }
            }
            if (zBooleanValue) {
                return Boolean.TRUE;
            }
            ArrayList arrayList2 = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var2 = new bl7();
                    bl7Var2.put("timeout.ms", new Long(240000L));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Waiting for network connectivity", null, xs7.R(bl7Var2));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Waiting for network connectivity", e2);
                }
            }
            c0 c0Var = new c0(this, ce2Var, objArr == true ? 1 : 0);
            a0Var.K = 1;
            objK0 = qy1.k0(240000L, c0Var, a0Var);
            gh2 gh2Var = gh2.I;
            if (objK0 == gh2Var) {
                return gh2Var;
            }
        } else {
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            ny7.F0(objK0);
        }
        Boolean bool2 = (Boolean) objK0;
        boolean zBooleanValue2 = bool2 != null ? bool2.booleanValue() : false;
        ArrayList arrayList3 = com.gingerlabs.notability.core.common.logging.a.a;
        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
            try {
                bl7 bl7Var3 = new bl7();
                bl7Var3.put("result", Boolean.valueOf(zBooleanValue2));
                com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "ensureNetworkAvailable: result", null, xs7.R(bl7Var3));
            } catch (Exception e3) {
                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "ensureNetworkAvailable: result", e3);
            }
        }
        return Boolean.valueOf(zBooleanValue2);
    }

    /* JADX WARN: Code duplicated, block: B:114:0x026d A[ADDED_TO_REGION, REMOVE] */
    /* JADX WARN: Code duplicated, block: B:124:0x029c  */
    /* JADX WARN: Code duplicated, block: B:128:0x02b2  */
    /* JADX WARN: Code duplicated, block: B:136:0x02d6  */
    /* JADX WARN: Code duplicated, block: B:138:0x02dc  */
    /* JADX WARN: Code duplicated, block: B:153:0x0318  */
    /* JADX WARN: Code duplicated, block: B:156:0x0321  */
    /* JADX WARN: Code duplicated, block: B:158:0x033e A[ADDED_TO_REGION] */
    /* JADX WARN: Code duplicated, block: B:163:0x0372  */
    /* JADX WARN: Code duplicated, block: B:166:0x0392  */
    /* JADX WARN: Code duplicated, block: B:168:0x0398  */
    /* JADX WARN: Code duplicated, block: B:173:0x03ab  */
    /* JADX WARN: Code duplicated, block: B:184:0x03e9  */
    /* JADX WARN: Code duplicated, block: B:185:0x03ed  */
    /* JADX WARN: Code duplicated, block: B:187:0x03f5  */
    /* JADX WARN: Code duplicated, block: B:195:0x0432  */
    /* JADX WARN: Code duplicated, block: B:197:0x0458  */
    /* JADX WARN: Code duplicated, block: B:199:0x045e  */
    /* JADX WARN: Code duplicated, block: B:200:0x0460  */
    /* JADX WARN: Code duplicated, block: B:204:0x0478  */
    /* JADX WARN: Code duplicated, block: B:207:0x047d  */
    /* JADX WARN: Code duplicated, block: B:213:0x02ee A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:215:0x027a A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:219:0x00d2 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:223:0x016f A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:229:0x0121 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:237:0x0407 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:245:0x03b9 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:247:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:248:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:249:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:33:0x00c8  */
    /* JADX WARN: Code duplicated, block: B:42:0x0110  */
    /* JADX WARN: Code duplicated, block: B:54:0x0150  */
    /* JADX WARN: Code duplicated, block: B:57:0x015a  */
    /* JADX WARN: Code duplicated, block: B:68:0x0192  */
    /* JADX WARN: Code duplicated, block: B:71:0x019e  */
    /* JADX WARN: Code duplicated, block: B:7:0x0019  */
    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r6v1, types: [djb, java.lang.String] */
    /* JADX WARN: Type inference failed for: r6v23 */
    /* JADX WARN: Type inference failed for: r6v29 */
    /* JADX WARN: Unsupported multi-entry loop pattern (BACK_EDGE: B:207:0x047d -> B:16:0x0050). Please report as a decompilation issue!!! */
    /*  JADX ERROR: JadxOverflowException in pass: RegionMakerVisitor
        jadx.core.utils.exceptions.JadxOverflowException: Regions stack size limit reached
        	at jadx.core.utils.ErrorsCounter.addError(ErrorsCounter.java:59)
        	at jadx.core.utils.ErrorsCounter.error(ErrorsCounter.java:31)
        	at jadx.core.dex.attributes.nodes.NotificationAttrNode.addError(NotificationAttrNode.java:19)
        */
    public final java.lang.Object e(java.lang.String r22, java.lang.String r23, defpackage.de2 r24) {
        /*
            Method dump skipped, instruction units count: 1194
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: com.gingerlabs.notability.data.transcription.a.e(java.lang.String, java.lang.String, de2):java.lang.Object");
    }

    public final void f(h hVar) {
        Instant instant;
        if (hVar.a() == r90.QUOTA_EXCEEDED) {
            y6f y6fVar = this.e;
            String strB = hVar.b();
            if (strB != null) {
                try {
                    instant = Instant.parse(strB);
                } catch (DateTimeParseException unused) {
                    ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
                    cl7 cl7Var = cl7.RECORDING;
                    jm7 jm7Var = jm7.J;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                        try {
                            bl7 bl7Var = new bl7();
                            bl7Var.put("asr.retry_after", strB);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Unparseable ASR retry-after", null, xs7.R(bl7Var));
                        } catch (Exception e) {
                            com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Unparseable ASR retry-after", e);
                        }
                    }
                    instant = null;
                }
            } else {
                instant = null;
            }
            if (instant != null) {
                fyd fydVarD = y6fVar.a.d();
                y6fVar.b = new x6f(instant, fydVarD != null ? fydVarD.a : null);
            }
        }
    }

    /* JADX WARN: Can't fix incorrect switch cases order, some code will duplicate */
    /* JADX WARN: Code duplicated, block: B:101:0x03d4  */
    /* JADX WARN: Code duplicated, block: B:117:0x041a  */
    /* JADX WARN: Code duplicated, block: B:120:0x0422  */
    /* JADX WARN: Code duplicated, block: B:122:0x0430  */
    /* JADX WARN: Code duplicated, block: B:131:0x0471 A[RETURN] */
    /* JADX WARN: Code duplicated, block: B:132:0x0472  */
    /* JADX WARN: Code duplicated, block: B:134:0x0476  */
    /* JADX WARN: Code duplicated, block: B:143:0x04c0  */
    /* JADX WARN: Code duplicated, block: B:146:0x04d1  */
    /* JADX WARN: Code duplicated, block: B:154:0x0502  */
    /* JADX WARN: Code duplicated, block: B:155:0x051d  */
    /* JADX WARN: Code duplicated, block: B:167:0x0561  */
    /* JADX WARN: Code duplicated, block: B:177:0x05af  */
    /* JADX WARN: Code duplicated, block: B:180:0x05c0  */
    /* JADX WARN: Code duplicated, block: B:195:0x05f8  */
    /* JADX WARN: Code duplicated, block: B:198:0x0606  */
    /* JADX WARN: Code duplicated, block: B:200:0x0609  */
    /* JADX WARN: Code duplicated, block: B:220:0x068c A[RETURN] */
    /* JADX WARN: Code duplicated, block: B:221:0x068d  */
    /* JADX WARN: Code duplicated, block: B:224:0x06b5 A[RETURN] */
    /* JADX WARN: Code duplicated, block: B:225:0x06b6  */
    /* JADX WARN: Code duplicated, block: B:226:0x06c0  */
    /* JADX WARN: Code duplicated, block: B:230:0x0705  */
    /* JADX WARN: Code duplicated, block: B:233:0x070d  */
    /* JADX WARN: Code duplicated, block: B:235:0x0728  */
    /* JADX WARN: Code duplicated, block: B:237:0x0730  */
    /* JADX WARN: Code duplicated, block: B:248:0x075b  */
    /* JADX WARN: Code duplicated, block: B:257:0x0779  */
    /* JADX WARN: Code duplicated, block: B:277:0x07f6  */
    /* JADX WARN: Code duplicated, block: B:279:0x07fc  */
    /* JADX WARN: Code duplicated, block: B:281:0x0806  */
    /* JADX WARN: Code duplicated, block: B:282:0x080b  */
    /* JADX WARN: Code duplicated, block: B:284:0x0821  */
    /* JADX WARN: Code duplicated, block: B:287:0x083a  */
    /* JADX WARN: Code duplicated, block: B:293:0x0863 A[RETURN] */
    /* JADX WARN: Code duplicated, block: B:294:0x0864  */
    /* JADX WARN: Code duplicated, block: B:298:0x05cc A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:302:0x04dd A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:306:0x043a A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:310:0x0399 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:322:0x0480 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:324:0x03eb A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:326:0x056d A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:328:0x034c A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:330:0x0545 A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:335:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:337:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:338:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:339:? A[RETURN, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:43:0x026a  */
    /* JADX WARN: Code duplicated, block: B:45:0x0275  */
    /* JADX WARN: Code duplicated, block: B:47:0x027d  */
    /* JADX WARN: Code duplicated, block: B:49:0x0297  */
    /* JADX WARN: Code duplicated, block: B:51:0x02bc  */
    /* JADX WARN: Code duplicated, block: B:61:0x02df  */
    /* JADX WARN: Code duplicated, block: B:65:0x030b  */
    /* JADX WARN: Code duplicated, block: B:68:0x0318  */
    /* JADX WARN: Code duplicated, block: B:71:0x033b  */
    /* JADX WARN: Code duplicated, block: B:8:0x001a  */
    /* JADX WARN: Code duplicated, block: B:91:0x0387  */
    /* JADX WARN: Type inference failed for: r8v23 */
    /* JADX WARN: Type inference failed for: r8v27, types: [android.net.Uri, java.lang.String, java.time.Instant] */
    /* JADX WARN: Type inference failed for: r8v28 */
    /* JADX WARN: Unreachable blocks removed: 1, instructions: 1 */
    /* JADX WARN: Unreachable blocks removed: 2, instructions: 2 */
    public final Object g(String str, Uri uri, Instant instant, long j, String str2, de2 de2Var) {
        e0 e0Var;
        Object objH;
        String str3;
        Uri uri2;
        Instant instant2;
        String str4;
        p6f p6fVar;
        String str5;
        String str6;
        long j2;
        bhb bhbVar;
        Boolean bool;
        boolean zBooleanValue;
        Object obj;
        boolean z;
        boolean z2;
        Object objB;
        String str7;
        String str8;
        Object obj2;
        Throwable thA;
        String str9;
        boolean z3;
        String str10;
        boolean z4;
        String str11;
        String str12;
        long j3;
        gh2 gh2Var;
        Object obj3;
        boolean z5;
        boolean z6;
        p6f p6fVar2;
        Object objA;
        gh2 gh2Var2;
        String str13;
        p6f p6fVar3;
        String str14;
        String str15;
        long j4;
        e7f e7fVar;
        String str16;
        String str17;
        String str18;
        String str19;
        String str20;
        boolean z7;
        Uri uri3;
        long j5;
        String str21;
        String str22;
        r7f r7fVar;
        String str23;
        String str24;
        String str25;
        String str26;
        Object objD;
        String str27;
        String str28;
        String str29;
        String str30;
        q qVarA;
        long j6;
        boolean z8;
        wvb wvbVar;
        Object objN;
        gh2 gh2Var3;
        wvb wvbVar2;
        String str31;
        String str32;
        String str33;
        Uri uri4;
        boolean z9;
        long j7;
        Instant instant3;
        jm7 jm7Var;
        q qVar;
        String str34;
        String str35;
        Object obj4;
        String str36;
        long j8;
        r7f r7fVar2;
        wvb wvbVar3;
        e0 e0Var2;
        String str37;
        String str38;
        long j9;
        String str39;
        Uri uri5;
        int iOrdinal;
        Object objE;
        r7f r7fVar3;
        ?? r8;
        boolean z10;
        q qVar2;
        r7f r7fVar4;
        i55 i55VarE;
        String str40;
        long j10;
        fjb fjbVar;
        String str41;
        String str42;
        boolean z11;
        Object objE2;
        Throwable th;
        s6f s6fVar;
        Throwable th2;
        String message;
        a aVar = this;
        if (de2Var instanceof e0) {
            e0Var = (e0) de2Var;
            int i = e0Var.V;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                e0Var.V = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                e0Var = new e0(aVar, de2Var);
            }
        } else {
            e0Var = new e0(aVar, de2Var);
        }
        e0 e0Var3 = e0Var;
        Object objN2 = e0Var3.T;
        int i2 = e0Var3.V;
        p6f p6fVar4 = aVar.f;
        jm7 jm7Var2 = jm7.L;
        jm7 jm7Var3 = jm7.I;
        cl7 cl7Var = cl7.RECORDING;
        wvb wvbVar4 = aVar.h;
        r7f r7fVar5 = aVar.d;
        gh2 gh2Var4 = gh2.I;
        switch (i2) {
            case 0:
                ny7.F0(objN2);
                ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    try {
                        bl7 bl7Var = new bl7();
                        bl7Var.put("recording.id", str);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Starting transcription for recording", null, xs7.R(bl7Var));
                    } catch (Exception e) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Starting transcription for recording", e);
                    }
                    break;
                }
                e0Var3.I = str;
                e0Var3.J = uri;
                e0Var3.K = instant;
                e0Var3.L = str2;
                e0Var3.M = null;
                e0Var3.N = null;
                e0Var3.R = j;
                e0Var3.V = 1;
                aVar = this;
                objH = aVar.h(str, uri, j, str2, e0Var3);
                if (objH == gh2Var4) {
                    return gh2Var4;
                }
                str3 = str;
                uri2 = uri;
                instant2 = instant;
                str4 = str2;
                p6fVar = p6fVar4;
                str5 = null;
                str6 = null;
                j2 = j;
                bhbVar = (bhb) objH;
                if (bhbVar != null) {
                    return new xub(new TranscriptionException.Blocked(bhbVar));
                }
                if (!aVar.e.a()) {
                    r7fVar5.b(str3, new s6f("Quota limit reached", false, r6f.I, 8));
                    return new xub(new TranscriptionException.QuotaExceeded());
                }
                str3.getClass();
                r7fVar5.e(str3, fhb.a);
                y72 y72Var = aVar.g;
                y72Var.a();
                bool = (Boolean) y72Var.a.getValue();
                zBooleanValue = bool.booleanValue();
                ArrayList arrayList2 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    z = zBooleanValue;
                    try {
                        bl7 bl7Var2 = new bl7();
                        bl7Var2.put("recording.id", str3);
                        obj = "recording.id";
                        try {
                            bl7Var2.put("connected", bool);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Quick network check", null, xs7.R(bl7Var2));
                        } catch (Exception e2) {
                            e = e2;
                            com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Quick network check", e);
                        }
                    } catch (Exception e3) {
                        e = e3;
                        obj = "recording.id";
                    }
                    break;
                } else {
                    obj = "recording.id";
                    z = zBooleanValue;
                }
                r7fVar5.e(str3, khb.a);
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str5;
                e0Var3.N = str6;
                e0Var3.R = j2;
                z2 = z;
                e0Var3.S = z2;
                e0Var3.V = 2;
                objB = this.c.b(uri2, e0Var3);
                gh2Var4 = gh2Var4;
                if (objB == gh2Var4) {
                    return gh2Var4;
                }
                String str43 = str6;
                str7 = str5;
                str8 = str43;
                obj2 = objB;
                thA = yub.a(obj2);
                if (thA != null) {
                    r7fVar5.c(str3, new s6f(tg2.D("Failed to compute hash: ", thA.getMessage()), true, null, 12));
                    return new xub(new TranscriptionException.HashingFailed(thA));
                }
                str9 = (String) obj2;
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str7;
                e0Var3.N = str8;
                e0Var3.O = str9;
                e0Var3.R = j2;
                e0Var3.S = z2;
                z3 = z2;
                e0Var3.V = 3;
                if (r7fVar5.d(str3, str9, e0Var3) == gh2Var4) {
                    return gh2Var4;
                }
                str10 = str7;
                z4 = z3;
                str11 = str8;
                str12 = str9;
                ArrayList arrayList3 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    try {
                        bl7 bl7Var3 = new bl7();
                        gh2Var = gh2Var4;
                        obj3 = obj;
                        try {
                            bl7Var3.put(obj3, str3);
                            z5 = z4;
                            j3 = j2;
                            try {
                                bl7Var3.put("hash.prefix", tqd.b1(16, str12));
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Computed hash", null, xs7.R(bl7Var3));
                            } catch (Exception e4) {
                                e = e4;
                                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Computed hash", e);
                            }
                        } catch (Exception e5) {
                            e = e5;
                            z5 = z4;
                            j3 = j2;
                        }
                    } catch (Exception e6) {
                        e = e6;
                        j3 = j2;
                        gh2Var = gh2Var4;
                        obj3 = obj;
                        z5 = z4;
                    }
                    break;
                } else {
                    j3 = j2;
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    z5 = z4;
                }
                ArrayList arrayList4 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    try {
                        bl7 bl7Var4 = new bl7();
                        bl7Var4.put(obj3, str3);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking local cache", null, xs7.R(bl7Var4));
                    } catch (Exception e7) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Checking local cache", e7);
                    }
                    break;
                }
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str10;
                e0Var3.N = str11;
                e0Var3.O = str12;
                e0Var3.R = j3;
                z6 = z5;
                e0Var3.S = z6;
                e0Var3.V = 4;
                p6fVar2 = p6fVar;
                objA = p6fVar2.a(str12, e0Var3);
                gh2Var2 = gh2Var;
                if (objA != gh2Var2) {
                    str13 = str12;
                    p6fVar3 = p6fVar2;
                    str14 = str10;
                    str15 = str11;
                    j4 = j3;
                    e7fVar = (e7f) objA;
                    ArrayList arrayList5 = com.gingerlabs.notability.core.common.logging.a.a;
                    str16 = str15;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        try {
                            bl7 bl7Var5 = new bl7();
                            bl7Var5.put(obj3, str3);
                            str18 = str14;
                            str17 = str4;
                            try {
                                bl7Var5.put("cache.hit", Boolean.valueOf(e7fVar instanceof d7f));
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Local cache result", null, xs7.R(bl7Var5));
                            } catch (Exception e8) {
                                e = e8;
                                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Local cache result", e);
                            }
                        } catch (Exception e9) {
                            e = e9;
                            str17 = str4;
                            str18 = str14;
                        }
                        break;
                    } else {
                        str17 = str4;
                        str18 = str14;
                    }
                    if (!(e7fVar instanceof d7f)) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList6 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var6 = new bl7();
                                bl7Var6.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var6));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList7 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var7 = new bl7();
                                        bl7Var7.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var7));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str44 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str44;
                                String str45 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j11 = j4;
                                uri3 = uri2;
                                str23 = str45;
                                j5 = j11;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str46 = str3;
                            String str47 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str46;
                            r7fVar = r7fVar5;
                            str23 = str47;
                        }
                        ArrayList arrayList8 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var5 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var8 = new bl7();
                            bl7Var8.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var8));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList9 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var9 = new bl7();
                            bl7Var9.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var9));
                            break;
                        }
                        g0 g0Var = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var, e0Var3);
                        gh2Var3 = gh2Var5;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList10 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var10 = new bl7();
                                    bl7Var10.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var10.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var10));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList11 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList12 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList13 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var4 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var4;
                            str37 = str34;
                            f0 f0Var = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    qVarA = ((d7f) e7fVar).a();
                    if (qVarA.d() != m0.M) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList14 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                try {
                                    bl7 bl7Var11 = new bl7();
                                    bl7Var11.put(obj3, str3);
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var11));
                                } catch (Exception e10) {
                                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "No network earlier, waiting for connectivity", e10);
                                }
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList15 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        try {
                                            bl7 bl7Var12 = new bl7();
                                            bl7Var12.put(obj3, str28);
                                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var12));
                                        } catch (Exception e11) {
                                            com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Network not available, returning NoNetwork error", e11);
                                        }
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str48 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str48;
                                String str49 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j12 = j4;
                                uri3 = uri2;
                                str23 = str49;
                                j5 = j12;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str410 = str3;
                            String str411 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str410;
                            r7fVar = r7fVar5;
                            str23 = str411;
                        }
                        ArrayList arrayList16 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var6 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            try {
                                bl7 bl7Var13 = new bl7();
                                bl7Var13.put(obj3, str22);
                                j6 = j5;
                                try {
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var13));
                                } catch (Exception e12) {
                                    e = e12;
                                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Network is available", e);
                                }
                            } catch (Exception e13) {
                                e = e13;
                                j6 = j5;
                            }
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList17 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            try {
                                bl7 bl7Var14 = new bl7();
                                bl7Var14.put(obj3, str22);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var14));
                            } catch (Exception e14) {
                                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Checking if job exists on server", e14);
                            }
                            break;
                        }
                        g0 g0Var2 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var2, e0Var3);
                        gh2Var3 = gh2Var6;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList18 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    try {
                                        bl7 bl7Var15 = new bl7();
                                        bl7Var15.put(obj3, str22);
                                        str35 = str33;
                                        obj4 = obj3;
                                        try {
                                            bl7Var15.put("job.status", qVar.d());
                                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var15));
                                        } catch (Exception e15) {
                                            e = e15;
                                            com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Existing job found", e);
                                        }
                                    } catch (Exception e16) {
                                        e = e16;
                                        str35 = str33;
                                        obj4 = obj3;
                                    }
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList19 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1 || iOrdinal == 2) {
                                    ArrayList arrayList110 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else if (iOrdinal == 3) {
                                    r7fVar3 = r7fVar;
                                    r8 = 0;
                                    e0Var3.I = str22;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = qVar;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 8;
                                    if (p6fVar3.b(str31, qVar, str22, e0Var3) != gh2Var3) {
                                        z10 = z9;
                                        e0Var3.I = r8;
                                        e0Var3.J = r8;
                                        e0Var3.K = r8;
                                        e0Var3.L = r8;
                                        e0Var3.M = r8;
                                        e0Var3.N = r8;
                                        e0Var3.O = r8;
                                        e0Var3.P = qVar;
                                        e0Var3.R = j7;
                                        e0Var3.S = z10;
                                        e0Var3.V = 9;
                                        if (r7fVar3.f(str22, qVar, e0Var3) != gh2Var3) {
                                            return qVar;
                                        }
                                    }
                                } else {
                                    if (iOrdinal != 4) {
                                        if (iOrdinal != 5) {
                                            yz3.t();
                                            return null;
                                        }
                                        ArrayList arrayList20 = com.gingerlabs.notability.core.common.logging.a.a;
                                        com.gingerlabs.notability.core.common.logging.a.d(jm7Var2, cl7Var, "Existing job has permanent error");
                                        str22.getClass();
                                        r7fVar.e(str22, jhb.a);
                                        return new xub(new TranscriptionException.ServerPermanentError());
                                    }
                                    ArrayList arrayList21 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var2, cl7Var, "Existing job has transient error, need to re-create");
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var5 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var5;
                            str37 = str34;
                            f0 f0Var2 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var2, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null && qVar2.d() == m0.J) {
                                String lowerCase = str39.toLowerCase(Locale.ROOT);
                                lowerCase.getClass();
                                switch (lowerCase.hashCode()) {
                                    case 106458:
                                        if (!lowerCase.equals("m4a")) {
                                            str40 = "audio/mp4";
                                        } else {
                                            str40 = "audio/m4a";
                                        }
                                        break;
                                    case 108273:
                                        lowerCase.equals("mp4");
                                        str40 = "audio/mp4";
                                        break;
                                    case 117484:
                                        if (!lowerCase.equals("wav")) {
                                            str40 = "audio/mp4";
                                        } else {
                                            str40 = "audio/wav";
                                        }
                                        break;
                                    case 3645325:
                                        if (!lowerCase.equals("weba")) {
                                            str40 = "audio/mp4";
                                        } else {
                                            str40 = "audio/webm";
                                        }
                                        break;
                                    case 3645337:
                                        if (!lowerCase.equals("webm")) {
                                            str40 = "audio/mp4";
                                        } else {
                                            str40 = "audio/webm";
                                        }
                                        break;
                                    default:
                                        str40 = "audio/mp4";
                                        break;
                                }
                                String str50 = str40;
                                ArrayList arrayList22 = com.gingerlabs.notability.core.common.logging.a.a;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    try {
                                        bl7 bl7Var16 = new bl7();
                                        j10 = j9;
                                        try {
                                            bl7Var16.put(obj4, str36);
                                            bl7Var16.put("mime.type", str50);
                                            bl7Var16.put("extension", str39);
                                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Starting upload", null, xs7.R(bl7Var16));
                                        } catch (Exception e17) {
                                            e = e17;
                                            com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Starting upload", e);
                                        }
                                    } catch (Exception e18) {
                                        e = e18;
                                        j10 = j9;
                                    }
                                } else {
                                    j10 = j9;
                                }
                                fjb fjbVar2 = new fjb();
                                aVar = this;
                                j9 = j10;
                                h0 h0Var = new h0(aVar, str36, j9, uri5, i55VarE, str50, fjbVar2, null);
                                e0Var2.I = str36;
                                e0Var2.J = null;
                                e0Var2.K = null;
                                e0Var2.L = null;
                                e0Var2.M = null;
                                e0Var2.N = null;
                                e0Var2.O = str38;
                                e0Var2.P = null;
                                e0Var2.Q = fjbVar2;
                                e0Var2.R = j9;
                                e0Var2.S = z9;
                                e0Var2.V = 12;
                                objN2 = me8.N(6, wvbVar3, h0Var, e0Var2);
                                if (objN2 == gh2Var4) {
                                    return gh2Var4;
                                }
                                fjbVar = fjbVar2;
                                str41 = str38;
                                str42 = str36;
                                z11 = z9;
                                if (((bjf) objN2) == null) {
                                    th = (Throwable) fjbVar.I;
                                    if (th != null) {
                                        s6f s6fVarC = c(th);
                                        th2 = (Throwable) fjbVar.I;
                                        if (th2 != null) {
                                            message = th2.getMessage();
                                        } else {
                                            message = null;
                                        }
                                        s6fVar = s6f.a(s6fVarC, "Upload failed after 6 attempts: " + message, 12);
                                    } else {
                                        s6fVar = new s6f("Upload failed after 6 attempts", false, null, 12);
                                    }
                                    r7fVar4.b(str42, s6fVar);
                                    return new xub(new TranscriptionException.UploadRetriesExhausted());
                                }
                                z9 = z11;
                                str38 = str41;
                                str36 = str42;
                            } else {
                                aVar = this;
                            }
                            break;
                            break;
                        }
                        return gh2Var3;
                    }
                    ArrayList arrayList23 = com.gingerlabs.notability.core.common.logging.a.a;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        try {
                            bl7 bl7Var17 = new bl7();
                            bl7Var17.put(obj3, str3);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Found completed transcription in local cache", null, xs7.R(bl7Var17));
                        } catch (Exception e19) {
                            com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Found completed transcription in local cache", e19);
                        }
                    }
                    e0Var3.I = null;
                    e0Var3.J = null;
                    e0Var3.K = null;
                    e0Var3.L = null;
                    e0Var3.M = null;
                    e0Var3.N = null;
                    e0Var3.O = null;
                    e0Var3.P = qVarA;
                    e0Var3.R = j4;
                    e0Var3.S = z6;
                    e0Var3.V = 5;
                    if (r7fVar5.f(str3, qVarA, e0Var3) != gh2Var2) {
                        return qVarA;
                    }
                    break;
                    e0Var2.I = null;
                    e0Var2.J = null;
                    e0Var2.K = null;
                    e0Var2.L = null;
                    e0Var2.M = null;
                    e0Var2.N = null;
                    e0Var2.O = null;
                    e0Var2.P = null;
                    e0Var2.Q = null;
                    e0Var2.R = j9;
                    e0Var2.S = z9;
                    e0Var2.V = 13;
                    objE2 = aVar.e(str36, str38, e0Var2);
                    if (objE2 == gh2Var4) {
                        return gh2Var4;
                    }
                    return objE2;
                }
                return gh2Var2;
            case 1:
                long j13 = e0Var3.R;
                String str51 = e0Var3.N;
                String str52 = e0Var3.M;
                String str53 = e0Var3.L;
                instant2 = e0Var3.K;
                Uri uri6 = e0Var3.J;
                String str54 = e0Var3.I;
                ny7.F0(objN2);
                str6 = str51;
                uri2 = uri6;
                j2 = j13;
                str3 = str54;
                str4 = str53;
                objH = objN2;
                str5 = str52;
                p6fVar = p6fVar4;
                bhbVar = (bhb) objH;
                if (bhbVar != null) {
                    return new xub(new TranscriptionException.Blocked(bhbVar));
                }
                if (!aVar.e.a()) {
                    r7fVar5.b(str3, new s6f("Quota limit reached", false, r6f.I, 8));
                    return new xub(new TranscriptionException.QuotaExceeded());
                }
                str3.getClass();
                r7fVar5.e(str3, fhb.a);
                y72 y72Var2 = aVar.g;
                y72Var2.a();
                bool = (Boolean) y72Var2.a.getValue();
                zBooleanValue = bool.booleanValue();
                ArrayList arrayList24 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    z = zBooleanValue;
                    bl7 bl7Var18 = new bl7();
                    bl7Var18.put("recording.id", str3);
                    obj = "recording.id";
                    bl7Var18.put("connected", bool);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Quick network check", null, xs7.R(bl7Var18));
                    break;
                } else {
                    obj = "recording.id";
                    z = zBooleanValue;
                }
                r7fVar5.e(str3, khb.a);
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str5;
                e0Var3.N = str6;
                e0Var3.R = j2;
                z2 = z;
                e0Var3.S = z2;
                e0Var3.V = 2;
                objB = this.c.b(uri2, e0Var3);
                gh2Var4 = gh2Var4;
                if (objB == gh2Var4) {
                    return gh2Var4;
                }
                String str412 = str6;
                str7 = str5;
                str8 = str412;
                obj2 = objB;
                thA = yub.a(obj2);
                if (thA != null) {
                    r7fVar5.c(str3, new s6f(tg2.D("Failed to compute hash: ", thA.getMessage()), true, null, 12));
                    return new xub(new TranscriptionException.HashingFailed(thA));
                }
                str9 = (String) obj2;
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str7;
                e0Var3.N = str8;
                e0Var3.O = str9;
                e0Var3.R = j2;
                e0Var3.S = z2;
                z3 = z2;
                e0Var3.V = 3;
                if (r7fVar5.d(str3, str9, e0Var3) == gh2Var4) {
                    return gh2Var4;
                }
                str10 = str7;
                z4 = z3;
                str11 = str8;
                str12 = str9;
                ArrayList arrayList25 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var19 = new bl7();
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    bl7Var19.put(obj3, str3);
                    z5 = z4;
                    j3 = j2;
                    bl7Var19.put("hash.prefix", tqd.b1(16, str12));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Computed hash", null, xs7.R(bl7Var19));
                    break;
                } else {
                    j3 = j2;
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    z5 = z4;
                }
                ArrayList arrayList26 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var20 = new bl7();
                    bl7Var20.put(obj3, str3);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking local cache", null, xs7.R(bl7Var20));
                    break;
                }
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str10;
                e0Var3.N = str11;
                e0Var3.O = str12;
                e0Var3.R = j3;
                z6 = z5;
                e0Var3.S = z6;
                e0Var3.V = 4;
                p6fVar2 = p6fVar;
                objA = p6fVar2.a(str12, e0Var3);
                gh2Var2 = gh2Var;
                if (objA != gh2Var2) {
                    str13 = str12;
                    p6fVar3 = p6fVar2;
                    str14 = str10;
                    str15 = str11;
                    j4 = j3;
                    e7fVar = (e7f) objA;
                    ArrayList arrayList27 = com.gingerlabs.notability.core.common.logging.a.a;
                    str16 = str15;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var21 = new bl7();
                        bl7Var21.put(obj3, str3);
                        str18 = str14;
                        str17 = str4;
                        bl7Var21.put("cache.hit", Boolean.valueOf(e7fVar instanceof d7f));
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Local cache result", null, xs7.R(bl7Var21));
                        break;
                    } else {
                        str17 = str4;
                        str18 = str14;
                    }
                    if (!(e7fVar instanceof d7f)) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList111 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var110 = new bl7();
                                bl7Var110.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var110));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList112 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var111 = new bl7();
                                        bl7Var111.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var111));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str413 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str413;
                                String str414 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j14 = j4;
                                uri3 = uri2;
                                str23 = str414;
                                j5 = j14;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str415 = str3;
                            String str416 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str415;
                            r7fVar = r7fVar5;
                            str23 = str416;
                        }
                        ArrayList arrayList113 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var7 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var112 = new bl7();
                            bl7Var112.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var112));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList114 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var113 = new bl7();
                            bl7Var113.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var113));
                            break;
                        }
                        g0 g0Var3 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var3, e0Var3);
                        gh2Var3 = gh2Var7;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList115 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var114 = new bl7();
                                    bl7Var114.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var114.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var114));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList116 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList117 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList118 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var6 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var6;
                            str37 = str34;
                            f0 f0Var3 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var3, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    qVarA = ((d7f) e7fVar).a();
                    if (qVarA.d() != m0.M) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList119 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var115 = new bl7();
                                bl7Var115.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var115));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList1110 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var116 = new bl7();
                                        bl7Var116.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var116));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str417 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str417;
                                String str418 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j15 = j4;
                                uri3 = uri2;
                                str23 = str418;
                                j5 = j15;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str419 = str3;
                            String str4110 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str419;
                            r7fVar = r7fVar5;
                            str23 = str4110;
                        }
                        ArrayList arrayList1111 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var8 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var117 = new bl7();
                            bl7Var117.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var117));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList1112 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var118 = new bl7();
                            bl7Var118.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var118));
                            break;
                        }
                        g0 g0Var4 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var4, e0Var3);
                        gh2Var3 = gh2Var8;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList1113 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var119 = new bl7();
                                    bl7Var119.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var119.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var119));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList1114 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList1115 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList1116 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var7 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var7;
                            str37 = str34;
                            f0 f0Var4 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var4, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    ArrayList arrayList28 = com.gingerlabs.notability.core.common.logging.a.a;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var120 = new bl7();
                        bl7Var120.put(obj3, str3);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Found completed transcription in local cache", null, xs7.R(bl7Var120));
                    }
                    e0Var3.I = null;
                    e0Var3.J = null;
                    e0Var3.K = null;
                    e0Var3.L = null;
                    e0Var3.M = null;
                    e0Var3.N = null;
                    e0Var3.O = null;
                    e0Var3.P = qVarA;
                    e0Var3.R = j4;
                    e0Var3.S = z6;
                    e0Var3.V = 5;
                    if (r7fVar5.f(str3, qVarA, e0Var3) != gh2Var2) {
                        return qVarA;
                    }
                    break;
                    e0Var2.I = null;
                    e0Var2.J = null;
                    e0Var2.K = null;
                    e0Var2.L = null;
                    e0Var2.M = null;
                    e0Var2.N = null;
                    e0Var2.O = null;
                    e0Var2.P = null;
                    e0Var2.Q = null;
                    e0Var2.R = j9;
                    e0Var2.S = z9;
                    e0Var2.V = 13;
                    objE2 = aVar.e(str36, str38, e0Var2);
                    if (objE2 == gh2Var4) {
                        return gh2Var4;
                    }
                    return objE2;
                }
                return gh2Var2;
            case 2:
                boolean z12 = e0Var3.S;
                long j16 = e0Var3.R;
                String str55 = e0Var3.N;
                String str56 = e0Var3.M;
                String str57 = e0Var3.L;
                Instant instant4 = e0Var3.K;
                Uri uri7 = e0Var3.J;
                String str58 = e0Var3.I;
                ny7.F0(objN2);
                objB = ((yub) objN2).I;
                p6fVar = p6fVar4;
                wvbVar4 = wvbVar4;
                obj = "recording.id";
                str7 = str56;
                z2 = z12;
                str8 = str55;
                uri2 = uri7;
                instant2 = instant4;
                jm7Var2 = jm7Var2;
                j2 = j16;
                e0Var3 = e0Var3;
                str3 = str58;
                str4 = str57;
                obj2 = objB;
                thA = yub.a(obj2);
                if (thA != null) {
                    r7fVar5.c(str3, new s6f(tg2.D("Failed to compute hash: ", thA.getMessage()), true, null, 12));
                    return new xub(new TranscriptionException.HashingFailed(thA));
                }
                str9 = (String) obj2;
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str7;
                e0Var3.N = str8;
                e0Var3.O = str9;
                e0Var3.R = j2;
                e0Var3.S = z2;
                z3 = z2;
                e0Var3.V = 3;
                if (r7fVar5.d(str3, str9, e0Var3) == gh2Var4) {
                    return gh2Var4;
                }
                str10 = str7;
                z4 = z3;
                str11 = str8;
                str12 = str9;
                ArrayList arrayList29 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var121 = new bl7();
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    bl7Var121.put(obj3, str3);
                    z5 = z4;
                    j3 = j2;
                    bl7Var121.put("hash.prefix", tqd.b1(16, str12));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Computed hash", null, xs7.R(bl7Var121));
                    break;
                } else {
                    j3 = j2;
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    z5 = z4;
                }
                ArrayList arrayList210 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var22 = new bl7();
                    bl7Var22.put(obj3, str3);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking local cache", null, xs7.R(bl7Var22));
                    break;
                }
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str10;
                e0Var3.N = str11;
                e0Var3.O = str12;
                e0Var3.R = j3;
                z6 = z5;
                e0Var3.S = z6;
                e0Var3.V = 4;
                p6fVar2 = p6fVar;
                objA = p6fVar2.a(str12, e0Var3);
                gh2Var2 = gh2Var;
                if (objA != gh2Var2) {
                    str13 = str12;
                    p6fVar3 = p6fVar2;
                    str14 = str10;
                    str15 = str11;
                    j4 = j3;
                    e7fVar = (e7f) objA;
                    ArrayList arrayList211 = com.gingerlabs.notability.core.common.logging.a.a;
                    str16 = str15;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var23 = new bl7();
                        bl7Var23.put(obj3, str3);
                        str18 = str14;
                        str17 = str4;
                        bl7Var23.put("cache.hit", Boolean.valueOf(e7fVar instanceof d7f));
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Local cache result", null, xs7.R(bl7Var23));
                        break;
                    } else {
                        str17 = str4;
                        str18 = str14;
                    }
                    if (!(e7fVar instanceof d7f)) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList1117 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var1110 = new bl7();
                                bl7Var1110.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var1110));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList1118 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var1111 = new bl7();
                                        bl7Var1111.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var1111));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str4111 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str4111;
                                String str4112 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j17 = j4;
                                uri3 = uri2;
                                str23 = str4112;
                                j5 = j17;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str4113 = str3;
                            String str4114 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str4113;
                            r7fVar = r7fVar5;
                            str23 = str4114;
                        }
                        ArrayList arrayList1119 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var9 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var1112 = new bl7();
                            bl7Var1112.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var1112));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList11110 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var1113 = new bl7();
                            bl7Var1113.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var1113));
                            break;
                        }
                        g0 g0Var5 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var5, e0Var3);
                        gh2Var3 = gh2Var9;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList11111 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var1114 = new bl7();
                                    bl7Var1114.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var1114.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var1114));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList11112 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList11113 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList11114 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var8 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var8;
                            str37 = str34;
                            f0 f0Var5 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var5, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    qVarA = ((d7f) e7fVar).a();
                    if (qVarA.d() != m0.M) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList11115 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var1115 = new bl7();
                                bl7Var1115.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var1115));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList11116 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var1116 = new bl7();
                                        bl7Var1116.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var1116));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str4115 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str4115;
                                String str4116 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j18 = j4;
                                uri3 = uri2;
                                str23 = str4116;
                                j5 = j18;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str4117 = str3;
                            String str4118 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str4117;
                            r7fVar = r7fVar5;
                            str23 = str4118;
                        }
                        ArrayList arrayList11117 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var10 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var1117 = new bl7();
                            bl7Var1117.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var1117));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList11118 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var1118 = new bl7();
                            bl7Var1118.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var1118));
                            break;
                        }
                        g0 g0Var6 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var6, e0Var3);
                        gh2Var3 = gh2Var10;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList11119 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var1119 = new bl7();
                                    bl7Var1119.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var1119.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var1119));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList111110 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList111111 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList111112 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var9 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var9;
                            str37 = str34;
                            f0 f0Var6 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var6, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    ArrayList arrayList212 = com.gingerlabs.notability.core.common.logging.a.a;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var122 = new bl7();
                        bl7Var122.put(obj3, str3);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Found completed transcription in local cache", null, xs7.R(bl7Var122));
                    }
                    e0Var3.I = null;
                    e0Var3.J = null;
                    e0Var3.K = null;
                    e0Var3.L = null;
                    e0Var3.M = null;
                    e0Var3.N = null;
                    e0Var3.O = null;
                    e0Var3.P = qVarA;
                    e0Var3.R = j4;
                    e0Var3.S = z6;
                    e0Var3.V = 5;
                    if (r7fVar5.f(str3, qVarA, e0Var3) != gh2Var2) {
                        return qVarA;
                    }
                    break;
                    e0Var2.I = null;
                    e0Var2.J = null;
                    e0Var2.K = null;
                    e0Var2.L = null;
                    e0Var2.M = null;
                    e0Var2.N = null;
                    e0Var2.O = null;
                    e0Var2.P = null;
                    e0Var2.Q = null;
                    e0Var2.R = j9;
                    e0Var2.S = z9;
                    e0Var2.V = 13;
                    objE2 = aVar.e(str36, str38, e0Var2);
                    if (objE2 == gh2Var4) {
                        return gh2Var4;
                    }
                    return objE2;
                }
                return gh2Var2;
            case 3:
                boolean z13 = e0Var3.S;
                long j19 = e0Var3.R;
                String str59 = e0Var3.O;
                String str60 = e0Var3.N;
                String str61 = e0Var3.M;
                String str62 = e0Var3.L;
                Instant instant5 = e0Var3.K;
                Uri uri8 = e0Var3.J;
                String str63 = e0Var3.I;
                ny7.F0(objN2);
                z4 = z13;
                p6fVar = p6fVar4;
                wvbVar4 = wvbVar4;
                obj = "recording.id";
                str11 = str60;
                str10 = str61;
                instant2 = instant5;
                str12 = str59;
                uri2 = uri8;
                str4 = str62;
                jm7Var2 = jm7Var2;
                j2 = j19;
                e0Var3 = e0Var3;
                str3 = str63;
                ArrayList arrayList213 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var123 = new bl7();
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    bl7Var123.put(obj3, str3);
                    z5 = z4;
                    j3 = j2;
                    bl7Var123.put("hash.prefix", tqd.b1(16, str12));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Computed hash", null, xs7.R(bl7Var123));
                    break;
                } else {
                    j3 = j2;
                    gh2Var = gh2Var4;
                    obj3 = obj;
                    z5 = z4;
                }
                ArrayList arrayList214 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var24 = new bl7();
                    bl7Var24.put(obj3, str3);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking local cache", null, xs7.R(bl7Var24));
                    break;
                }
                e0Var3.I = str3;
                e0Var3.J = uri2;
                e0Var3.K = instant2;
                e0Var3.L = str4;
                e0Var3.M = str10;
                e0Var3.N = str11;
                e0Var3.O = str12;
                e0Var3.R = j3;
                z6 = z5;
                e0Var3.S = z6;
                e0Var3.V = 4;
                p6fVar2 = p6fVar;
                objA = p6fVar2.a(str12, e0Var3);
                gh2Var2 = gh2Var;
                if (objA != gh2Var2) {
                    str13 = str12;
                    p6fVar3 = p6fVar2;
                    str14 = str10;
                    str15 = str11;
                    j4 = j3;
                    e7fVar = (e7f) objA;
                    ArrayList arrayList215 = com.gingerlabs.notability.core.common.logging.a.a;
                    str16 = str15;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var25 = new bl7();
                        bl7Var25.put(obj3, str3);
                        str18 = str14;
                        str17 = str4;
                        bl7Var25.put("cache.hit", Boolean.valueOf(e7fVar instanceof d7f));
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Local cache result", null, xs7.R(bl7Var25));
                        break;
                    } else {
                        str17 = str4;
                        str18 = str14;
                    }
                    if (!(e7fVar instanceof d7f)) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList111113 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var11110 = new bl7();
                                bl7Var11110.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var11110));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList111114 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var11111 = new bl7();
                                        bl7Var11111.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var11111));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str4119 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str4119;
                                String str41110 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j110 = j4;
                                uri3 = uri2;
                                str23 = str41110;
                                j5 = j110;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str41111 = str3;
                            String str41112 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str41111;
                            r7fVar = r7fVar5;
                            str23 = str41112;
                        }
                        ArrayList arrayList111115 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var11 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var11112 = new bl7();
                            bl7Var11112.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var11112));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList111116 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var11113 = new bl7();
                            bl7Var11113.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var11113));
                            break;
                        }
                        g0 g0Var7 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var7, e0Var3);
                        gh2Var3 = gh2Var11;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList111117 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var11114 = new bl7();
                                    bl7Var11114.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var11114.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var11114));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList111118 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList111119 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList1111110 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var10 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var10;
                            str37 = str34;
                            f0 f0Var7 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var7, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    qVarA = ((d7f) e7fVar).a();
                    if (qVarA.d() != m0.M) {
                        r7fVar5 = r7fVar5;
                        if (!z6) {
                            ArrayList arrayList1111111 = com.gingerlabs.notability.core.common.logging.a.a;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var11115 = new bl7();
                                bl7Var11115.put(obj3, str3);
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var11115));
                            }
                            e0Var3.I = str3;
                            e0Var3.J = uri2;
                            e0Var3.K = instant2;
                            str20 = str17;
                            e0Var3.L = str20;
                            str24 = str18;
                            e0Var3.M = str24;
                            e0Var3.N = str16;
                            str25 = str3;
                            str26 = str13;
                            e0Var3.O = str26;
                            e0Var3.R = j4;
                            e0Var3.S = z6;
                            z7 = z6;
                            e0Var3.V = 6;
                            aVar = this;
                            objD = aVar.d(e0Var3);
                            if (objD != gh2Var2) {
                                str27 = str26;
                                str28 = str25;
                                str29 = str24;
                                str30 = str16;
                                if (!((Boolean) objD).booleanValue()) {
                                    ArrayList arrayList1111112 = com.gingerlabs.notability.core.common.logging.a.a;
                                    jm7Var = jm7Var2;
                                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                        bl7 bl7Var11116 = new bl7();
                                        bl7Var11116.put(obj3, str28);
                                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var11116));
                                        break;
                                    }
                                    r7fVar5.a(str28, wgb.a);
                                    return new xub(new TranscriptionException.NoNetwork());
                                }
                                String str41113 = str29;
                                r7fVar = r7fVar5;
                                str21 = str30;
                                str19 = str41113;
                                String str41114 = str27;
                                str22 = str28;
                                jm7Var2 = jm7Var2;
                                long j111 = j4;
                                uri3 = uri2;
                                str23 = str41114;
                                j5 = j111;
                            }
                            break;
                        } else {
                            str19 = str18;
                            str20 = str17;
                            String str41115 = str3;
                            String str41116 = str13;
                            z7 = z6;
                            aVar = this;
                            uri3 = uri2;
                            j5 = j4;
                            str21 = str16;
                            str22 = str41115;
                            r7fVar = r7fVar5;
                            str23 = str41116;
                        }
                        ArrayList arrayList1111113 = com.gingerlabs.notability.core.common.logging.a.a;
                        gh2 gh2Var12 = gh2Var2;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var11117 = new bl7();
                            bl7Var11117.put(obj3, str22);
                            j6 = j5;
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var11117));
                            break;
                        } else {
                            j6 = j5;
                        }
                        ArrayList arrayList1111114 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var11118 = new bl7();
                            bl7Var11118.put(obj3, str22);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var11118));
                            break;
                        }
                        g0 g0Var8 = new g0(aVar, str22, str23, (ce2) null);
                        e0Var3.I = str22;
                        e0Var3.J = uri3;
                        e0Var3.K = instant2;
                        e0Var3.L = str20;
                        e0Var3.M = str19;
                        e0Var3.N = str21;
                        e0Var3.O = str23;
                        e0Var3.R = j6;
                        z8 = z7;
                        e0Var3.S = z8;
                        e0Var3.V = 7;
                        wvbVar = wvbVar4;
                        objN = me8.N(5, wvbVar, g0Var8, e0Var3);
                        gh2Var3 = gh2Var12;
                        if (objN != gh2Var3) {
                            wvbVar2 = wvbVar;
                            str31 = str23;
                            str32 = str21;
                            str33 = str19;
                            uri4 = uri3;
                            z9 = z8;
                            j7 = j6;
                            instant3 = instant2;
                            qVar = (q) objN;
                            if (qVar != null) {
                                ArrayList arrayList1111115 = com.gingerlabs.notability.core.common.logging.a.a;
                                str34 = str20;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                    bl7 bl7Var11119 = new bl7();
                                    bl7Var11119.put(obj3, str22);
                                    str35 = str33;
                                    obj4 = obj3;
                                    bl7Var11119.put("job.status", qVar.d());
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var11119));
                                } else {
                                    str35 = str33;
                                    obj4 = obj3;
                                }
                                iOrdinal = qVar.d().ordinal();
                                if (iOrdinal == 0) {
                                    ArrayList arrayList1111116 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                                } else if (iOrdinal != 1) {
                                    ArrayList arrayList1111117 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                } else {
                                    ArrayList arrayList1111118 = com.gingerlabs.notability.core.common.logging.a.a;
                                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                    e0Var3.I = null;
                                    e0Var3.J = null;
                                    e0Var3.K = null;
                                    e0Var3.L = null;
                                    e0Var3.M = null;
                                    e0Var3.N = null;
                                    e0Var3.O = null;
                                    e0Var3.P = null;
                                    e0Var3.R = j7;
                                    e0Var3.S = z9;
                                    e0Var3.V = 10;
                                    objE = aVar.e(str22, str31, e0Var3);
                                    if (objE != gh2Var3) {
                                        return objE;
                                    }
                                }
                            } else {
                                str34 = str20;
                                str35 = str33;
                                obj4 = obj3;
                            }
                            e0 e0Var11 = e0Var3;
                            str36 = str22;
                            j8 = j7;
                            r7fVar2 = r7fVar;
                            wvbVar3 = wvbVar2;
                            gh2Var4 = gh2Var3;
                            e0Var2 = e0Var11;
                            str37 = str34;
                            f0 f0Var8 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                            e0Var2.I = str36;
                            e0Var2.J = uri4;
                            e0Var2.K = null;
                            e0Var2.L = str37;
                            e0Var2.M = null;
                            e0Var2.N = null;
                            e0Var2.O = str31;
                            e0Var2.P = null;
                            e0Var2.R = j8;
                            e0Var2.S = z9;
                            e0Var2.V = 11;
                            objN2 = me8.N(6, wvbVar3, f0Var8, e0Var2);
                            if (objN2 == gh2Var4) {
                                return gh2Var4;
                            }
                            str38 = str31;
                            j9 = j8;
                            str39 = str37;
                            uri5 = uri4;
                            qVar2 = (q) objN2;
                            if (qVar2 == null) {
                                r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                                return new xub(new TranscriptionException.CreateRetriesExhausted());
                            }
                            r7fVar4 = r7fVar2;
                            i55VarE = qVar2.e();
                            if (i55VarE == null) {
                            }
                            aVar = this;
                            break;
                        }
                        return gh2Var3;
                    }
                    ArrayList arrayList216 = com.gingerlabs.notability.core.common.logging.a.a;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var124 = new bl7();
                        bl7Var124.put(obj3, str3);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Found completed transcription in local cache", null, xs7.R(bl7Var124));
                    }
                    e0Var3.I = null;
                    e0Var3.J = null;
                    e0Var3.K = null;
                    e0Var3.L = null;
                    e0Var3.M = null;
                    e0Var3.N = null;
                    e0Var3.O = null;
                    e0Var3.P = qVarA;
                    e0Var3.R = j4;
                    e0Var3.S = z6;
                    e0Var3.V = 5;
                    if (r7fVar5.f(str3, qVarA, e0Var3) != gh2Var2) {
                        return qVarA;
                    }
                    break;
                    e0Var2.I = null;
                    e0Var2.J = null;
                    e0Var2.K = null;
                    e0Var2.L = null;
                    e0Var2.M = null;
                    e0Var2.N = null;
                    e0Var2.O = null;
                    e0Var2.P = null;
                    e0Var2.Q = null;
                    e0Var2.R = j9;
                    e0Var2.S = z9;
                    e0Var2.V = 13;
                    objE2 = aVar.e(str36, str38, e0Var2);
                    if (objE2 == gh2Var4) {
                        return gh2Var4;
                    }
                    return objE2;
                }
                return gh2Var2;
            case 4:
                boolean z14 = e0Var3.S;
                long j20 = e0Var3.R;
                String str64 = e0Var3.O;
                String str65 = e0Var3.N;
                String str66 = e0Var3.M;
                String str67 = e0Var3.L;
                Instant instant6 = e0Var3.K;
                Uri uri9 = e0Var3.J;
                String str68 = e0Var3.I;
                ny7.F0(objN2);
                z6 = z14;
                str13 = str64;
                wvbVar4 = wvbVar4;
                uri2 = uri9;
                str14 = str66;
                instant2 = instant6;
                str4 = str67;
                jm7Var2 = jm7Var2;
                gh2Var2 = gh2Var4;
                obj3 = "recording.id";
                str15 = str65;
                str3 = str68;
                e0Var3 = e0Var3;
                objA = objN2;
                p6fVar3 = p6fVar4;
                j4 = j20;
                e7fVar = (e7f) objA;
                ArrayList arrayList217 = com.gingerlabs.notability.core.common.logging.a.a;
                str16 = str15;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var26 = new bl7();
                    bl7Var26.put(obj3, str3);
                    str18 = str14;
                    str17 = str4;
                    bl7Var26.put("cache.hit", Boolean.valueOf(e7fVar instanceof d7f));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Local cache result", null, xs7.R(bl7Var26));
                    break;
                } else {
                    str17 = str4;
                    str18 = str14;
                }
                if (!(e7fVar instanceof d7f)) {
                    r7fVar5 = r7fVar5;
                    if (!z6) {
                        ArrayList arrayList1111119 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var111110 = new bl7();
                            bl7Var111110.put(obj3, str3);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var111110));
                            break;
                        }
                        e0Var3.I = str3;
                        e0Var3.J = uri2;
                        e0Var3.K = instant2;
                        str20 = str17;
                        e0Var3.L = str20;
                        str24 = str18;
                        e0Var3.M = str24;
                        e0Var3.N = str16;
                        str25 = str3;
                        str26 = str13;
                        e0Var3.O = str26;
                        e0Var3.R = j4;
                        e0Var3.S = z6;
                        z7 = z6;
                        e0Var3.V = 6;
                        aVar = this;
                        objD = aVar.d(e0Var3);
                        if (objD != gh2Var2) {
                            str27 = str26;
                            str28 = str25;
                            str29 = str24;
                            str30 = str16;
                            if (!((Boolean) objD).booleanValue()) {
                                ArrayList arrayList11111110 = com.gingerlabs.notability.core.common.logging.a.a;
                                jm7Var = jm7Var2;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                    bl7 bl7Var111111 = new bl7();
                                    bl7Var111111.put(obj3, str28);
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var111111));
                                    break;
                                }
                                r7fVar5.a(str28, wgb.a);
                                return new xub(new TranscriptionException.NoNetwork());
                            }
                            String str41117 = str29;
                            r7fVar = r7fVar5;
                            str21 = str30;
                            str19 = str41117;
                            String str41118 = str27;
                            str22 = str28;
                            jm7Var2 = jm7Var2;
                            long j112 = j4;
                            uri3 = uri2;
                            str23 = str41118;
                            j5 = j112;
                        }
                        return gh2Var2;
                    }
                    str19 = str18;
                    str20 = str17;
                    String str41119 = str3;
                    String str411110 = str13;
                    z7 = z6;
                    aVar = this;
                    uri3 = uri2;
                    j5 = j4;
                    str21 = str16;
                    str22 = str41119;
                    r7fVar = r7fVar5;
                    str23 = str411110;
                    ArrayList arrayList11111111 = com.gingerlabs.notability.core.common.logging.a.a;
                    gh2 gh2Var13 = gh2Var2;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var111112 = new bl7();
                        bl7Var111112.put(obj3, str22);
                        j6 = j5;
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var111112));
                        break;
                    } else {
                        j6 = j5;
                    }
                    ArrayList arrayList11111112 = com.gingerlabs.notability.core.common.logging.a.a;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var111113 = new bl7();
                        bl7Var111113.put(obj3, str22);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var111113));
                        break;
                    }
                    g0 g0Var9 = new g0(aVar, str22, str23, (ce2) null);
                    e0Var3.I = str22;
                    e0Var3.J = uri3;
                    e0Var3.K = instant2;
                    e0Var3.L = str20;
                    e0Var3.M = str19;
                    e0Var3.N = str21;
                    e0Var3.O = str23;
                    e0Var3.R = j6;
                    z8 = z7;
                    e0Var3.S = z8;
                    e0Var3.V = 7;
                    wvbVar = wvbVar4;
                    objN = me8.N(5, wvbVar, g0Var9, e0Var3);
                    gh2Var3 = gh2Var13;
                    if (objN != gh2Var3) {
                        wvbVar2 = wvbVar;
                        str31 = str23;
                        str32 = str21;
                        str33 = str19;
                        uri4 = uri3;
                        z9 = z8;
                        j7 = j6;
                        instant3 = instant2;
                        qVar = (q) objN;
                        if (qVar != null) {
                            ArrayList arrayList11111113 = com.gingerlabs.notability.core.common.logging.a.a;
                            str34 = str20;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var111114 = new bl7();
                                bl7Var111114.put(obj3, str22);
                                str35 = str33;
                                obj4 = obj3;
                                bl7Var111114.put("job.status", qVar.d());
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var111114));
                            } else {
                                str35 = str33;
                                obj4 = obj3;
                            }
                            iOrdinal = qVar.d().ordinal();
                            if (iOrdinal == 0) {
                                ArrayList arrayList11111114 = com.gingerlabs.notability.core.common.logging.a.a;
                                com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                            } else if (iOrdinal != 1) {
                                ArrayList arrayList11111115 = com.gingerlabs.notability.core.common.logging.a.a;
                                com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                e0Var3.I = null;
                                e0Var3.J = null;
                                e0Var3.K = null;
                                e0Var3.L = null;
                                e0Var3.M = null;
                                e0Var3.N = null;
                                e0Var3.O = null;
                                e0Var3.P = null;
                                e0Var3.R = j7;
                                e0Var3.S = z9;
                                e0Var3.V = 10;
                                objE = aVar.e(str22, str31, e0Var3);
                                if (objE != gh2Var3) {
                                    return objE;
                                }
                            } else {
                                ArrayList arrayList11111116 = com.gingerlabs.notability.core.common.logging.a.a;
                                com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                e0Var3.I = null;
                                e0Var3.J = null;
                                e0Var3.K = null;
                                e0Var3.L = null;
                                e0Var3.M = null;
                                e0Var3.N = null;
                                e0Var3.O = null;
                                e0Var3.P = null;
                                e0Var3.R = j7;
                                e0Var3.S = z9;
                                e0Var3.V = 10;
                                objE = aVar.e(str22, str31, e0Var3);
                                if (objE != gh2Var3) {
                                    return objE;
                                }
                            }
                        } else {
                            str34 = str20;
                            str35 = str33;
                            obj4 = obj3;
                        }
                        e0 e0Var12 = e0Var3;
                        str36 = str22;
                        j8 = j7;
                        r7fVar2 = r7fVar;
                        wvbVar3 = wvbVar2;
                        gh2Var4 = gh2Var3;
                        e0Var2 = e0Var12;
                        str37 = str34;
                        f0 f0Var9 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                        e0Var2.I = str36;
                        e0Var2.J = uri4;
                        e0Var2.K = null;
                        e0Var2.L = str37;
                        e0Var2.M = null;
                        e0Var2.N = null;
                        e0Var2.O = str31;
                        e0Var2.P = null;
                        e0Var2.R = j8;
                        e0Var2.S = z9;
                        e0Var2.V = 11;
                        objN2 = me8.N(6, wvbVar3, f0Var9, e0Var2);
                        if (objN2 == gh2Var4) {
                            return gh2Var4;
                        }
                        str38 = str31;
                        j9 = j8;
                        str39 = str37;
                        uri5 = uri4;
                        qVar2 = (q) objN2;
                        if (qVar2 == null) {
                            r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                            return new xub(new TranscriptionException.CreateRetriesExhausted());
                        }
                        r7fVar4 = r7fVar2;
                        i55VarE = qVar2.e();
                        if (i55VarE == null) {
                        }
                        aVar = this;
                        break;
                    }
                    return gh2Var3;
                }
                qVarA = ((d7f) e7fVar).a();
                if (qVarA.d() != m0.M) {
                    r7fVar5 = r7fVar5;
                    if (!z6) {
                        ArrayList arrayList11111117 = com.gingerlabs.notability.core.common.logging.a.a;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var111115 = new bl7();
                            bl7Var111115.put(obj3, str3);
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "No network earlier, waiting for connectivity", null, xs7.R(bl7Var111115));
                        }
                        e0Var3.I = str3;
                        e0Var3.J = uri2;
                        e0Var3.K = instant2;
                        str20 = str17;
                        e0Var3.L = str20;
                        str24 = str18;
                        e0Var3.M = str24;
                        e0Var3.N = str16;
                        str25 = str3;
                        str26 = str13;
                        e0Var3.O = str26;
                        e0Var3.R = j4;
                        e0Var3.S = z6;
                        z7 = z6;
                        e0Var3.V = 6;
                        aVar = this;
                        objD = aVar.d(e0Var3);
                        if (objD != gh2Var2) {
                            str27 = str26;
                            str28 = str25;
                            str29 = str24;
                            str30 = str16;
                            if (!((Boolean) objD).booleanValue()) {
                                ArrayList arrayList11111118 = com.gingerlabs.notability.core.common.logging.a.a;
                                jm7Var = jm7Var2;
                                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                                    bl7 bl7Var111116 = new bl7();
                                    bl7Var111116.put(obj3, str28);
                                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var111116));
                                    break;
                                }
                                r7fVar5.a(str28, wgb.a);
                                return new xub(new TranscriptionException.NoNetwork());
                            }
                            String str411111 = str29;
                            r7fVar = r7fVar5;
                            str21 = str30;
                            str19 = str411111;
                            String str411112 = str27;
                            str22 = str28;
                            jm7Var2 = jm7Var2;
                            long j113 = j4;
                            uri3 = uri2;
                            str23 = str411112;
                            j5 = j113;
                        }
                        break;
                    } else {
                        str19 = str18;
                        str20 = str17;
                        String str411113 = str3;
                        String str411114 = str13;
                        z7 = z6;
                        aVar = this;
                        uri3 = uri2;
                        j5 = j4;
                        str21 = str16;
                        str22 = str411113;
                        r7fVar = r7fVar5;
                        str23 = str411114;
                    }
                    ArrayList arrayList11111119 = com.gingerlabs.notability.core.common.logging.a.a;
                    gh2 gh2Var14 = gh2Var2;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var111117 = new bl7();
                        bl7Var111117.put(obj3, str22);
                        j6 = j5;
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var111117));
                        break;
                    } else {
                        j6 = j5;
                    }
                    ArrayList arrayList111111110 = com.gingerlabs.notability.core.common.logging.a.a;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var111118 = new bl7();
                        bl7Var111118.put(obj3, str22);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var111118));
                        break;
                    }
                    g0 g0Var10 = new g0(aVar, str22, str23, (ce2) null);
                    e0Var3.I = str22;
                    e0Var3.J = uri3;
                    e0Var3.K = instant2;
                    e0Var3.L = str20;
                    e0Var3.M = str19;
                    e0Var3.N = str21;
                    e0Var3.O = str23;
                    e0Var3.R = j6;
                    z8 = z7;
                    e0Var3.S = z8;
                    e0Var3.V = 7;
                    wvbVar = wvbVar4;
                    objN = me8.N(5, wvbVar, g0Var10, e0Var3);
                    gh2Var3 = gh2Var14;
                    if (objN != gh2Var3) {
                        wvbVar2 = wvbVar;
                        str31 = str23;
                        str32 = str21;
                        str33 = str19;
                        uri4 = uri3;
                        z9 = z8;
                        j7 = j6;
                        instant3 = instant2;
                        qVar = (q) objN;
                        if (qVar != null) {
                            ArrayList arrayList111111111 = com.gingerlabs.notability.core.common.logging.a.a;
                            str34 = str20;
                            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                                bl7 bl7Var111119 = new bl7();
                                bl7Var111119.put(obj3, str22);
                                str35 = str33;
                                obj4 = obj3;
                                bl7Var111119.put("job.status", qVar.d());
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var111119));
                            } else {
                                str35 = str33;
                                obj4 = obj3;
                            }
                            iOrdinal = qVar.d().ordinal();
                            if (iOrdinal == 0) {
                                ArrayList arrayList111111112 = com.gingerlabs.notability.core.common.logging.a.a;
                                com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                            } else if (iOrdinal != 1) {
                                ArrayList arrayList111111113 = com.gingerlabs.notability.core.common.logging.a.a;
                                com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                e0Var3.I = null;
                                e0Var3.J = null;
                                e0Var3.K = null;
                                e0Var3.L = null;
                                e0Var3.M = null;
                                e0Var3.N = null;
                                e0Var3.O = null;
                                e0Var3.P = null;
                                e0Var3.R = j7;
                                e0Var3.S = z9;
                                e0Var3.V = 10;
                                objE = aVar.e(str22, str31, e0Var3);
                                if (objE != gh2Var3) {
                                    return objE;
                                }
                            } else {
                                ArrayList arrayList111111114 = com.gingerlabs.notability.core.common.logging.a.a;
                                com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                                e0Var3.I = null;
                                e0Var3.J = null;
                                e0Var3.K = null;
                                e0Var3.L = null;
                                e0Var3.M = null;
                                e0Var3.N = null;
                                e0Var3.O = null;
                                e0Var3.P = null;
                                e0Var3.R = j7;
                                e0Var3.S = z9;
                                e0Var3.V = 10;
                                objE = aVar.e(str22, str31, e0Var3);
                                if (objE != gh2Var3) {
                                    return objE;
                                }
                            }
                        } else {
                            str34 = str20;
                            str35 = str33;
                            obj4 = obj3;
                        }
                        e0 e0Var13 = e0Var3;
                        str36 = str22;
                        j8 = j7;
                        r7fVar2 = r7fVar;
                        wvbVar3 = wvbVar2;
                        gh2Var4 = gh2Var3;
                        e0Var2 = e0Var13;
                        str37 = str34;
                        f0 f0Var10 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                        e0Var2.I = str36;
                        e0Var2.J = uri4;
                        e0Var2.K = null;
                        e0Var2.L = str37;
                        e0Var2.M = null;
                        e0Var2.N = null;
                        e0Var2.O = str31;
                        e0Var2.P = null;
                        e0Var2.R = j8;
                        e0Var2.S = z9;
                        e0Var2.V = 11;
                        objN2 = me8.N(6, wvbVar3, f0Var10, e0Var2);
                        if (objN2 == gh2Var4) {
                            return gh2Var4;
                        }
                        str38 = str31;
                        j9 = j8;
                        str39 = str37;
                        uri5 = uri4;
                        qVar2 = (q) objN2;
                        if (qVar2 == null) {
                            r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                            return new xub(new TranscriptionException.CreateRetriesExhausted());
                        }
                        r7fVar4 = r7fVar2;
                        i55VarE = qVar2.e();
                        if (i55VarE == null) {
                        }
                        aVar = this;
                        break;
                    }
                    return gh2Var3;
                }
                ArrayList arrayList218 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var125 = new bl7();
                    bl7Var125.put(obj3, str3);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Found completed transcription in local cache", null, xs7.R(bl7Var125));
                }
                e0Var3.I = null;
                e0Var3.J = null;
                e0Var3.K = null;
                e0Var3.L = null;
                e0Var3.M = null;
                e0Var3.N = null;
                e0Var3.O = null;
                e0Var3.P = qVarA;
                e0Var3.R = j4;
                e0Var3.S = z6;
                e0Var3.V = 5;
                if (r7fVar5.f(str3, qVarA, e0Var3) != gh2Var2) {
                    return qVarA;
                }
                break;
                return gh2Var2;
                e0Var2.I = null;
                e0Var2.J = null;
                e0Var2.K = null;
                e0Var2.L = null;
                e0Var2.M = null;
                e0Var2.N = null;
                e0Var2.O = null;
                e0Var2.P = null;
                e0Var2.Q = null;
                e0Var2.R = j9;
                e0Var2.S = z9;
                e0Var2.V = 13;
                objE2 = aVar.e(str36, str38, e0Var2);
                if (objE2 == gh2Var4) {
                    return gh2Var4;
                }
                return objE2;
            case 5:
                q qVar3 = e0Var3.P;
                ny7.F0(objN2);
                return qVar3;
            case 6:
                boolean z15 = e0Var3.S;
                long j21 = e0Var3.R;
                String str69 = e0Var3.O;
                String str70 = e0Var3.N;
                String str71 = e0Var3.M;
                String str72 = e0Var3.L;
                Instant instant7 = e0Var3.K;
                Uri uri10 = e0Var3.J;
                String str73 = e0Var3.I;
                ny7.F0(objN2);
                z7 = z15;
                str29 = str71;
                wvbVar4 = wvbVar4;
                instant2 = instant7;
                str20 = str72;
                jm7Var2 = jm7Var2;
                gh2Var2 = gh2Var4;
                obj3 = "recording.id";
                str30 = str70;
                str27 = str69;
                uri2 = uri10;
                str28 = str73;
                e0Var3 = e0Var3;
                objD = objN2;
                p6fVar3 = p6fVar4;
                j4 = j21;
                if (!((Boolean) objD).booleanValue()) {
                    ArrayList arrayList111111115 = com.gingerlabs.notability.core.common.logging.a.a;
                    jm7Var = jm7Var2;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                        bl7 bl7Var1111110 = new bl7();
                        bl7Var1111110.put(obj3, str28);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Network not available, returning NoNetwork error", null, xs7.R(bl7Var1111110));
                        break;
                    }
                    r7fVar5.a(str28, wgb.a);
                    return new xub(new TranscriptionException.NoNetwork());
                }
                String str411115 = str29;
                r7fVar = r7fVar5;
                str21 = str30;
                str19 = str411115;
                String str411116 = str27;
                str22 = str28;
                jm7Var2 = jm7Var2;
                long j114 = j4;
                uri3 = uri2;
                str23 = str411116;
                j5 = j114;
                ArrayList arrayList111111116 = com.gingerlabs.notability.core.common.logging.a.a;
                gh2 gh2Var15 = gh2Var2;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var1111111 = new bl7();
                    bl7Var1111111.put(obj3, str22);
                    j6 = j5;
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Network is available", null, xs7.R(bl7Var1111111));
                    break;
                } else {
                    j6 = j5;
                }
                ArrayList arrayList111111117 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                    bl7 bl7Var1111112 = new bl7();
                    bl7Var1111112.put(obj3, str22);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Checking if job exists on server", null, xs7.R(bl7Var1111112));
                    break;
                }
                g0 g0Var11 = new g0(aVar, str22, str23, (ce2) null);
                e0Var3.I = str22;
                e0Var3.J = uri3;
                e0Var3.K = instant2;
                e0Var3.L = str20;
                e0Var3.M = str19;
                e0Var3.N = str21;
                e0Var3.O = str23;
                e0Var3.R = j6;
                z8 = z7;
                e0Var3.S = z8;
                e0Var3.V = 7;
                wvbVar = wvbVar4;
                objN = me8.N(5, wvbVar, g0Var11, e0Var3);
                gh2Var3 = gh2Var15;
                if (objN != gh2Var3) {
                    wvbVar2 = wvbVar;
                    str31 = str23;
                    str32 = str21;
                    str33 = str19;
                    uri4 = uri3;
                    z9 = z8;
                    j7 = j6;
                    instant3 = instant2;
                    qVar = (q) objN;
                    if (qVar != null) {
                        ArrayList arrayList111111118 = com.gingerlabs.notability.core.common.logging.a.a;
                        str34 = str20;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                            bl7 bl7Var1111113 = new bl7();
                            bl7Var1111113.put(obj3, str22);
                            str35 = str33;
                            obj4 = obj3;
                            bl7Var1111113.put("job.status", qVar.d());
                            com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var1111113));
                        } else {
                            str35 = str33;
                            obj4 = obj3;
                        }
                        iOrdinal = qVar.d().ordinal();
                        if (iOrdinal == 0) {
                            ArrayList arrayList111111119 = com.gingerlabs.notability.core.common.logging.a.a;
                            com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                        } else if (iOrdinal != 1) {
                            ArrayList arrayList1111111110 = com.gingerlabs.notability.core.common.logging.a.a;
                            com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                            e0Var3.I = null;
                            e0Var3.J = null;
                            e0Var3.K = null;
                            e0Var3.L = null;
                            e0Var3.M = null;
                            e0Var3.N = null;
                            e0Var3.O = null;
                            e0Var3.P = null;
                            e0Var3.R = j7;
                            e0Var3.S = z9;
                            e0Var3.V = 10;
                            objE = aVar.e(str22, str31, e0Var3);
                            if (objE != gh2Var3) {
                                return objE;
                            }
                        } else {
                            ArrayList arrayList1111111111 = com.gingerlabs.notability.core.common.logging.a.a;
                            com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                            e0Var3.I = null;
                            e0Var3.J = null;
                            e0Var3.K = null;
                            e0Var3.L = null;
                            e0Var3.M = null;
                            e0Var3.N = null;
                            e0Var3.O = null;
                            e0Var3.P = null;
                            e0Var3.R = j7;
                            e0Var3.S = z9;
                            e0Var3.V = 10;
                            objE = aVar.e(str22, str31, e0Var3);
                            if (objE != gh2Var3) {
                                return objE;
                            }
                        }
                        break;
                    } else {
                        str34 = str20;
                        str35 = str33;
                        obj4 = obj3;
                    }
                    e0 e0Var14 = e0Var3;
                    str36 = str22;
                    j8 = j7;
                    r7fVar2 = r7fVar;
                    wvbVar3 = wvbVar2;
                    gh2Var4 = gh2Var3;
                    e0Var2 = e0Var14;
                    str37 = str34;
                    f0 f0Var11 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                    e0Var2.I = str36;
                    e0Var2.J = uri4;
                    e0Var2.K = null;
                    e0Var2.L = str37;
                    e0Var2.M = null;
                    e0Var2.N = null;
                    e0Var2.O = str31;
                    e0Var2.P = null;
                    e0Var2.R = j8;
                    e0Var2.S = z9;
                    e0Var2.V = 11;
                    objN2 = me8.N(6, wvbVar3, f0Var11, e0Var2);
                    if (objN2 == gh2Var4) {
                        return gh2Var4;
                    }
                    str38 = str31;
                    j9 = j8;
                    str39 = str37;
                    uri5 = uri4;
                    qVar2 = (q) objN2;
                    if (qVar2 == null) {
                        r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                        return new xub(new TranscriptionException.CreateRetriesExhausted());
                    }
                    r7fVar4 = r7fVar2;
                    i55VarE = qVar2.e();
                    if (i55VarE == null) {
                        break;
                    }
                    aVar = this;
                    e0Var2.I = null;
                    e0Var2.J = null;
                    e0Var2.K = null;
                    e0Var2.L = null;
                    e0Var2.M = null;
                    e0Var2.N = null;
                    e0Var2.O = null;
                    e0Var2.P = null;
                    e0Var2.Q = null;
                    e0Var2.R = j9;
                    e0Var2.S = z9;
                    e0Var2.V = 13;
                    objE2 = aVar.e(str36, str38, e0Var2);
                    if (objE2 == gh2Var4) {
                        return gh2Var4;
                    }
                    return objE2;
                }
                return gh2Var3;
            case 7:
                boolean z16 = e0Var3.S;
                long j22 = e0Var3.R;
                str31 = e0Var3.O;
                String str74 = e0Var3.N;
                String str75 = e0Var3.M;
                String str76 = e0Var3.L;
                Instant instant8 = e0Var3.K;
                Uri uri11 = e0Var3.J;
                String str77 = e0Var3.I;
                ny7.F0(objN2);
                wvbVar2 = wvbVar4;
                r7fVar = r7fVar5;
                z9 = z16;
                e0Var3 = e0Var3;
                str20 = str76;
                jm7Var2 = jm7Var2;
                j7 = j22;
                gh2Var3 = gh2Var4;
                str22 = str77;
                obj3 = "recording.id";
                objN = objN2;
                uri4 = uri11;
                p6fVar3 = p6fVar4;
                str33 = str75;
                instant3 = instant8;
                str32 = str74;
                qVar = (q) objN;
                if (qVar != null) {
                    ArrayList arrayList1111111112 = com.gingerlabs.notability.core.common.logging.a.a;
                    str34 = str20;
                    if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var3, cl7Var)) {
                        bl7 bl7Var1111114 = new bl7();
                        bl7Var1111114.put(obj3, str22);
                        str35 = str33;
                        obj4 = obj3;
                        bl7Var1111114.put("job.status", qVar.d());
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var3, cl7Var, "Existing job found", null, xs7.R(bl7Var1111114));
                    } else {
                        str35 = str33;
                        obj4 = obj3;
                    }
                    iOrdinal = qVar.d().ordinal();
                    if (iOrdinal == 0) {
                        if (iOrdinal != 1) {
                            ArrayList arrayList1111111113 = com.gingerlabs.notability.core.common.logging.a.a;
                            com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                            e0Var3.I = null;
                            e0Var3.J = null;
                            e0Var3.K = null;
                            e0Var3.L = null;
                            e0Var3.M = null;
                            e0Var3.N = null;
                            e0Var3.O = null;
                            e0Var3.P = null;
                            e0Var3.R = j7;
                            e0Var3.S = z9;
                            e0Var3.V = 10;
                            objE = aVar.e(str22, str31, e0Var3);
                            if (objE != gh2Var3) {
                                return objE;
                            }
                        } else {
                            ArrayList arrayList1111111114 = com.gingerlabs.notability.core.common.logging.a.a;
                            com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is being processed, polling for completion");
                            e0Var3.I = null;
                            e0Var3.J = null;
                            e0Var3.K = null;
                            e0Var3.L = null;
                            e0Var3.M = null;
                            e0Var3.N = null;
                            e0Var3.O = null;
                            e0Var3.P = null;
                            e0Var3.R = j7;
                            e0Var3.S = z9;
                            e0Var3.V = 10;
                            objE = aVar.e(str22, str31, e0Var3);
                            if (objE != gh2Var3) {
                                return objE;
                            }
                        }
                        return gh2Var3;
                    }
                    ArrayList arrayList1111111115 = com.gingerlabs.notability.core.common.logging.a.a;
                    com.gingerlabs.notability.core.common.logging.a.d(jm7Var3, cl7Var, "Existing job is in UPLOADING state, need to re-create to get upload policy");
                    break;
                } else {
                    str34 = str20;
                    str35 = str33;
                    obj4 = obj3;
                }
                e0 e0Var15 = e0Var3;
                str36 = str22;
                j8 = j7;
                r7fVar2 = r7fVar;
                wvbVar3 = wvbVar2;
                gh2Var4 = gh2Var3;
                e0Var2 = e0Var15;
                str37 = str34;
                f0 f0Var12 = new f0(aVar, str36, str31, instant3, j8, str37, str35, str32, null);
                e0Var2.I = str36;
                e0Var2.J = uri4;
                e0Var2.K = null;
                e0Var2.L = str37;
                e0Var2.M = null;
                e0Var2.N = null;
                e0Var2.O = str31;
                e0Var2.P = null;
                e0Var2.R = j8;
                e0Var2.S = z9;
                e0Var2.V = 11;
                objN2 = me8.N(6, wvbVar3, f0Var12, e0Var2);
                if (objN2 == gh2Var4) {
                    return gh2Var4;
                }
                str38 = str31;
                j9 = j8;
                str39 = str37;
                uri5 = uri4;
                qVar2 = (q) objN2;
                if (qVar2 == null) {
                    r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                    return new xub(new TranscriptionException.CreateRetriesExhausted());
                }
                r7fVar4 = r7fVar2;
                i55VarE = qVar2.e();
                if (i55VarE == null) {
                    break;
                }
                aVar = this;
                e0Var2.I = null;
                e0Var2.J = null;
                e0Var2.K = null;
                e0Var2.L = null;
                e0Var2.M = null;
                e0Var2.N = null;
                e0Var2.O = null;
                e0Var2.P = null;
                e0Var2.Q = null;
                e0Var2.R = j9;
                e0Var2.S = z9;
                e0Var2.V = 13;
                objE2 = aVar.e(str36, str38, e0Var2);
                if (objE2 == gh2Var4) {
                    return gh2Var4;
                }
                return objE2;
            case 8:
                z10 = e0Var3.S;
                long j23 = e0Var3.R;
                q qVar4 = e0Var3.P;
                str22 = e0Var3.I;
                ny7.F0(objN2);
                j7 = j23;
                qVar = qVar4;
                e0Var3 = e0Var3;
                gh2Var3 = gh2Var4;
                r8 = 0;
                r7fVar3 = r7fVar5;
                e0Var3.I = r8;
                e0Var3.J = r8;
                e0Var3.K = r8;
                e0Var3.L = r8;
                e0Var3.M = r8;
                e0Var3.N = r8;
                e0Var3.O = r8;
                e0Var3.P = qVar;
                e0Var3.R = j7;
                e0Var3.S = z10;
                e0Var3.V = 9;
                if (r7fVar3.f(str22, qVar, e0Var3) != gh2Var3) {
                    return qVar;
                }
                return gh2Var3;
            case 9:
                q qVar5 = e0Var3.P;
                ny7.F0(objN2);
                return qVar5;
            case 10:
                ny7.F0(objN2);
                return ((yub) objN2).I;
            case 11:
                boolean z17 = e0Var3.S;
                j9 = e0Var3.R;
                String str78 = e0Var3.O;
                str39 = e0Var3.L;
                Uri uri12 = e0Var3.J;
                String str79 = e0Var3.I;
                ny7.F0(objN2);
                r7fVar2 = r7fVar5;
                obj4 = "recording.id";
                z9 = z17;
                e0Var2 = e0Var3;
                wvbVar3 = wvbVar4;
                str36 = str79;
                str38 = str78;
                uri5 = uri12;
                qVar2 = (q) objN2;
                if (qVar2 == null) {
                    r7fVar2.b(str36, new s6f("Job creation failed after 6 attempts", false, null, 12));
                    return new xub(new TranscriptionException.CreateRetriesExhausted());
                }
                r7fVar4 = r7fVar2;
                i55VarE = qVar2.e();
                if (i55VarE == null) {
                    break;
                }
                aVar = this;
                e0Var2.I = null;
                e0Var2.J = null;
                e0Var2.K = null;
                e0Var2.L = null;
                e0Var2.M = null;
                e0Var2.N = null;
                e0Var2.O = null;
                e0Var2.P = null;
                e0Var2.Q = null;
                e0Var2.R = j9;
                e0Var2.S = z9;
                e0Var2.V = 13;
                objE2 = aVar.e(str36, str38, e0Var2);
                if (objE2 == gh2Var4) {
                    return gh2Var4;
                }
                return objE2;
            case 12:
                z11 = e0Var3.S;
                j9 = e0Var3.R;
                fjbVar = e0Var3.Q;
                str41 = e0Var3.O;
                str42 = e0Var3.I;
                ny7.F0(objN2);
                e0Var2 = e0Var3;
                r7fVar4 = r7fVar5;
                if (((bjf) objN2) == null) {
                    th = (Throwable) fjbVar.I;
                    if (th != null) {
                        s6f s6fVarC2 = c(th);
                        th2 = (Throwable) fjbVar.I;
                        if (th2 != null) {
                            message = th2.getMessage();
                        } else {
                            message = null;
                        }
                        s6fVar = s6f.a(s6fVarC2, "Upload failed after 6 attempts: " + message, 12);
                    } else {
                        s6fVar = new s6f("Upload failed after 6 attempts", false, null, 12);
                    }
                    r7fVar4.b(str42, s6fVar);
                    return new xub(new TranscriptionException.UploadRetriesExhausted());
                }
                z9 = z11;
                str38 = str41;
                str36 = str42;
                e0Var2.I = null;
                e0Var2.J = null;
                e0Var2.K = null;
                e0Var2.L = null;
                e0Var2.M = null;
                e0Var2.N = null;
                e0Var2.O = null;
                e0Var2.P = null;
                e0Var2.Q = null;
                e0Var2.R = j9;
                e0Var2.S = z9;
                e0Var2.V = 13;
                objE2 = aVar.e(str36, str38, e0Var2);
                if (objE2 == gh2Var4) {
                    return gh2Var4;
                }
                return objE2;
            case 13:
                ny7.F0(objN2);
                return ((yub) objN2).I;
            default:
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
        }
    }

    /* JADX WARN: Code duplicated, block: B:7:0x001f  */
    public final Object h(String str, Uri uri, long j, String str2, de2 de2Var) throws Throwable {
        i0 i0Var;
        Object objC;
        String str3;
        String str4;
        if (de2Var instanceof i0) {
            i0Var = (i0) de2Var;
            int i = i0Var.L;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                i0Var.L = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                i0Var = new i0(this, de2Var);
            }
        } else {
            i0Var = new i0(this, de2Var);
        }
        Object obj = i0Var.J;
        int i2 = i0Var.L;
        r7f r7fVar = this.d;
        if (i2 == 0) {
            ny7.F0(obj);
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            jm7 jm7Var = jm7.I;
            cl7 cl7Var = cl7.RECORDING;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var = new bl7();
                    bl7Var.put("recording.id", str);
                    bl7Var.put("uri", uri);
                    bl7Var.put("duration.ms", new Long(j));
                    bl7Var.put("extension", str2);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "validateRecording", null, xs7.R(bl7Var));
                } catch (Exception e) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "validateRecording", e);
                }
            }
            ArrayList arrayList2 = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var2 = new bl7();
                    bl7Var2.put("allowed.extensions", f6f.a());
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "validateRecording: allowed extensions", null, xs7.R(bl7Var2));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "validateRecording: allowed extensions", e2);
                }
            }
            if (j < 3000) {
                ArrayList arrayList3 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                    try {
                        bl7 bl7Var3 = new bl7();
                        bl7Var3.put("duration.ms", new Long(j));
                        bl7Var3.put("min.duration.ms", new Long(3000L));
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "validateRecording: BLOCKED - duration too short", null, xs7.R(bl7Var3));
                    } catch (Exception e3) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "validateRecording: BLOCKED - duration too short", e3);
                    }
                }
                ahb ahbVar = ahb.a;
                r7fVar.a(str, ahbVar);
                return ahbVar;
            }
            if (j > 10800000) {
                ArrayList arrayList4 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                    try {
                        bl7 bl7Var4 = new bl7();
                        bl7Var4.put("duration.ms", new Long(j));
                        bl7Var4.put("max.duration.ms", new Long(10800000L));
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "validateRecording: BLOCKED - duration too long", null, xs7.R(bl7Var4));
                    } catch (Exception e4) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "validateRecording: BLOCKED - duration too long", e4);
                    }
                }
                zgb zgbVar = zgb.a;
                r7fVar.a(str, zgbVar);
                return zgbVar;
            }
            String lowerCase = str2.toLowerCase(Locale.ROOT);
            lowerCase.getClass();
            boolean zContains = f6f.a().contains(lowerCase);
            ArrayList arrayList5 = com.gingerlabs.notability.core.common.logging.a.a;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var5 = new bl7();
                    bl7Var5.put("extension", lowerCase);
                    bl7Var5.put("extension.valid", Boolean.valueOf(zContains));
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "validateRecording: extension check", null, xs7.R(bl7Var5));
                } catch (Exception e5) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "validateRecording: extension check", e5);
                }
            }
            if (!zContains) {
                ugb ugbVar = new ugb(str2);
                ArrayList arrayList6 = com.gingerlabs.notability.core.common.logging.a.a;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                    try {
                        bl7 bl7Var6 = new bl7();
                        bl7Var6.put("extension", str2);
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "validateRecording: BLOCKED - invalid file format", null, xs7.R(bl7Var6));
                    } catch (Exception e6) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "validateRecording: BLOCKED - invalid file format", e6);
                    }
                }
                r7fVar.a(str, ugbVar);
                return ugbVar;
            }
            i0Var.I = str;
            i0Var.L = 1;
            objC = this.c.c(uri, i0Var);
            gh2 gh2Var = gh2.I;
            if (objC == gh2Var) {
                return gh2Var;
            }
            str3 = str;
        } else {
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            str3 = i0Var.I;
            ny7.F0(obj);
            objC = ((yub) obj).I;
        }
        if (objC instanceof xub) {
            tgb tgbVar = tgb.a;
            r7fVar.a(str3, tgbVar);
            return tgbVar;
        }
        ny7.F0(objC);
        long jLongValue = ((Number) objC).longValue();
        if (jLongValue <= 100000000) {
            return null;
        }
        if (jLongValue >= 1000000000) {
            str4 = String.format("%.1f GB", Arrays.copyOf(new Object[]{Double.valueOf(jLongValue / 1.0E9d)}, 1));
        } else if (jLongValue >= 1000000) {
            str4 = String.format("%.1f MB", Arrays.copyOf(new Object[]{Double.valueOf(jLongValue / 1000000.0d)}, 1));
        } else if (jLongValue >= 1000) {
            str4 = String.format("%.1f KB", Arrays.copyOf(new Object[]{Double.valueOf(jLongValue / 1000.0d)}, 1));
        } else {
            str4 = jLongValue + " B";
        }
        ygb ygbVar = new ygb(str4);
        r7fVar.a(str3, ygbVar);
        return ygbVar;
    }
}
