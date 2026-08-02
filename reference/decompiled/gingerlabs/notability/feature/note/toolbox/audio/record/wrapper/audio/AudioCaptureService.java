package com.gingerlabs.notability.feature.note.toolbox.audio.record.wrapper.audio;

import android.app.ForegroundServiceStartNotAllowedException;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.media.AudioFormat;
import android.media.AudioPlaybackCaptureConfiguration;
import android.media.AudioRecord;
import android.media.projection.MediaProjection;
import android.media.projection.MediaProjectionManager;
import android.os.IBinder;
import android.os.Parcelable;
import androidx.credentials.exceptions.publickeycredential.DomExceptionUtils;
import androidx.recyclerview.widget.RecyclerView;
import com.gingerlabs.notability.core.common.logging.a;
import com.google.android.gms.fido.fido2.api.common.UserVerificationMethods;
import defpackage.bjf;
import defpackage.bl7;
import defpackage.c2;
import defpackage.ce2;
import defpackage.cl7;
import defpackage.de2;
import defpackage.dmd;
import defpackage.f92;
import defpackage.gh2;
import defpackage.jm7;
import defpackage.mf3;
import defpackage.mz1;
import defpackage.ny7;
import defpackage.o03;
import defpackage.o1e;
import defpackage.pq8;
import defpackage.qm8;
import defpackage.qy1;
import defpackage.rk;
import defpackage.rkb;
import defpackage.s4g;
import defpackage.sd0;
import defpackage.t23;
import defpackage.tg2;
import defpackage.tqd;
import defpackage.tz0;
import defpackage.ud2;
import defpackage.vi2;
import defpackage.w76;
import defpackage.x76;
import defpackage.xd0;
import defpackage.xg9;
import defpackage.xs7;
import defpackage.yz3;
import defpackage.zb;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;
import kotlin.Metadata;
import kotlin.NoWhenBranchMatchedException;

/* JADX INFO: loaded from: classes2.dex */
@Metadata(d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u0007¢\u0006\u0004\b\u0002\u0010\u0003¨\u0006\u0004"}, d2 = {"Lcom/gingerlabs/notability/feature/note/toolbox/audio/record/wrapper/audio/AudioCaptureService;", "Landroid/app/Service;", "<init>", "()V", "toolbox"}, k = 1, mv = {2, 3, 0}, xi = 48)
public final class AudioCaptureService extends Service {
    public MediaProjectionManager I;
    public MediaProjection J;
    public dmd K;
    public AudioRecord L;
    public final zb M = new zb();
    public final ud2 N;
    public final pq8 O;
    public boolean P;

    public AudioCaptureService() {
        t23 t23Var = mf3.a;
        o03 o03Var = o03.K;
        o1e o1eVarM = s4g.m();
        o03Var.getClass();
        this.N = tz0.a(qy1.V(o03Var, o1eVarM));
        this.O = new pq8();
    }

    /* JADX WARN: Code duplicated, block: B:7:0x0025  */
    /* JADX WARN: Multi-variable type inference failed */
    /* JADX WARN: Type inference failed for: r13v0, types: [java.lang.String] */
    /* JADX WARN: Type inference failed for: r13v1 */
    /* JADX WARN: Type inference failed for: r13v6 */
    /* JADX WARN: Type inference failed for: r13v7 */
    /* JADX WARN: Type inference failed for: r13v8 */
    /* JADX WARN: Type inference failed for: r2v2 */
    /* JADX WARN: Type inference failed for: r2v22 */
    /* JADX WARN: Type inference failed for: r2v3, types: [java.lang.String] */
    /* JADX WARN: Type inference failed for: r2v6 */
    public static final Object b(AudioCaptureService audioCaptureService, File file, de2 de2Var) throws Throwable {
        sd0 sd0Var;
        ?? r2;
        String str;
        Object obj;
        File file2;
        File file3 = file;
        jm7 jm7Var = jm7.I;
        jm7 jm7Var2 = jm7.M;
        cl7 cl7Var = cl7.RECORDING;
        if (de2Var instanceof sd0) {
            sd0Var = (sd0) de2Var;
            int i = sd0Var.M;
            if ((i & RecyclerView.UNDEFINED_DURATION) != 0) {
                sd0Var.M = i - RecyclerView.UNDEFINED_DURATION;
            } else {
                sd0Var = new sd0(audioCaptureService, de2Var);
            }
        } else {
            sd0Var = new sd0(audioCaptureService, de2Var);
        }
        Object obj2 = sd0Var.K;
        gh2 gh2Var = gh2.I;
        int i2 = sd0Var.M;
        ?? r13 = "PCM to AAC conversion failed";
        try {
            try {
                if (i2 == 0) {
                    ny7.F0(obj2);
                    zb zbVar = audioCaptureService.M;
                    File parentFile = file3.getParentFile();
                    parentFile.getClass();
                    String name = file3.getName();
                    name.getClass();
                    zbVar.getClass();
                    str = "PCM to AAC conversion failed";
                    try {
                        int iH0 = tqd.H0(name, ".", 0, 6);
                        if (iH0 != -1) {
                            name = name.substring(0, iH0);
                        }
                        if (xd0.a[0] != 1) {
                            throw new NoWhenBranchMatchedException();
                        }
                        File file4 = new File(parentFile, name.concat(".m4a"));
                        ArrayList arrayList = a.a;
                        a.d(jm7Var, cl7Var, "Converting PCM to AAC: " + file3.getAbsolutePath() + " -> " + file4.getAbsolutePath());
                        zb zbVar2 = audioCaptureService.M;
                        audioCaptureService.O.getClass();
                        sd0Var.I = file3;
                        sd0Var.J = file4;
                        r13 = 1;
                        sd0Var.M = 1;
                        zbVar2.getClass();
                        t23 t23Var = mf3.a;
                        Object objT = vi2.T(o03.K, new rk(3, (ce2) null, file3, file4), sd0Var);
                        if (objT == gh2Var) {
                            return gh2Var;
                        }
                        obj = objT;
                        file2 = file4;
                    } catch (Exception e) {
                        e = e;
                        r2 = str;
                        ArrayList arrayList2 = a.a;
                        if (a.a(jm7Var2, cl7Var)) {
                            try {
                                a.e(jm7Var2, cl7Var, "Error during audio conversion, dropping recording", e, xs7.R(new bl7()));
                            } catch (Exception e2) {
                                a.g(cl7Var, "Error during audio conversion, dropping recording", e2);
                            }
                        }
                        qm8 qm8Var = qm8.i;
                        if (qm8Var != null) {
                            mz1 mz1Var = qm8Var.e;
                            if (mz1Var == null) {
                                ArrayList arrayList3 = a.a;
                                a.d(jm7Var2, cl7Var, "Audio conversion failure dropped — no awaiter");
                            } else {
                                mz1Var.d0(new IOException((String) r2));
                            }
                        }
                    }
                } else {
                    if (i2 != 1) {
                        yz3.l("call to 'resume' before 'invoke' with coroutine");
                        return null;
                    }
                    file2 = sd0Var.J;
                    file3 = sd0Var.I;
                    ny7.F0(obj2);
                    str = "PCM to AAC conversion failed";
                    obj = obj2;
                    r13 = r13;
                }
                if (((Boolean) obj).booleanValue()) {
                    if (file3.delete()) {
                        ArrayList arrayList4 = a.a;
                        a.d(jm7Var, cl7Var, "Deleted PCM file: " + file3.getAbsolutePath());
                    }
                    ArrayList arrayList5 = a.a;
                    a.d(jm7Var, cl7Var, "PCM to AAC conversion succeeded: " + file2.getAbsolutePath());
                    qm8 qm8Var2 = qm8.i;
                    if (qm8Var2 != null) {
                        mz1 mz1Var2 = qm8Var2.e;
                        if (mz1Var2 == null) {
                            a.d(jm7Var2, cl7Var, "Audio conversion result dropped — no awaiter");
                        } else {
                            mz1Var2.P(file2);
                        }
                    }
                } else {
                    ArrayList arrayList6 = a.a;
                    a.d(jm7Var2, cl7Var, "PCM to AAC conversion failed, dropping recording");
                    qm8 qm8Var3 = qm8.i;
                    if (qm8Var3 != null) {
                        mz1 mz1Var3 = qm8Var3.e;
                        if (mz1Var3 == null) {
                            a.d(jm7Var2, cl7Var, "Audio conversion failure dropped — no awaiter");
                        } else {
                            mz1Var3.d0(new IOException(str));
                        }
                    }
                }
            } catch (Exception e3) {
                e = e3;
                r2 = obj2;
            }
        } catch (Exception e4) {
            e = e4;
            r2 = r13;
        }
        return bjf.a;
    }

    public static final File c(AudioCaptureService audioCaptureService) {
        File file = new File(audioCaptureService.getFilesDir(), "AudioCaptures");
        s4g.F(file);
        return new File(f92.B(file.getAbsolutePath(), DomExceptionUtils.SEPARATOR, f92.m("Recording-", new SimpleDateFormat("dd-MM-yyyy-hh-mm-ss", Locale.US).format(new Date()), ".pcm")));
    }

    public static final void d(AudioCaptureService audioCaptureService, File file, c2 c2Var) throws IOException {
        AudioRecord audioRecord;
        int i;
        short[] sArr = new short[UserVerificationMethods.USER_VERIFY_ALL];
        byte[] bArr = new byte[2048];
        FileOutputStream fileOutputStream = new FileOutputStream(file);
        while (rkb.K(c2Var.getContext()) && (audioRecord = audioCaptureService.L) != null && (i = audioRecord.read(sArr, 0, UserVerificationMethods.USER_VERIFY_ALL)) > 0) {
            try {
                for (int i2 = 0; i2 < 1024; i2++) {
                    int i3 = i2 * 2;
                    short s = sArr[i2];
                    bArr[i3] = (byte) (s & 255);
                    bArr[i3 + 1] = (byte) (s >> 8);
                    sArr[i2] = 0;
                }
                fileOutputStream.write(bArr, 0, i * 2);
            } catch (Throwable th) {
                try {
                    throw th;
                } catch (Throwable th2) {
                    w76.q(fileOutputStream, th);
                    throw th2;
                }
            }
        }
        fileOutputStream.close();
        ArrayList arrayList = a.a;
        a.d(jm7.I, cl7.RECORDING, "Audio capture finished for " + file.getAbsolutePath() + ". File size is " + file.length() + " bytes.");
    }

    public final void a(RuntimeException runtimeException) {
        this.P = true;
        ArrayList arrayList = a.a;
        cl7 cl7Var = cl7.RECORDING;
        jm7 jm7Var = jm7.M;
        if (a.a(jm7Var, cl7Var)) {
            try {
                a.e(jm7Var, cl7Var, "Foreground start denied for audio capture; aborting recording", runtimeException, xs7.R(new bl7()));
            } catch (Exception e) {
                a.g(cl7Var, "Foreground start denied for audio capture; aborting recording", e);
            }
        }
        qm8 qm8Var = qm8.i;
        if (qm8Var != null) {
            mz1 mz1Var = qm8Var.e;
            if (mz1Var == null) {
                ArrayList arrayList2 = a.a;
                a.d(jm7Var, cl7Var, "Audio conversion failure dropped — no awaiter");
            } else {
                mz1Var.d0(new IOException("PCM to AAC conversion failed"));
            }
        }
        stopSelf();
    }

    @Override // android.app.Service
    public final IBinder onBind(Intent intent) {
        return null;
    }

    @Override // android.app.Service
    public final void onCreate() {
        super.onCreate();
        NotificationChannel notificationChannel = new NotificationChannel("AudioCapture channel", "Notability Audio Capture Service Channel", 3);
        Object systemService = getSystemService((Class<Object>) NotificationManager.class);
        systemService.getClass();
        ((NotificationManager) systemService).createNotificationChannel(notificationChannel);
        try {
            startForeground(123, new xg9(this, "AudioCapture channel").b());
            Object systemService2 = getApplicationContext().getSystemService("media_projection");
            systemService2.getClass();
            this.I = (MediaProjectionManager) systemService2;
        } catch (ForegroundServiceStartNotAllowedException e) {
            a(e);
        } catch (SecurityException e2) {
            a(e2);
        }
    }

    @Override // android.app.Service
    public final void onDestroy() {
        tz0.n(this.N, null);
        super.onDestroy();
    }

    @Override // android.app.Service
    public final int onStartCommand(Intent intent, int i, int i2) {
        if (this.P || intent == null) {
            return 2;
        }
        String action = intent.getAction();
        if (action != null) {
            int iHashCode = action.hashCode();
            if (iHashCode != -1218185065) {
                if (iHashCode == 890955373 && action.equals("AudioCaptureService:Start")) {
                    MediaProjectionManager mediaProjectionManager = this.I;
                    if (mediaProjectionManager == null) {
                        x76.d0("mediaProjectionManager");
                        throw null;
                    }
                    Parcelable parcelableExtra = intent.getParcelableExtra("AudioCaptureService:Extra:ResultData");
                    parcelableExtra.getClass();
                    MediaProjection mediaProjection = mediaProjectionManager.getMediaProjection(-1, (Intent) parcelableExtra);
                    mediaProjection.getClass();
                    this.J = mediaProjection;
                    MediaProjection mediaProjection2 = this.J;
                    mediaProjection2.getClass();
                    AudioPlaybackCaptureConfiguration audioPlaybackCaptureConfigurationBuild = new AudioPlaybackCaptureConfiguration.Builder(mediaProjection2).addMatchingUsage(1).build();
                    audioPlaybackCaptureConfigurationBuild.getClass();
                    AudioFormat.Builder encoding = new AudioFormat.Builder().setEncoding(2);
                    this.O.getClass();
                    AudioRecord audioRecordBuild = new AudioRecord.Builder().setAudioFormat(encoding.setSampleRate(44100).setChannelMask(16).build()).setBufferSizeInBytes(2048).setAudioPlaybackCaptureConfig(audioPlaybackCaptureConfigurationBuild).build();
                    this.L = audioRecordBuild;
                    audioRecordBuild.getClass();
                    audioRecordBuild.startRecording();
                    this.K = vi2.A(this.N, null, null, new c2(this, null, 9), 3);
                    return 1;
                }
            } else if (action.equals("AudioCaptureService:Stop")) {
                if (this.K == null) {
                    qm8 qm8Var = qm8.i;
                    if (qm8Var != null) {
                        mz1 mz1Var = qm8Var.e;
                        if (mz1Var == null) {
                            ArrayList arrayList = a.a;
                            a.d(jm7.M, cl7.RECORDING, "Audio conversion failure dropped — no awaiter");
                        } else {
                            mz1Var.d0(new IOException("PCM to AAC conversion failed"));
                        }
                    }
                    stopSelf();
                    return 2;
                }
                AudioRecord audioRecord = this.L;
                if (audioRecord != null) {
                    audioRecord.stop();
                }
                AudioRecord audioRecord2 = this.L;
                if (audioRecord2 != null) {
                    audioRecord2.release();
                }
                this.L = null;
                MediaProjection mediaProjection3 = this.J;
                if (mediaProjection3 != null) {
                    mediaProjection3.stop();
                }
                this.J = null;
                return 2;
            }
        }
        yz3.r(tg2.D("Unexpected action received: ", intent.getAction()));
        return 0;
    }
}
