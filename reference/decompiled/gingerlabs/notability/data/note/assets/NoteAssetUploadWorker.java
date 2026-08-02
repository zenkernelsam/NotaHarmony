package com.gingerlabs.notability.data.note.assets;

import android.content.Context;
import androidx.work.WorkerParameters;
import defpackage.mf3;
import defpackage.o03;
import defpackage.or7;
import defpackage.ox8;
import defpackage.qy8;
import defpackage.t23;
import defpackage.vi2;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\b\u0007\u0018\u00002\u00020\u0001:\u0001\nB%\b\u0000\u0012\b\b\u0001\u0010\u0003\u001a\u00020\u0002\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0004\u0012\u0006\u0010\u0007\u001a\u00020\u0006¢\u0006\u0004\b\b\u0010\t¨\u0006\u000b"}, d2 = {"Lcom/gingerlabs/notability/data/note/assets/NoteAssetUploadWorker;", "Lcom/gingerlabs/notability/data/note/assets/NoteAssetTransferWorker;", "Landroid/content/Context;", "appContext", "Landroidx/work/WorkerParameters;", "params", "Lqy8;", "noteAssetsRepository", "<init>", "(Landroid/content/Context;Landroidx/work/WorkerParameters;Lqy8;)V", "yl2", "assets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoteAssetUploadWorker extends NoteAssetTransferWorker {
    public final qy8 g;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public NoteAssetUploadWorker(Context context, WorkerParameters workerParameters, qy8 qy8Var) {
        super(context, workerParameters, "NoteAssetUploadWorker", null);
        context.getClass();
        workerParameters.getClass();
        qy8Var.getClass();
        this.g = qy8Var;
    }

    @Override // com.gingerlabs.notability.data.note.assets.NoteAssetTransferWorker
    public final Object c(ox8 ox8Var) {
        qy8 qy8Var = this.g;
        qy8Var.getClass();
        t23 t23Var = mf3.a;
        return vi2.T(o03.K, new or7(qy8Var, null, 16), ox8Var);
    }
}
