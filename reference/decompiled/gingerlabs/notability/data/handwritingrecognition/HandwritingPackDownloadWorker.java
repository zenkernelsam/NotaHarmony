package com.gingerlabs.notability.data.handwritingrecognition;

import android.content.Context;
import androidx.recyclerview.widget.RecyclerView;
import androidx.work.CoroutineWorker;
import androidx.work.WorkerParameters;
import com.gingerlabs.notability.core.network.HttpStatusException;
import defpackage.ce2;
import defpackage.de2;
import defpackage.ga5;
import defpackage.gh2;
import defpackage.ja5;
import defpackage.ka5;
import defpackage.kg7;
import defpackage.ny7;
import defpackage.rab;
import defpackage.yub;
import defpackage.yz3;
import java.io.IOException;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\b\u0007\u0018\u00002\u00020\u0001:\u0002\n\u000bB%\b\u0000\u0012\b\b\u0001\u0010\u0003\u001a\u00020\u0002\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0004\u0012\u0006\u0010\u0007\u001a\u00020\u0006¢\u0006\u0004\b\b\u0010\t¨\u0006\f"}, d2 = {"Lcom/gingerlabs/notability/data/handwritingrecognition/HandwritingPackDownloadWorker;", "Landroidx/work/CoroutineWorker;", "Landroid/content/Context;", "appContext", "Landroidx/work/WorkerParameters;", "params", "Lga5;", "installer", "<init>", "(Landroid/content/Context;Landroidx/work/WorkerParameters;Lga5;)V", "xhh", "ia5", "handwritingrecognition"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class HandwritingPackDownloadWorker extends CoroutineWorker {
    public final ga5 g;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public HandwritingPackDownloadWorker(Context context, WorkerParameters workerParameters, ga5 ga5Var) {
        super(context, workerParameters);
        context.getClass();
        workerParameters.getClass();
        ga5Var.getClass();
        this.g = ga5Var;
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    @Override // androidx.work.CoroutineWorker
    public final Object b(ce2 ce2Var) {
        ja5 ja5Var;
        Object objE;
        int i;
        if (ce2Var instanceof ja5) {
            ja5Var = (ja5) ce2Var;
            int i2 = ja5Var.K;
            if ((i2 & RecyclerView.UNDEFINED_DURATION) != 0) {
                ja5Var.K = i2 - RecyclerView.UNDEFINED_DURATION;
            } else {
                ja5Var = new ja5(this, (de2) ce2Var);
            }
        } else {
            ja5Var = new ja5(this, (de2) ce2Var);
        }
        Object obj = ja5Var.I;
        int i3 = ja5Var.K;
        if (i3 == 0) {
            ny7.F0(obj);
            String strA = this.b.a().a("language_id");
            if (strA != null) {
                ka5.K.getClass();
                ka5 ka5VarA = rab.A(strA);
                if (ka5VarA != null) {
                    ja5Var.K = 1;
                    objE = this.g.e(ka5VarA, ja5Var);
                    gh2 gh2Var = gh2.I;
                    if (objE == gh2Var) {
                        return gh2Var;
                    }
                }
            }
            return kg7.a();
        }
        if (i3 != 1) {
            yz3.l("call to 'resume' before 'invoke' with coroutine");
            return null;
        }
        ny7.F0(obj);
        objE = ((yub) obj).I;
        Throwable thA = yub.a(objE);
        if (thA == null) {
            return kg7.c();
        }
        if ((!(thA instanceof HttpStatusException) || 400 > (i = ((HttpStatusException) thA).getI()) || i >= 500) && (thA instanceof IOException)) {
            return kg7.b();
        }
        return kg7.a();
    }
}
