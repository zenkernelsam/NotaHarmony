package com.gingerlabs.notability.ui.support.data;

import defpackage.nu7;
import defpackage.tqd;
import java.util.List;

/* JADX INFO: loaded from: classes2.dex */
public abstract class g {
    public static h a(String str, String str2, String str3, String str4, String str5, String str6, String str7, List list) {
        str.getClass();
        str2.getClass();
        str3.getClass();
        str4.getClass();
        str6.getClass();
        str7.getClass();
        list.getClass();
        c cVar = new c(str2 + "\n\n----\n\n" + str3 + "\nProduct type: Android\nSupport Source: help", list);
        if (str5 == null) {
            str5 = tqd.Z0(str4, "@");
        }
        f fVar = new f(str5, str4);
        nu7 nu7Var = new nu7();
        nu7Var.put("360034791432", str6);
        nu7Var.put("1260826780729", str7);
        return new h(new e(str, cVar, fVar, nu7Var.b()));
    }
}
