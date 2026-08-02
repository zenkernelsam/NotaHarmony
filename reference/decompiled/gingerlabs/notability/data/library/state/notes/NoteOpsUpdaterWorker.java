package com.gingerlabs.notability.data.library.state.notes;

import android.content.Context;
import androidx.work.CoroutineWorker;
import androidx.work.WorkerParameters;
import defpackage.aj8;
import defpackage.bj8;
import defpackage.ef3;
import defpackage.jp3;
import defpackage.nab;
import defpackage.np3;
import defpackage.p7j;
import defpackage.sdg;
import defpackage.wp9;
import defpackage.x69;
import defpackage.zb;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000.\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0007\b\u0007\u0018\u00002\u00020\u0001:\u0003\u0010\u0011\u0012B=\b\u0000\u0012\b\b\u0001\u0010\u0003\u001a\u00020\u0002\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0004\u0012\u0006\u0010\u0007\u001a\u00020\u0006\u0012\u0006\u0010\t\u001a\u00020\b\u0012\u0006\u0010\u000b\u001a\u00020\n\u0012\u0006\u0010\r\u001a\u00020\f¢\u0006\u0004\b\u000e\u0010\u000f¨\u0006\u0013"}, d2 = {"Lcom/gingerlabs/notability/data/library/state/notes/NoteOpsUpdaterWorker;", "Landroidx/work/CoroutineWorker;", "Landroid/content/Context;", "appContext", "Landroidx/work/WorkerParameters;", "params", "Lx69;", "noteOpsRepository", "Lnab;", "rawNoteMetadataRepository", "Lef3;", "diskQuotaRepository", "Lwp9;", "opsDownloadPriority", "<init>", "(Landroid/content/Context;Landroidx/work/WorkerParameters;Lx69;Lnab;Lef3;Lwp9;)V", "ha5", "zb", "d79", "state"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoteOpsUpdaterWorker extends CoroutineWorker {
    public static final zb l = new zb();
    public static final long m;
    public static final long n;
    public static final aj8 o;
    public final WorkerParameters g;
    public final x69 h;
    public final nab i;
    public final ef3 j;
    public final wp9 k;

    static {
        p7j p7jVar = jp3.J;
        m = sdg.r0(30, np3.SECONDS);
        n = sdg.r0(5, np3.MINUTES);
        o = bj8.a();
    }

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public NoteOpsUpdaterWorker(Context context, WorkerParameters workerParameters, x69 x69Var, nab nabVar, ef3 ef3Var, wp9 wp9Var) {
        super(context, workerParameters);
        context.getClass();
        workerParameters.getClass();
        x69Var.getClass();
        nabVar.getClass();
        ef3Var.getClass();
        wp9Var.getClass();
        this.g = workerParameters;
        this.h = x69Var;
        this.i = nabVar;
        this.j = ef3Var;
        this.k = wp9Var;
    }

    /* JADX WARN: Code duplicated, block: B:103:0x0249  */
    /* JADX WARN: Code duplicated, block: B:106:0x0269  */
    /* JADX WARN: Code duplicated, block: B:107:0x026a  */
    /* JADX WARN: Code duplicated, block: B:110:0x0277 A[Catch: all -> 0x0040, IOException -> 0x031a, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:112:0x02a6  */
    /* JADX WARN: Code duplicated, block: B:113:0x02a7 A[Catch: all -> 0x0040, IOException -> 0x031a, PHI: r0 r1 r3 r5 r6 r8
  0x02a7: PHI (r0v42 ??) = (r0v49 ??), (r0v46 ??) binds: [B:111:0x02a4, B:19:0x0050] A[DONT_GENERATE, DONT_INLINE]
  0x02a7: PHI (r1v40 int) = (r1v29 int), (r1v43 int) binds: [B:111:0x02a4, B:19:0x0050] A[DONT_GENERATE, DONT_INLINE]
  0x02a7: PHI (r3v43 yi8) = (r3v60 yi8), (r3v47 yi8) binds: [B:111:0x02a4, B:19:0x0050] A[DONT_GENERATE, DONT_INLINE]
  0x02a7: PHI (r5v25 int) = (r5v23 int), (r5v27 int) binds: [B:111:0x02a4, B:19:0x0050] A[DONT_GENERATE, DONT_INLINE]
  0x02a7: PHI (r6v30 java.lang.Object) = (r6v28 java.lang.Object), (r6v37 java.lang.Object) binds: [B:111:0x02a4, B:19:0x0050] A[DONT_GENERATE, DONT_INLINE]
  0x02a7: PHI (r8v4 boolean) = (r8v2 boolean), (r8v6 boolean) binds: [B:111:0x02a4, B:19:0x0050] A[DONT_GENERATE, DONT_INLINE], TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:115:0x02af A[Catch: all -> 0x0040, IOException -> 0x031a, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:119:0x02df A[Catch: all -> 0x0040, IOException -> 0x031a, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:121:0x02e7 A[Catch: all -> 0x0040, IOException -> 0x031a, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:129:0x030b A[Catch: all -> 0x0040, IOException -> 0x031a, TRY_LEAVE, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:70:0x0168  */
    /* JADX WARN: Code duplicated, block: B:73:0x017d  */
    /* JADX WARN: Code duplicated, block: B:75:0x0181 A[PHI: r3 r5
  0x0181: PHI (r3v16 boolean) = (r3v12 boolean), (r3v19 boolean) binds: [B:69:0x0166, B:74:0x017f] A[DONT_GENERATE, DONT_INLINE]
  0x0181: PHI (r5v6 iof) = (r5v3 iof), (r5v8 iof) binds: [B:69:0x0166, B:74:0x017f] A[DONT_GENERATE, DONT_INLINE]] */
    /* JADX WARN: Code duplicated, block: B:78:0x0195  */
    /* JADX WARN: Code duplicated, block: B:7:0x0017  */
    /* JADX WARN: Code duplicated, block: B:81:0x01b3  */
    /* JADX WARN: Code duplicated, block: B:82:0x01b5  */
    /* JADX WARN: Code duplicated, block: B:85:0x01c7 A[Catch: all -> 0x0040, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:86:0x01d5 A[Catch: all -> 0x0040, TRY_LEAVE, TryCatch #1 {all -> 0x0040, blocks: (B:13:0x003b, B:118:0x02da, B:132:0x031a, B:113:0x02a7, B:115:0x02af, B:108:0x026b, B:110:0x0277, B:119:0x02df, B:121:0x02e7, B:124:0x02f0, B:126:0x02f8, B:127:0x0305, B:128:0x030a, B:129:0x030b, B:104:0x024c, B:83:0x01b8, B:85:0x01c7, B:86:0x01d5, B:79:0x0199), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:89:0x01f4  */
    /* JADX WARN: Code duplicated, block: B:92:0x0204 A[Catch: all -> 0x00af, TryCatch #7 {all -> 0x00af, blocks: (B:36:0x00a3, B:90:0x0200, B:92:0x0204, B:94:0x0215, B:96:0x021b, B:98:0x0221, B:100:0x0230, B:41:0x00bd), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:94:0x0215 A[Catch: all -> 0x00af, TryCatch #7 {all -> 0x00af, blocks: (B:36:0x00a3, B:90:0x0200, B:92:0x0204, B:94:0x0215, B:96:0x021b, B:98:0x0221, B:100:0x0230, B:41:0x00bd), top: B:142:0x002e }] */
    /* JADX WARN: Code duplicated, block: B:95:0x021a  */
    /* JADX WARN: Code duplicated, block: B:98:0x0221 A[Catch: all -> 0x00af, TRY_LEAVE, TryCatch #7 {all -> 0x00af, blocks: (B:36:0x00a3, B:90:0x0200, B:92:0x0204, B:94:0x0215, B:96:0x021b, B:98:0x0221, B:100:0x0230, B:41:0x00bd), top: B:142:0x002e }] */
    /* JADX WARN: Code restructure failed: missing block: B:116:0x02d7, code lost:
    
        if (r12.c(r6, r2) == r4) goto L117;
     */
    /* JADX WARN: Code restructure failed: missing block: B:54:0x012f, code lost:
    
        if (r1 == r4) goto L117;
     */
    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Not initialized variable reg: 6, insn: 0x00b0: MOVE (r3 I:??[OBJECT, ARRAY]) = (r6 I:??[OBJECT, ARRAY]), block:B:39:0x00b0 */
    /* JADX WARN: Type inference failed for: r0v0, types: [com.gingerlabs.notability.data.library.state.notes.NoteOpsUpdaterWorker, java.lang.Object] */
    /* JADX WARN: Type inference failed for: r0v22 */
    /* JADX WARN: Type inference failed for: r0v26, types: [iof] */
    /* JADX WARN: Type inference failed for: r0v29 */
    /* JADX WARN: Type inference failed for: r0v30, types: [iof] */
    /* JADX WARN: Type inference failed for: r0v33 */
    /* JADX WARN: Type inference failed for: r0v34 */
    /* JADX WARN: Type inference failed for: r0v35, types: [iof, java.lang.Object] */
    /* JADX WARN: Type inference failed for: r0v4, types: [iof] */
    /* JADX WARN: Type inference failed for: r0v40 */
    /* JADX WARN: Type inference failed for: r0v41 */
    /* JADX WARN: Type inference failed for: r0v42, types: [iof] */
    /* JADX WARN: Type inference failed for: r0v45 */
    /* JADX WARN: Type inference failed for: r0v46 */
    /* JADX WARN: Type inference failed for: r0v49 */
    /* JADX WARN: Type inference failed for: r0v50 */
    /* JADX WARN: Type inference failed for: r0v51 */
    /* JADX WARN: Type inference failed for: r12v0, types: [x69] */
    /* JADX WARN: Type inference failed for: r3v0, types: [int] */
    /* JADX WARN: Type inference failed for: r3v1 */
    /* JADX WARN: Type inference failed for: r3v2, types: [yi8] */
    /* JADX WARN: Type inference failed for: r3v29 */
    /* JADX WARN: Type inference failed for: r3v3 */
    /* JADX WARN: Type inference failed for: r3v31 */
    /* JADX WARN: Type inference failed for: r3v35 */
    /* JADX WARN: Type inference failed for: r3v36 */
    /* JADX WARN: Type inference failed for: r3v4, types: [yi8] */
    /* JADX WARN: Type inference failed for: r3v40 */
    /* JADX WARN: Type inference failed for: r3v41 */
    /* JADX WARN: Type inference failed for: r3v45 */
    /* JADX WARN: Type inference failed for: r3v46 */
    /* JADX WARN: Type inference failed for: r3v55 */
    /* JADX WARN: Type inference failed for: r3v56 */
    /* JADX WARN: Type inference failed for: r3v57 */
    /* JADX WARN: Type inference failed for: r3v58 */
    /* JADX WARN: Type inference failed for: r3v59 */
    /* JADX WARN: Type inference fix 'apply assigned field type' failed
    java.lang.UnsupportedOperationException: ArgType.getObject(), call class: class jadx.core.dex.instructions.args.ArgType$UnknownArg
    	at jadx.core.dex.instructions.args.ArgType.getObject(ArgType.java:596)
    	at jadx.core.dex.attributes.nodes.ClassTypeVarsAttr.getTypeVarsMapFor(ClassTypeVarsAttr.java:35)
    	at jadx.core.dex.nodes.utils.TypeUtils.replaceClassGenerics(TypeUtils.java:177)
    	at jadx.core.dex.visitors.typeinference.FixTypesVisitor.insertExplicitUseCast(FixTypesVisitor.java:397)
    	at jadx.core.dex.visitors.typeinference.FixTypesVisitor.tryFieldTypeWithNewCasts(FixTypesVisitor.java:359)
    	at jadx.core.dex.visitors.typeinference.FixTypesVisitor.applyFieldType(FixTypesVisitor.java:309)
    	at jadx.core.dex.visitors.typeinference.FixTypesVisitor.visit(FixTypesVisitor.java:94)
     */
    @Override // androidx.work.CoroutineWorker
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public final java.lang.Object b(defpackage.ce2 r18) throws java.lang.Throwable {
        /*
            Method dump skipped, instruction units count: 846
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: com.gingerlabs.notability.data.library.state.notes.NoteOpsUpdaterWorker.b(ce2):java.lang.Object");
    }
}
