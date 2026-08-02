package com.gingerlabs.notability.app;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import com.gingerlabs.notability.R;
import defpackage.vr7;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/app/MissingNativeLibraryActivity;", "Landroid/app/Activity;", "<init>", "()V", "app"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MissingNativeLibraryActivity extends Activity {
    public static final /* synthetic */ int I = 0;

    @Override // android.app.Activity
    public final void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        new AlertDialog.Builder(this).setTitle(R.string.app__missing_native_library_title).setMessage(R.string.app__missing_native_library_message).setCancelable(false).setPositiveButton(android.R.string.ok, new vr7(this, 3)).show();
    }
}
