package com.gingerlabs.notability.app.widgets;

import android.content.Context;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.app.NbApplication;
import com.gingerlabs.notability.app.widgets.NoteThumbnailConfigActivity;
import com.google.android.gms.fido.fido2.api.common.UserVerificationMethods;
import defpackage.a83;
import defpackage.aii;
import defpackage.ay4;
import defpackage.bp;
import defpackage.bt1;
import defpackage.bx1;
import defpackage.ci8;
import defpackage.du1;
import defpackage.g49;
import defpackage.g70;
import defpackage.gb0;
import defpackage.ha8;
import defpackage.hb0;
import defpackage.hl5;
import defpackage.i65;
import defpackage.ir8;
import defpackage.iyi;
import defpackage.j0g;
import defpackage.j1c;
import defpackage.ka8;
import defpackage.kad;
import defpackage.kqi;
import defpackage.lmi;
import defpackage.lv9;
import defpackage.ny7;
import defpackage.ov4;
import defpackage.q32;
import defpackage.rkb;
import defpackage.ro4;
import defpackage.ru3;
import defpackage.s32;
import defpackage.s4g;
import defpackage.sf;
import defpackage.ske;
import defpackage.t97;
import defpackage.tni;
import defpackage.tqd;
import defpackage.u42;
import defpackage.w76;
import defpackage.xdb;
import defpackage.xei;
import defpackage.xi7;
import defpackage.yg;
import defpackage.z19;
import defpackage.zle;
import defpackage.zs1;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000 \n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\n²\u0006\u000e\u0010\u0005\u001a\u0004\u0018\u00010\u00048\nX\u008a\u0084\u0002²\u0006\u000e\u0010\u0007\u001a\u00020\u00068\n@\nX\u008a\u008e\u0002²\u0006\u000e\u0010\t\u001a\u00020\b8\n@\nX\u008a\u008e\u0002"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/NoteThumbnailConfigActivity;", "Lj0g;", "<init>", "()V", "Lt97;", "state", "", "query", "", "gridWidthPx", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoteThumbnailConfigActivity extends j0g {
    public static final /* synthetic */ int L = 0;
    public final int K = R.string.app_widgets__widget_note_picker_login_required;

    /* JADX WARN: Code duplicated, block: B:161:0x0131 A[SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:164:0x00f4 A[SYNTHETIC] */
    /* JADX WARN: Multi-variable type inference failed */
    @Override // defpackage.j0g
    public final void g(bx1 bx1Var, final NbApplication nbApplication, final ov4 ov4Var, s32 s32Var, int i) {
        ay4 ay4Var;
        Collection collectionValues;
        int i2;
        boolean z;
        float f;
        float fJ0;
        String str;
        String str2;
        String title;
        Object obj;
        bx1Var.getClass();
        ov4Var.getClass();
        ay4 ay4Var2 = (ay4) s32Var;
        ay4Var2.h0(-1414895549);
        int i3 = (i & 6) == 0 ? (ay4Var2.g(bx1Var) ? 4 : 2) | i : i;
        if ((i & 48) == 0) {
            i3 |= (i & 64) == 0 ? ay4Var2.g(nbApplication) : ay4Var2.i(nbApplication) ? 32 : 16;
        }
        if ((i & 384) == 0) {
            i3 |= ay4Var2.i(ov4Var) ? UserVerificationMethods.USER_VERIFY_HANDPRINT : UserVerificationMethods.USER_VERIFY_PATTERN;
        }
        if (ay4Var2.X(i3 & 1, (i3 & 147) != 146)) {
            ci8 ci8VarN = lmi.n(nbApplication.b().m(), null, null, ay4Var2, 48, 2);
            Object objS = ay4Var2.S();
            Object obj2 = q32.a;
            if (objS == obj2) {
                objS = nbApplication.b().i();
                ay4Var2.p0(objS);
            }
            String str3 = (String) objS;
            Object objS2 = ay4Var2.S();
            if (objS2 == obj2) {
                objS2 = lmi.T("");
                ay4Var2.p0(objS2);
            }
            ci8 ci8Var = (ci8) objS2;
            boolean zG = ay4Var2.g((t97) ci8VarN.getValue());
            Object objS3 = ay4Var2.S();
            if (zG || objS3 == obj2) {
                t97 t97Var = (t97) ci8VarN.getValue();
                objS3 = (t97Var == null || (collectionValues = t97Var.d.values()) == null) ? ru3.I : zs1.J1(collectionValues, rkb.d);
                ay4Var2.p0(objS3);
            }
            List list = (List) objS3;
            boolean zG2 = ay4Var2.g(list) | ay4Var2.g((String) ci8Var.getValue());
            Object objS4 = ay4Var2.S();
            if (zG2 || objS4 == obj2) {
                ArrayList arrayList = new ArrayList();
                for (Object obj3 : list) {
                    g49 g49Var = (g49) obj3;
                    if (!tqd.E0((String) ci8Var.getValue())) {
                        String strL = g49Var.l();
                        if (!tqd.r0(strL == null ? str3 : strL, (String) ci8Var.getValue(), true)) {
                            z = false;
                        }
                        if (z) {
                            arrayList.add(obj3);
                        }
                    }
                    z = true;
                    if (z) {
                        arrayList.add(obj3);
                    }
                }
                i2 = 0;
                objS4 = zs1.M1(arrayList, 200);
                ay4Var2.p0(objS4);
            } else {
                i2 = 0;
            }
            final List<g49> list2 = (List) objS4;
            a83 a83Var = (a83) ay4Var2.k(u42.h);
            Object objS5 = ay4Var2.S();
            if (objS5 == obj2) {
                objS5 = lmi.T(Integer.valueOf(i2));
                ay4Var2.p0(objS5);
            }
            ci8 ci8Var2 = (ci8) objS5;
            if (((Number) ci8Var2.getValue()).intValue() <= 0) {
                ay4Var2.g0(-343025189);
                ay4Var2.r(i2);
                fJ0 = 0.0f;
                f = 0.0f;
            } else {
                ay4Var2.g0(-342999984);
                float fIntValue = ((Number) ci8Var2.getValue()).intValue();
                bp.d0(ay4Var2).getClass();
                f = 0.0f;
                fJ0 = (fIntValue - a83Var.j0(48.0f)) / 3.0f;
                ay4Var2.r(false);
            }
            boolean zG3 = ay4Var2.g((t97) ci8VarN.getValue()) | ay4Var2.g(list2);
            Object objS6 = ay4Var2.S();
            Object obj4 = objS6;
            if (zG3 || objS6 == obj2) {
                ArrayList arrayList2 = new ArrayList(bt1.H0(list2, 10));
                for (g49 g49Var2 : list2) {
                    t97 t97Var2 = (t97) ci8VarN.getValue();
                    arrayList2.add(t97Var2 != null ? t97Var2.a(g49Var2.h()) : null);
                }
                ay4Var2.p0(arrayList2);
                obj4 = arrayList2;
            }
            final List list3 = (List) obj4;
            String strU = xi7.U(ay4Var2, R.string.ui_folder__unfiled);
            boolean zG4 = ay4Var2.g(list2) | ay4Var2.g(list3) | ay4Var2.g(strU);
            Object objS7 = ay4Var2.S();
            if (zG4 || objS7 == obj2) {
                ArrayList arrayList3 = new ArrayList(bt1.H0(list2, 10));
                Iterator it = list2.iterator();
                int i4 = 0;
                while (it.hasNext()) {
                    Object next = it.next();
                    int i5 = i4 + 1;
                    if (i4 < 0) {
                        ny7.E0();
                        throw null;
                    }
                    g49 g49Var3 = (g49) next;
                    String str4 = str3;
                    Iterator it2 = it;
                    String strN = j1c.n(g49Var3.m());
                    boolean zI = g49Var3.i();
                    String str5 = strU;
                    boolean zO = g49Var3.o();
                    ro4 ro4Var = (ro4) list3.get(i4);
                    if (ro4Var == null || (title = ro4Var.getTitle()) == null) {
                        title = str5;
                    }
                    arrayList3.add(new z19(strN, title, zI, zO));
                    i4 = i5;
                    str3 = str4;
                    strU = str5;
                    it = it2;
                }
                str = strU;
                str2 = str3;
                ay4Var2.p0(arrayList3);
                obj = arrayList3;
            } else {
                str = strU;
                str2 = str3;
                obj = objS7;
            }
            final List list4 = (List) obj;
            final List listH = iyi.h(fJ0, 3, list4, ay4Var2, 48);
            final float fG = iyi.g(!list2.isEmpty() && fJ0 > f, ay4Var2);
            kqi.e(0, ay4Var2, xi7.U(ay4Var2, R.string.app_widgets__widget_note_thumbnail_picker_title));
            bp.d0(ay4Var2).getClass();
            ha8 ha8Var = ha8.I;
            tni.h(ay4Var2, kad.h(ha8Var, 16.0f));
            String str6 = (String) ci8Var.getValue();
            Object objS8 = ay4Var2.S();
            int i6 = 7;
            if (objS8 == obj2) {
                objS8 = new hl5(ci8Var, i6);
                ay4Var2.p0(objS8);
            }
            kqi.d(str6, (ov4) objS8, xi7.U(ay4Var2, R.string.app_widgets__widget_note_picker_search_hint), ay4Var2, 48);
            bp.d0(ay4Var2).getClass();
            tni.h(ay4Var2, kad.h(ha8Var, 16.0f));
            if (((t97) ci8VarN.getValue()) == null) {
                ay4Var2.g0(1790105138);
                kqi.a(bx1Var, ay4Var2, i3 & 14);
                ay4Var2.r(false);
                ay4Var = ay4Var2;
            } else {
                boolean z2 = false;
                if (list2.isEmpty()) {
                    ay4Var2.g0(-341262310);
                    String strU2 = xi7.U(ay4Var2, R.string.app_widgets__widget_picker_no_notes);
                    ir8.a(ay4Var2).getClass();
                    ske.b(strU2, null, du1.b(ay4Var2).c.b, null, 0L, null, null, null, 0L, null, 0L, 0, false, 0, 0, null, zle.J, ay4Var2, 0, 0, 131066);
                    ay4 ay4Var3 = ay4Var2;
                    ay4Var3.r(false);
                    ay4Var = ay4Var3;
                } else {
                    ay4Var2.g0(-341013907);
                    i65 i65Var = new i65(3);
                    ka8 ka8VarK = w76.k(bx1Var.a(1.0f, kad.f(ha8Var, 1.0f), true));
                    Object objS9 = ay4Var2.S();
                    if (objS9 == obj2) {
                        objS9 = new hl5(ci8Var2, 8);
                        ay4Var2.p0(objS9);
                    }
                    ka8 ka8VarB = xei.b(ka8VarK, (ov4) objS9);
                    bp.d0(ay4Var2).getClass();
                    g70 g70Var = new g70(24.0f, true, new sf(z2));
                    bp.d0(ay4Var2).getClass();
                    float f2 = f;
                    lv9 lv9VarJ = s4g.j(f2, f2, f2, 32.0f, 7);
                    final String str7 = str;
                    boolean zI2 = ay4Var2.i(list2) | ay4Var2.i(list3) | ay4Var2.i(list4) | ay4Var2.d(fG) | ((i3 & 896) == 256) | ay4Var2.i(listH) | ((i3 & 112) == 32 || ((i3 & 64) != 0 && ay4Var2.i(nbApplication))) | ay4Var2.g(str7);
                    Object objS10 = ay4Var2.S();
                    if (zI2 || objS10 == obj2) {
                        final String str8 = str2;
                        Object obj5 = new ov4() { // from class: eb9
                            @Override // defpackage.ov4
                            public final Object invoke(Object obj6) {
                                wu6 wu6Var = (wu6) obj6;
                                int i7 = NoteThumbnailConfigActivity.L;
                                wu6Var.getClass();
                                kg3 kg3Var = new kg3(24);
                                List list5 = list2;
                                wu6Var.j0(list5.size(), new q5(29, kg3Var, list5), new xc(8, list5), new n12(new hb9(list5, list3, list4, fG, ov4Var, listH, nbApplication, str8, str7), true, -1942245546));
                                return bjf.a;
                            }
                        };
                        ay4Var2.p0(obj5);
                        objS10 = obj5;
                    }
                    aii.a(i65Var, ka8VarB, null, lv9VarJ, null, g70Var, null, false, null, (ov4) objS10, ay4Var2, 0, 948);
                    ay4Var2.r(false);
                    ay4Var = ay4Var2;
                }
            }
        } else {
            ay4Var2.a0();
            ay4Var = ay4Var2;
        }
        xdb xdbVarV = ay4Var.v();
        if (xdbVarV != null) {
            xdbVarV.d = new yg(this, bx1Var, nbApplication, ov4Var, i, 6);
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
        context.getSharedPreferences("widget_bindings", 0).edit().putString("note_" + i, str).apply();
    }

    @Override // defpackage.j0g
    public final void j(Context context, int i) {
        hb0.b.execute(new gb0(new NoteThumbnailWidgetProvider(), context, i));
    }
}
