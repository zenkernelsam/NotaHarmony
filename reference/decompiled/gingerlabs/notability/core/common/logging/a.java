package com.gingerlabs.notability.core.common.logging;

import defpackage.bl7;
import defpackage.cl7;
import defpackage.g82;
import defpackage.iof;
import defpackage.jm7;
import defpackage.km7;
import defpackage.ny7;
import defpackage.ov4;
import defpackage.qz3;
import defpackage.sz3;
import defpackage.x41;
import defpackage.xs7;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;

/* JADX INFO: loaded from: classes.dex */
public final class a {
    public static final ArrayList a;
    public static final ArrayList b;

    static {
        ny7.l0(g82.b);
        ArrayList arrayListO0 = ny7.o0(g82.c);
        a = arrayListO0;
        b = arrayListO0;
    }

    public static boolean a(jm7 jm7Var, cl7 cl7Var) {
        cl7Var.getClass();
        ArrayList arrayList = b;
        int size = arrayList.size();
        for (int i = 0; i < size; i++) {
            if (((km7) arrayList.get(i)).a(jm7Var, cl7Var)) {
                return true;
            }
        }
        return false;
    }

    public static void b(cl7 cl7Var, String str, ov4 ov4Var) {
        cl7Var.getClass();
        c(cl7Var, str, null, ov4Var);
    }

    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r5v0, types: [java.lang.Exception, java.lang.Throwable] */
    /* JADX WARN: Type inference failed for: r5v2, types: [java.lang.Throwable] */
    /* JADX WARN: Type inference failed for: r5v3, types: [java.lang.Throwable] */
    /* JADX WARN: Type inference failed for: r5v4 */
    /* JADX WARN: Type inference failed for: r5v5, types: [java.lang.Throwable] */
    /* JADX WARN: Type inference failed for: r6v0, types: [ov4] */
    public static void c(cl7 cl7Var, String str, Exception exc, ov4 ov4Var) {
        Throwable nbLog$FatalLogError;
        String message;
        jm7 jm7Var = jm7.N;
        cl7Var.getClass();
        try {
            qz3 qz3Var = new qz3();
            if (ov4Var != 0) {
                ov4Var.invoke(qz3Var);
            }
            sz3 sz3VarB = qz3Var.b();
            Map map = sz3VarB.b;
            if (str == null) {
                message = exc != 0 ? exc.getMessage() : null;
                if (message == null) {
                    message = "FATAL ERROR";
                }
            } else {
                message = str;
            }
            if (exc == 0) {
                exc = sz3VarB.a;
            }
            nbLog$FatalLogError = exc != 0 ? new NbLog$FatalLogError((Throwable) exc) : new NbLog$FatalLogError(message);
            if (exc == 0) {
                exc = nbLog$FatalLogError;
            }
            e(jm7Var, cl7Var, message, exc, map);
        } catch (Exception e) {
            bl7 bl7Var = new bl7();
            bl7Var.put("original.message", str);
            e(jm7Var, cl7Var, "Failed to build log event", e, xs7.R(bl7Var));
            nbLog$FatalLogError = e;
        }
        if (x41.a()) {
            throw nbLog$FatalLogError;
        }
    }

    public static void d(jm7 jm7Var, cl7 cl7Var, String str) {
        if (a(jm7Var, cl7Var)) {
            e(jm7Var, cl7Var, str, null, null);
        }
    }

    public static void e(jm7 jm7Var, cl7 cl7Var, String str, Throwable th, Map map) {
        cl7Var.getClass();
        str.getClass();
        ArrayList arrayList = b;
        int size = arrayList.size();
        int i = 0;
        while (i < size) {
            km7 km7Var = (km7) arrayList.get(i);
            jm7 jm7Var2 = jm7Var;
            cl7 cl7Var2 = cl7Var;
            String str2 = str;
            Throwable th2 = th;
            Map map2 = map;
            if (km7Var.a(jm7Var, cl7Var)) {
                km7Var.c(jm7Var2, cl7Var2, str2, th2, map2);
            }
            i++;
            jm7Var = jm7Var2;
            cl7Var = cl7Var2;
            str = str2;
            th = th2;
            map = map2;
        }
    }

    public static void f(Object obj, String str) {
        str.getClass();
        jm7 jm7Var = jm7.J;
        cl7 cl7Var = cl7.APP;
        if (a(jm7Var, cl7Var)) {
            ArrayList arrayList = b;
            int size = arrayList.size();
            for (int i = 0; i < size; i++) {
                km7 km7Var = (km7) arrayList.get(i);
                if (km7Var.a(jm7Var, cl7Var)) {
                    km7Var.d(obj, str);
                }
            }
        }
    }

    public static void g(cl7 cl7Var, String str, Exception exc) {
        cl7Var.getClass();
        str.getClass();
        bl7 bl7Var = new bl7();
        bl7Var.put("original.message", str);
        e(jm7.M, cl7Var, "Failed to build log event", exc, xs7.R(bl7Var));
    }

    public static void h(iof iofVar) {
        Iterator it = a.iterator();
        while (it.hasNext()) {
            ((km7) it.next()).b(iofVar);
        }
    }

    public static void i(cl7 cl7Var, String str) {
        cl7Var.getClass();
        d(jm7.L, cl7Var, str);
    }
}
