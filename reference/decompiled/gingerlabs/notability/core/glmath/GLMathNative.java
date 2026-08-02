package com.gingerlabs.notability.core.glmath;

import defpackage.ad5;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u00004\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u0007\n\u0002\b\u0002\n\u0002\u0010\u0014\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\bÀ\u0002\u0018\u00002\u00020\u0001J\u0018\u0010\u0005\u001a\u00020\u00042\u0006\u0010\u0003\u001a\u00020\u0002H\u0086 ¢\u0006\u0004\b\u0005\u0010\u0006J*\u0010\f\u001a\u0004\u0018\u00010\u000b2\u0006\u0010\u0007\u001a\u00020\u00022\u0006\u0010\t\u001a\u00020\b2\u0006\u0010\n\u001a\u00020\bH\u0086 ¢\u0006\u0004\b\f\u0010\rJ@\u0010\u0013\u001a\u00020\u00042\u0006\u0010\u0007\u001a\u00020\u00022\u0006\u0010\t\u001a\u00020\b2\u0006\u0010\u000e\u001a\u00020\b2\u0006\u0010\n\u001a\u00020\b2\u0006\u0010\u0010\u001a\u00020\u000f2\u0006\u0010\u0012\u001a\u00020\u0011H\u0086 ¢\u0006\u0004\b\u0013\u0010\u0014¨\u0006\u0015"}, d2 = {"Lcom/gingerlabs/notability/core/glmath/GLMathNative;", "", "", "resPath", "", "nativeInit", "(Ljava/lang/String;)Z", "latex", "", "width", "fontSize", "", "nativeMeasure", "(Ljava/lang/String;FF)[F", "height", "", "argbColor", "Lcom/gingerlabs/notability/core/glmath/MathDrawTarget;", "target", "nativeDraw", "(Ljava/lang/String;FFFILcom/gingerlabs/notability/core/glmath/MathDrawTarget;)Z", "glmath"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class GLMathNative {
    public static final GLMathNative a = new GLMathNative();

    static {
        ad5 ad5Var = ad5.S;
        try {
            System.loadLibrary("glmath");
        } catch (NoClassDefFoundError e) {
            ad5Var.n("glmath", e);
        } catch (UnsatisfiedLinkError e2) {
            ad5Var.n("glmath", e2);
        }
    }

    public final native boolean nativeDraw(String latex, float width, float height, float fontSize, int argbColor, MathDrawTarget target);

    public final native boolean nativeInit(String resPath);

    public final native float[] nativeMeasure(String latex, float width, float fontSize);
}
