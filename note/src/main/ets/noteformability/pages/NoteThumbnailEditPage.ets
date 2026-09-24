// 原版 NoteThumbnailConfigActivity 的配置面："Choose a note" +
// 搜索（widget_note_picker_search_hint）+ "No notes yet" 空态，
// 选定写回 widget_bindings。Harmony：本页由
// NoteThumbnailFormEditAbility 以 loadContent 拉起，LocalStorage
// 携带 editFormId；选定即写回绑定并推送标题刷新（缩略图随后由
// UIAbility 侧补齐，与 feed 两阶段语义一致）。
import { common } from '@kit.AbilityKit';
import { NoteMeta } from '../../core/model/NoteTypes';
import { DatabaseManager } from '../../data/DatabaseManager';
import { NoteRepositoryImpl } from '../../data/NoteRepositoryImpl';
import {
  setNoteThumbnailFormNote,
  pushNoteThumbnailTitles
} from '../../data/NoteThumbnailFormFeed';

@Entry
@Component
struct NoteThumbnailEditPage {
  @LocalStorageProp('editFormId') editFormId: string = '';
  @State notes: NoteMeta[] = [];
  @State query: string = '';
  @State loading: boolean = true;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIExtensionContext;
    const db: DatabaseManager = DatabaseManager.getInstance();
    db.initialize(context).then(() => {
      const repo: NoteRepositoryImpl = new NoteRepositoryImpl(db);
      return repo.getAllNotes();
    }).then((notes: NoteMeta[]) => {
      this.notes = notes;
      this.loading = false;
    }).catch((e: Error) => {
      console.error(`note picker list failed: ${JSON.stringify(e)}`);
      this.loading = false;
    });
  }

  private filteredNotes(): NoteMeta[] {
    const q: string = this.query.trim().toLowerCase();
    if (q.length === 0) {
      return this.notes;
    }
    return this.notes.filter((note: NoteMeta) =>
      note.title.toLowerCase().includes(q));
  }

  private pickNote(noteId: string): void {
    const context = getContext(this) as common.UIExtensionContext;
    setNoteThumbnailFormNote(context, this.editFormId, noteId).then(() => {
      return pushNoteThumbnailTitles(context, this.editFormId);
    }).catch((e: Error) => {
      console.error(`note pick failed: ${JSON.stringify(e)}`);
    });
  }

  build() {
    Column() {
      Text($r('app.string.form_note_thumbnail_pick'))
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 12, bottom: 8 })
      TextInput({ placeholder: $r('app.string.form_note_picker_search_hint') })
        .width('92%')
        .margin({ bottom: 8 })
        .onChange((value: string) => {
          this.query = value;
        })
      if (this.loading) {
        Text($r('app.string.loading'))
          .fontSize(13)
          .opacity(0.6)
      } else if (this.filteredNotes().length === 0) {
        Text($r('app.string.form_picker_no_notes'))
          .fontSize(13)
          .opacity(0.6)
      } else {
        List() {
          ForEach(this.filteredNotes(), (note: NoteMeta) => {
            ListItem() {
              Text(note.title)
                .fontSize(14)
                .width('100%')
                .padding(12)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .onClick(() => {
              this.pickNote(note.id);
            })
          }, (note: NoteMeta) => note.id)
        }
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }
}
