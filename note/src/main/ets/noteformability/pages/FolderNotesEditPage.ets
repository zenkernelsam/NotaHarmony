// 原版 FolderNotesConfigActivity 的配置面：列出文件夹供选定后写回
// widget_bindings。Harmony：本页由 FolderFormEditAbility 以
// loadContent 拉起，LocalStorage 携带 editFormId；选定即写回
// folder_notes_form_config.json 并推送标题刷新（缩略图随后由
// UIAbility 侧补齐，与 feed 的两阶段语义一致）。
import { common } from '@kit.AbilityKit';
import { DatabaseManager } from '../../data/DatabaseManager';
import { FolderRepositoryImpl, NoteFolder } from '../../data/FolderRepositoryImpl';
import {
  setFolderNotesFormFolder,
  pushFolderNotesTitles
} from '../../data/FolderNotesFormFeed';

@Entry
@Component
struct FolderNotesEditPage {
  @LocalStorageProp('editFormId') editFormId: string = '';
  @State folders: NoteFolder[] = [];
  @State loading: boolean = true;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIExtensionContext;
    const db: DatabaseManager = DatabaseManager.getInstance();
    db.initialize(context).then(() => {
      const repo: FolderRepositoryImpl = new FolderRepositoryImpl(db);
      return repo.getAllFolders();
    }).then((folders: NoteFolder[]) => {
      this.folders = folders;
      this.loading = false;
    }).catch((e: Error) => {
      console.error(`folder edit list failed: ${JSON.stringify(e)}`);
      this.loading = false;
    });
  }

  private pickFolder(folderId: string): void {
    const context = getContext(this) as common.UIExtensionContext;
    setFolderNotesFormFolder(context, this.editFormId, folderId).then(() => {
      return pushFolderNotesTitles(context, this.editFormId);
    }).catch((e: Error) => {
      console.error(`folder pick failed: ${JSON.stringify(e)}`);
    });
  }

  build() {
    Column() {
      Text($r('app.string.form_folder_edit_title'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 12, bottom: 8 })
      if (this.loading) {
        Text($r('app.string.loading'))
          .fontSize(13)
          .opacity(0.6)
      } else if (this.folders.length === 0) {
        Text($r('app.string.form_folder_edit_empty'))
          .fontSize(13)
          .opacity(0.6)
      } else {
        List() {
          ForEach(this.folders, (folder: NoteFolder) => {
            ListItem() {
              Text(folder.name)
                .fontSize(14)
                .width('100%')
                .padding(12)
            }
            .onClick(() => {
              this.pickFolder(folder.id);
            })
          }, (folder: NoteFolder) => folder.id)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
