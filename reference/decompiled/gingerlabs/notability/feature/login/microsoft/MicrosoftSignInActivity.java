package com.gingerlabs.notability.feature.login.microsoft;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.core.common.logging.a;
import defpackage.a78;
import defpackage.c0;
import defpackage.cl7;
import defpackage.dmd;
import defpackage.f92;
import defpackage.hu2;
import defpackage.jm7;
import defpackage.lhh;
import defpackage.ot8;
import defpackage.q02;
import defpackage.r02;
import defpackage.tq3;
import defpackage.tz0;
import defpackage.vi2;
import defpackage.w50;
import defpackage.w68;
import defpackage.x68;
import defpackage.x76;
import defpackage.y68;
import java.util.ArrayList;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/feature/login/microsoft/MicrosoftSignInActivity;", "Lq02;", "<init>", "()V", "login"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MicrosoftSignInActivity extends q02 {
    public static final /* synthetic */ int M = 0;
    public a78 I;
    public boolean J;
    public boolean K;
    public dmd L;

    @Override // android.app.Activity
    public final void finish() {
        super.finish();
        if (Build.VERSION.SDK_INT >= 34) {
            overrideActivityTransition(1, 0, 0);
        } else {
            overridePendingTransition(0, 0);
        }
    }

    public final void g(a78 a78Var) {
        setResult(a78Var instanceof w68 ? 0 : -1, new Intent().putExtra("result", a78Var));
        finish();
    }

    public final void h(Uri uri) {
        a78 x68Var;
        String string = getString(R.string.feature_login__microsoft_sign_in_error);
        string.getClass();
        String queryParameter = uri.getQueryParameter("code");
        String queryParameter2 = uri.getQueryParameter("error");
        String queryParameter3 = uri.getQueryParameter("error_description");
        if (queryParameter2 == null) {
            x68Var = (queryParameter == null || queryParameter.length() == 0) ? new x68(string) : new y68(queryParameter);
        } else if (queryParameter2.equals("access_denied")) {
            x68Var = w68.I;
        } else {
            ArrayList arrayList = a.a;
            a.d(jm7.L, cl7.LOGIN, f92.m("Microsoft OAuth error: ", queryParameter2, queryParameter3 != null ? ", description: ".concat(queryParameter3) : ""));
            x68Var = new x68(string);
        }
        this.I = x68Var;
        g(x68Var);
    }

    @Override // defpackage.q02, defpackage.p02, android.app.Activity
    public final void onCreate(Bundle bundle) {
        Uri data;
        super.onCreate(bundle);
        if (Build.VERSION.SDK_INT >= 34) {
            overrideActivityTransition(0, 0, 0);
        } else {
            overridePendingTransition(0, 0);
        }
        tq3.b(this);
        getOnBackPressedDispatcher().a(this, new w50(this, 1));
        if (bundle != null) {
            this.I = (a78) hu2.Z(bundle, "result", a78.class);
            this.J = bundle.getBoolean("has_launched", false);
            this.K = bundle.getBoolean("has_received_redirect", false);
        }
        a78 a78Var = this.I;
        if (a78Var != null) {
            g(a78Var);
            return;
        }
        Intent intent = getIntent();
        if (intent != null && (data = intent.getData()) != null && x76.p(data.getScheme(), "msauth")) {
            this.K = true;
            h(data);
            return;
        }
        String stringExtra = getIntent().getStringExtra("auth_url");
        if (stringExtra == null) {
            String string = getString(R.string.feature_login__microsoft_sign_in_error);
            string.getClass();
            g(new x68(string));
            return;
        }
        r02.a(this, lhh.b);
        if (this.J) {
            return;
        }
        this.J = true;
        try {
            ot8 ot8Var = new ot8();
            Intent intent2 = (Intent) ot8Var.c;
            ot8Var.a = 2;
            intent2.putExtra("android.support.customtabs.extra.SHARE_MENU_ITEM", false);
            intent2.putExtra("android.support.customtabs.extra.TITLE_VISIBILITY", 0);
            intent2.putExtra("androidx.browser.customtabs.extra.DISABLE_BACKGROUND_INTERACTION", true);
            intent2.putExtra("org.chromium.chrome.browser.customtabs.EXTRA_DISABLE_STAR_BUTTON", true);
            intent2.putExtra("android.support.customtabs.extra.ENABLE_URLBAR_HIDING", true);
            ot8Var.a().U(this, Uri.parse(stringExtra));
        } catch (ActivityNotFoundException e) {
            ArrayList arrayList = a.a;
            a.c(cl7.LOGIN, null, e, null);
            String string2 = getString(R.string.feature_login__microsoft_sign_in_error);
            string2.getClass();
            g(new x68(string2));
        }
    }

    @Override // defpackage.q02, android.app.Activity
    public final void onNewIntent(Intent intent) {
        intent.getClass();
        super.onNewIntent(intent);
        dmd dmdVar = this.L;
        if (dmdVar != null) {
            dmdVar.a(null);
        }
        this.L = null;
        Uri data = intent.getData();
        if (data == null || !x76.p(data.getScheme(), "msauth")) {
            return;
        }
        this.K = true;
        h(data);
    }

    @Override // android.app.Activity
    public final void onPause() {
        super.onPause();
        dmd dmdVar = this.L;
        if (dmdVar != null) {
            dmdVar.a(null);
        }
        this.L = null;
    }

    @Override // android.app.Activity
    public final void onResume() {
        super.onResume();
        if (this.J && this.I == null && !this.K) {
            this.L = vi2.A(tz0.v(this), null, null, new c0(this, null, 25), 3);
        }
    }

    @Override // defpackage.q02, defpackage.p02, android.app.Activity
    public final void onSaveInstanceState(Bundle bundle) {
        bundle.getClass();
        super.onSaveInstanceState(bundle);
        bundle.putParcelable("result", this.I);
        bundle.putBoolean("has_launched", this.J);
        bundle.putBoolean("has_received_redirect", this.K);
    }
}
