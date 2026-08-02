package defpackage;

import android.graphics.Matrix;
import androidx.ink.geometry.BoxAccumulator;
import androidx.ink.geometry.ImmutableBox;
import androidx.ink.geometry.MutableBox;
import androidx.ink.strokes.StrokeInput;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicBoolean;
import kotlin.jvm.functions.Function0;

/* JADX INFO: loaded from: classes.dex */
public final class jv5 {
    public final mo0 a;
    public final d2 b;
    public final au5 c;
    public final gs6 d;
    public final Function0 e;
    public CountDownLatch f;
    public CountDownLatch g;
    public final Matrix h;
    public final hs6 i;
    public final s95 j;
    public final o2 k;
    public final jx2 l;
    public final t52 m;

    public jv5(mo0 mo0Var, e1d e1dVar, d2 d2Var, au5 au5Var, sa saVar) {
        ou5 ou5Var = ou5.I;
        d30 d30Var = new d30(e1dVar);
        e1dVar.getClass();
        this.a = mo0Var;
        this.b = d2Var;
        this.c = au5Var;
        this.d = saVar;
        this.e = ou5Var;
        this.h = new Matrix();
        this.i = new hs6();
        this.j = new s95();
        this.k = new o2(this, 7);
        this.l = new jx2(this, d30Var);
        this.m = new t52(this);
    }

    public static void f(jv5 jv5Var, StrokeInput strokeInput, mu5 mu5Var, long j, fs6 fs6Var, int i) {
        if ((i & 16) != 0) {
            fs6Var = null;
        }
        jv5Var.b(mu5Var);
        s4g.q();
        s95 s95Var = jv5Var.j;
        s95Var.J = j;
        s4g.q();
        ((LinkedHashMap) s95Var.K).put(mu5Var, gv5.a);
        jv5Var.m(new tu5(strokeInput, mu5Var, fs6Var));
    }

    public final void a() {
        this.a.b();
    }

    public final hv5 b(mu5 mu5Var) {
        s4g.q();
        iv5 iv5Var = (iv5) ((LinkedHashMap) this.j.K).get(mu5Var);
        if (iv5Var instanceof hv5) {
            return (hv5) iv5Var;
        }
        if (iv5Var instanceof ev5) {
            rc6.v("Stroke with ID ", mu5Var, " was already canceled.");
            return null;
        }
        if ((iv5Var instanceof gv5) || (iv5Var instanceof fv5)) {
            rc6.v("Stroke with ID ", mu5Var, " is already finished.");
            return null;
        }
        if (iv5Var == null) {
            rc6.v("Stroke with ID ", mu5Var, " was not found.");
            return null;
        }
        yz3.t();
        return null;
    }

    public final void c(mu5 mu5Var) {
        mu5Var.getClass();
        long jLongValue = ((Number) this.e.invoke()).longValue();
        s4g.q();
        s95 s95Var = this.j;
        if (((LinkedHashMap) s95Var.K).get(mu5Var) instanceof hv5) {
            s4g.q();
            ((LinkedHashMap) s95Var.K).put(mu5Var, ev5.a);
            s4g.q();
            s95Var.J = jLongValue / 1000000;
            m(new su5(mu5Var, hs6.c(this.i, null, p7j.V, mu5Var, jLongValue)));
        }
    }

    public final void d(MutableBox mutableBox) {
        mo0 mo0Var = this.a;
        mo0Var.m(mutableBox);
        a();
        jx2 jx2Var = this.l;
        for (bv5 bv5Var : ((LinkedHashMap) jx2Var.c).values()) {
            if (!bv5Var.a().m()) {
                e(bv5Var);
                yt5 yt5VarA = bv5Var.a();
                a();
                mo0Var.c(yt5VarA, (Matrix) jx2Var.g);
            }
        }
        mo0Var.a();
    }

    public final void e(bv5 bv5Var) {
        a();
        jx2 jx2Var = this.l;
        ((Matrix) jx2Var.g).set(bv5Var.c());
        a();
        Matrix matrix = (Matrix) jx2Var.g;
        a();
        matrix.postConcat((Matrix) jx2Var.f);
    }

    public final void g() {
        ConcurrentLinkedQueue concurrentLinkedQueue = (ConcurrentLinkedQueue) this.m.O;
        a();
        jx2 jx2Var = this.l;
        concurrentLinkedQueue.addAll((b80) jx2Var.e);
        a();
        ((b80) jx2Var.e).clear();
        this.c.invoke(this.k);
    }

    public final void h(mu5 mu5Var, bv5 bv5Var) {
        Object objF = bv5Var.a().f();
        if (objF == null) {
            bv5Var.f(yu5.a);
            return;
        }
        bv5Var.f(xu5.a);
        ConcurrentLinkedQueue concurrentLinkedQueue = (ConcurrentLinkedQueue) this.m.K;
        a();
        jx2 jx2Var = this.l;
        concurrentLinkedQueue.add(new qe4(mu5Var, objF, new Matrix((Matrix) jx2Var.g)));
        a();
        jx2Var.a = true;
    }

    public final void i() {
        mo0 mo0Var;
        BoxAccumulator boxAccumulator;
        BoxAccumulator boxAccumulator2;
        MutableBox mutableBox;
        ConcurrentLinkedQueue concurrentLinkedQueue;
        boolean z;
        d30 d30Var;
        b80 b80Var;
        jx2 jx2Var;
        a();
        a();
        jx2 jx2Var2 = this.l;
        ArrayList arrayList = (ArrayList) jx2Var2.h;
        BoxAccumulator boxAccumulator3 = (BoxAccumulator) jx2Var2.i;
        d30 d30Var2 = (d30) jx2Var2.d;
        b80 b80Var2 = (b80) jx2Var2.e;
        MutableBox mutableBox2 = (MutableBox) jx2Var2.j;
        LinkedHashMap linkedHashMap = (LinkedHashMap) jx2Var2.c;
        if (!arrayList.isEmpty()) {
            yz3.l("Check failed.");
            return;
        }
        t52 t52Var = this.m;
        AtomicBoolean atomicBoolean = (AtomicBoolean) t52Var.P;
        hda hdaVar = (hda) t52Var.N;
        ConcurrentLinkedQueue concurrentLinkedQueue2 = (ConcurrentLinkedQueue) t52Var.L;
        if (atomicBoolean.get()) {
            return;
        }
        boolean z2 = true;
        ((AtomicBoolean) t52Var.R).set(true);
        ((Number) this.e.invoke()).longValue();
        while (true) {
            boolean zIsEmpty = concurrentLinkedQueue2.isEmpty();
            mo0Var = this.a;
            if (zIsEmpty || ((concurrentLinkedQueue2.peek() instanceof dv5) && ((AtomicBoolean) t52Var.P).get())) {
                break;
            }
            pu5 pu5Var = (pu5) concurrentLinkedQueue2.poll();
            if (pu5Var == null) {
                yz3.l("Actions should only be removed by onDraw.");
                return;
            }
            a();
            if (pu5Var instanceof cv5) {
                cv5 cv5Var = (cv5) pu5Var;
                a();
                Matrix matrix = new Matrix();
                Matrix matrix2 = cv5Var.c;
                z = z2;
                StrokeInput strokeInput = cv5Var.a;
                matrix2.invert(matrix);
                Object obj = cv5Var.d;
                a();
                d30Var2.getClass();
                e1d e1dVar = (e1d) d30Var2.J;
                concurrentLinkedQueue = concurrentLinkedQueue2;
                int iD = e1dVar.d(obj);
                mutableBox = mutableBox2;
                pg8 pg8Var = (pg8) d30Var2.K;
                Object objB = pg8Var.b(iD);
                boxAccumulator2 = boxAccumulator3;
                if (objB == null) {
                    nu5 nu5Var = new nu5();
                    pg8Var.j(iD, nu5Var);
                    objB = nu5Var;
                }
                nu5 nu5Var2 = (nu5) objB;
                ArrayList arrayList2 = nu5Var2.a;
                arrayList2.getClass();
                Object objRemove = arrayList2.isEmpty() ? null : arrayList2.remove(0);
                if (objRemove == null) {
                    objRemove = e1dVar.b(iD);
                }
                nu5Var2.b = nu5Var2.e() + 1;
                nu5Var2.c++;
                yt5 yt5Var = (yt5) objRemove;
                ((fh8) d30Var2.L).h(iD, yt5Var);
                d30Var = d30Var2;
                b80Var = b80Var2;
                bv5 bv5Var = new bv5(yt5Var, matrix, cv5Var.f);
                yt5Var.b(obj);
                fi8 fi8Var = new fi8();
                try {
                    fi8Var.h(strokeInput);
                } catch (Throwable unused) {
                }
                yt5Var.e(fi8Var, nq5.c);
                bv5Var.a().g();
                hdaVar.getClass();
                strokeInput.getClass();
                ((ConcurrentLinkedQueue) hdaVar.J).offer(strokeInput);
                a();
                linkedHashMap.put(cv5Var.b, bv5Var);
                fs6 fs6Var = cv5Var.e;
                if (fs6Var != null) {
                    a();
                    b80Var.addLast(fs6Var);
                }
            } else {
                jx2Var2 = jx2Var2;
                boxAccumulator2 = boxAccumulator3;
                mutableBox = mutableBox2;
                concurrentLinkedQueue = concurrentLinkedQueue2;
                z = z2;
                d30Var = d30Var2;
                b80Var = b80Var2;
                if (pu5Var instanceof qu5) {
                    qu5 qu5Var = (qu5) pu5Var;
                    a();
                    a();
                    bv5 bv5Var2 = (bv5) linkedHashMap.get(qu5Var.c);
                    if (bv5Var2 == null) {
                        yz3.s("Stroke state with ID ", qu5Var.c, " was not found.");
                        return;
                    }
                    if (!(bv5Var2.b() instanceof zu5)) {
                        yz3.s("Stroke with ID ", qu5Var.c, " was already finished.");
                        return;
                    }
                    if (bv5Var2.a().m()) {
                        yz3.s("Stroke with ID ", qu5Var.c, " was canceled.");
                        return;
                    }
                    bv5Var2.a().e(qu5Var.a, qu5Var.b);
                    a();
                    b80Var.addAll(qu5Var.d);
                    a();
                    b80Var.addAll(qu5Var.e);
                    ((r45) t52Var.M).C(qu5Var);
                } else if (pu5Var instanceof tu5) {
                    tu5 tu5Var = (tu5) pu5Var;
                    a();
                    a();
                    mu5 mu5Var = tu5Var.b;
                    StrokeInput strokeInput2 = tu5Var.a;
                    bv5 bv5Var3 = (bv5) linkedHashMap.get(mu5Var);
                    if (bv5Var3 == null) {
                        yz3.s("Stroke state with ID ", mu5Var, " was not found.");
                        return;
                    }
                    if (!(bv5Var3.b() instanceof zu5)) {
                        yz3.s("Stroke with ID ", mu5Var, " was already finished.");
                        return;
                    }
                    if (bv5Var3.a().m()) {
                        yz3.s("Stroke with ID ", mu5Var, " was canceled.");
                        return;
                    }
                    yt5 yt5VarA = bv5Var3.a();
                    if (yt5VarA.m()) {
                        yz3.s("Stroke with ID ", mu5Var, " was canceled.");
                        return;
                    }
                    e(bv5Var3);
                    if (strokeInput2 != null) {
                        fi8 fi8Var2 = new fi8();
                        try {
                            fi8Var2.h(strokeInput2);
                        } catch (Throwable unused2) {
                        }
                        yt5VarA.e(fi8Var2, nq5.c);
                    }
                    yt5VarA.finishInput();
                    bv5Var3.a().g();
                    h(mu5Var, bv5Var3);
                    if (strokeInput2 != null) {
                        hdaVar.getClass();
                        ((ConcurrentLinkedQueue) hdaVar.J).offer(strokeInput2);
                    }
                    fs6 fs6Var2 = tu5Var.c;
                    if (fs6Var2 != null) {
                        a();
                        b80Var.addLast(fs6Var2);
                    }
                } else {
                    if (pu5Var instanceof su5) {
                        su5 su5Var = (su5) pu5Var;
                        a();
                        a();
                        mu5 mu5Var2 = su5Var.a;
                        Object obj2 = linkedHashMap.get(mu5Var2);
                        if (obj2 == null) {
                            yz3.s("Stroke state with ID ", mu5Var2, " was not found.");
                            return;
                        }
                        bv5 bv5Var4 = (bv5) obj2;
                        if (!(bv5Var4.b() instanceof zu5)) {
                            yz3.s("Stroke with ID ", mu5Var2, " was already finished.");
                            return;
                        } else {
                            bv5Var4.a().cancel();
                            a();
                            b80Var.addLast(su5Var.b);
                        }
                    } else if (pu5Var instanceof vu5) {
                        a();
                        a();
                        jx2Var = jx2Var2;
                        ((Matrix) jx2Var.f).set(((vu5) pu5Var).a);
                    } else {
                        jx2Var = jx2Var2;
                        if (pu5Var instanceof dv5) {
                            a();
                            a();
                            for (bv5 bv5Var5 : linkedHashMap.values()) {
                                a();
                                d30Var.J(bv5Var5.a());
                            }
                            a();
                            linkedHashMap.clear();
                            mo0Var.p();
                        }
                    }
                    a();
                    ((ArrayList) jx2Var.h).add(pu5Var);
                    jx2Var2 = jx2Var;
                    d30Var2 = d30Var;
                    b80Var2 = b80Var;
                    z2 = z;
                    concurrentLinkedQueue2 = concurrentLinkedQueue;
                    mutableBox2 = mutableBox;
                    boxAccumulator3 = boxAccumulator2;
                }
            }
            jx2Var = jx2Var2;
            a();
            ((ArrayList) jx2Var.h).add(pu5Var);
            jx2Var2 = jx2Var;
            d30Var2 = d30Var;
            b80Var2 = b80Var;
            z2 = z;
            concurrentLinkedQueue2 = concurrentLinkedQueue;
            mutableBox2 = mutableBox;
            boxAccumulator3 = boxAccumulator2;
        }
        BoxAccumulator boxAccumulator4 = boxAccumulator3;
        MutableBox mutableBox3 = mutableBox2;
        jx2 jx2Var3 = jx2Var2;
        a();
        Iterator it = linkedHashMap.values().iterator();
        while (it.hasNext()) {
            ((bv5) it.next()).a().g();
        }
        if (!mo0Var.f()) {
            a();
            mutableBox3.setXBounds(Float.NEGATIVE_INFINITY, Float.POSITIVE_INFINITY);
            a();
            mutableBox3.setYBounds(Float.NEGATIVE_INFINITY, Float.POSITIVE_INFINITY);
            a();
            d(mutableBox3);
            return;
        }
        a();
        for (bv5 bv5Var6 : linkedHashMap.values()) {
            a();
            ImmutableBox immutableBoxD = bv5Var6.a().d();
            boxAccumulator4.reset();
            if (immutableBoxD != null) {
                boxAccumulator = boxAccumulator4;
                boxAccumulator.a(immutableBoxD.getA(), immutableBoxD.getB());
                boxAccumulator.a(immutableBoxD.getC(), immutableBoxD.getD());
            } else {
                boxAccumulator = boxAccumulator4;
            }
            bv5Var6.a().a();
            a();
            MutableBox mutableBox4 = boxAccumulator.b ? boxAccumulator.a : null;
            if (mutableBox4 != null) {
                a();
                mutableBox3.getClass();
                mutableBox3.a = mutableBox4.a;
                mutableBox3.b = mutableBox4.b;
                mutableBox3.c = mutableBox4.c;
                mutableBox3.d = mutableBox4.d;
                e(bv5Var6);
                a();
                a();
                bg8.b(mutableBox3, (Matrix) jx2Var3.g);
                a();
                d(mutableBox3);
            }
            boxAccumulator4 = boxAccumulator;
        }
    }

    public final void j() throws Throwable {
        a();
        jx2 jx2Var = this.l;
        ArrayList arrayList = (ArrayList) jx2Var.h;
        LinkedHashMap linkedHashMap = (LinkedHashMap) jx2Var.c;
        Iterator it = arrayList.iterator();
        it.getClass();
        while (it.hasNext()) {
            Object next = it.next();
            next.getClass();
            pu5 pu5Var = (pu5) next;
            a();
            if (pu5Var instanceof ru5) {
                a();
                for (Map.Entry entry : linkedHashMap.entrySet()) {
                    mu5 mu5Var = (mu5) entry.getKey();
                    bv5 bv5Var = (bv5) entry.getValue();
                    if (bv5Var.b() instanceof yu5) {
                        h(mu5Var, bv5Var);
                    }
                }
            } else if (pu5Var instanceof su5) {
                a();
                bv5 bv5Var2 = (bv5) linkedHashMap.remove(((su5) pu5Var).a);
                if (bv5Var2 != null) {
                    a();
                    ((d30) jx2Var.d).J(bv5Var2.a());
                }
                a();
                jx2Var.a = true;
            }
        }
        a();
        ((ArrayList) jx2Var.h).clear();
        ((AtomicBoolean) this.m.R).set(false);
        a();
        if (jx2Var.a) {
            a();
            Collection collectionValues = linkedHashMap.values();
            if (!(collectionValues instanceof Collection) || !collectionValues.isEmpty()) {
                Iterator it2 = collectionValues.iterator();
                do {
                    if (!it2.hasNext()) {
                        l();
                        break;
                    }
                } while (((bv5) it2.next()).d());
            } else {
                l();
                break;
            }
            a();
            jx2Var.a = false;
        }
        a();
        Collection collectionValues2 = linkedHashMap.values();
        if ((collectionValues2 instanceof Collection) && collectionValues2.isEmpty()) {
            return;
        }
        Iterator it3 = collectionValues2.iterator();
        if (it3.hasNext()) {
            ((bv5) it3.next()).e();
            a();
            d30 d30Var = (d30) jx2Var.b;
            ((AtomicBoolean) d30Var.K).set(true);
            this.b.invoke((o2) d30Var.L);
        }
    }

    public final void k(List list) {
        list.getClass();
        s4g.q();
        for (bu5 bu5Var : (LinkedHashSet) this.j.L) {
            cu5 cu5Var = bu5Var.b;
            pe4 pe4Var = (pe4) bu5Var.a.J;
            pe4Var.getClass();
            LinkedHashMap linkedHashMap = pe4Var.K;
            for (Object obj : list) {
                linkedHashMap.put(((qe4) obj).b(), obj);
            }
            pe4Var.invalidate();
            LinkedHashMap linkedHashMap2 = new LinkedHashMap();
            Iterator it = list.iterator();
            while (it.hasNext()) {
                qe4 qe4Var = (qe4) it.next();
                linkedHashMap2.put(qe4Var.b(), qe4Var.a());
            }
            cu5Var.R.putAll(linkedHashMap2);
            for (tzf tzfVar : cu5Var.Q) {
                tzfVar.getClass();
                uzf uzfVar = tzfVar.a;
                LinkedHashSet linkedHashSet = uzfVar.k;
                if (!linkedHashSet.isEmpty()) {
                    Set setKeySet = linkedHashMap2.keySet();
                    LinkedHashSet linkedHashSet2 = new LinkedHashSet();
                    for (Object obj2 : setKeySet) {
                        if (linkedHashSet.contains((mu5) obj2)) {
                            linkedHashSet2.add(obj2);
                        }
                    }
                    if (!linkedHashSet2.isEmpty()) {
                        uzfVar.a.e(linkedHashSet2);
                        linkedHashSet.removeAll(zs1.T0(linkedHashSet2));
                    }
                }
                LinkedHashSet linkedHashSet3 = uzfVar.h;
                for (Map.Entry entry : linkedHashMap2.entrySet()) {
                    mu5 mu5Var = (mu5) entry.getKey();
                    kzf kzfVar = (kzf) entry.getValue();
                    Function0 function0 = (Function0) kzfVar.d().getAndSet(null);
                    if (function0 != null) {
                        function0.invoke();
                    }
                    if (kzfVar.f() == null) {
                        linkedHashSet3.add(mu5Var);
                    }
                }
                if (!linkedHashSet3.isEmpty()) {
                    uzfVar.a(linkedHashSet3);
                    linkedHashSet3.clear();
                }
            }
        }
    }

    public final void l() {
        d30 d30Var = (d30) this.m.J;
        ((AtomicBoolean) d30Var.K).set(true);
        this.b.invoke((o2) d30Var.L);
    }

    public final void m(pu5 pu5Var) {
        t52 t52Var = this.m;
        ((ConcurrentLinkedQueue) t52Var.L).offer(pu5Var);
        if (((AtomicBoolean) t52Var.P).get()) {
            return;
        }
        this.a.n();
    }

    public final void n(cw4 cw4Var) {
        cw4Var.getClass();
        long jLongValue = ((Number) this.e.invoke()).longValue();
        a();
        Iterator<E> it = ((b80) this.l.e).iterator();
        while (it.hasNext()) {
            cw4Var.invoke((fs6) it.next(), Long.valueOf(jLongValue));
        }
    }
}
