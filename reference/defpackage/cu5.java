package defpackage;

import android.content.Context;
import android.graphics.Matrix;
import android.graphics.Path;
import android.util.Log;
import android.view.MotionEvent;
import android.widget.FrameLayout;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CountDownLatch;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes.dex */
public final class cu5 extends FrameLayout {
    public static final Matrix T = new Matrix();
    public boolean I;
    public long J;
    public e1d K;
    public Function0 L;
    public Path M;
    public final Matrix N;
    public gs6 O;
    public in P;
    public final LinkedHashSet Q;
    public final LinkedHashMap R;
    public final pg8 S;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public cu5(Context context) {
        super(context, null, 0);
        context.getClass();
        this.N = new Matrix();
        this.Q = new LinkedHashSet();
        this.R = new LinkedHashMap();
        this.S = new pg8();
    }

    /* JADX WARN: Code duplicated, block: B:16:0x004f A[DONT_INVERT] */
    /* JADX WARN: Code duplicated, block: B:17:0x0051 A[LOOP:0: B:5:0x000e->B:17:0x0051, LOOP_END] */
    /* JADX WARN: Code duplicated, block: B:25:0x0054 A[EDGE_INSN: B:25:0x0054->B:18:0x0054 BREAK  A[LOOP:0: B:5:0x000e->B:17:0x0051], SYNTHETIC] */
    public static void b(cu5 cu5Var, mu5 mu5Var) {
        jv5 jv5Var;
        mu5Var.getClass();
        pg8 pg8Var = cu5Var.S;
        long[] jArr = pg8Var.a;
        int length = jArr.length - 2;
        if (length >= 0) {
            int i = 0;
            while (true) {
                long j = jArr[i];
                if ((((~j) << 7) & j & (-9187201950435737472L)) == -9187201950435737472L) {
                    if (i != length) {
                        break;
                        break;
                    }
                    i++;
                } else {
                    int i2 = 8 - ((~(i - length)) >>> 31);
                    for (int i3 = 0; i3 < i2; i3++) {
                        if ((255 & j) < 128) {
                            int i4 = (i << 3) + i3;
                            int i5 = pg8Var.b[i4];
                            if (x76.p((mu5) pg8Var.c[i4], mu5Var)) {
                                pg8Var.i(i4);
                            }
                        }
                        j >>= 8;
                    }
                    if (i2 != 8) {
                        break;
                    } else if (i != length) {
                        break;
                    } else {
                        i++;
                    }
                }
            }
        }
        in inVar = cu5Var.P;
        if (inVar == null || (jv5Var = (jv5) inVar.L) == null) {
            return;
        }
        jv5Var.c(mu5Var);
    }

    public static /* synthetic */ void getInProgressShapeCounter$annotations() {
    }

    private static /* synthetic */ void getLatencyDataCallback$annotations() {
    }

    @l83
    public static /* synthetic */ void getUseHighLatencyRenderHelper$annotations() {
    }

    public final void a(MotionEvent motionEvent, int i, MotionEvent motionEvent2) {
        in inVar;
        jv5 jv5Var;
        fi8 fi8Var;
        qu5 qu5Var;
        int iFindPointerIndex;
        mu5 mu5Var = (mu5) this.S.b(i);
        if (mu5Var == null || (inVar = this.P) == null || (jv5Var = (jv5) inVar.L) == null) {
            return;
        }
        MotionEvent motionEvent3 = null;
        if (motionEvent2 != null) {
            if (motionEvent2.getEventTime() != 0) {
                int historySize = motionEvent2.getHistorySize();
                int i2 = 0;
                while (true) {
                    if (i2 >= historySize) {
                        motionEvent3 = motionEvent2;
                        break;
                    } else {
                        if (motionEvent2.getHistoricalEventTime(i2) == 0) {
                            Log.e("InProgressStrokesView", "Prediction motionevent has historicalEventTime[" + i2 + "] = 0L and is being ignored.");
                            break;
                        }
                        i2++;
                    }
                }
            } else {
                Log.e("InProgressStrokesView", "prediction motionevent has eventTime = 0L and is being ignored.");
            }
        }
        t52 t52Var = jv5Var.m;
        long jLongValue = ((Number) jv5Var.e.invoke()).longValue();
        hv5 hv5VarB = jv5Var.b(mu5Var);
        if (!hv5VarB.a()) {
            yz3.s("Stroke ID ", mu5Var, " was started with a StrokeInput but added to with a MotionEvent");
            return;
        }
        int iFindPointerIndex2 = motionEvent.findPointerIndex(i);
        if (iFindPointerIndex2 < 0) {
            c1c.h(f92.j(i, "Pointer id ", " is not present in event."));
            return;
        }
        qu5 qu5Var2 = (qu5) ((ConcurrentLinkedQueue) ((r45) t52Var.M).J).poll();
        if (qu5Var2 == null) {
            qu5Var2 = new qu5();
        }
        fi8 fi8Var2 = qu5Var2.b;
        fi8 fi8Var3 = qu5Var2.a;
        ((hda) t52Var.N).t(motionEvent, iFindPointerIndex2, hv5VarB.b(), hv5VarB.c(), hv5VarB.d(), null, null, null, qu5Var2.a);
        if (fi8Var3.f()) {
            fi8Var = fi8Var3;
        } else {
            fi8Var = fi8Var3;
            jv5Var.i.b(motionEvent, p7j.S, mu5Var, jLongValue, false, qu5Var2.d);
        }
        if (!fi8Var2.f()) {
            yz3.l("Check failed.");
            return;
        }
        if (!qu5Var2.e.isEmpty()) {
            yz3.l("Check failed.");
            return;
        }
        if (motionEvent3 == null || fi8Var.f() || (iFindPointerIndex = motionEvent3.findPointerIndex(i)) < 0) {
            qu5Var = qu5Var2;
        } else {
            qu5Var = qu5Var2;
            MotionEvent motionEvent4 = motionEvent3;
            ((hda) t52Var.N).t(motionEvent4, iFindPointerIndex, hv5VarB.b(), hv5VarB.c(), hv5VarB.d(), Boolean.valueOf(fi8Var.d()), Boolean.valueOf(fi8Var.e()), Boolean.valueOf(fi8Var.c()), qu5Var2.b);
            if (!fi8Var2.f()) {
                jv5Var.i.b(motionEvent4, p7j.T, mu5Var, jLongValue, true, qu5Var.e);
            }
        }
        qu5Var.c = mu5Var;
        if (fi8Var.f() && fi8Var2.f()) {
            ((r45) t52Var.M).C(qu5Var);
        } else {
            jv5Var.m(qu5Var);
        }
    }

    public final void c() {
        jv5 jv5Var;
        in inVar = this.P;
        if (inVar == null || (jv5Var = (jv5) inVar.L) == null) {
            return;
        }
        s4g.q();
        LinkedHashMap linkedHashMap = (LinkedHashMap) jv5Var.j.K;
        LinkedHashMap linkedHashMap2 = new LinkedHashMap();
        for (Map.Entry entry : linkedHashMap.entrySet()) {
            if (((iv5) entry.getValue()) instanceof hv5) {
                linkedHashMap2.put(entry.getKey(), entry.getValue());
            }
        }
        Iterator it = linkedHashMap2.keySet().iterator();
        while (it.hasNext()) {
            jv5Var.c((mu5) it.next());
        }
    }

    public final in d() {
        in inVar = this.P;
        if (inVar != null) {
            return inVar;
        }
        e1d e1dVar = this.K;
        if (e1dVar == null) {
            Function0 function0 = this.L;
            if (function0 == null) {
                yz3.l("Must set `InProgressShapesView.customShapeWorkflowFactory` before calling `startShape` or `eagerInit`. Consider using `InProgressStrokesView` instead for easier initialization and recommended behavior.");
                return null;
            }
            e1dVar = (e1d) function0.invoke();
            setCustomShapeWorkflow(e1dVar);
        }
        in inVar2 = new in(this, e1dVar);
        this.P = inVar2;
        if (isAttachedToWindow()) {
            addView((pe4) inVar2.J, 0);
        }
        return inVar2;
    }

    public final void e(Set set) {
        pe4 pe4Var;
        set.getClass();
        Iterator it = set.iterator();
        while (it.hasNext()) {
            this.R.remove((mu5) it.next());
        }
        in inVar = this.P;
        if (inVar == null || (pe4Var = (pe4) inVar.J) == null) {
            return;
        }
        Iterator it2 = set.iterator();
        while (it2.hasNext()) {
            pe4Var.K.remove((mu5) it2.next());
        }
        pe4Var.invalidate();
    }

    public final CountDownLatch getAwaitAfterStartOfHandoffTestLatch$ink_authoring() {
        return ((jv5) d().L).g;
    }

    public final Map<mu5, Object> getCompletedShapes() {
        return this.R;
    }

    public final CountDownLatch getCountDownWhenFlushInProgressTestLatch$ink_authoring() {
        return ((jv5) d().L).f;
    }

    public final e1d getCustomShapeWorkflow() {
        return this.K;
    }

    public final Function0 getCustomShapeWorkflowFactory$ink_authoring() {
        return this.L;
    }

    public final long getHandoffDebounceTimeMs$ink_authoring() {
        return this.J;
    }

    public final qh2 getInProgressShapeCounter() {
        return null;
    }

    public final gs6 getLatencyDataCallback() {
        return this.O;
    }

    public final Path getMaskPath() {
        return this.M;
    }

    public final Matrix getMotionEventToViewTransform() {
        return this.N;
    }

    public final boolean getUseHighLatencyRenderHelper() {
        return this.I;
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onAttachedToWindow() {
        super.onAttachedToWindow();
        in inVar = this.P;
        if (inVar != null) {
            ((cu5) inVar.M).addView((pe4) inVar.J, 0);
        }
    }

    @Override // android.view.ViewGroup, android.view.View
    public final void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        in inVar = this.P;
        if (inVar != null) {
            ((cu5) inVar.M).removeView((pe4) inVar.J);
        }
    }

    public final void setAwaitAfterStartOfHandoffTestLatch$ink_authoring(CountDownLatch countDownLatch) {
        ((jv5) d().L).g = countDownLatch;
    }

    public final void setCountDownWhenFlushInProgressTestLatch$ink_authoring(CountDownLatch countDownLatch) {
        ((jv5) d().L).f = countDownLatch;
    }

    public final void setCustomShapeWorkflow(e1d e1dVar) {
        if (this.P == null) {
            this.K = e1dVar;
        } else {
            yz3.l("Cannot set customShapeAdapter after initialization.");
        }
    }

    public final void setCustomShapeWorkflowFactory$ink_authoring(Function0 function0) {
        this.L = function0;
    }

    public final void setHandoffDebounceTimeMs$ink_authoring(long j) {
        jv5 jv5Var;
        if (j < 0) {
            c1c.h(nt6.m(j, "Debounce time must not be negative, received "));
            return;
        }
        this.J = j;
        in inVar = this.P;
        if (inVar == null || (jv5Var = (jv5) inVar.L) == null || !jv5Var.a.g()) {
            return;
        }
        s4g.q();
        jv5Var.j.I = j;
        jv5Var.l();
    }

    public final void setInProgressShapeCounter(qh2 qh2Var) {
        in inVar = this.P;
        if (inVar != null) {
            ((jv5) inVar.L).getClass();
        }
    }

    public final void setLatencyDataCallback(gs6 gs6Var) {
        this.O = gs6Var;
    }

    public final void setMaskPath(Path path) {
        this.M = path;
        in inVar = this.P;
        if (inVar != null) {
            ((mo0) inVar.K).b = path;
        }
    }

    public final void setMotionEventToViewTransform(Matrix matrix) {
        matrix.getClass();
        this.N.set(matrix);
        in inVar = this.P;
        if (inVar != null) {
            jv5 jv5Var = (jv5) inVar.L;
            jv5Var.getClass();
            jv5Var.h.set(matrix);
            jv5Var.m(new vu5(new Matrix(matrix)));
        }
    }

    public final void setUseHighLatencyRenderHelper(boolean z) {
        this.I = z;
    }
}
