import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { audio } from '@kit.AudioKit';
import {
  OriginalRecordingAudioFocusGateway, OriginalRecordingPermissionGateway,
} from './OriginalRecordingSessionController';

const MICROPHONE_PERMISSION: Permissions = 'ohos.permission.MICROPHONE';

export class HarmonyOriginalRecordingPermissionGateway implements OriginalRecordingPermissionGateway {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async requestMicrophonePermission(): Promise<boolean> {
    const manager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const result: PermissionRequestResult =
      await manager.requestPermissionsFromUser(this.context, [MICROPHONE_PERMISSION]);
    return result.permissions.length === 1 && result.permissions[0] === MICROPHONE_PERMISSION &&
      result.authResults.length === 1 &&
      result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
  }
}

export class HarmonyOriginalRecordingAudioFocusGateway implements OriginalRecordingAudioFocusGateway {
  private manager: audio.AudioSessionManager = audio.getAudioManager().getSessionManager();
  private handler: ((event: audio.AudioSessionDeactivatedEvent) => void) | null = null;
  private active: boolean = false;

  async activate(onInterrupted: () => void): Promise<void> {
    await this.deactivate();
    const handler = (_event: audio.AudioSessionDeactivatedEvent): void => {
      if (handler !== this.handler) {
        return;
      }
      this.active = false;
      this.handler = null;
      try {
        this.manager.off('audioSessionDeactivated', handler);
      } catch (_offError) {
      }
      onInterrupted();
    };
    this.handler = handler;
    try {
      this.manager.setAudioSessionScene(audio.AudioSessionScene.AUDIO_SESSION_SCENE_MEDIA);
      this.manager.on('audioSessionDeactivated', handler);
      await this.manager.activateAudioSession({
        concurrencyMode: audio.AudioConcurrencyMode.CONCURRENCY_PAUSE_OTHERS,
      });
      this.active = true;
    } catch (error) {
      this.handler = null;
      try {
        this.manager.off('audioSessionDeactivated', handler);
      } catch (_offError) {
      }
      throw new Error(`activating recording audio session failed: ${JSON.stringify(error)}`);
    }
  }

  async deactivate(): Promise<void> {
    const handler = this.handler;
    this.handler = null;
    if (handler !== null) {
      try {
        this.manager.off('audioSessionDeactivated', handler);
      } catch (_offError) {
      }
    }
    if (!this.active) {
      return;
    }
    this.active = false;
    await this.manager.deactivateAudioSession();
  }
}
