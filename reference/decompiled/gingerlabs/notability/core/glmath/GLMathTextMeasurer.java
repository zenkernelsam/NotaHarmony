package com.gingerlabs.notability.core.glmath;

import android.graphics.Paint;
import defpackage.rx4;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000&\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0003\n\u0002\u0010\u0014\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0007\n\u0000\bÁ\u0002\u0018\u00002\u00020\u0001B\t\b\u0002¢\u0006\u0004\b\u0002\u0010\u0003J(\u0010\u0004\u001a\u00020\u00052\u0006\u0010\u0006\u001a\u00020\u00072\u0006\u0010\b\u001a\u00020\u00072\u0006\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\fH\u0007¨\u0006\r"}, d2 = {"Lcom/gingerlabs/notability/core/glmath/GLMathTextMeasurer;", "", "<init>", "()V", "measure", "", "text", "", "fontFile", "fontStyle", "", "fontSize", "", "glmath"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class GLMathTextMeasurer {
    public static final GLMathTextMeasurer INSTANCE = new GLMathTextMeasurer();

    private GLMathTextMeasurer() {
    }

    public static final float[] measure(String text, String fontFile, int fontStyle, float fontSize) {
        text.getClass();
        fontFile.getClass();
        Paint paint = new Paint(1);
        paint.setTypeface(rx4.a.a(fontStyle, fontFile));
        paint.setTextSize(fontSize);
        Paint.FontMetrics fontMetrics = paint.getFontMetrics();
        return new float[]{paint.measureText(text), fontMetrics.ascent, fontMetrics.descent};
    }
}
