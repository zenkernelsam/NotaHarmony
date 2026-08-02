package com.gingerlabs.notability.core.network;

import java.io.IOException;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/core/network/NoConnectivityException;", "Ljava/io/IOException;", "<init>", "()V", "network"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class NoConnectivityException extends IOException {
    public NoConnectivityException() {
        super("No network connectivity");
    }
}
