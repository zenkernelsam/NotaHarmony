package com.gingerlabs.notability.data.learn;

import defpackage.f92;
import defpackage.x76;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000B\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00060\u0001j\u0002`\u0002:\f\u0003\u0004\u0005\u0006\u0007\b\t\n\u000b\f\r\u000e\u0082\u0001\f\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a¨\u0006\u001b"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "LLMBadResponse", "ContentTooShort", "InsufficientContext", "JobFailed", "Timeout", "LearnRequestError", "Network", "Subscription", "QuotaLimit", "BatchNotFound", "AiDisabled", "NoContent", "Lcom/gingerlabs/notability/data/learn/LearnError$AiDisabled;", "Lcom/gingerlabs/notability/data/learn/LearnError$BatchNotFound;", "Lcom/gingerlabs/notability/data/learn/LearnError$ContentTooShort;", "Lcom/gingerlabs/notability/data/learn/LearnError$InsufficientContext;", "Lcom/gingerlabs/notability/data/learn/LearnError$JobFailed;", "Lcom/gingerlabs/notability/data/learn/LearnError$LLMBadResponse;", "Lcom/gingerlabs/notability/data/learn/LearnError$LearnRequestError;", "Lcom/gingerlabs/notability/data/learn/LearnError$Network;", "Lcom/gingerlabs/notability/data/learn/LearnError$NoContent;", "Lcom/gingerlabs/notability/data/learn/LearnError$QuotaLimit;", "Lcom/gingerlabs/notability/data/learn/LearnError$Subscription;", "Lcom/gingerlabs/notability/data/learn/LearnError$Timeout;", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
public abstract class LearnError extends Exception {

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$AiDisabled;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class AiDisabled extends LearnError {
        public static final AiDisabled I = new AiDisabled();

        private AiDisabled() {
            super("AI disabled");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof AiDisabled);
        }

        public final int hashCode() {
            return -1184995804;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "AiDisabled";
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$BatchNotFound;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class BatchNotFound extends LearnError {
        public static final BatchNotFound I = new BatchNotFound();

        private BatchNotFound() {
            super("Study materials batch not found");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof BatchNotFound);
        }

        public final int hashCode() {
            return 426871401;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "BatchNotFound";
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$ContentTooShort;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class ContentTooShort extends LearnError {
        public static final ContentTooShort I = new ContentTooShort();

        private ContentTooShort() {
            super("Note content is too short");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof ContentTooShort);
        }

        public final int hashCode() {
            return 1302155201;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "ContentTooShort";
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$InsufficientContext;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class InsufficientContext extends LearnError {
        public static final InsufficientContext I = new InsufficientContext();

        private InsufficientContext() {
            super("Unable to generate summary because the input is incoherent or nonsensical");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof InsufficientContext);
        }

        public final int hashCode() {
            return -121774900;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "InsufficientContext";
        }
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$JobFailed;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class JobFailed extends LearnError {
        public final String I;

        public JobFailed(String str) {
            super("Unable to generate study materials: ".concat(str));
            this.I = str;
        }

        public final boolean equals(Object obj) {
            if (this == obj) {
                return true;
            }
            return (obj instanceof JobFailed) && x76.p(this.I, ((JobFailed) obj).I);
        }

        public final int hashCode() {
            return this.I.hashCode();
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return f92.m("JobFailed(msg=", this.I, ")");
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$LLMBadResponse;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class LLMBadResponse extends LearnError {
        public static final LLMBadResponse I = new LLMBadResponse();

        private LLMBadResponse() {
            super("LLM generated incorrect or malformed JSON");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof LLMBadResponse);
        }

        public final int hashCode() {
            return 2010396057;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "LLMBadResponse";
        }
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$LearnRequestError;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class LearnRequestError extends LearnError {
        public final String I;

        public LearnRequestError(String str) {
            super(str);
            this.I = str;
        }

        public final boolean equals(Object obj) {
            if (this == obj) {
                return true;
            }
            return (obj instanceof LearnRequestError) && x76.p(this.I, ((LearnRequestError) obj).I);
        }

        public final int hashCode() {
            return this.I.hashCode();
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return f92.m("LearnRequestError(msg=", this.I, ")");
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$NoContent;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class NoContent extends LearnError {
        public static final NoContent I = new NoContent();

        private NoContent() {
            super("No content available");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof NoContent);
        }

        public final int hashCode() {
            return 1580704792;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "NoContent";
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$QuotaLimit;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class QuotaLimit extends LearnError {
        public static final QuotaLimit I = new QuotaLimit();

        private QuotaLimit() {
            super("Learn quota exceeded");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof QuotaLimit);
        }

        public final int hashCode() {
            return -1979331709;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "QuotaLimit";
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$Subscription;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class Subscription extends LearnError {
        public static final Subscription I = new Subscription();

        private Subscription() {
            super("User not subscribed or unable to verify subscription");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof Subscription);
        }

        public final int hashCode() {
            return -582785923;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "Subscription";
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\bÆ\n\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$Timeout;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "<init>", "()V", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class Timeout extends LearnError {
        public static final Timeout I = new Timeout();

        private Timeout() {
            super("Generating study materials took too long");
        }

        public final boolean equals(Object obj) {
            return this == obj || (obj instanceof Timeout);
        }

        public final int hashCode() {
            return 987801089;
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "Timeout";
        }
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/data/learn/LearnError$Network;", "Lcom/gingerlabs/notability/data/learn/LearnError;", "learn"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final /* data */ class Network extends LearnError {
        public final String I;
        public final boolean J;

        public Network(String str, boolean z) {
            super("Network error: ".concat(str));
            this.I = str;
            this.J = z;
        }

        public final boolean equals(Object obj) {
            if (this == obj) {
                return true;
            }
            if (!(obj instanceof Network)) {
                return false;
            }
            Network network = (Network) obj;
            return x76.p(this.I, network.I) && this.J == network.J;
        }

        public final int hashCode() {
            return Boolean.hashCode(this.J) + (this.I.hashCode() * 31);
        }

        @Override // java.lang.Throwable
        public final String toString() {
            return "Network(key=" + this.I + ", isConnectionError=" + this.J + ")";
        }

        public /* synthetic */ Network(String str) {
            this(str, false);
        }
    }
}
