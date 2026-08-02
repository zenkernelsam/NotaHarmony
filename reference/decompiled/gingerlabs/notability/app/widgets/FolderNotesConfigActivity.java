package com.gingerlabs.notability.app.widgets;

import android.content.Context;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.app.NbApplication;
import com.google.android.gms.fido.fido2.api.common.UserVerificationMethods;
import defpackage.av3;
import defpackage.ay4;
import defpackage.bp;
import defpackage.bx1;
import defpackage.ci8;
import defpackage.gb0;
import defpackage.ha8;
import defpackage.hb0;
import defpackage.ich;
import defpackage.in3;
import defpackage.j0g;
import defpackage.j1c;
import defpackage.jof;
import defpackage.ka8;
import defpackage.kad;
import defpackage.kqi;
import defpackage.lmi;
import defpackage.ny7;
import defpackage.oo4;
import defpackage.ov4;
import defpackage.pu;
import defpackage.q32;
import defpackage.rbh;
import defpackage.ro4;
import defpackage.ru3;
import defpackage.s30;
import defpackage.s32;
import defpackage.sh2;
import defpackage.so4;
import defpackage.t97;
import defpackage.tni;
import defpackage.to4;
import defpackage.tqd;
import defpackage.uo4;
import defpackage.we7;
import defpackage.xdb;
import defpackage.xi7;
import defpackage.yg;
import defpackage.zs1;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import kotlin.Metadata;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000$\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\"\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u000b²\u0006\u000e\u0010\u0005\u001a\u0004\u0018\u00010\u00048\nX\u008a\u0084\u0002²\u0006\u000e\u0010\u0007\u001a\u00020\u00068\n@\nX\u008a\u008e\u0002²\u0006\u0014\u0010\n\u001a\b\u0012\u0004\u0012\u00020\t0\b8\n@\nX\u008a\u008e\u0002"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/FolderNotesConfigActivity;", "Lj0g;", "<init>", "()V", "Lt97;", "loaded", "", "query", "", "Loo4;", "expandedFolderIds", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class FolderNotesConfigActivity extends j0g {
    public static final /* synthetic */ int L = 0;
    public final int K = R.string.app_widgets__widget_folder_picker_login_required;

    /* JADX WARN: Multi-variable type inference failed */
    @Override // defpackage.j0g
    public final void g(bx1 bx1Var, NbApplication nbApplication, ov4 ov4Var, s32 s32Var, int i) {
        ay4 ay4Var;
        uo4 uo4Var;
        uo4 uo4Var2;
        Collection collectionValues;
        int i2;
        bx1Var.getClass();
        ov4Var.getClass();
        ay4 ay4Var2 = (ay4) s32Var;
        ay4Var2.h0(-1642667805);
        int i3 = (i & 6) == 0 ? (ay4Var2.g(bx1Var) ? 4 : 2) | i : i;
        if ((i & 48) == 0) {
            i3 |= (i & 64) == 0 ? ay4Var2.g(nbApplication) : ay4Var2.i(nbApplication) ? 32 : 16;
        }
        if ((i & 384) == 0) {
            i3 |= ay4Var2.i(ov4Var) ? UserVerificationMethods.USER_VERIFY_HANDPRINT : UserVerificationMethods.USER_VERIFY_PATTERN;
        }
        if ((i & 3072) == 0) {
            i3 |= ay4Var2.i(this) ? 2048 : UserVerificationMethods.USER_VERIFY_ALL;
        }
        if (ay4Var2.X(i3 & 1, (i3 & 1171) != 1170)) {
            ci8 ci8VarN = lmi.n(nbApplication.b().m(), null, null, ay4Var2, 48, 2);
            Object objS = ay4Var2.S();
            Object obj = q32.a;
            if (objS == obj) {
                objS = lmi.T("");
                ay4Var2.p0(objS);
            }
            ci8 ci8Var = (ci8) objS;
            Object objS2 = ay4Var2.S();
            if (objS2 == obj) {
                objS2 = lmi.T(av3.I);
                ay4Var2.p0(objS2);
            }
            ci8 ci8Var2 = (ci8) objS2;
            Object objS3 = ay4Var2.S();
            if (objS3 == obj) {
                jof jofVar = oo4.b;
                Object oo4Var = new oo4(j1c.q());
                ay4Var2.p0(oo4Var);
                objS3 = oo4Var;
            }
            jof jofVar2 = ((oo4) objS3).a;
            t97 t97Var = (t97) ci8VarN.getValue();
            boolean zG = ay4Var2.g(t97Var);
            Object objS4 = ay4Var2.S();
            Object obj2 = ru3.I;
            Object objS1 = null;
            if (zG || objS4 == obj) {
                Object obj3 = (t97Var == null || (uo4Var = t97Var.a) == null) ? null : uo4Var.c;
                objS4 = obj3 == null ? obj2 : obj3;
                ay4Var2.p0(objS4);
            }
            List list = (List) objS4;
            boolean zG2 = ay4Var2.g(t97Var);
            Object objS5 = ay4Var2.S();
            if (zG2 || objS5 == obj) {
                if (t97Var != null && (uo4Var2 = t97Var.a) != null && (collectionValues = uo4Var2.a.values()) != null) {
                    objS1 = zs1.S1(collectionValues);
                }
                Object obj4 = objS1 == null ? obj2 : objS1;
                ay4Var2.p0(obj4);
                objS5 = obj4;
            }
            List list2 = (List) objS5;
            boolean zG3 = ay4Var2.g(list) | ay4Var2.g(list2) | ay4Var2.g((String) ci8Var.getValue()) | ay4Var2.g((Set) ci8Var2.getValue());
            Object objS6 = ay4Var2.S();
            if (zG3 || objS6 == obj) {
                if (tqd.E0((String) ci8Var.getValue())) {
                    Set set = (Set) ci8Var2.getValue();
                    list.getClass();
                    set.getClass();
                    we7 we7VarS = ny7.S();
                    rbh.b(we7VarS, set, list);
                    objS6 = ny7.E(we7VarS);
                } else {
                    ArrayList arrayList = new ArrayList();
                    for (Object obj5 : list2) {
                        if (tqd.r0(((ro4) obj5).getTitle(), (String) ci8Var.getValue(), true)) {
                            arrayList.add(obj5);
                        }
                    }
                    objS6 = zs1.J1(arrayList, new sh2(20));
                }
                ay4Var2.p0(objS6);
            }
            List list3 = (List) objS6;
            kqi.e(0, ay4Var2, xi7.U(ay4Var2, R.string.app_widgets__widget_folder_picker_title));
            bp.d0(ay4Var2).getClass();
            ha8 ha8Var = ha8.I;
            tni.h(ay4Var2, kad.h(ha8Var, 16.0f));
            String str = (String) ci8Var.getValue();
            Object objS7 = ay4Var2.S();
            if (objS7 == obj) {
                objS7 = new pu(ci8Var, 25);
                ay4Var2.p0(objS7);
            }
            kqi.d(str, (ov4) objS7, xi7.U(ay4Var2, R.string.app_widgets__widget_folder_picker_search_hint), ay4Var2, 48);
            bp.d0(ay4Var2).getClass();
            tni.h(ay4Var2, kad.h(ha8Var, 16.0f));
            if (t97Var == null) {
                ay4Var2.g0(142248034);
                kqi.a(bx1Var, ay4Var2, i3 & 14);
                ay4Var2.r(false);
                ay4Var = ay4Var2;
            } else {
                ay4Var2.g0(142307616);
                ka8 ka8VarA = bx1Var.a(1.0f, ha8Var, true);
                Set set2 = (Set) ci8Var2.getValue();
                boolean z = (i3 & 896) == 256;
                Object objS8 = ay4Var2.S();
                if (z || objS8 == obj) {
                    i2 = 0;
                    objS8 = new so4(0, ov4Var);
                    ay4Var2.p0(objS8);
                } else {
                    i2 = 0;
                }
                ov4 ov4Var2 = (ov4) objS8;
                Object objS9 = ay4Var2.S();
                if (objS9 == obj) {
                    objS9 = new to4(ci8Var2, i2);
                    ay4Var2.p0(objS9);
                }
                ov4 ov4Var3 = (ov4) objS9;
                boolean zI = ay4Var2.i(this);
                Object objS10 = ay4Var2.S();
                if (zI || objS10 == obj) {
                    objS10 = new in3(this, 4);
                    ay4Var2.p0(objS10);
                }
                s30.e(ich.a, list3, jofVar2, set2, ov4Var2, ov4Var3, (Function0) objS10, ka8VarA, false, 0.0f, null, ay4Var2, 906166278, 0, UserVerificationMethods.USER_VERIFY_ALL);
                ay4 ay4Var3 = ay4Var2;
                ay4Var3.r(i2);
                ay4Var = ay4Var3;
            }
        } else {
            ay4Var2.a0();
            ay4Var = ay4Var2;
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new yg(this, bx1Var, nbApplication, ov4Var, i, 2);
        }
    }

    @Override // defpackage.j0g
    /* JADX INFO: renamed from: h, reason: from getter */
    public final int getK() {
        return this.K;
    }

    @Override // defpackage.j0g
    public final void i(Context context, int i, String str) {
        str.getClass();
        context.getSharedPreferences("widget_bindings", 0).edit().putString("folder_" + i, str).apply();
    }

    @Override // defpackage.j0g
    public final void j(Context context, int i) {
        hb0.b.execute(new gb0(new FolderNotesWidgetProvider(), context, i));
    }
}
