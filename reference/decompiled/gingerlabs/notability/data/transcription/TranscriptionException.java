package com.gingerlabs.notability.data.transcription;

import defpackage.bhb;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000:\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u00002\u00060\u0001j\u0002`\u0002:\n\u0003\u0004\u0005\u0006\u0007\b\t\n\u000b\f\u0082\u0001\n\r\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016¨\u0006\u0017"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "Ljava/lang/Exception;", "Lkotlin/Exception;", "Blocked", "QuotaExceeded", "HashingFailed", "ServerPermanentError", "ServerTransientError", "PollingExhausted", "UploadRetriesExhausted", "CreateRetriesExhausted", "TooManyErrors", "NoNetwork", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$Blocked;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$CreateRetriesExhausted;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$HashingFailed;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$NoNetwork;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$PollingExhausted;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$QuotaExceeded;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$ServerPermanentError;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$ServerTransientError;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$TooManyErrors;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException$UploadRetriesExhausted;", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
public abstract class TranscriptionException extends Exception {

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$Blocked;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class Blocked extends TranscriptionException {
        public Blocked(bhb bhbVar) {
            super("Recording blocked: " + bhbVar, null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$CreateRetriesExhausted;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class CreateRetriesExhausted extends TranscriptionException {
        public CreateRetriesExhausted() {
            super("Job creation failed after max retries", null);
        }
    }

    @Metadata(d1 = {"\u0000\n\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u0001¨\u0006\u0002"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$HashingFailed;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class HashingFailed extends TranscriptionException {
        public HashingFailed(Throwable th) {
            super("Failed to compute file hash", th);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$NoNetwork;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class NoNetwork extends TranscriptionException {
        public NoNetwork() {
            super("No network connection available", null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$PollingExhausted;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class PollingExhausted extends TranscriptionException {
        public PollingExhausted() {
            super("Polling for completion exhausted", null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$QuotaExceeded;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class QuotaExceeded extends TranscriptionException {
        public QuotaExceeded() {
            super("Transcription quota exceeded", null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$ServerPermanentError;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class ServerPermanentError extends TranscriptionException {
        public ServerPermanentError() {
            super("Server reported permanent error", null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$ServerTransientError;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class ServerTransientError extends TranscriptionException {
        public ServerTransientError() {
            super("Server reported transient error", null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$TooManyErrors;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class TooManyErrors extends TranscriptionException {
        public TooManyErrors() {
            super("Too many consecutive errors", null);
        }
    }

    @Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/data/transcription/TranscriptionException$UploadRetriesExhausted;", "Lcom/gingerlabs/notability/data/transcription/TranscriptionException;", "<init>", "()V", "transcription"}, k = 1, mv = {2, 3, 0}, xi = 48)
    public static final class UploadRetriesExhausted extends TranscriptionException {
        public UploadRetriesExhausted() {
            super("Upload failed after max retries", null);
        }
    }
}
