package com.gingerlabs.notability.feature.login.apple;

import android.content.Intent;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import com.gingerlabs.notability.R;
import defpackage.a60;
import defpackage.cvi;
import defpackage.d60;
import defpackage.h3;
import defpackage.lmi;
import defpackage.m2a;
import defpackage.n12;
import defpackage.q02;
import defpackage.r02;
import defpackage.tq3;
import defpackage.w50;
import defpackage.y50;
import defpackage.z50;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/feature/login/apple/AppleSignInActivity;", "Lq02;", "<init>", "()V", "login"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class AppleSignInActivity extends q02 {
    public static final /* synthetic */ int L = 0;
    public final m2a I = lmi.T(Boolean.TRUE);
    public d60 J;
    public WebView K;

    public final void g(d60 d60Var) {
        int i = d60Var instanceof z50 ? 0 : -1;
        Intent intent = new Intent();
        d60Var.getClass();
        Bundle bundle = new Bundle();
        cvi.c(bundle, d60Var);
        intent.replaceExtras(bundle);
        setResult(i, intent);
        finish();
    }

    @Override // defpackage.q02, defpackage.p02, android.app.Activity
    public final void onCreate(Bundle bundle) {
        Bundle bundle2;
        d60 d60VarB;
        super.onCreate(bundle);
        setRequestedOrientation(getResources().getConfiguration().orientation == 2 ? 6 : 7);
        tq3.b(this);
        getOnBackPressedDispatcher().a(this, new w50(this, 0));
        if (bundle != null && (bundle2 = bundle.getBundle("flow_state")) != null && (d60VarB = cvi.b(bundle2)) != null) {
            this.J = d60VarB;
        }
        d60 d60Var = this.J;
        if (d60Var != null) {
            g(d60Var);
            return;
        }
        String stringExtra = getIntent().getStringExtra("auth_url");
        if (stringExtra == null) {
            String string = getString(R.string.feature_login__apple_sign_in_error);
            string.getClass();
            g(new a60(string));
            return;
        }
        String stringExtra2 = getIntent().getStringExtra("callback_url");
        WebView webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(false);
        settings.setSupportZoom(false);
        settings.setBuiltInZoomControls(false);
        settings.setDisplayZoomControls(false);
        webView.setWebViewClient(new y50(this, stringExtra2, webView));
        this.K = webView;
        r02.a(this, new n12(new h3(3, webView, this), true, 522055173));
        webView.loadUrl(stringExtra);
    }

    @Override // android.app.Activity
    public final void onDestroy() {
        WebView webView = this.K;
        if (webView != null) {
            webView.stopLoading();
        }
        WebView webView2 = this.K;
        if (webView2 != null) {
            webView2.destroy();
        }
        this.K = null;
        super.onDestroy();
    }

    @Override // defpackage.q02, defpackage.p02, android.app.Activity
    public final void onSaveInstanceState(Bundle bundle) {
        bundle.getClass();
        super.onSaveInstanceState(bundle);
        d60 d60Var = this.J;
        if (d60Var != null) {
            Bundle bundle2 = new Bundle();
            cvi.c(bundle2, d60Var);
            bundle.putBundle("flow_state", bundle2);
        }
    }
}
