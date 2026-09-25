// 原版 ou5/zvh.a 导入详情页：文件列表 + tv5 目的地选择（qv5 现有笔记 /
// sv5 新建笔记 / rv5 各自笔记）+ wt5 逐文件题覆盖 + tt5 笔记搜索 +
// yt5 文件夹选择 + zt5 确认 / dismiss 取消。
// w8:155 头部 Arrange/Done 切换 + te4 move_up/move_down 行内排序
// （files>1 时）；确认经 ImportPlan.orderedUris 回传排序。
import { ImportDestination, ImportFileDescriptor, ImportPlan } from '../../data/NoteImporter';
import { NoteMeta } from '../../core/model/NoteTypes';
import { NoteFolder } from '../../data/FolderRepositoryImpl';
import { common } from '@kit.AbilityKit';
import { ThemeTokens, ThemeMode } from '../theme/EditorTheme';
import { ThemeStore, THEME_MODE_KEY, THEME_SYSTEM_DARK_KEY } from '../theme/ThemeStore';

function fileStem(fileName: string): string {
  const dot: number = fileName.lastIndexOf('.');
  return dot > 0 ? fileName.substring(0, dot) : fileName;
}

function fileEmoji(fileName: string): string {
  const lower: string = fileName.toLowerCase();
  if (lower.endsWith('.pdf')) {
    return '📄';
  }
  if (/\.(png|jpe?g|gif|webp|heic|heif|tiff?|bmp)$/.test(lower)) {
    return '🖼';
  }
  if (/\.(mp3|m4a|aac|wav|aiff?|mp4)$/.test(lower)) {
    return '🎵';
  }
  if (/\.(txt|md)$/.test(lower)) {
    return '📃';
  }
  return '📎';
}

function sizeLabel(size: number): string {
  if (size <= 0) {
    return '';
  }
  if (size < 1024 * 1024) {
    return `${Math.max(1, Math.round(size / 1024))} KB`;
  }
  return `${(size / (1024 * 1024)).toFixed(1)} MB`;
}

interface FileRowEntry {
  item: ImportFileDescriptor;
  idx: number;
}

const NOTE_LIST_LIMIT: number = 60;

@CustomDialog
export struct ImportDetailsSheet {
  controller?: CustomDialogController;
  files: ImportFileDescriptor[] = [];
  context: string = 'standalone';   // 'standalone' | 'note'（编辑器默认 qv5 当前笔记）
  currentNoteId: string = '';
  notes: NoteMeta[] = [];
  folders: NoteFolder[] = [];
  onResult: (plan: ImportPlan | null) => void = (_plan: ImportPlan | null): void => {
  };

  @StorageLink(THEME_MODE_KEY) themeMode: string = 'system';
  @StorageLink(THEME_SYSTEM_DARK_KEY) systemDark: boolean = false;
  @State destination: number = ImportDestination.SEPARATE_NOTES;
  @State orderedFiles: ImportFileDescriptor[] = [];  // w8/te4：可排序副本
  @State arranging: boolean = false;
  @State titleDrafts: string[] = [];   // 与 files 下标对齐（rv5 逐文件题）
  @State singleTitle: string = '';
  @State folderId: string = '';
  @State noteSearch: string = '';
  @State selectedNoteId: string = '';

  private resolveTokens(): ThemeTokens {
    return ThemeStore.resolve(this.themeMode as ThemeMode, this.systemDark);
  }

  aboutToAppear(): void {
    const drafts: string[] = [];
    for (const f of this.files) {
      drafts.push(fileStem(f.fileName));
    }
    this.titleDrafts = drafts;
    this.singleTitle = this.files.length > 0 ? fileStem(this.files[0].fileName) : '';
    this.orderedFiles = this.files.slice();
    if (this.context === 'note') {
      this.destination = ImportDestination.EXISTING_NOTE;
      this.selectedNoteId = this.currentNoteId;
    } else {
      this.destination = this.files.length > 1 ?
        ImportDestination.SEPARATE_NOTES : ImportDestination.SINGLE_NOTE;
    }
  }

  // 原版 te4：arrange 模式下每行 move_up/move_down 交换相邻文件；
  // 逐文件题草稿（下标对齐）随行移动。
  private moveFile(index: number, delta: number): void {
    const target: number = index + delta;
    if (index < 0 || target < 0 || index >= this.orderedFiles.length ||
      target >= this.orderedFiles.length) {
      return;
    }
    const files: ImportFileDescriptor[] = this.orderedFiles.slice();
    const tmp: ImportFileDescriptor = files[index];
    files[index] = files[target];
    files[target] = tmp;
    this.orderedFiles = files;
    const drafts: string[] = this.titleDrafts.slice();
    while (drafts.length < this.orderedFiles.length) {
      drafts.push('');
    }
    const dt: string = drafts[index];
    drafts[index] = drafts[target];
    drafts[target] = dt;
    this.titleDrafts = drafts;
  }

  private filteredNotes(): NoteMeta[] {
    const query: string = this.noteSearch.trim().toLowerCase();
    const source: NoteMeta[] = query.length === 0 ? this.notes :
      this.notes.filter((note: NoteMeta): boolean =>
        note.title.toLowerCase().includes(query));
    return source.slice(0, NOTE_LIST_LIMIT);
  }

  private importEnabled(): boolean {
    return this.destination !== ImportDestination.EXISTING_NOTE ||
      this.selectedNoteId.length > 0;
  }

  private finish(plan: ImportPlan | null): void {
    this.onResult(plan);
    if (this.controller !== undefined) {
      this.controller.close();
    }
  }

  // Original y5j.a: the confirm button is contextual —
  //   EXISTING  -> ui_fileimport__add_to_note ("Add to \"%1$s\"")
  //   SINGLE    -> ui_fileimport__create_single_note ("Create single note")
  //   SEPARATE  -> ui_fileimport__create_new_note ("Create new note")
  // The existing-note title falls back to default_note_title when empty
  // (y5j.java:59 null||empty guard).
  private confirmLabel(): ResourceStr {
    if (this.destination === ImportDestination.EXISTING_NOTE) {
      const target: NoteMeta | undefined = this.notes.find(
        (note: NoteMeta): boolean => note.id === this.selectedNoteId);
      let title: string = target !== undefined ? target.title : '';
      if (title.length === 0) {
        try {
          title = (getContext(this) as common.UIAbilityContext)
            .resourceManager.getStringSync($r('app.string.untitled_note').id);
        } catch (_e) {
          title = 'New Note';
        }
      }
      return $r('app.string.import_add_to_note', title);
    }
    return this.destination === ImportDestination.SINGLE_NOTE ?
      $r('app.string.import_create_single') : $r('app.string.import_create_new');
  }

  private confirm(): void {
    const overrides: Map<string, string> = new Map<string, string>();
    if (this.destination === ImportDestination.SEPARATE_NOTES) {
      for (let i = 0; i < this.orderedFiles.length; i++) {
        const draft: string = i < this.titleDrafts.length ?
          this.titleDrafts[i].trim() : '';
        const stem: string = fileStem(this.orderedFiles[i].fileName);
        if (draft.length > 0 && draft !== stem) {
          overrides.set(this.orderedFiles[i].uri, draft);
        }
      }
    }
    this.finish({
      orderedUris: this.orderedFiles.map((f: ImportFileDescriptor): string => f.uri),
      destination: this.destination as ImportDestination,
      noteId: this.selectedNoteId,
      folderId: this.folderId.length > 0 ? this.folderId : null,
      singleTitle: this.singleTitle.trim(),
      titleOverrides: overrides
    });
  }

  @Builder
  private destinationChip(label: string | Resource, value: number,
    tokens: ThemeTokens) {
    Text(label)
      .fontSize(13)
      .fontColor(this.destination === value ? 0xFFFFFF : tokens.textPrimary)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor(this.destination === value ?
        tokens.accent : tokens.control)
      .onClick(() => {
        this.destination = value;
        if (value === ImportDestination.EXISTING_NOTE &&
          this.selectedNoteId.length === 0 && this.context === 'note') {
          this.selectedNoteId = this.currentNoteId;
        }
      })
  }

  @Builder
  private fileRow(file: ImportFileDescriptor, index: number,
    tokens: ThemeTokens) {
    Column() {
      Row() {
        Text(fileEmoji(file.fileName))
          .fontSize(16)
        Column() {
          Text(file.fileName)
            .fontSize(13)
            .fontColor(tokens.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(sizeLabel(file.size))
            .fontSize(11)
            .fontColor(tokens.textSecondary)
            .visibility(sizeLabel(file.size).length > 0 ?
              Visibility.Visible : Visibility.None)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 8 })
        if (this.arranging) {
          // te4：arrange 态行尾 move_up/move_down
          Row() {
            Text('↑')
              .fontSize(16)
              .fontColor(index > 0 ? tokens.textPrimary : tokens.textSecondary)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .accessibilityText($r('app.string.import_move_up'))
              .enabled(index > 0)
              .onClick(() => {
                this.moveFile(index, -1);
              })
            Text('↓')
              .fontSize(16)
              .fontColor(index < this.orderedFiles.length - 1 ?
                tokens.textPrimary : tokens.textSecondary)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .accessibilityText($r('app.string.import_move_down'))
              .enabled(index < this.orderedFiles.length - 1)
              .onClick(() => {
                this.moveFile(index, 1);
              })
          }
        }
      }
      .width('100%')
      if (!this.arranging &&
        this.destination === ImportDestination.SEPARATE_NOTES) {
        // wt5 逐文件题覆盖
        TextInput({ placeholder: $r('app.string.import_note_title_hint'),
          text: index < this.titleDrafts.length ? this.titleDrafts[index] : '' })
          .fontSize(13)
          .width('100%')
          .margin({ top: 6 })
          .onChange((value: string) => {
            const drafts: string[] = this.titleDrafts.slice();
            while (drafts.length <= index) {
              drafts.push('');
            }
            drafts[index] = value;
            this.titleDrafts = drafts;
          })
      }
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Text($r('app.string.import_details_title'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.resolveTokens().textPrimary)
              .layoutWeight(1)
            if (this.orderedFiles.length > 1) {
              // w8:155：z11 切换 arrange↔done
              Text(this.arranging ? $r('app.string.done') :
                $r('app.string.import_arrange'))
                .fontSize(13)
                .fontColor(this.resolveTokens().accent)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .onClick(() => {
                  this.arranging = !this.arranging;
                })
            }
          }
          .width('100%')
          // aeh:87 → ui_fileimport__n_files_capitalized：文件计数标题
          Text(this.orderedFiles.length === 1 ?
            $r('app.string.import_files_count_one', this.orderedFiles.length) :
            $r('app.string.import_files_count_other', this.orderedFiles.length))
            .fontSize(13)
            .fontColor(this.resolveTokens().textSecondary)
            .width('100%')
            .margin({ top: 6 })
          // utf 文件列表（rv5 模式下逐行附题输入）
          ForEach(this.orderedFiles.map((file: ImportFileDescriptor, index: number): FileRowEntry =>
            ({ item: file, idx: index })),
            (entry: FileRowEntry) => {
              this.fileRow(entry.item, entry.idx, this.resolveTokens())
            },
            (entry: FileRowEntry): string =>
              `${entry.idx}:${entry.item.uri}`)
          // tv5 目的地
          Row() {
            this.destinationChip($r('app.string.import_dest_separate'),
              ImportDestination.SEPARATE_NOTES, this.resolveTokens())
            this.destinationChip($r('app.string.import_dest_single'),
              ImportDestination.SINGLE_NOTE, this.resolveTokens())
            this.destinationChip($r('app.string.import_dest_existing'),
              ImportDestination.EXISTING_NOTE, this.resolveTokens())
          }
          .width('100%')
          .margin({ top: 8 })
          if (this.destination === ImportDestination.SINGLE_NOTE) {
            // sv5 CreateSingleNewNote(title, folderId)
            TextInput({ placeholder: $r('app.string.import_note_title_hint'),
              text: this.singleTitle })
              .fontSize(13)
              .width('100%')
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.singleTitle = value;
              })
          }
          if (this.destination !== ImportDestination.EXISTING_NOTE &&
            this.folders.length > 0) {
            // yt5 文件夹选择（null = 根）
            Row() {
              this.destinationChip($r('app.string.import_folder_none'), -1,
                this.resolveTokens())
              ForEach(this.folders.slice(0, 8),
                (folder: NoteFolder) => {
                  Text(folder.name)
                    .fontSize(13)
                    .fontColor(this.folderId === folder.id ? 0xFFFFFF :
                      this.resolveTokens().textPrimary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .borderRadius(14)
                    .backgroundColor(this.folderId === folder.id ?
                      this.resolveTokens().accent :
                      this.resolveTokens().control)
                    .margin({ left: 6 })
                    .onClick(() => {
                      this.folderId = folder.id;
                    })
                },
                (folder: NoteFolder): string => folder.id)
            }
            .width('100%')
            .margin({ top: 8 })
          }
          if (this.destination === ImportDestination.EXISTING_NOTE) {
            // st5 既有笔记选择 + tt5 搜索
            TextInput({ placeholder: $r('app.string.search_notes'),
              text: this.noteSearch })
              .fontSize(13)
              .width('100%')
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.noteSearch = value;
              })
            List() {
              ForEach(this.filteredNotes(),
                (note: NoteMeta) => {
                  ListItem() {
                    Row() {
                      Text(note.title.length > 0 ? note.title :
                        $r('app.string.untitled_note'))
                        .fontSize(13)
                        .fontColor(this.resolveTokens().textPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                      if (this.selectedNoteId === note.id) {
                        Text('✓')
                          .fontSize(14)
                          .fontColor(this.resolveTokens().accent)
                      }
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                    .onClick(() => {
                      this.selectedNoteId = note.id;
                    })
                  }
                },
                (note: NoteMeta): string => note.id)
            }
            .width('100%')
            .height(160)
            .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      Row() {
        Button($r('app.string.cancel'))
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => {
            this.finish(null);
          })
        Button(this.confirmLabel())
          .height(36)
          .fontSize(14)
          .layoutWeight(1)
          .margin({ left: 12 })
          .enabled(this.importEnabled())
          .onClick(() => {
            if (this.importEnabled()) {
              this.confirm();
            }
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .padding(16)
    .width(360)
    .constraintSize({ maxHeight: '80%' })
    .backgroundColor(this.resolveTokens().surface)
  }
}
