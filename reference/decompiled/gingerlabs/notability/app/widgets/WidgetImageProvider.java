package com.gingerlabs.notability.app.widgets;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.app.NbApplication;
import defpackage.iof;
import defpackage.iri;
import defpackage.ix9;
import defpackage.lof;
import defpackage.lri;
import defpackage.n29;
import defpackage.ny7;
import defpackage.p7e;
import defpackage.tse;
import defpackage.x76;
import defpackage.zs1;
import java.io.File;
import java.io.FileNotFoundException;
import java.security.NoSuchAlgorithmException;
import java.util.List;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/WidgetImageProvider;", "Landroid/content/ContentProvider;", "<init>", "()V", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class WidgetImageProvider extends ContentProvider {
    public static final /* synthetic */ int I = 0;

    @Override // android.content.ContentProvider
    public final int delete(Uri uri, String str, String[] strArr) {
        uri.getClass();
        return 0;
    }

    @Override // android.content.ContentProvider
    public final String getType(Uri uri) {
        uri.getClass();
        return "image/png";
    }

    @Override // android.content.ContentProvider
    public final Uri insert(Uri uri, ContentValues contentValues) {
        uri.getClass();
        return null;
    }

    @Override // android.content.ContentProvider
    public final boolean onCreate() {
        return true;
    }

    /* JADX WARN: Code duplicated, block: B:16:0x0039  */
    /* JADX WARN: Code duplicated, block: B:34:0x007d  */
    @Override // android.content.ContentProvider
    public final ParcelFileDescriptor openFile(Uri uri, String str) throws NoSuchAlgorithmException, FileNotFoundException {
        Context applicationContext;
        String lastPathSegment;
        iof iofVarR0;
        File fileC;
        tse tseVar;
        ix9 ix9VarE;
        uri.getClass();
        str.getClass();
        Context context = getContext();
        if (context == null || (applicationContext = context.getApplicationContext()) == null) {
            throw new FileNotFoundException(uri.toString());
        }
        List<String> pathSegments = uri.getPathSegments();
        pathSegments.getClass();
        String str2 = (String) zs1.f1(pathSegments);
        File fileC2 = null;
        if (x76.p(str2, "thumbnail")) {
            String lastPathSegment2 = uri.getLastPathSegment();
            if (lastPathSegment2 != null) {
                p7e p7eVar = lof.a;
                try {
                    iofVarR0 = ny7.r0(lastPathSegment2);
                } catch (IllegalArgumentException unused) {
                    iofVarR0 = null;
                }
                if (iofVarR0 == null) {
                    iofVarR0 = null;
                }
            } else {
                iofVarR0 = null;
            }
            NbApplication nbApplication = applicationContext instanceof NbApplication ? (NbApplication) applicationContext : null;
            if (nbApplication == null || (tseVar = (tse) nbApplication.I.q.invoke()) == null || iofVarR0 == null) {
                fileC = null;
            } else {
                String queryParameter = uri.getQueryParameter("f");
                if (queryParameter == null || (ix9VarE = tse.e(queryParameter)) == null || !x76.p(((n29) ix9VarE.I).I, iofVarR0)) {
                    fileC = tseVar.c(iofVarR0);
                } else {
                    fileC = new File(tseVar.d(), queryParameter);
                    if (!fileC.exists()) {
                        fileC = tseVar.c(iofVarR0);
                    }
                }
            }
            if (fileC != null) {
                fileC2 = lri.a(applicationContext, fileC, (int) (applicationContext.getResources().getDisplayMetrics().density * 48.0f), applicationContext.getResources().getDimension(R.dimen.app_widgets__widget_thumb_corner_radius));
            }
        } else if (x76.p(str2, "text") && (lastPathSegment = uri.getLastPathSegment()) != null) {
            fileC2 = iri.c(applicationContext, lastPathSegment);
        }
        if (fileC2 == null) {
            throw new FileNotFoundException(uri.toString());
        }
        ParcelFileDescriptor parcelFileDescriptorOpen = ParcelFileDescriptor.open(fileC2, 268435456);
        parcelFileDescriptorOpen.getClass();
        return parcelFileDescriptorOpen;
    }

    @Override // android.content.ContentProvider
    public final Cursor query(Uri uri, String[] strArr, String str, String[] strArr2, String str2) {
        uri.getClass();
        return null;
    }

    @Override // android.content.ContentProvider
    public final int update(Uri uri, ContentValues contentValues, String str, String[] strArr) {
        uri.getClass();
        return 0;
    }
}
