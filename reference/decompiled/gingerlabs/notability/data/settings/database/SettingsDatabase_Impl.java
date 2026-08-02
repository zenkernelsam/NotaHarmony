package com.gingerlabs.notability.data.settings.database;

import defpackage.dlb;
import defpackage.i86;
import defpackage.ibe;
import defpackage.m17;
import defpackage.mua;
import defpackage.p7e;
import defpackage.ps3;
import defpackage.ru3;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/settings/database/SettingsDatabase_Impl;", "Lcom/gingerlabs/notability/data/settings/database/SettingsDatabase;", "<init>", "()V", "settings"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class SettingsDatabase_Impl extends SettingsDatabase {
    public final p7e l = new p7e(new mua(this, 21));

    @Override // defpackage.h1c
    public final List e(LinkedHashMap linkedHashMap) {
        return new ArrayList();
    }

    @Override // defpackage.h1c
    public final i86 f() {
        return new i86(this, new LinkedHashMap(), new LinkedHashMap(), "PaperBackground", "BackgroundInfo");
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
        linkedHashMap.put(dlb.a.b(ibe.class), ru3.I);
        return linkedHashMap;
    }

    @Override // com.gingerlabs.notability.data.settings.database.SettingsDatabase
    public final ibe u() {
        return (ibe) this.l.getValue();
    }
}
