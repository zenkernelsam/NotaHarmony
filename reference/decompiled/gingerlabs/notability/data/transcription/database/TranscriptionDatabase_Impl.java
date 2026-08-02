package com.gingerlabs.notability.data.transcription.database;

import defpackage.dlb;
import defpackage.i6f;
import defpackage.i86;
import defpackage.m17;
import defpackage.p7e;
import defpackage.ps3;
import defpackage.ru3;
import defpackage.z1f;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/database/TranscriptionDatabase_Impl;", "Lcom/gingerlabs/notability/data/transcription/database/TranscriptionDatabase;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class TranscriptionDatabase_Impl extends TranscriptionDatabase {
    public final p7e l = new p7e(new z1f(this, 1));

    @Override // defpackage.h1c
    public final List e(LinkedHashMap linkedHashMap) {
        return new ArrayList();
    }

    @Override // defpackage.h1c
    public final i86 f() {
        return new i86(this, new LinkedHashMap(), new LinkedHashMap(), "transcriptions", "transcription_segments");
    }

    @Override // defpackage.h1c
    public final ps3 g() {
        return new m17(this);
    }

    @Override // defpackage.h1c
    public final Set k() {
        return new LinkedHashSet();
    }

    @Override // defpackage.h1c
    public final LinkedHashMap l() {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        linkedHashMap.put(dlb.a.b(i6f.class), ru3.I);
        return linkedHashMap;
    }

    @Override // com.gingerlabs.notability.data.transcription.database.TranscriptionDatabase
    public final i6f u() {
        return (i6f) this.l.getValue();
    }
}
