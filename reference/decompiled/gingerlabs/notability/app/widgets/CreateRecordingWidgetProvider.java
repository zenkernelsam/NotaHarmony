package com.gingerlabs.notability.app.widgets;

import android.content.Context;
import android.content.Intent;
import com.gingerlabs.notability.R;
import defpackage.ym2;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/CreateRecordingWidgetProvider;", "Lym2;", "<init>", "()V", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class CreateRecordingWidgetProvider extends ym2 {
    public final int b = R.layout.app_widgets__create_recording_widget;
    public final int c = R.layout.app_widgets__create_recording_widget_compact;
    public final int d = R.string.app_widgets__widget_recording_label;
    public final String e = "recording";

    @Override // defpackage.ym2
    /* JADX INFO: renamed from: a, reason: from getter */
    public final String getE() {
        return this.e;
    }

    @Override // defpackage.ym2
    /* JADX INFO: renamed from: b, reason: from getter */
    public final int getC() {
        return this.c;
    }

    @Override // defpackage.ym2
    /* JADX INFO: renamed from: c, reason: from getter */
    public final int getB() {
        return this.b;
    }

    @Override // defpackage.ym2
    /* JADX INFO: renamed from: d, reason: from getter */
    public final int getD() {
        return this.d;
    }

    @Override // defpackage.ym2
    public final Intent e(Context context) {
        Intent className = new Intent().setClassName(context.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
        className.getClass();
        Intent action = className.setAction("android.intent.action.CREATE_NOTE");
        action.getClass();
        Intent intentPutExtra = action.putExtra("start_recording", true);
        intentPutExtra.getClass();
        return intentPutExtra;
    }
}
