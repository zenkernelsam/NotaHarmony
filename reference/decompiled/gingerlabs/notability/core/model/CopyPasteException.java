package com.gingerlabs.notability.core.model;

import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000&\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b7\u0018\u00002\u00060\u0001j\u0002`\u0002:\u0005\u0003\u0004\u0005\u0006\u0007\u0082\u0001\u0005\b\t\n\u000b\f¨\u0006\r"}, d2 = {"Lcom/gingerlabs/notability/core/model/CopyPasteException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "MissingPosition", "IncompatibleContent", "Consistency", "InvalidArguments", "ConcurrentPaste", "Lcom/gingerlabs/notability/core/model/CopyPasteException$ConcurrentPaste;", "Lcom/gingerlabs/notability/core/model/CopyPasteException$Consistency;", "Lcom/gingerlabs/notability/core/model/CopyPasteException$IncompatibleContent;", "Lcom/gingerlabs/notability/core/model/CopyPasteException$InvalidArguments;", "Lcom/gingerlabs/notability/core/model/CopyPasteException$MissingPosition;", "model"}, k = 1, mv = {2, 3, 0}, xi = 48)
public abstract class CopyPasteException extends Exception {

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÇ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/core/model/CopyPasteException$ConcurrentPaste;", "Lcom/gingerlabs/notability/core/model/CopyPasteException;", "<init>", "()V", "model"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class ConcurrentPaste extends CopyPasteException {
        public static final ConcurrentPaste I = new ConcurrentPaste();

        private ConcurrentPaste() {
            super(null);
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof ConcurrentPaste);
        }

        public final int hashCode() {
            return -479951857;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "ConcurrentPaste";
        }
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0007\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/core/model/CopyPasteException$Consistency;", "Lcom/gingerlabs/notability/core/model/CopyPasteException;", "model"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class Consistency extends CopyPasteException {
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0007\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/core/model/CopyPasteException$IncompatibleContent;", "Lcom/gingerlabs/notability/core/model/CopyPasteException;", "model"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class IncompatibleContent extends CopyPasteException {
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0007\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/core/model/CopyPasteException$InvalidArguments;", "Lcom/gingerlabs/notability/core/model/CopyPasteException;", "model"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class InvalidArguments extends CopyPasteException {
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÇ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/core/model/CopyPasteException$MissingPosition;", "Lcom/gingerlabs/notability/core/model/CopyPasteException;", "<init>", "()V", "model"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class MissingPosition extends CopyPasteException {
        public static final MissingPosition I = new MissingPosition();

        private MissingPosition() {
            super(null);
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof MissingPosition);
        }

        public final int hashCode() {
            return -1027606110;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "MissingPosition";
        }
    }
}
