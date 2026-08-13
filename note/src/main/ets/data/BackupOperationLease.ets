export type BackupOperationRelease = () => void;

/**
 * Process-wide, non-queuing lease for backup-page workflow mutations. A second page instance is
 * rejected instead of silently scheduling an operation the user can no longer see. This is not a
 * cross-process lock for the system BackupExtensionAbility.
 */
export class BackupOperationLease {
  private active: boolean = false;

  tryAcquire(): BackupOperationRelease | null {
    if (this.active) {
      return null;
    }
    this.active = true;
    let released: boolean = false;
    return (): void => {
      if (released) {
        return;
      }
      released = true;
      this.active = false;
    };
  }

  isActive(): boolean {
    return this.active;
  }
}

export const backupOperationLease: BackupOperationLease = new BackupOperationLease();
