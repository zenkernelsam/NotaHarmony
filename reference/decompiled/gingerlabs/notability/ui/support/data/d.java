package com.gingerlabs.notability.ui.support.data;

import androidx.recyclerview.widget.RecyclerView;
import defpackage.bjf;
import defpackage.bl7;
import defpackage.cl7;
import defpackage.de2;
import defpackage.dub;
import defpackage.gh2;
import defpackage.jm7;
import defpackage.nvb;
import defpackage.ny7;
import defpackage.t8g;
import defpackage.u8g;
import defpackage.v8g;
import defpackage.w8g;
import defpackage.x8g;
import defpackage.xs7;
import defpackage.xub;
import defpackage.yub;
import defpackage.yz3;
import defpackage.ztb;
import java.io.IOException;
import java.io.InputStream;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import retrofit2.HttpException;

/* JADX INFO: loaded from: classes2.dex */
public final class d {
    public final a a;

    public d(nvb nvbVar) {
        this.a = (a) nvbVar.b(a.class);
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    public final Object a(String str, String str2, String str3, String str4, String str5, String str6, String str7, List list, de2 de2Var) {
        u8g u8gVar;
        Object xubVar;
        ztb ztbVar;
        dub dubVar;
        if (de2Var instanceof u8g) {
            u8gVar = (u8g) de2Var;
            int i = u8gVar.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                u8gVar.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                u8gVar = new u8g(this, de2Var);
            }
        } else {
            u8gVar = new u8g(this, de2Var);
        }
        Object objC = u8gVar.I;
        int i2 = u8gVar.K;
        String strU = null;
        try {
            if (i2 == 0) {
                ny7.F0(objC);
                h hVarA = g.a(str, str2, str3, str4, str5, str6, str7, list);
                a aVar = this.a;
                u8gVar.K = 1;
                objC = aVar.c(hVarA, u8gVar);
                gh2 gh2Var = gh2.I;
                if (objC == gh2Var) {
                    return gh2Var;
                }
            } else {
                if (i2 != 1) {
                    yz3.l("call to 'resume' before 'invoke' with coroutine");
                    return null;
                }
                ny7.F0(objC);
            }
            i iVar = (i) objC;
            String error = iVar.getError();
            if (error != null && error.length() != 0) {
                String description = iVar.getDescription();
                if (description == null) {
                    description = iVar.getError();
                }
                description.getClass();
                throw new ZendeskApiException(description);
            }
            xubVar = bjf.a;
        } catch (Exception e) {
            if (!(e instanceof IOException) && !(e instanceof HttpException) && !(e instanceof ZendeskApiException)) {
                throw e;
            }
            xubVar = new xub(e);
        }
        Throwable thA = yub.a(xubVar);
        if (thA != null) {
            HttpException httpException = thA instanceof HttpException ? (HttpException) thA : null;
            if (httpException != null && (ztbVar = httpException.J) != null && (dubVar = ztbVar.c) != null) {
                strU = dubVar.u();
            }
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            jm7 jm7Var = jm7.L;
            cl7 cl7Var = cl7.NETWORK;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    bl7 bl7Var = new bl7();
                    bl7Var.put("errorBody", strU);
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Failed to create ticket", thA, xs7.R(bl7Var));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Failed to create ticket", e2);
                }
            }
        }
        return xubVar;
    }

    /* JADX WARN: Code duplicated, block: B:8:0x0014  */
    public final Object b(de2 de2Var) {
        v8g v8gVar;
        Object xubVar;
        if (de2Var instanceof v8g) {
            v8gVar = (v8g) de2Var;
            int i = v8gVar.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                v8gVar.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                v8gVar = new v8g(this, de2Var);
            }
        } else {
            v8gVar = new v8g(this, de2Var);
        }
        v8g v8gVar2 = v8gVar;
        Object objB = v8gVar2.I;
        int i2 = v8gVar2.K;
        try {
            if (i2 == 0) {
                ny7.F0(objB);
                a aVar = this.a;
                v8gVar2.K = 1;
                objB = aVar.b("200815918", 20, "created_at", "2019-10-12", v8gVar2);
                gh2 gh2Var = gh2.I;
                if (objB == gh2Var) {
                    return gh2Var;
                }
            } else {
                if (i2 != 1) {
                    yz3.l("call to 'resume' before 'invoke' with coroutine");
                    return null;
                }
                ny7.F0(objB);
            }
            xubVar = ((b) objB).getResults();
        } catch (Exception e) {
            if (!(e instanceof IOException) && !(e instanceof HttpException) && !(e instanceof ZendeskApiException)) {
                throw e;
            }
            xubVar = new xub(e);
        }
        Throwable thA = yub.a(xubVar);
        if (thA != null) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            jm7 jm7Var = jm7.L;
            cl7 cl7Var = cl7.NETWORK;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Failed to fetch latest updates", thA, xs7.R(new bl7()));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Failed to fetch latest updates", e2);
                }
            }
        }
        return xubVar;
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    public final Object c(String str, de2 de2Var) {
        w8g w8gVar;
        Object xubVar;
        if (de2Var instanceof w8g) {
            w8gVar = (w8g) de2Var;
            int i = w8gVar.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                w8gVar.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                w8gVar = new w8g(this, de2Var);
            }
        } else {
            w8gVar = new w8g(this, de2Var);
        }
        Object objA = w8gVar.I;
        int i2 = w8gVar.K;
        try {
            if (i2 == 0) {
                ny7.F0(objA);
                a aVar = this.a;
                w8gVar.K = 1;
                objA = aVar.a(str, 8, w8gVar);
                gh2 gh2Var = gh2.I;
                if (objA == gh2Var) {
                    return gh2Var;
                }
            } else {
                if (i2 != 1) {
                    yz3.l("call to 'resume' before 'invoke' with coroutine");
                    return null;
                }
                ny7.F0(objA);
            }
            xubVar = ((b) objA).getResults();
        } catch (Exception e) {
            if (!(e instanceof IOException) && !(e instanceof HttpException) && !(e instanceof ZendeskApiException)) {
                throw e;
            }
            xubVar = new xub(e);
        }
        Throwable thA = yub.a(xubVar);
        if (thA != null) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            jm7 jm7Var = jm7.L;
            cl7 cl7Var = cl7.NETWORK;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Failed to search articles", thA, xs7.R(new bl7()));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Failed to search articles", e2);
                }
            }
        }
        return xubVar;
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    public final Serializable d(String str, InputStream inputStream, long j, de2 de2Var) {
        x8g x8gVar;
        Serializable xubVar;
        if (de2Var instanceof x8g) {
            x8gVar = (x8g) de2Var;
            int i = x8gVar.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                x8gVar.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                x8gVar = new x8g(this, de2Var);
            }
        } else {
            x8gVar = new x8g(this, de2Var);
        }
        Object objD = x8gVar.I;
        int i2 = x8gVar.K;
        try {
            if (i2 == 0) {
                ny7.F0(objD);
                t8g t8gVar = new t8g(j, inputStream);
                a aVar = this.a;
                x8gVar.K = 1;
                objD = aVar.d(str, "application/binary", t8gVar, x8gVar);
                gh2 gh2Var = gh2.I;
                if (objD == gh2Var) {
                    return gh2Var;
                }
            } else {
                if (i2 != 1) {
                    yz3.l("call to 'resume' before 'invoke' with coroutine");
                    return null;
                }
                ny7.F0(objD);
            }
            xubVar = ((k) objD).getUpload().getToken();
        } catch (Exception e) {
            if (!(e instanceof IOException) && !(e instanceof HttpException) && !(e instanceof ZendeskApiException)) {
                throw e;
            }
            xubVar = new xub(e);
        }
        Throwable thA = yub.a(xubVar);
        if (thA != null) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            jm7 jm7Var = jm7.L;
            cl7 cl7Var = cl7.NETWORK;
            if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                try {
                    com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Failed to upload attachment", thA, xs7.R(new bl7()));
                } catch (Exception e2) {
                    com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Failed to upload attachment", e2);
                }
            }
        }
        return xubVar;
    }
}
