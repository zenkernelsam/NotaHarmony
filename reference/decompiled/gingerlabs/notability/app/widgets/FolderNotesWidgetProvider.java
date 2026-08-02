package com.gingerlabs.notability.app.widgets;

import android.content.Context;
import android.content.Intent;
import com.gingerlabs.notability.R;
import defpackage.hhd;
import defpackage.hqi;
import defpackage.jof;
import defpackage.lof;
import defpackage.oo4;
import defpackage.rg9;
import defpackage.ro4;
import defpackage.ru3;
import defpackage.t97;
import defpackage.wnh;
import java.util.Collection;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/FolderNotesWidgetProvider;", "Lrg9;", "<init>", "()V", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class FolderNotesWidgetProvider extends rg9 {
    public final int f = R.string.app_widgets__widget_folder_no_notes;
    public final int g = R.string.app_widgets__widget_folder_empty;
    public final int h = R.string.app_widgets__widget_new_note_label;

    @Override // defpackage.rg9
    /* JADX INFO: renamed from: c, reason: from getter */
    public final int getH() {
        return this.h;
    }

    @Override // defpackage.rg9
    /* JADX INFO: renamed from: d, reason: from getter */
    public final int getF() {
        return this.f;
    }

    @Override // defpackage.rg9
    /* JADX INFO: renamed from: e, reason: from getter */
    public final int getG() {
        return this.g;
    }

    @Override // defpackage.rg9
    public final hhd g(Context context, int i, t97 t97Var) {
        jof jofVarB;
        ro4 ro4VarA;
        context.getClass();
        String strE = hqi.e(context, i);
        if (strE == null || (jofVarB = wnh.b(strE)) == null || t97Var == null || (ro4VarA = t97Var.a(jofVarB)) == null) {
            return null;
        }
        String title = ro4VarA.getTitle();
        Intent className = new Intent().setClassName(context.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
        className.getClass();
        Intent action = className.setAction("android.intent.action.CREATE_NOTE");
        action.getClass();
        jof jofVar = oo4.b;
        Intent intentPutExtra = action.putExtra("folder_id", lof.e(jofVarB).toString());
        intentPutExtra.getClass();
        Intent className2 = new Intent().setClassName(context.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
        className2.getClass();
        Intent intentPutExtra2 = className2.setAction("android.intent.action.VIEW").putExtra("folder_id", lof.e(jofVarB).toString());
        intentPutExtra2.getClass();
        Collection collection = (List) t97Var.b.get(new oo4(jofVarB));
        if (collection == null) {
            collection = ru3.I;
        }
        return new hhd(title, intentPutExtra, intentPutExtra2, collection);
    }
}
