package com.gingerlabs.notability.feature.note.toolbox.audio.record;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.os.PowerManager;
import com.gingerlabs.notability.R;
import defpackage.xg9;
import kotlin.Metadata;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0004\b\u0007\u0018\u00002\u00020\u0001:\u0001\u0004B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0005"}, d2 = {"Lcom/gingerlabs/notability/feature/note/toolbox/audio/record/RecordingForegroundService;", "Landroid/app/Service;", "<init>", "()V", "u5j", "toolbox"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class RecordingForegroundService extends Service {
    public static boolean J;
    public PowerManager.WakeLock I;

    @Override // android.app.Service
    public final IBinder onBind(Intent intent) {
        return null;
    }

    @Override // android.app.Service
    public final void onDestroy() {
        PowerManager.WakeLock wakeLock = this.I;
        if (wakeLock != null && wakeLock.isHeld()) {
            wakeLock.release();
        }
        this.I = null;
        super.onDestroy();
    }

    @Override // android.app.Service
    public final int onStartCommand(Intent intent, int i, int i2) {
        if (!J) {
            Object systemService = getSystemService("notification");
            systemService.getClass();
            ((NotificationManager) systemService).createNotificationChannel(new NotificationChannel("notability_recording", getString(R.string.feature_note_toolbox__recording_notification_channel_name), 2));
            J = true;
        }
        xg9 xg9Var = new xg9(this, "notability_recording");
        Notification notification = xg9Var.o;
        notification.icon = R.drawable.feature_note_toolbox__record_option;
        xg9Var.e = xg9.c(getString(R.string.feature_note_toolbox__recording_notification_title));
        notification.flags |= 2;
        xg9Var.p = true;
        Notification notificationB = xg9Var.b();
        notificationB.getClass();
        startForeground(2001, notificationB);
        Object systemService2 = getSystemService("power");
        systemService2.getClass();
        PowerManager.WakeLock wakeLockNewWakeLock = ((PowerManager) systemService2).newWakeLock(1, "Notability::RecordingWakeLock");
        wakeLockNewWakeLock.acquire(86400000L);
        this.I = wakeLockNewWakeLock;
        return 2;
    }
}
