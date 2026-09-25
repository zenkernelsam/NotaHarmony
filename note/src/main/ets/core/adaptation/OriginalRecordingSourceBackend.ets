import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import {
  OriginalRecordingAudioSource, OriginalRecordingAudioSourceSelector,
  OriginalRecordingCaptureBackend, OriginalRecordingCaptureErrorListener,
  OriginalRecordingCaptureInterruptionListener, OriginalRecordingCaptureStart,
  OriginalRecordingCaptureStop,
} from './OriginalRecordingCaptureController';

export class OriginalRecordingSourceBackend implements OriginalRecordingCaptureBackend,
  OriginalRecordingAudioSourceSelector {
  private microphone: OriginalRecordingCaptureBackend;
  private internalAudio: OriginalRecordingCaptureBackend;
  private context: common.UIAbilityContext | null;
  private source: OriginalRecordingAudioSource = OriginalRecordingAudioSource.MICROPHONE;
  private active: OriginalRecordingCaptureBackend | null = null;
  private continuousTaskRunning: boolean = false;

  constructor(microphone: OriginalRecordingCaptureBackend,
    internalAudio: OriginalRecordingCaptureBackend,
    context: common.UIAbilityContext | null = null) {
    this.microphone = microphone;
    this.internalAudio = internalAudio;
    this.context = context;
  }

  selectSource(source: OriginalRecordingAudioSource): boolean {
    if (this.active !== null || (source !== OriginalRecordingAudioSource.MICROPHONE &&
      source !== OriginalRecordingAudioSource.DEVICE_ONLY)) {
      return false;
    }
    this.source = source;
    return true;
  }

  getSource(): OriginalRecordingAudioSource {
    return this.source;
  }

  setErrorListener(listener: OriginalRecordingCaptureErrorListener | null): void {
    this.microphone.setErrorListener(listener);
    this.internalAudio.setErrorListener(listener);
  }

  setInterruptionListener(listener: OriginalRecordingCaptureInterruptionListener | null): void {
    this.microphone.setInterruptionListener(listener);
    this.internalAudio.setInterruptionListener(listener);
  }

  supportsPause(): boolean {
    return this.selectedBackend().supportsPause();
  }

  async start(): Promise<OriginalRecordingCaptureStart> {
    if (this.active !== null) {
      throw new Error('recording source backend is already active');
    }
    const selected: OriginalRecordingCaptureBackend = this.selectedBackend();
    try {
      const started: OriginalRecordingCaptureStart = await selected.start();
      this.active = selected;
      // 原版 RecordingForegroundService/AudioCaptureService：录音会话期间挂
      // 前台服务保持后台存活；Harmony 对应物为 AUDIO_RECORDING 长时任务。
      await this.beginContinuousTask();
      return started;
    } catch (error) {
      this.active = null;
      throw error as Error;
    }
  }

  async pause(): Promise<void> {
    const active: OriginalRecordingCaptureBackend = this.requireActive();
    if (!active.supportsPause()) {
      throw new Error('selected recording source does not support pause');
    }
    await active.pause();
  }

  async resume(): Promise<void> {
    const active: OriginalRecordingCaptureBackend = this.requireActive();
    if (!active.supportsPause()) {
      throw new Error('selected recording source does not support resume');
    }
    await active.resume();
  }

  async stop(): Promise<OriginalRecordingCaptureStop> {
    const active: OriginalRecordingCaptureBackend = this.requireActive();
    try {
      return await active.stop();
    } finally {
      this.active = null;
      await this.endContinuousTask();
    }
  }

  async abort(): Promise<void> {
    const active: OriginalRecordingCaptureBackend | null = this.active;
    this.active = null;
    try {
      if (active !== null) {
        await active.abort();
      }
    } finally {
      await this.endContinuousTask();
    }
  }

  private selectedBackend(): OriginalRecordingCaptureBackend {
    return this.source === OriginalRecordingAudioSource.DEVICE_ONLY ?
      this.internalAudio : this.microphone;
  }

  private requireActive(): OriginalRecordingCaptureBackend {
    if (this.active === null) {
      throw new Error('recording source backend is not active');
    }
    return this.active;
  }

  private async beginContinuousTask(): Promise<void> {
    const context: common.UIAbilityContext | null = this.context;
    if (context === null) {
      return;
    }
    try {
      const agent: object = await wantAgent.getWantAgent({
        wants: [{
          bundleName: context.abilityInfo.bundleName,
          abilityName: 'NoteAbility',
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      });
      await backgroundTaskManager.startBackgroundRunning(
        context, backgroundTaskManager.BackgroundMode.AUDIO_RECORDING, agent);
      this.continuousTaskRunning = true;
    } catch {
      // 长时任务启动失败仅丧失后台续录，不阻断前台录音。
      this.continuousTaskRunning = false;
    }
  }

  private async endContinuousTask(): Promise<void> {
    const context: common.UIAbilityContext | null = this.context;
    if (context === null || !this.continuousTaskRunning) {
      return;
    }
    this.continuousTaskRunning = false;
    try {
      await backgroundTaskManager.stopBackgroundRunning(context);
    } catch {
      // 任务可能已被系统回收。
    }
  }
}
