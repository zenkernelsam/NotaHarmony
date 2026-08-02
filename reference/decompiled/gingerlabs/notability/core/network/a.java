package com.gingerlabs.notability.core.network;

import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.net.Uri;
import com.google.firebase.perf.network.FirebasePerfUrlConnection;
import defpackage.ar4;
import defpackage.bjf;
import defpackage.bl7;
import defpackage.ce2;
import defpackage.cl7;
import defpackage.cw4;
import defpackage.fh2;
import defpackage.fi1;
import defpackage.gh2;
import defpackage.ich;
import defpackage.jm7;
import defpackage.jp3;
import defpackage.jr4;
import defpackage.kb2;
import defpackage.kch;
import defpackage.m3e;
import defpackage.ny7;
import defpackage.rkb;
import defpackage.t7d;
import defpackage.ts8;
import defpackage.u7d;
import defpackage.w76;
import defpackage.x76;
import defpackage.x7d;
import defpackage.xs7;
import defpackage.xub;
import defpackage.yub;
import defpackage.yz3;
import defpackage.zq4;
import java.io.BufferedReader;
import java.io.FilterInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Map;
import java.util.concurrent.CancellationException;
import java.util.zip.GZIPInputStream;
import kotlin.NoWhenBranchMatchedException;

/* JADX INFO: loaded from: classes.dex */
public final class a extends m3e implements cw4 {
    public boolean I;
    public int J;
    public final /* synthetic */ x7d K;
    public final /* synthetic */ String L;
    public final /* synthetic */ u7d M;
    public final /* synthetic */ boolean N;
    public final /* synthetic */ long O;
    public final /* synthetic */ long P;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public a(x7d x7dVar, String str, u7d u7dVar, boolean z, long j, long j2, ce2 ce2Var) {
        super(2, ce2Var);
        this.K = x7dVar;
        this.L = str;
        this.M = u7dVar;
        this.N = z;
        this.O = j;
        this.P = j2;
    }

    @Override // defpackage.nq0
    public final ce2 create(Object obj, ce2 ce2Var) {
        return new a(this.K, this.L, this.M, this.N, this.O, this.P, ce2Var);
    }

    @Override // defpackage.cw4
    public final Object invoke(Object obj, Object obj2) {
        return ((a) create((fh2) obj, (ce2) obj2)).invokeSuspend(bjf.a);
    }

    /* JADX WARN: Code duplicated, block: B:102:0x01c2 A[Catch: all -> 0x01dd, TRY_LEAVE, TryCatch #6 {all -> 0x01dd, blocks: (B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8, B:103:0x01c9, B:105:0x01d1, B:115:0x01e3), top: B:152:0x01bc, outer: #3, inners: #1, #4 }] */
    /* JADX WARN: Code duplicated, block: B:105:0x01d1 A[Catch: all -> 0x01e1, TRY_LEAVE, TryCatch #1 {all -> 0x01e1, blocks: (B:103:0x01c9, B:105:0x01d1), top: B:144:0x01c9, outer: #6 }] */
    /* JADX WARN: Code duplicated, block: B:107:0x01d8  */
    /* JADX WARN: Code duplicated, block: B:119:0x01e9  */
    /* JADX WARN: Code duplicated, block: B:123:0x01f6 A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:131:0x0204  */
    /* JADX WARN: Code duplicated, block: B:132:0x0205  */
    /* JADX WARN: Code duplicated, block: B:152:0x01bc A[EXC_TOP_SPLITTER, SYNTHETIC] */
    /* JADX WARN: Code duplicated, block: B:28:0x008c A[Catch: all -> 0x0092, TRY_ENTER, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:34:0x00aa A[Catch: all -> 0x0092, LOOP:0: B:32:0x00a4->B:34:0x00aa, LOOP_END, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:41:0x00e6 A[Catch: all -> 0x00fc, TRY_LEAVE, TryCatch #5 {all -> 0x00fc, blocks: (B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:49:0x0100, B:42:0x00f4), top: B:151:0x00e0, outer: #3, inners: #2, #7 }] */
    /* JADX WARN: Code duplicated, block: B:53:0x0106  */
    /* JADX WARN: Code duplicated, block: B:55:0x0109  */
    /* JADX WARN: Code duplicated, block: B:59:0x0117 A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:67:0x0127 A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:68:0x012b A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:70:0x012f A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:80:0x015c A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:81:0x0171 A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:83:0x0179 A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:84:0x0181 A[Catch: all -> 0x0092, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:86:0x0187 A[ADDED_TO_REGION, Catch: all -> 0x0092, REMOVE, TryCatch #3 {all -> 0x0092, blocks: (B:25:0x007b, B:28:0x008c, B:31:0x0095, B:32:0x00a4, B:34:0x00aa, B:35:0x00c0, B:57:0x0111, B:59:0x0117, B:61:0x011b, B:64:0x0120, B:65:0x0121, B:67:0x0127, B:78:0x0154, B:80:0x015c, B:81:0x0171, B:83:0x0179, B:84:0x0181, B:85:0x0186, B:68:0x012b, B:70:0x012f, B:72:0x0133, B:74:0x0143, B:77:0x0151, B:86:0x0187, B:56:0x010b, B:91:0x0190, B:93:0x01a6, B:95:0x01ac, B:96:0x01b2, B:121:0x01f0, B:123:0x01f6, B:125:0x01fa, B:128:0x01ff, B:129:0x0200, B:133:0x0206, B:134:0x0208, B:135:0x021f, B:120:0x01eb, B:39:0x00e0, B:41:0x00e6, B:43:0x00f8, B:51:0x0102, B:52:0x0105, B:100:0x01bc, B:102:0x01c2, B:108:0x01d9, B:117:0x01e5, B:118:0x01e8), top: B:148:0x007b, inners: #0, #5, #6 }] */
    /* JADX WARN: Code duplicated, block: B:89:0x018c  */
    /* JADX WARN: Multi-variable type inference failed */
    @Override // defpackage.nq0
    public final Object invokeSuspend(Object obj) throws NotAuthenticatedException, NoConnectivityException {
        boolean zP;
        Map map;
        Object objA;
        HttpURLConnection httpURLConnection;
        boolean z;
        int responseCode;
        Object xubVar;
        Throwable thA;
        InputStream errorStream;
        InputStreamReader inputStreamReader;
        char[] cArr;
        int i;
        Object xubVar2;
        Throwable thA2;
        Throwable thA3;
        ich ichVarD;
        InputStream errorStream2;
        BufferedReader bufferedReader;
        String str = "";
        u7d u7dVar = this.M;
        int i2 = this.J;
        String str2 = this.L;
        x7d x7dVar = this.K;
        Object obj2 = null;
        try {
            if (i2 == 0) {
                ny7.F0(obj);
                ConnectivityManager connectivityManager = x7dVar.a;
                NetworkCapabilities networkCapabilities = connectivityManager.getNetworkCapabilities(connectivityManager.getActiveNetwork());
                if (networkCapabilities == null || !networkCapabilities.hasCapability(16)) {
                    throw new NoConnectivityException();
                }
                zP = x76.p(Uri.parse(str2).getHost(), rkb.x());
                ts8 ts8Var = x7dVar.b;
                if (zP) {
                    this.I = zP;
                    this.J = 1;
                    objA = ts8Var.a(this);
                    gh2 gh2Var = gh2.I;
                    if (objA == gh2Var) {
                        return gh2Var;
                    }
                } else {
                    map = ts8.b;
                    if (map == null) {
                        x76.d0("UNIVERSAL_HEADERS");
                        throw null;
                    }
                }
                URLConnection uRLConnection = (URLConnection) FirebasePerfUrlConnection.instrument(new URL(str2).openConnection());
                uRLConnection.getClass();
                httpURLConnection = (HttpURLConnection) uRLConnection;
                z = this.N;
                long j = this.O;
                long j2 = this.P;
                httpURLConnection.setRequestMethod(u7dVar.name());
                if (z) {
                    httpURLConnection.setRequestProperty("Accept-Encoding", "gzip");
                }
                httpURLConnection.setRequestProperty("Connection", "close");
                for (Map.Entry entry : map.entrySet()) {
                    httpURLConnection.setRequestProperty((String) entry.getKey(), (String) entry.getValue());
                }
                httpURLConnection.setConnectTimeout((int) jp3.e(j));
                httpURLConnection.setReadTimeout((int) jp3.e(j2));
                httpURLConnection.setDoInput(true);
                httpURLConnection.connect();
                responseCode = httpURLConnection.getResponseCode();
                if (responseCode == 401 && zP) {
                    try {
                        errorStream2 = httpURLConnection.getErrorStream();
                        if (errorStream2 != null) {
                            bufferedReader = new BufferedReader(new InputStreamReader(errorStream2, fi1.a), 8192);
                            try {
                                xubVar2 = rkb.V(bufferedReader);
                                bufferedReader.close();
                            } catch (Throwable th) {
                                try {
                                    throw th;
                                } catch (Throwable th2) {
                                    w76.q(bufferedReader, th);
                                    throw th2;
                                }
                            }
                        } else {
                            xubVar2 = null;
                        }
                        if (xubVar2 == null) {
                            xubVar2 = "";
                        }
                    } catch (Throwable th3) {
                        xubVar2 = new xub(th3);
                        thA2 = yub.a(xubVar2);
                        if (thA2 != null) {
                            throw thA2;
                        }
                        thA3 = yub.a(xubVar2);
                        if (thA3 == null) {
                            if (thA3 instanceof Error) {
                                throw thA3;
                            }
                            throw thA3;
                        }
                        str = (String) xubVar2;
                        ichVarD = kch.d(str);
                        if (ichVarD instanceof ar4) {
                            x7dVar.d.a(jr4.HttpUpdateClientError, ((ar4) ichVarD).c(), ((ar4) ichVarD).b());
                        } else {
                            if (!ichVarD.equals(zq4.b)) {
                                throw new NoWhenBranchMatchedException();
                            }
                            x7dVar.c.a("HTTP 401 SimpleHttpDownloader");
                        }
                        if (200 > responseCode) {
                        }
                        if (responseCode == 403) {
                            try {
                                errorStream = httpURLConnection.getErrorStream();
                                if (errorStream != null) {
                                    inputStreamReader = new InputStreamReader(errorStream, fi1.a);
                                    try {
                                        cArr = new char[200];
                                        i = inputStreamReader.read(cArr);
                                        if (i > 0) {
                                            xubVar = new String(cArr, 0, i);
                                        } else {
                                            xubVar = null;
                                        }
                                        inputStreamReader.close();
                                    } catch (Throwable th4) {
                                        try {
                                            throw th4;
                                        } catch (Throwable th5) {
                                            w76.q(inputStreamReader, th4);
                                            throw th5;
                                        }
                                    }
                                } else {
                                    xubVar = null;
                                }
                            } catch (Throwable th6) {
                                xubVar = new xub(th6);
                            }
                            thA = yub.a(xubVar);
                            if (thA != null) {
                                throw thA;
                            }
                            if (!(xubVar instanceof xub)) {
                                obj2 = xubVar;
                            }
                            obj2 = (String) obj2;
                        }
                        throw new HttpStatusException(responseCode, this.L, u7dVar.name(), obj2, httpURLConnection.getHeaderField("cf-ray"));
                    }
                    thA2 = yub.a(xubVar2);
                    if (thA2 != null && ((thA2 instanceof Error) || (thA2 instanceof CancellationException))) {
                        throw thA2;
                    }
                    thA3 = yub.a(xubVar2);
                    if (thA3 == null) {
                        str = (String) xubVar2;
                    } else {
                        if ((thA3 instanceof Error) || (thA3 instanceof CancellationException)) {
                            throw thA3;
                        }
                        Exception exc = (Exception) thA3;
                        ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
                        cl7 cl7Var = cl7.NETWORK;
                        jm7 jm7Var = jm7.L;
                        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                            try {
                                com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Failed to read 401 error stream", exc, xs7.R(new bl7()));
                            } catch (Exception e) {
                                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Failed to read 401 error stream", e);
                            }
                        }
                    }
                    ichVarD = kch.d(str);
                    if (ichVarD instanceof ar4) {
                        x7dVar.d.a(jr4.HttpUpdateClientError, ((ar4) ichVarD).c(), ((ar4) ichVarD).b());
                    } else {
                        if (!ichVarD.equals(zq4.b)) {
                            throw new NoWhenBranchMatchedException();
                        }
                        x7dVar.c.a("HTTP 401 SimpleHttpDownloader");
                    }
                }
                if (200 > responseCode && responseCode < 300) {
                    long contentLengthLong = httpURLConnection.getContentLengthLong();
                    InputStream inputStream = httpURLConnection.getInputStream();
                    inputStream.getClass();
                    FilterInputStream kb2Var = new kb2(contentLengthLong, inputStream);
                    String contentEncoding = httpURLConnection.getContentEncoding();
                    if (contentEncoding != null && contentEncoding.equalsIgnoreCase("gzip")) {
                        kb2Var = new GZIPInputStream(kb2Var);
                    }
                    return new t7d(kb2Var, httpURLConnection);
                }
                if (responseCode == 403) {
                    errorStream = httpURLConnection.getErrorStream();
                    if (errorStream != null) {
                        inputStreamReader = new InputStreamReader(errorStream, fi1.a);
                        cArr = new char[200];
                        i = inputStreamReader.read(cArr);
                        if (i > 0) {
                            xubVar = new String(cArr, 0, i);
                        } else {
                            xubVar = null;
                        }
                        inputStreamReader.close();
                    } else {
                        xubVar = null;
                    }
                    thA = yub.a(xubVar);
                    if (thA != null && ((thA instanceof Error) || (thA instanceof CancellationException))) {
                        throw thA;
                    }
                    if (!(xubVar instanceof xub)) {
                        obj2 = xubVar;
                    }
                    obj2 = (String) obj2;
                }
                throw new HttpStatusException(responseCode, this.L, u7dVar.name(), obj2, httpURLConnection.getHeaderField("cf-ray"));
            }
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            zP = this.I;
            ny7.F0(obj);
            objA = obj;
            z = this.N;
            long j3 = this.O;
            long j4 = this.P;
            httpURLConnection.setRequestMethod(u7dVar.name());
            if (z) {
                httpURLConnection.setRequestProperty("Accept-Encoding", "gzip");
            }
            httpURLConnection.setRequestProperty("Connection", "close");
            while (r8.hasNext()) {
                httpURLConnection.setRequestProperty((String) entry.getKey(), (String) entry.getValue());
            }
            httpURLConnection.setConnectTimeout((int) jp3.e(j3));
            httpURLConnection.setReadTimeout((int) jp3.e(j4));
            httpURLConnection.setDoInput(true);
            httpURLConnection.connect();
            responseCode = httpURLConnection.getResponseCode();
            if (responseCode == 401) {
                errorStream2 = httpURLConnection.getErrorStream();
                if (errorStream2 != null) {
                    bufferedReader = new BufferedReader(new InputStreamReader(errorStream2, fi1.a), 8192);
                    xubVar2 = rkb.V(bufferedReader);
                    bufferedReader.close();
                } else {
                    xubVar2 = null;
                }
                if (xubVar2 == null) {
                    xubVar2 = "";
                }
                thA2 = yub.a(xubVar2);
                if (thA2 != null) {
                    throw thA2;
                }
                thA3 = yub.a(xubVar2);
                if (thA3 == null) {
                    if (thA3 instanceof Error) {
                        throw thA3;
                    }
                    throw thA3;
                }
                str = (String) xubVar2;
                ichVarD = kch.d(str);
                if (ichVarD instanceof ar4) {
                    x7dVar.d.a(jr4.HttpUpdateClientError, ((ar4) ichVarD).c(), ((ar4) ichVarD).b());
                } else {
                    if (!ichVarD.equals(zq4.b)) {
                        throw new NoWhenBranchMatchedException();
                    }
                    x7dVar.c.a("HTTP 401 SimpleHttpDownloader");
                }
            }
            if (200 > responseCode) {
            }
            if (responseCode == 403) {
                errorStream = httpURLConnection.getErrorStream();
                if (errorStream != null) {
                    inputStreamReader = new InputStreamReader(errorStream, fi1.a);
                    cArr = new char[200];
                    i = inputStreamReader.read(cArr);
                    if (i > 0) {
                        xubVar = new String(cArr, 0, i);
                    } else {
                        xubVar = null;
                    }
                    inputStreamReader.close();
                } else {
                    xubVar = null;
                }
                thA = yub.a(xubVar);
                if (thA != null) {
                    throw thA;
                }
                if (!(xubVar instanceof xub)) {
                    obj2 = xubVar;
                }
                obj2 = (String) obj2;
            }
            throw new HttpStatusException(responseCode, this.L, u7dVar.name(), obj2, httpURLConnection.getHeaderField("cf-ray"));
        } catch (Throwable th7) {
            httpURLConnection.disconnect();
            throw th7;
        }
        map = (Map) objA;
        if (map == null) {
            throw new NotAuthenticatedException();
        }
        URLConnection uRLConnection2 = (URLConnection) FirebasePerfUrlConnection.instrument(new URL(str2).openConnection());
        uRLConnection2.getClass();
        httpURLConnection = (HttpURLConnection) uRLConnection2;
    }
}
