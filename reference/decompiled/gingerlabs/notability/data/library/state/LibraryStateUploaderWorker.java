package com.gingerlabs.notability.data.library.state;

import android.content.Context;
import androidx.recyclerview.widget.RecyclerView;
import androidx.work.CoroutineWorker;
import androidx.work.WorkerParameters;
import com.gingerlabs.notability.core.common.logging.a;
import defpackage.ce2;
import defpackage.cl7;
import defpackage.de2;
import defpackage.gh2;
import defpackage.kf5;
import defpackage.kg7;
import defpackage.ny7;
import defpackage.tz0;
import defpackage.va7;
import defpackage.wa7;
import defpackage.yub;
import defpackage.yz3;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.concurrent.CancellationException;
import kotlin.Metadata;
import retrofit2.HttpException;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\b\u0007\u0018\u00002\u00020\u0001:\u0002\n\u000bB%\b\u0000\u0012\b\b\u0001\u0010\u0003\u001a\u00020\u0002\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0004\u0012\u0006\u0010\u0007\u001a\u00020\u0006¢\u0006\u0004\b\b\u0010\t¨\u0006\f"}, d2 = {"Lcom/gingerlabs/notability/data/library/state/LibraryStateUploaderWorker;", "Landroidx/work/CoroutineWorker;", "Landroid/content/Context;", "appContext", "Landroidx/work/WorkerParameters;", "params", "Lva7;", "libraryStateUploader", "<init>", "(Landroid/content/Context;Landroidx/work/WorkerParameters;Lva7;)V", "ha5", "ia5", "state"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class LibraryStateUploaderWorker extends CoroutineWorker {
    public final va7 g;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public LibraryStateUploaderWorker(Context context, WorkerParameters workerParameters, va7 va7Var) {
        super(context, workerParameters);
        context.getClass();
        workerParameters.getClass();
        va7Var.getClass();
        this.g = va7Var;
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    @Override // androidx.work.CoroutineWorker
    public final Object b(ce2 ce2Var) throws Exception {
        wa7 wa7Var;
        Object objB;
        Object next;
        Object next2;
        int i;
        int i2;
        if (ce2Var instanceof wa7) {
            wa7Var = (wa7) ce2Var;
            int i3 = wa7Var.K;
            if ((i3 & RecyclerView.UNDEFINED_DURATION) != 0) {
                wa7Var.K = i3 - RecyclerView.UNDEFINED_DURATION;
            } else {
                wa7Var = new wa7(this, (de2) ce2Var);
            }
        } else {
            wa7Var = new wa7(this, (de2) ce2Var);
        }
        Object obj = wa7Var.I;
        int i4 = wa7Var.K;
        if (i4 == 0) {
            ny7.F0(obj);
            wa7Var.K = 1;
            objB = this.g.b(wa7Var);
            gh2 gh2Var = gh2.I;
            if (objB == gh2Var) {
                return gh2Var;
            }
        } else {
            if (i4 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            ny7.F0(obj);
            objB = ((yub) obj).I;
        }
        Throwable thA = yub.a(objB);
        if (thA == null) {
            return kg7.c();
        }
        if ((thA instanceof Error) || (thA instanceof CancellationException)) {
            throw thA;
        }
        Exception exc = (Exception) thA;
        Throwable cause = exc;
        while (true) {
            if (cause == null) {
                cause = null;
                break;
            }
            if (cause instanceof HttpException) {
                break;
            }
            cause = cause.getCause();
        }
        HttpException httpException = (HttpException) cause;
        Iterator it = tz0.y(exc).iterator();
        do {
            if (!it.hasNext()) {
                next = null;
                break;
            }
            next = it.next();
        } while (!(((Throwable) next) instanceof RetryableUploadException));
        if (next == null) {
            Iterator it2 = tz0.y(exc).iterator();
            do {
                if (!it2.hasNext()) {
                    next2 = null;
                    break;
                }
                next2 = it2.next();
            } while (!(((Throwable) next2) instanceof IOException));
            if (next2 == null && !(exc instanceof UploadInProgressException)) {
                Throwable cause2 = exc;
                while (true) {
                    if (cause2 == null) {
                        cause2 = null;
                        break;
                    }
                    if (cause2 instanceof IOException) {
                        break;
                    }
                    cause2 = cause2.getCause();
                }
                if (cause2 == null) {
                    if (httpException != null && 500 <= (i2 = httpException.I) && i2 < 600) {
                        return kg7.b();
                    }
                    if (httpException == null || 400 > (i = httpException.I) || i >= 500) {
                        throw exc;
                    }
                    ArrayList arrayList = a.a;
                    a.c(cl7.NETWORK, "Client error during library state upload", null, new kf5(exc, 13));
                    return kg7.a();
                }
            }
        }
        return kg7.b();
    }
}
