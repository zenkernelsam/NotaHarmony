package com.gingerlabs.notability.data.learn;

import com.apollographql.apollo.exception.ApolloException;
import com.apollographql.apollo.exception.ApolloHttpException;
import com.apollographql.apollo.exception.ApolloNetworkException;
import defpackage.cl7;
import defpackage.dlb;
import defpackage.jm7;
import defpackage.oy3;
import defpackage.p17;
import defpackage.qz3;
import defpackage.sz3;
import defpackage.tg2;
import defpackage.yz3;
import java.util.ArrayList;
import java.util.Map;

/* JADX INFO: loaded from: classes2.dex */
public abstract class b {
    public static final String a(oy3 oy3Var) {
        oy3Var.getClass();
        Map map = oy3Var.e;
        Object obj = map != null ? map.get("key") : null;
        if (obj instanceof String) {
            return (String) obj;
        }
        return null;
    }

    public static final String b(Throwable th) {
        LearnError learnErrorE = e(th);
        if (learnErrorE.equals(LearnError.LLMBadResponse.I)) {
            return "Bad Response";
        }
        if (learnErrorE.equals(LearnError.ContentTooShort.I)) {
            return "Content Too Short";
        }
        if (learnErrorE.equals(LearnError.InsufficientContext.I)) {
            return "Insufficient Context";
        }
        if (learnErrorE instanceof LearnError.JobFailed) {
            return "Job Failed";
        }
        if (learnErrorE.equals(LearnError.Timeout.I)) {
            return "Timeout";
        }
        if (learnErrorE instanceof LearnError.LearnRequestError) {
            return "Request Error";
        }
        if (learnErrorE instanceof LearnError.Network) {
            return ((LearnError.Network) learnErrorE).J ? "No Internet" : "Network Error";
        }
        if (learnErrorE.equals(LearnError.Subscription.I)) {
            return "Subscription";
        }
        if (learnErrorE.equals(LearnError.QuotaLimit.I)) {
            return "Quota Limit";
        }
        if (learnErrorE.equals(LearnError.BatchNotFound.I)) {
            return "Batch Not Found";
        }
        if (learnErrorE.equals(LearnError.AiDisabled.I)) {
            return "AI Disabled";
        }
        if (learnErrorE.equals(LearnError.NoContent.I)) {
            return "No Content";
        }
        yz3.t();
        return null;
    }

    /* JADX WARN: Failed to restore switch over string. Please report as a decompilation issue */
    public static final LearnError c(String str) {
        if (str == null) {
            return null;
        }
        switch (str.hashCode()) {
            case -1743423169:
                if (str.equals("inputTextNotProvided")) {
                    return LearnError.NoContent.I;
                }
                return null;
            case -1020574708:
                if (str.equals("noStudyMaterialsBatchFound")) {
                    return LearnError.BatchNotFound.I;
                }
                return null;
            case -820193882:
                if (str.equals("userNotSubscribedError")) {
                    return LearnError.Subscription.I;
                }
                return null;
            case -448871521:
                if (str.equals("learnLowContentError")) {
                    return LearnError.ContentTooShort.I;
                }
                return null;
            case 774295047:
                if (str.equals("learnQuotaExceeded")) {
                    return LearnError.QuotaLimit.I;
                }
                return null;
            case 1944453828:
                if (str.equals("aiDisabled")) {
                    return LearnError.AiDisabled.I;
                }
                return null;
            default:
                return null;
        }
    }

    public static final LearnError d(p17 p17Var) {
        p17Var.getClass();
        String str = p17Var.I;
        switch (p17Var) {
            case p17.BUCKET_RESULT_NOT_FOUND:
            case p17.PROCESSING_FAILURE:
            case p17.RESULT_RETRIEVAL_FAILURE:
            case p17.TRANSCRIPT_DOES_NOT_EXIST:
                return new LearnError.JobFailed(str);
            case p17.INPUT_TOO_SHORT:
                return LearnError.ContentTooShort.I;
            case p17.INSUFFICIENT_CONTEXT:
                return LearnError.InsufficientContext.I;
            case p17.LLM_IMPROPER_SCHEMA:
            case p17.LLM_INVALID_JSON:
            case p17.LLM_UNEXPECTED_RESPONSE:
                return LearnError.LLMBadResponse.I;
            case p17.UNKNOWN__:
                ArrayList arrayList = com.gingerlabs.notability.core.common.logging.a.a;
                jm7 jm7Var = jm7.L;
                cl7 cl7Var = cl7.LEARN;
                if (com.gingerlabs.notability.core.common.logging.a.a(jm7Var, cl7Var)) {
                    try {
                        qz3 qz3Var = new qz3();
                        qz3Var.b.put("errorReason", qz3Var);
                        sz3 sz3VarB = qz3Var.b();
                        com.gingerlabs.notability.core.common.logging.a.e(jm7Var, cl7Var, "Unable to parse learn error", sz3VarB.a, sz3VarB.b);
                    } catch (Exception e) {
                        com.gingerlabs.notability.core.common.logging.a.g(cl7Var, "Unable to parse learn error", e);
                    }
                    break;
                }
                return new LearnError.JobFailed(str);
            default:
                yz3.t();
                return null;
        }
    }

    public static final LearnError e(Throwable th) {
        th.getClass();
        if (th instanceof LearnError) {
            return (LearnError) th;
        }
        if (th instanceof ApolloHttpException) {
            return new LearnError.Network(tg2.l(((ApolloHttpException) th).I, "HTTP "), false);
        }
        if (th instanceof ApolloNetworkException) {
            return new LearnError.Network("Apollo Network", true);
        }
        if (th instanceof ApolloException) {
            String strP = dlb.a.b(th.getClass()).p();
            if (strP == null) {
                strP = "Apollo";
            }
            return new LearnError.Network(strP, false);
        }
        String strP2 = dlb.a.b(th.getClass()).p();
        if (strP2 == null) {
            strP2 = "Unknown";
        }
        return new LearnError.Network(strP2, false);
    }
}
