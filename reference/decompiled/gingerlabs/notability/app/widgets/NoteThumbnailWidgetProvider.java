package com.gingerlabs.notability.app.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.widget.RemoteViews;
import androidx.recyclerview.widget.RecyclerView;
import com.gingerlabs.notability.R;
import com.gingerlabs.notability.app.NbApplication;
import defpackage.ac9;
import defpackage.ce2;
import defpackage.db9;
import defpackage.de2;
import defpackage.g49;
import defpackage.gh2;
import defpackage.hb0;
import defpackage.hqi;
import defpackage.iof;
import defpackage.kx;
import defpackage.lof;
import defpackage.mf3;
import defpackage.mu3;
import defpackage.ny7;
import defpackage.o03;
import defpackage.or7;
import defpackage.p7e;
import defpackage.qri;
import defpackage.qy1;
import defpackage.t23;
import defpackage.tse;
import defpackage.vi2;
import defpackage.yb9;
import defpackage.yz3;
import defpackage.zb9;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\b\u0007\u0018\u00002\u00020\u0001:\u0001\u0004B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/app/widgets/NoteThumbnailWidgetProvider;", "Lhb0;", "<init>", "()V", "yb9", "widgets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoteThumbnailWidgetProvider extends hb0 {
    /* JADX WARN: Code duplicated, block: B:38:0x00e7  */
    /* JADX WARN: Code duplicated, block: B:40:0x00f1  */
    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    /* JADX WARN: Multi-variable type inference failed */
    public static final Object c(NoteThumbnailWidgetProvider noteThumbnailWidgetProvider, Context context, iof iofVar, int i, int i2, de2 de2Var) {
        zb9 zb9Var;
        int i3;
        NbApplication nbApplication;
        int i4;
        int i5;
        Context context2;
        g49 g49Var;
        Bitmap bitmap;
        float f;
        String strI;
        if (de2Var instanceof zb9) {
            zb9Var = (zb9) de2Var;
            int i6 = zb9Var.Q;
            if ((i6 & RecyclerView.UNDEFINED_DURATION) != 0) {
                zb9Var.Q = i6 - RecyclerView.UNDEFINED_DURATION;
            } else {
                zb9Var = new zb9(noteThumbnailWidgetProvider, de2Var);
            }
        } else {
            zb9Var = new zb9(noteThumbnailWidgetProvider, de2Var);
        }
        Object obj = zb9Var.O;
        int i7 = zb9Var.Q;
        Bitmap bitmapB = null;
        Object[] objArr = 0;
        Object[] objArr2 = 0;
        gh2 gh2Var = gh2.I;
        if (i7 == 0) {
            ny7.F0(obj);
            Context applicationContext = context.getApplicationContext();
            applicationContext.getClass();
            NbApplication nbApplication2 = (NbApplication) applicationContext;
            long j = noteThumbnailWidgetProvider.a;
            or7 or7Var = new or7(25, objArr == true ? 1 : 0, nbApplication2, iofVar);
            zb9Var.I = context;
            zb9Var.J = iofVar;
            zb9Var.K = nbApplication2;
            zb9Var.M = i;
            zb9Var.N = i2;
            zb9Var.Q = 1;
            Object objL0 = qy1.l0(j, or7Var, zb9Var);
            if (objL0 != gh2Var) {
                obj = objL0;
                i3 = i;
                nbApplication = nbApplication2;
            }
            return gh2Var;
        }
        if (i7 == 1) {
            i2 = zb9Var.N;
            int i8 = zb9Var.M;
            NbApplication nbApplication3 = zb9Var.K;
            iofVar = zb9Var.J;
            context = zb9Var.I;
            ny7.F0(obj);
            nbApplication = nbApplication3;
            i3 = i8;
        } else {
            if (i7 != 2) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            i5 = zb9Var.N;
            i4 = zb9Var.M;
            g49Var = zb9Var.L;
            nbApplication = zb9Var.K;
            context2 = zb9Var.I;
            ny7.F0(obj);
        }
        bitmap = (Bitmap) obj;
        f = context2.getResources().getDisplayMetrics().density * 16.0f;
        if (g49Var != null || (strI = g49Var.l()) == null) {
            strI = nbApplication.b().i();
        }
        if (bitmap != null) {
            bitmapB = qri.b(bitmap, i4, i5, f);
            bitmap.recycle();
        }
        return new yb9(strI, bitmapB);
        g49 g49Var2 = (g49) obj;
        ((db9) nbApplication.I.C1.invoke()).a(iofVar, g49Var2 != null ? g49Var2.k() : null, g49Var2 != null ? g49Var2.j() : null, g49Var2 != null);
        tse tseVar = (tse) nbApplication.I.q.invoke();
        zb9Var.I = context;
        zb9Var.J = null;
        zb9Var.K = nbApplication;
        zb9Var.L = g49Var2;
        zb9Var.M = i3;
        zb9Var.N = i2;
        zb9Var.Q = 2;
        tseVar.getClass();
        t23 t23Var = mf3.a;
        Object objT = vi2.T(o03.K, new kx(24, (ce2) (objArr2 == true ? 1 : 0), (Object) tseVar, (Object) iofVar), zb9Var);
        if (objT != gh2Var) {
            Context context3 = context;
            i4 = i3;
            i5 = i2;
            context2 = context3;
            obj = objT;
            g49Var = g49Var2;
            bitmap = (Bitmap) obj;
            f = context2.getResources().getDisplayMetrics().density * 16.0f;
            if (g49Var != null) {
                strI = nbApplication.b().i();
            } else {
                strI = nbApplication.b().i();
            }
            if (bitmap != null) {
                bitmapB = qri.b(bitmap, i4, i5, f);
                bitmap.recycle();
            }
            return new yb9(strI, bitmapB);
        }
        return gh2Var;
    }

    /* JADX WARN: Code duplicated, block: B:10:0x0019  */
    @Override // defpackage.hb0
    public final void a(Context context, AppWidgetManager appWidgetManager, int i) {
        iof iofVar;
        Context context2;
        yb9 yb9Var;
        Intent intentAddCategory;
        iof iofVarR0;
        context.getClass();
        appWidgetManager.getClass();
        String strG = hqi.g(context, i);
        if (strG != null) {
            p7e p7eVar = lof.a;
            try {
                iofVarR0 = ny7.r0(strG);
            } catch (IllegalArgumentException unused) {
                iofVarR0 = null;
            }
            if (iofVarR0 != null) {
                iofVar = iofVarR0;
            } else {
                iofVar = null;
            }
        } else {
            iofVar = null;
        }
        float f = context.getResources().getDisplayMetrics().density;
        Bundle appWidgetOptions = appWidgetManager.getAppWidgetOptions(i);
        boolean z = context.getResources().getConfiguration().orientation != 2;
        int i2 = z ? appWidgetOptions.getInt("appWidgetMinWidth") : appWidgetOptions.getInt("appWidgetMaxWidth");
        Integer numValueOf = Integer.valueOf(i2);
        if (i2 <= 0) {
            numValueOf = null;
        }
        int iIntValue = numValueOf != null ? numValueOf.intValue() : 150;
        int i3 = z ? appWidgetOptions.getInt("appWidgetMaxHeight") : appWidgetOptions.getInt("appWidgetMinHeight");
        Integer numValueOf2 = Integer.valueOf(i3);
        if (i3 <= 0) {
            numValueOf2 = null;
        }
        int i4 = (int) (iIntValue * f);
        int iIntValue2 = (int) ((numValueOf2 != null ? numValueOf2.intValue() : 150) * f);
        if (iofVar != null) {
            context2 = context;
            yb9Var = (yb9) vi2.J(mu3.I, new ac9(this, context2, iofVar, i4, iIntValue2, null));
        } else {
            context2 = context;
            yb9Var = null;
        }
        RemoteViews remoteViews = new RemoteViews(context2.getPackageName(), R.layout.app_widgets__widget_note_thumbnail);
        Bitmap bitmapA = yb9Var != null ? yb9Var.a() : null;
        if (bitmapA != null) {
            remoteViews.setViewVisibility(R.id.app_widgets__widget_thumbnail_image, 0);
            remoteViews.setViewVisibility(R.id.app_widgets__widget_thumbnail_placeholder, 8);
            remoteViews.setImageViewBitmap(R.id.app_widgets__widget_thumbnail_image, bitmapA);
            remoteViews.setContentDescription(R.id.app_widgets__widget_thumbnail_image, yb9Var.b());
        } else {
            remoteViews.setViewVisibility(R.id.app_widgets__widget_thumbnail_image, 8);
            remoteViews.setViewVisibility(R.id.app_widgets__widget_thumbnail_placeholder, 0);
        }
        if (iofVar != null) {
            Intent className = new Intent().setClassName(context2.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
            className.getClass();
            Intent action = className.setAction("android.intent.action.VIEW");
            action.getClass();
            intentAddCategory = action.putExtra("note_id", iofVar.toString());
            intentAddCategory.getClass();
        } else {
            Intent className2 = new Intent().setClassName(context2.getPackageName(), "com.gingerlabs.notability.app.MainActivity");
            className2.getClass();
            intentAddCategory = className2.setAction("android.intent.action.MAIN").addCategory("android.intent.category.LAUNCHER");
            intentAddCategory.getClass();
        }
        remoteViews.setOnClickPendingIntent(R.id.app_widgets__widget_root, PendingIntent.getActivity(context2, i, intentAddCategory, 201326592));
        appWidgetManager.updateAppWidget(i, remoteViews);
    }
}
