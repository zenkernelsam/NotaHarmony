package com.gingerlabs.notability.app.widgets;

import android.content.Context;
import android.content.Intent;
import com.gingerlabs.notability.R;
import defpackage.hhd;
import defpackage.rg9;
import defpackage.ru3;
import defpackage.t97;
import java.util.Collection;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/RecentNotesWidgetProvider;", "Lrg9;", "<init>", "()V", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class RecentNotesWidgetProvider extends rg9 {
    public final int f = R.string.app_widgets__widget_recent_notes_empty;
    public final int g = R.string.app_widgets__widget_recent_notes_empty;
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
        Collection collectionValues;
        context.getClass();
        String string = context.getString(R.string.app_widgets__widget_recent_notes_label);
        string.getClass();
        Intent className = new Intent().setClassName(context.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
        className.getClass();
        Intent action = className.setAction("android.intent.action.CREATE_NOTE");
        action.getClass();
        Intent className2 = new Intent().setClassName(context.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
        className2.getClass();
        Intent intentPutExtra = className2.setAction("android.intent.action.VIEW").putExtra("show_recent", true);
        intentPutExtra.getClass();
        if (t97Var == null || (collectionValues = t97Var.d.values()) == null) {
            collectionValues = ru3.I;
        }
        return new hhd(string, action, intentPutExtra, collectionValues);
    }
}
