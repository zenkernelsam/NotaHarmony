package com.gingerlabs.notability.data.note.assets;

import android.content.Context;
import androidx.recyclerview.widget.RecyclerView;
import androidx.work.CoroutineWorker;
import androidx.work.WorkerParameters;
import com.gingerlabs.notability.core.common.logging.a;
import defpackage.bl7;
import defpackage.ce2;
import defpackage.cl7;
import defpackage.cz2;
import defpackage.da0;
import defpackage.de2;
import defpackage.gh2;
import defpackage.jm7;
import defpackage.kg7;
import defpackage.ny7;
import defpackage.ov4;
import defpackage.ox8;
import defpackage.xs7;
import defpackage.yz3;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.NoSuchElementException;
import kotlin.Metadata;
import retrofit2.HttpException;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00020\u0001\u0082\u0001\u0002\u0002\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/note/assets/NoteAssetTransferWorker;", "Landroidx/work/CoroutineWorker;", "Lcom/gingerlabs/notability/data/note/assets/NoteAssetDownloadWorker;", "Lcom/gingerlabs/notability/data/note/assets/NoteAssetUploadWorker;", "assets"}, k = 1, mv = {2, 3, 0}, xi = 48)
public abstract class NoteAssetTransferWorker extends CoroutineWorker {
    public NoteAssetTransferWorker(Context context, WorkerParameters workerParameters, String str, cz2 cz2Var) {
        super(context, workerParameters);
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0013  */
    public static Object d(NoteAssetTransferWorker noteAssetTransferWorker, de2 de2Var) {
        ox8 ox8Var;
        if (de2Var instanceof ox8) {
            ox8Var = (ox8) de2Var;
            int i = ox8Var.K;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                ox8Var.K = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                ox8Var = new ox8(noteAssetTransferWorker, de2Var);
            }
        } else {
            ox8Var = new ox8(noteAssetTransferWorker, de2Var);
        }
        Object objC = ox8Var.I;
        int i2 = ox8Var.K;
        final int i3 = 1;
        if (i2 == 0) {
            ny7.F0(objC);
            ox8Var.K = 1;
            objC = noteAssetTransferWorker.c(ox8Var);
            gh2 gh2Var = gh2.I;
            if (objC == gh2Var) {
                return gh2Var;
            }
        } else {
            if (i2 != 1) {
                yz3.l("call to 'resume' before 'invoke' with coroutine");
                return null;
            }
            ny7.F0(objC);
        }
        final da0 da0Var = (da0) objC;
        if (da0Var.a().isEmpty()) {
            return kg7.c();
        }
        Collection collectionValues = da0Var.a().values();
        if (!(collectionValues instanceof Collection) || !collectionValues.isEmpty()) {
            Iterator it = collectionValues.iterator();
            while (it.hasNext()) {
                if (((Exception) it.next()) instanceof IOException) {
                    return kg7.b();
                }
            }
        }
        Collection collectionValues2 = da0Var.a().values();
        ArrayList arrayList = new ArrayList();
        for (Object obj : collectionValues2) {
            if (obj instanceof HttpException) {
                arrayList.add(obj);
            }
        }
        boolean zIsEmpty = arrayList.isEmpty();
        jm7 jm7Var = jm7.L;
        cl7 cl7Var = cl7.SERVER_PERSISTENCE;
        if (!zIsEmpty) {
            Iterator it2 = arrayList.iterator();
            while (it2.hasNext()) {
                if (((HttpException) it2.next()).I == 429) {
                    ArrayList arrayList2 = a.a;
                    a.d(jm7Var, cl7Var, "Got code 429 (rate-limiting), scheduling retry");
                    return kg7.b();
                }
            }
        }
        Collection collectionValues3 = da0Var.a().values();
        ArrayList arrayList3 = new ArrayList();
        for (Object obj2 : collectionValues3) {
            if (obj2 instanceof HttpException) {
                arrayList3.add(obj2);
            }
        }
        if (!arrayList3.isEmpty()) {
            Iterator it3 = arrayList3.iterator();
            while (it3.hasNext()) {
                if (((HttpException) it3.next()).I >= 500) {
                    ArrayList arrayList4 = a.a;
                    if (a.a(jm7Var, cl7Var)) {
                        try {
                            bl7 bl7Var = new bl7();
                            Collection collectionValues4 = da0Var.a().values();
                            ArrayList arrayList5 = new ArrayList();
                            for (Object obj3 : collectionValues4) {
                                if (obj3 instanceof HttpException) {
                                    arrayList5.add(obj3);
                                }
                            }
                            for (Object obj4 : arrayList5) {
                                if (((HttpException) obj4).I >= 500) {
                                    Throwable th = (Throwable) obj4;
                                    th.getClass();
                                    a.e(jm7Var, cl7Var, "Got server error, scheduling retry", th, xs7.R(bl7Var));
                                }
                            }
                            throw new NoSuchElementException("Collection contains no element matching the predicate.");
                        } catch (Exception e) {
                            a.g(cl7Var, "Got server error, scheduling retry", e);
                        }
                    }
                    return kg7.b();
                }
            }
        }
        Collection collectionValues5 = da0Var.a().values();
        ArrayList arrayList6 = new ArrayList();
        for (Object obj5 : collectionValues5) {
            if (obj5 instanceof HttpException) {
                arrayList6.add(obj5);
            }
        }
        if (!arrayList6.isEmpty()) {
            Iterator it4 = arrayList6.iterator();
            while (it4.hasNext()) {
                int i4 = ((HttpException) it4.next()).I;
                if (i4 >= 400 && i4 < 500) {
                    ArrayList arrayList7 = a.a;
                    final int i5 = 0;
                    a.c(cl7Var, "Got 4xx exception, returning failure", null, new ov4() { // from class: nx8
                        @Override // defpackage.ov4
                        public final Object invoke(Object obj6) {
                            int i6 = i5;
                            bjf bjfVar = bjf.a;
                            da0 da0Var2 = da0Var;
                            qz3 qz3Var = (qz3) obj6;
                            switch (i6) {
                                case 0:
                                    qz3Var.getClass();
                                    Collection collectionValues6 = da0Var2.b.values();
                                    ArrayList arrayList8 = new ArrayList();
                                    for (Object obj7 : collectionValues6) {
                                        if (obj7 instanceof HttpException) {
                                            arrayList8.add(obj7);
                                        }
                                    }
                                    for (Object obj8 : arrayList8) {
                                        int i7 = ((HttpException) obj8).I;
                                        if (i7 >= 400 && i7 < 500) {
                                            qz3Var.c((Throwable) obj8);
                                            return bjfVar;
                                        }
                                    }
                                    c1c.u("Collection contains no element matching the predicate.");
                                    return null;
                                default:
                                    qz3Var.getClass();
                                    qz3Var.c((Throwable) zs1.b1(da0Var2.b.values()));
                                    return bjfVar;
                            }
                        }
                    });
                    return kg7.a();
                }
            }
        }
        ArrayList arrayList8 = a.a;
        a.c(cl7Var, "Got unexpected exception, returning failure", null, new ov4() { // from class: nx8
            @Override // defpackage.ov4
            public final Object invoke(Object obj6) {
                int i6 = i3;
                bjf bjfVar = bjf.a;
                da0 da0Var2 = da0Var;
                qz3 qz3Var = (qz3) obj6;
                switch (i6) {
                    case 0:
                        qz3Var.getClass();
                        Collection collectionValues6 = da0Var2.b.values();
                        ArrayList arrayList9 = new ArrayList();
                        for (Object obj7 : collectionValues6) {
                            if (obj7 instanceof HttpException) {
                                arrayList9.add(obj7);
                            }
                        }
                        for (Object obj8 : arrayList9) {
                            int i7 = ((HttpException) obj8).I;
                            if (i7 >= 400 && i7 < 500) {
                                qz3Var.c((Throwable) obj8);
                                return bjfVar;
                            }
                        }
                        c1c.u("Collection contains no element matching the predicate.");
                        return null;
                    default:
                        qz3Var.getClass();
                        qz3Var.c((Throwable) zs1.b1(da0Var2.b.values()));
                        return bjfVar;
                }
            }
        });
        return kg7.a();
    }

    @Override // androidx.work.CoroutineWorker
    public final Object b(ce2 ce2Var) {
        return d(this, (de2) ce2Var);
    }

    public abstract Object c(ox8 ox8Var);
}
