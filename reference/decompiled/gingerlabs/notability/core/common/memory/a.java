package com.gingerlabs.notability.core.common.memory;

import android.os.SharedMemory;
import android.system.ErrnoException;
import defpackage.bl7;
import defpackage.c1c;
import defpackage.cl7;
import defpackage.g3d;
import defpackage.h3d;
import defpackage.i3d;
import defpackage.jm7;
import defpackage.rc6;
import defpackage.ru3;
import defpackage.tg2;
import defpackage.xs7;
import defpackage.zs1;
import java.lang.ref.Reference;
import java.lang.ref.ReferenceQueue;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;

/* JADX INFO: loaded from: classes.dex */
public abstract class a implements AutoCloseable {
    public final String I;
    public final ByteOrder J;
    public final String K;
    public final String L;
    public final String M;
    public final ArrayList N = new ArrayList(4);
    public final HashSet O = new HashSet();
    public final ReferenceQueue P = new ReferenceQueue();
    public final ByteBuffer Q;
    public volatile boolean R;
    public long S;
    public long T;
    public long U;
    public int V;

    public a(String str, ByteOrder byteOrder, String str2, String str3, String str4) {
        this.I = str;
        this.J = byteOrder;
        this.K = str2;
        this.L = str3;
        this.M = str4;
        ByteBuffer byteBufferOrder = ByteBuffer.allocate(0).order(byteOrder);
        byteBufferOrder.getClass();
        this.Q = byteBufferOrder;
    }

    public final h3d a(int i) throws ErrnoException {
        ArrayList arrayList = this.N;
        h3d h3dVar = (h3d) zs1.o1(arrayList);
        if (h3dVar != null && h3dVar.c + i <= h3dVar.b.capacity()) {
            return h3dVar;
        }
        int iMax = Math.max(4194304, i);
        SharedMemory sharedMemoryCreate = SharedMemory.create(this.I, iMax);
        sharedMemoryCreate.getClass();
        try {
            ByteBuffer byteBufferOrder = sharedMemoryCreate.mapReadWrite().order(this.J);
            byteBufferOrder.getClass();
            h3d h3dVar2 = new h3d(sharedMemoryCreate, byteBufferOrder);
            arrayList.add(h3dVar2);
            long j = this.T + ((long) iMax);
            this.T = j;
            if (j > this.U) {
                this.U = j;
            }
            return h3dVar2;
        } catch (ErrnoException e) {
            sharedMemoryCreate.close();
            throw e;
        }
    }

    public final ByteBuffer b(int i) {
        g3d g3dVarE;
        ByteBuffer byteBufferOrder;
        if (i < 0) {
            c1c.h(tg2.l(i, "sizeBytes must be non-negative: "));
            return null;
        }
        if (i == 0) {
            if (this.R) {
                throw new SharedMemoryByteArena$ArenaClosedException(this.I.concat(" arena is closed"));
            }
            return this.Q;
        }
        synchronized (this) {
            if (this.R) {
                throw new SharedMemoryByteArena$ArenaClosedException(this.I.concat(" arena is closed"));
            }
            g3dVarE = e();
            h3d h3dVarA = a(i);
            h3dVarA.b.position(h3dVarA.c).limit(h3dVarA.c + i);
            byteBufferOrder = h3dVarA.b.slice().order(this.J);
            byteBufferOrder.getClass();
            h3dVarA.b.clear();
            i3d i3dVar = new i3d(byteBufferOrder, this.P, h3dVarA);
            try {
                this.O.add(i3dVar);
                h3dVarA.c += i;
                h3dVarA.d++;
                this.S += (long) i;
            } catch (Throwable th) {
                i3dVar.clear();
                throw th;
            }
        }
        m(g3dVarE);
        for (h3d h3dVar : g3dVarE.a) {
            SharedMemory.unmap(h3dVar.b);
            h3dVar.a.close();
        }
        return byteBufferOrder;
    }

    @Override // java.lang.AutoCloseable
    public final void close() {
        synchronized (this) {
            try {
                if (this.R) {
                    return;
                }
                this.R = true;
                g3d g3dVarE = e();
                ArrayList<h3d> arrayList = new ArrayList(g3dVarE.a.size() + this.N.size());
                arrayList.addAll(g3dVarE.a);
                Iterator it = this.N.iterator();
                it.getClass();
                int i = 0;
                while (it.hasNext()) {
                    Object next = it.next();
                    next.getClass();
                    h3d h3dVar = (h3d) next;
                    if (h3dVar.d == 0) {
                        arrayList.add(h3dVar);
                        it.remove();
                    } else {
                        i++;
                    }
                }
                long j = this.S;
                long j2 = this.T;
                long j3 = this.U;
                int i2 = this.V;
                int size = this.O.size();
                m(g3dVarE);
                ArrayList arrayList2 = com.gingerlabs.notability.core.common.logging.a.a;
                cl7 cl7Var = cl7.INK;
                String str = this.K;
                jm7 jm7Var = jm7.K;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                    try {
                        bl7 bl7Var = new bl7();
                        bl7Var.put("regions.deferred", Integer.valueOf(i));
                        bl7Var.put("bytes_allocated", Long.valueOf(j));
                        bl7Var.put("bytes_reserved", Long.valueOf(j2));
                        bl7Var.put("peak_bytes_reserved", Long.valueOf(j3));
                        bl7Var.put("regions_recycled_during_life", Integer.valueOf(i2));
                        bl7Var.put("outstanding_slices", Integer.valueOf(size));
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, str, null, xs7.R(bl7Var));
                    } catch (Exception e) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, str, e);
                    }
                }
                for (h3d h3dVar2 : arrayList) {
                    SharedMemory.unmap(h3dVar2.b);
                    h3dVar2.a.close();
                }
            } catch (Throwable th) {
                throw th;
            }
        }
    }

    public final g3d e() {
        int i = 0;
        long j = 0;
        ArrayList arrayList = null;
        while (true) {
            Reference referencePoll = this.P.poll();
            HashSet hashSet = this.O;
            ArrayList arrayList2 = this.N;
            if (referencePoll == null) {
                if (i > 0) {
                    this.V += i;
                }
                List list = arrayList;
                if (arrayList == null) {
                    list = ru3.I;
                }
                return new g3d(list, i, j, arrayList2.size(), hashSet.size());
            }
            i3d i3dVar = (i3d) referencePoll;
            hashSet.remove(i3dVar);
            h3d h3dVar = i3dVar.a;
            i3dVar.clear();
            int i2 = h3dVar.d - 1;
            h3dVar.d = i2;
            if (i2 < 0) {
                rc6.i(this.I.concat(" arena: region.liveSlices went negative — refcounting bug"));
                return null;
            }
            if (i2 == 0 && h3dVar != zs1.o1(arrayList2) && arrayList2.remove(h3dVar)) {
                long jCapacity = h3dVar.b.capacity();
                j += jCapacity;
                this.T -= jCapacity;
                arrayList = arrayList;
                if (arrayList == null) {
                    arrayList = new ArrayList();
                }
                arrayList.add(h3dVar);
                i++;
            }
        }
    }

    public final void m(g3d g3dVar) {
        int i = g3dVar.b;
        if (i == 0) {
            return;
        }
        ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
        String str = this.L;
        jm7 jm7Var = jm7.I;
        cl7 cl7Var = cl7.INK;
        if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
            try {
                bl7 bl7Var = new bl7();
                bl7Var.put("regions", Integer.valueOf(i));
                bl7Var.put("bytes", Long.valueOf(g3dVar.c));
                bl7Var.put("remaining_regions", Integer.valueOf(g3dVar.d));
                bl7Var.put("outstanding_slices", Integer.valueOf(g3dVar.e));
                com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, str, null, xs7.R(bl7Var));
            } catch (Exception e) {
                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, str, e);
            }
        }
    }

    public final ByteBuffer u(int i) {
        if (this.R) {
            return null;
        }
        try {
            return b(i);
        } catch (ErrnoException e) {
            ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
            cl7 cl7Var = cl7.INK;
            String str = this.M;
            jm7 jm7Var = jm7.L;
            if (!com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                return null;
            }
            try {
                com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, str, e, xs7.R(new bl7()));
                return null;
            } catch (Exception e2) {
                com.gingerlabs.notability.core.common.logging.a.g(cl7Var, str, e2);
                return null;
            }
        } catch (SharedMemoryByteArena$ArenaClosedException unused) {
            return null;
        }
    }
}
