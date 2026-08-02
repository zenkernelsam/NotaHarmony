package com.gingerlabs.notability.core.glmath;

import android.graphics.Canvas;
import android.graphics.Paint;
import defpackage.rx4;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u00006\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0007\n\u0002\b\u0012\n\u0002\u0010\u000e\n\u0002\b\u0018\n\u0002\u0018\u0002\n\u0002\b\u0005\b\u0001\u0018\u00002\u00020\u0001B\u000f\u0012\u0006\u0010\u0003\u001a\u00020\u0002¢\u0006\u0004\b\u0004\u0010\u0005J\u0015\u0010\t\u001a\u00020\b2\u0006\u0010\u0007\u001a\u00020\u0006¢\u0006\u0004\b\t\u0010\nJ-\u0010\u0010\u001a\u00020\b2\u0006\u0010\f\u001a\u00020\u000b2\u0006\u0010\r\u001a\u00020\u00062\u0006\u0010\u000e\u001a\u00020\u00062\u0006\u0010\u000f\u001a\u00020\u000b¢\u0006\u0004\b\u0010\u0010\u0011J\u001d\u0010\u0014\u001a\u00020\b2\u0006\u0010\u0012\u001a\u00020\u000b2\u0006\u0010\u0013\u001a\u00020\u000b¢\u0006\u0004\b\u0014\u0010\u0015J\u001d\u0010\u0018\u001a\u00020\b2\u0006\u0010\u0016\u001a\u00020\u000b2\u0006\u0010\u0017\u001a\u00020\u000b¢\u0006\u0004\b\u0018\u0010\u0015J%\u0010\u001c\u001a\u00020\b2\u0006\u0010\u0019\u001a\u00020\u000b2\u0006\u0010\u001a\u001a\u00020\u000b2\u0006\u0010\u001b\u001a\u00020\u000b¢\u0006\u0004\b\u001c\u0010\u001dJ=\u0010%\u001a\u00020\b2\u0006\u0010\u001f\u001a\u00020\u001e2\u0006\u0010 \u001a\u00020\u000b2\u0006\u0010!\u001a\u00020\u000b2\u0006\u0010\"\u001a\u00020\u001e2\u0006\u0010#\u001a\u00020\u00062\u0006\u0010$\u001a\u00020\u000b¢\u0006\u0004\b%\u0010&J-\u0010+\u001a\u00020\b2\u0006\u0010'\u001a\u00020\u000b2\u0006\u0010(\u001a\u00020\u000b2\u0006\u0010)\u001a\u00020\u000b2\u0006\u0010*\u001a\u00020\u000b¢\u0006\u0004\b+\u0010,J-\u0010/\u001a\u00020\b2\u0006\u0010 \u001a\u00020\u000b2\u0006\u0010!\u001a\u00020\u000b2\u0006\u0010-\u001a\u00020\u000b2\u0006\u0010.\u001a\u00020\u000b¢\u0006\u0004\b/\u0010,J-\u00100\u001a\u00020\b2\u0006\u0010 \u001a\u00020\u000b2\u0006\u0010!\u001a\u00020\u000b2\u0006\u0010-\u001a\u00020\u000b2\u0006\u0010.\u001a\u00020\u000b¢\u0006\u0004\b0\u0010,J=\u00103\u001a\u00020\b2\u0006\u0010 \u001a\u00020\u000b2\u0006\u0010!\u001a\u00020\u000b2\u0006\u0010-\u001a\u00020\u000b2\u0006\u0010.\u001a\u00020\u000b2\u0006\u00101\u001a\u00020\u000b2\u0006\u00102\u001a\u00020\u000b¢\u0006\u0004\b3\u00104J=\u00105\u001a\u00020\b2\u0006\u0010 \u001a\u00020\u000b2\u0006\u0010!\u001a\u00020\u000b2\u0006\u0010-\u001a\u00020\u000b2\u0006\u0010.\u001a\u00020\u000b2\u0006\u00101\u001a\u00020\u000b2\u0006\u00102\u001a\u00020\u000b¢\u0006\u0004\b5\u00104R\u0014\u0010\u0003\u001a\u00020\u00028\u0002X\u0082\u0004¢\u0006\u0006\n\u0004\b\u0003\u00106R\u0014\u00108\u001a\u0002078\u0002X\u0082\u0004¢\u0006\u0006\n\u0004\b8\u00109R\u0014\u0010:\u001a\u0002078\u0002X\u0082\u0004¢\u0006\u0006\n\u0004\b:\u00109R\u0014\u0010;\u001a\u0002078\u0002X\u0082\u0004¢\u0006\u0006\n\u0004\b;\u00109¨\u0006<"}, d2 = {"Lcom/gingerlabs/notability/core/glmath/MathDrawTarget;", "", "Landroid/graphics/Canvas;", "canvas", "<init>", "(Landroid/graphics/Canvas;)V", "", "argb", "Lbjf;", "setColor", "(I)V", "", "width", "cap", "join", "miterLimit", "setStroke", "(FIIF)V", "dx", "dy", "translate", "(FF)V", "sx", "sy", "scale", "degrees", "px", "py", "rotate", "(FFF)V", "", "text", "x", "y", "fontFile", "fontStyle", "fontSize", "drawText", "(Ljava/lang/String;FFLjava/lang/String;IF)V", "x1", "y1", "x2", "y2", "drawLine", "(FFFF)V", "w", "h", "drawRect", "fillRect", "rx", "ry", "drawRoundRect", "(FFFFFF)V", "fillRoundRect", "Landroid/graphics/Canvas;", "Landroid/graphics/Paint;", "textPaint", "Landroid/graphics/Paint;", "strokePaint", "fillPaint", "glmath"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class MathDrawTarget {
    private final Canvas canvas;
    private final Paint fillPaint;
    private final Paint strokePaint;
    private final Paint textPaint;

    public MathDrawTarget(Canvas canvas) {
        canvas.getClass();
        this.canvas = canvas;
        this.textPaint = new Paint(129);
        Paint paint = new Paint(1);
        paint.setStyle(Paint.Style.STROKE);
        this.strokePaint = paint;
        Paint paint2 = new Paint(1);
        paint2.setStyle(Paint.Style.FILL);
        this.fillPaint = paint2;
    }

    public final void drawLine(float x1, float y1, float x2, float y2) {
        this.canvas.drawLine(x1, y1, x2, y2, this.strokePaint);
    }

    public final void drawRect(float x, float y, float w, float h) {
        this.canvas.drawRect(x, y, x + w, y + h, this.strokePaint);
    }

    public final void drawRoundRect(float x, float y, float w, float h, float rx, float ry) {
        this.canvas.drawRoundRect(x, y, x + w, y + h, rx, ry, this.strokePaint);
    }

    public final void drawText(String text, float x, float y, String fontFile, int fontStyle, float fontSize) {
        text.getClass();
        fontFile.getClass();
        this.textPaint.setTypeface(rx4.a.a(fontStyle, fontFile));
        this.textPaint.setTextSize(fontSize);
        this.canvas.drawText(text, x, y, this.textPaint);
    }

    public final void fillRect(float x, float y, float w, float h) {
        this.canvas.drawRect(x, y, x + w, y + h, this.fillPaint);
    }

    public final void fillRoundRect(float x, float y, float w, float h, float rx, float ry) {
        this.canvas.drawRoundRect(x, y, x + w, y + h, rx, ry, this.fillPaint);
    }

    public final void rotate(float degrees, float px, float py) {
        this.canvas.rotate(degrees, px, py);
    }

    public final void scale(float sx, float sy) {
        this.canvas.scale(sx, sy);
    }

    public final void setColor(int argb) {
        this.textPaint.setColor(argb);
        this.strokePaint.setColor(argb);
        this.fillPaint.setColor(argb);
    }

    public final void setStroke(float width, int cap, int join, float miterLimit) {
        Paint.Cap cap2;
        Paint.Join join2;
        this.strokePaint.setStrokeWidth(width);
        Paint paint = this.strokePaint;
        if (cap != 1) {
            cap2 = cap != 2 ? Paint.Cap.BUTT : Paint.Cap.SQUARE;
        } else {
            cap2 = Paint.Cap.ROUND;
        }
        paint.setStrokeCap(cap2);
        Paint paint2 = this.strokePaint;
        if (join != 0) {
            join2 = join != 2 ? Paint.Join.MITER : Paint.Join.ROUND;
        } else {
            join2 = Paint.Join.BEVEL;
        }
        paint2.setStrokeJoin(join2);
        if (miterLimit > 0.0f) {
            this.strokePaint.setStrokeMiter(miterLimit);
        }
    }

    public final void translate(float dx, float dy) {
        this.canvas.translate(dx, dy);
    }
}
