# Task 2 Technical Checkpoint Report

## Markdown Editor & Bidirectional Linking

| Thông tin | Giá trị |
|---|---|
| Project | FPTU SE Knowledge — Obsidian-like Second Brain |
| Course | PRM393 — Mobile Programming |
| Task owner | Member 2 |
| Scope | Markdown Editor, Wiki-link, Backlinks, LocalNoteRepository |
| Branch | `feature/editor-md` |
| Baseline commit | `1e7e069 feat: add kUseMock flag` |
| Flutter | `3.47.2 stable` |
| Dart | `3.13.2 stable` |
| Report date | 2026-09-16 |
| Current phase | Technical checkpoint before further implementation |

> Báo cáo này mô tả chính xác trạng thái implementation tại checkpoint hiện tại. Snapshot số dòng và số file bên dưới được ghi nhận trước khi chính file báo cáo này được tạo. Không có commit, push hoặc Pull Request nào được thực hiện.

---

## 1. Executive summary

Task 2 chịu trách nhiệm xây dựng Knowledge Linking Engine của ứng dụng, bao gồm:

- mở và chỉnh sửa Markdown note;
- Edit, Preview và Split View;
- autosave và manual save;
- phân tích Wiki-link `[[...]]`;
- điều hướng Wiki-link;
- tìm Backlinks;
- đọc và ghi Markdown file thật trong Vault.

Implementation hiện tại đã hoàn thành phần lớn code độc lập của Member 2 và có automated tests. Các phần phụ thuộc integration với Member 1 và Member 4 chưa được xem là hoàn tất.

Trạng thái tổng quát:

| Hạng mục | Trạng thái |
|---|---|
| Note model và immutability | DONE |
| Wiki-link parser cơ bản | DONE |
| MockNoteRepository | DONE |
| NoteProvider và autosave | DONE |
| Editor UI | PARTIAL |
| Markdown preview | PARTIAL |
| Existing Wiki-link navigation | PARTIAL |
| Missing Wiki-link creation | NEEDS INTEGRATION |
| Backlinks algorithm | DONE |
| Backlinks UI | PARTIAL |
| LocalNoteRepository | DONE |
| Vault → Editor integration | NEEDS INTEGRATION |
| Windows manual verification sau implementation | NOT YET MANUALLY VERIFIED |

Không nên coi toàn bộ Task 2 là DONE tại checkpoint này vì real Vault flow và manual Windows flow chưa được xác nhận.

---

## 2. Git snapshot

### 2.1 Branch và baseline

```text
Branch: feature/editor-md
HEAD:   1e7e069 feat: add kUseMock flag
```

Không có commit mới trên branch này.

### 2.2 Tracked files đã sửa

```text
 M lib/main.dart
 M lib/mocks/mock_note_repository.dart
 M lib/models/note.dart
 M lib/providers/note_provider.dart
 M lib/screens/shell_screen.dart
 M test/widget_test.dart
```

### 2.3 Files/directories mới

```text
?? lib/core/utils/
?? lib/screens/editor/
?? lib/services/
?? test/mocks/
?? test/models/
?? test/providers/
?? test/repositories/
?? test/screens/
```

### 2.4 Thống kê implementation trước khi tạo report

| Loại | Số file | Added | Deleted |
|---|---:|---:|---:|
| Modified | 6 | 240 | 67 |
| Created | 10 | 729 | 0 |
| Tổng | 16 | 969 | 67 |

Các file generated/native không còn dirty sau lần verification cuối.

### 2.5 Files không bị thay đổi

Những file quan trọng sau giữ nguyên:

- `lib/contracts/note_repository.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `lib/providers/ai_provider.dart`
- `lib/providers/graph_provider.dart`
- các Gemini/AI services
- Graph rendering code

Không có dependency mới.

---

## 3. File-by-file change report

| File | State | Added/Deleted | Task | Trách nhiệm và thay đổi chính | Cross-member impact |
|---|---|---:|---|---|---|
| `lib/models/note.dart` | Modified | +7/-5 | T2.1 | Defensive immutable copy cho `outgoingLinks` và `backlinks` | Member 3/4 đọc cùng model nhưng public fields không đổi |
| `lib/core/utils/wikilink_parser.dart` | Created | +37/-0 | T2.1, T2.5 | Parse, normalize, compare và preview-transform Wiki-link | Member 4 nhận `outgoingLinks` đã normalize |
| `lib/mocks/mock_note_repository.dart` | Modified | +16/-12 | T2.2, T2.5 | Dùng parser chung, path-safe note title, backlink comparison | Không đổi `NoteRepository` contract |
| `lib/providers/note_provider.dart` | Modified | +150/-8 | T2.3 | State machine, autosave, manual save, errors, backlinks, Vault root | Member 1/3/4 phụ thuộc provider state |
| `lib/screens/editor/note_editor_screen.dart` | Created | +276/-0 | T2.4, T2.5, T2.6 | Editor Desktop, toolbar, views, shortcuts, Wiki-link resolution | Member 1 mở note; Member 4 host screen trong shell |
| `lib/screens/editor/widgets/markdown_preview.dart` | Created | +35/-0 | T2.5 | Render preview và intercept Wiki-link click | Không gọi filesystem |
| `lib/screens/editor/widgets/backlinks_panel.dart` | Created | +55/-0 | T2.6 | Hiển thị và điều hướng backlinks | Phụ thuộc NoteProvider backlinks |
| `lib/services/local_note_repository.dart` | Created | +86/-0 | T2.6 | `dart:io` read/write/scan/backlinks | Member 1 cung cấp Vault root và file path |
| `lib/main.dart` | Modified | +9/-4 | T2.6/integration | Dùng `LocalNoteRepository` khi `kUseMock == false` | Cross-ownership với Member 4 |
| `lib/screens/shell_screen.dart` | Modified | +47/-33 | T2.4/integration | Thay Member 2 placeholder bằng `NoteEditorScreen` | Cross-ownership với Member 4 |
| `test/models/note_test.dart` | Created | +16/-0 | T2.1 | Immutability test | Không |
| `test/mocks/mock_note_repository_test.dart` | Created | +31/-0 | T2.2, T2.5 | Wiki-link parsing tests | Không |
| `test/providers/note_provider_test.dart` | Created | +87/-0 | T2.3 | Open, save, autosave, errors, backlinks tests | Không |
| `test/repositories/local_note_repository_test.dart` | Created | +44/-0 | T2.6 | Real temporary filesystem tests | Không |
| `test/screens/editor/note_editor_screen_test.dart` | Created | +62/-0 | T2.4, T2.5, T2.6 | Editor/Preview/Wiki-link/Backlinks widget tests | Không |
| `test/widget_test.dart` | Modified | +11/-5 | T2.4 | App smoke test đổi từ placeholder sang editor empty state | Shared test |

---

## 4. Requirement traceability

| Task | Requirement | Implementation | Tests | Status |
|---|---|---|---|---|
| T2.1 | Audit/finalize `Note` và compatibility | Immutable link lists; contract giữ nguyên | `note_test.dart` | DONE |
| T2.2 | MockNoteRepository | Mock read/save/parser/backlinks | `mock_note_repository_test.dart` | DONE |
| T2.3 | NoteProvider | State, open, edit, debounce, save, errors, backlinks | `note_provider_test.dart` | DONE |
| T2.4 | Desktop Markdown Editor | TextField, word count, states, views, Ctrl+S | Editor widget tests | PARTIAL |
| T2.5 | Preview và Wiki-link | Preview transform, click existing, missing dialog | Parser và editor widget tests | PARTIAL |
| T2.6 | Backlinks và LocalNoteRepository | Recursive Markdown scan, read/write, backlinks panel | Repository và editor tests | NEEDS INTEGRATION |

T2.4 và T2.5 là PARTIAL vì chưa manual verify trên Windows sau implementation. T2.6 cần Member 1 cung cấp real Vault lifecycle và create-note flow.

---

## 5. Architecture compliance

Flow hiện tại tuân theo kiến trúc dự án:

```text
NoteEditorScreen
→ NoteProvider
→ NoteRepository
→ MockNoteRepository / LocalNoteRepository
→ Memory / dart:io Markdown files
```

Các giới hạn ownership được giữ:

- Widget không gọi `dart:io`.
- Widget không tự scan Vault.
- Member 2 không implement Gemini.
- Member 2 không implement Graph rendering.
- Không thêm database.
- Không thêm state-management library.
- Không thêm dependency.

---

## 6. Note model audit

### 6.1 Thay đổi so với `develop`

`outgoingLinks` và `backlinks` trước đây nhận trực tiếp list từ caller. Constructor mới tạo snapshot:

```dart
outgoingLinks = List.unmodifiable(outgoingLinks),
backlinks = List.unmodifiable(backlinks),
```

### 6.2 Immutability semantics

- Caller không thể gọi `add`, `remove` hoặc sửa list trong `Note`.
- Mutate list gốc sau khi tạo `Note` không làm thay đổi note.
- `copyWith` tạo một `Note` mới và constructor tiếp tục tạo unmodifiable copy.

### 6.3 `lastModified`

- Constructor dùng `DateTime.now()` nếu không truyền giá trị.
- Local repository lấy `FileStat.modified` khi đọc file.
- `NoteProvider.updateContent()` set `DateTime.now()` khi user thay đổi content.
- `copyWith()` giữ timestamp cũ nếu caller không cung cấp timestamp mới.

### 6.4 Limitations

- Chưa override `==` và `hashCode`.
- Model chưa chứa explicit `vaultRoot` hoặc note ID độc lập với path.
- Title uniqueness là assumption của MVP, chưa enforce trong model.

---

## 7. Wiki-link engine

### 7.1 Parser

Parser dùng regex:

```dart
RegExp(r'\[\[([^\[\]]*)\]\]')
```

Rules:

- trim leading/trailing whitespace;
- bỏ empty title;
- dedupe bằng lowercase key;
- giữ casing của lần xuất hiện đầu tiên;
- giữ source order;
- không collapse whitespace bên trong title.

### 7.2 Example

Input:

```md
[[Flutter]]
[[ flutter ]]
[[FLUTTER]]
[[Provider Pattern]]
[[]]
[[   ]]
```

Actual output:

```dart
['Flutter', 'Provider Pattern']
```

### 7.3 Known parser limitations

Parser không dùng Markdown AST. Vì vậy:

| Context | Behavior hiện tại |
|---|---|
| Inline code | Vẫn parse literal `[[...]]` |
| Fenced code block | Vẫn parse literal `[[...]]` |
| Markdown link label | Có thể parse literal `[[...]]` trong label |
| Escaped text | Không hiểu Markdown escaping; phụ thuộc raw bracket sequence |
| Alias `[[note\|alias]]` | Coi toàn bộ là literal title |
| Heading `[[note#heading]]` | Coi toàn bộ là literal title |
| Embed `![[note]]` | Parser vẫn bắt phần `[[note]]` |

Các behavior này chưa được mở rộng vì nằm ngoài MVP hiện tại.

---

## 8. Preview-only Wiki-link transformation

Preview biến đổi:

```md
[[Provider]]
```

thành:

```md
[Provider](wikilink:///Provider)
```

Transform chỉ được dùng làm input cho `flutter_markdown`. `Note.content` và file Markdown gốc không bị sửa.

Click flow:

```text
Markdown.onTapLink
→ MarkdownPreview.onOpenWikiLink
→ NoteEditorScreen._openWikiLink
→ NoteRepository.getAllNotes
→ NoteProvider.openNote
```

Internal scheme:

```text
wikilink:///
```

Title được `Uri.encodeComponent` khi tạo URL và `Uri.decodeComponent` khi click.

Known issue: label Markdown chưa escape riêng các ký tự đặc biệt như `]`, `(` và `)`.

---

## 9. NoteProvider state machine

### 9.1 State

```text
currentNote
vaultRootPath
autoSaveTimer
isLoading
isDirty
isSaving
errorMessage
openRequestId
saveRequestId
```

### 9.2 Open note

```text
openNote(filePath)
→ cancel pending debounce
→ invalidate previous open/save request IDs
→ clear current note
→ isLoading = true
→ repository.getNote
→ refresh backlinks when vault root exists
→ isLoading = false
```

### 9.3 Edit and autosave

```text
TextField.onChanged
→ updateContent
→ update content + outgoingLinks + lastModified
→ isDirty = true
→ cancel previous debounce
→ schedule 1-second timer
→ notifyListeners
```

Timer fire:

```text
saveCurrentNote
→ capture current Note snapshot
→ isSaving = true
→ repository.saveNote
→ clear dirty only if current content still matches saved snapshot
→ refresh backlinks
→ isSaving = false
```

### 9.4 Manual save

`Ctrl+S` được map bằng Flutter `Shortcuts` và `Actions`:

```text
Ctrl+S → _SaveIntent → saveCurrentNote()
```

### 9.5 Switch-note race behavior

Scenario:

```text
Edit A
→ debounce chưa fire
→ open B
```

`openNote(B)` cancel timer của A. Kết quả:

- A không bị save;
- B không bị save nhầm;
- thay đổi chưa save của A có thể mất.

Nếu save A đã bắt đầu trước khi open B, save dùng snapshot A nên vẫn ghi đúng A. Request ID ngăn completion của A cập nhật UI state của B.

### 9.6 Dispose

`dispose()` cancel pending Timer. Một save đã bắt đầu không bị cancel.

---

## 10. Missing Wiki-link flow

Flow hiện tại:

```text
Click missing Wiki-link
→ scan notes trong repository
→ không tìm thấy
→ show AlertDialog
→ user chọn Create note
→ show SnackBar request message
```

Chưa có file nào được tạo.

Widget không gọi `dart:io`. Integration đúng dự kiến nên là:

```text
NoteEditorScreen
→ VaultProvider / VaultService.createNote
→ filesystem
→ NoteProvider.openNote(newPath)
```

Phần này có overlap với Member 1 và đang là **NEEDS INTEGRATION**.

---

## 11. LocalNoteRepository

### 11.1 `getNote`

```text
exists check
→ read UTF-8
→ read file modified time
→ derive title from basename
→ extract outgoingLinks
→ return Note
```

Missing file ném `FileSystemException`. Empty file hợp lệ và trả content rỗng.

### 11.2 `saveNote`

```text
parent directory exists check
→ write UTF-8 to .<filename>.writing
→ flush
→ rename temp to target
→ cleanup temp in finally
```

Đây là temp-file safe-write strategy. Báo cáo không tuyên bố atomic behavior.

Test Windows đã xác nhận ghi mới và ghi đè file hiện có trong test environment.

### 11.3 `getAllNotes`

- scan recursive;
- không follow symlink;
- chỉ lấy extension `.md`, case-insensitive;
- hidden folders không bị exclude;
- sort theo lowercase path;
- đọc từng note bằng `getNote`.

Missing directory ném `FileSystemException`. Permission errors từ `dart:io` propagate lên Provider.

### 11.4 `getBacklinksForNote`

```text
read all notes
→ exclude note có cùng title với target
→ compare outgoing link title case-insensitively
→ return source note titles
```

Duplicate title chưa được enforce. Nếu Vault vi phạm assumption title unique, resolution có thể ambiguous.

### 11.5 Safe-write limitation

Temp filename cố định theo target:

```text
.<target-file-name>.writing
```

Concurrent saves cho cùng target có thể tranh chấp temp file.

---

## 12. Backlink algorithm

```text
currentNote.title
→ NoteProvider.refreshBacklinks
→ LocalNoteRepository.getBacklinksForNote
→ recursive scan toàn Vault
→ parse every Markdown file
→ collect matching source titles
→ currentNote.copyWith(backlinks)
```

Properties:

- dynamically derived;
- case-insensitive;
- self-link excluded theo title;
- không persisted vào Markdown;
- outgoing link trong mỗi note được dedupe;
- output backlinks chưa guaranteed dedupe nếu duplicate note titles tồn tại.

Complexity khái quát:

```text
O(number of notes × Markdown content size)
```

Autosave thành công sẽ scan lại toàn Vault nếu `vaultRootPath` đã được set.

---

## 13. Editor UI

### 13.1 Modes

| Mode | Behavior |
|---|---|
| Edit | Expanded monospace TextField |
| Preview | Render Markdown bằng `flutter_markdown` |
| Split | Editor và Preview song song |

### 13.2 Toolbar

Toolbar hiển thị:

- file title;
- word count;
- `Saved`;
- `Unsaved changes`;
- `Saving…`;
- Save button;
- Edit / Preview / Split selector.

### 13.3 States

| Provider state | UI |
|---|---|
| Loading | `CircularProgressIndicator` |
| No note | Editor empty state |
| Open failure | Centered error message |
| Error while note exists | `MaterialBanner` và Retry |
| Backlinks empty | `No backlinks yet` |

### 13.4 TextEditingController lifecycle

Controller được tạo một lần và dispose cùng widget state.

Khi note path thay đổi:

```text
A path → B path
→ replace controller TextEditingValue with B content
→ cursor reset to offset 0
```

Programmatic controller assignment không gọi `TextField.onChanged`, nên không tạo update loop.

Known limitations:

- cursor reset về đầu khi đổi note;
- reload cùng path không sync content mới vì `_displayedPath` không đổi;
- chưa có unsaved-change confirmation trước khi switch note;
- controller giữ A trong memory trong lúc loading B, nhưng editor được ẩn bởi loading state.

---

## 14. Team integration contracts

### 14.1 Member 1 → Member 2

Existing contract vẫn giữ:

```text
Sidebar chọn .md
→ NoteProvider.openNote(filePath)
```

Contract bổ sung:

```dart
NoteProvider.setVaultRootPath(vaultPath)
```

Member 1 hoặc integration layer phải gọi sau khi Vault mở thành công và trước khi dùng backlinks.

Nếu không gọi:

- open/edit/save vẫn hoạt động;
- AI vẫn đọc được current content;
- outgoing links vẫn update;
- backlinks real Vault không refresh.

### 14.2 Member 2 → Member 3

```dart
NoteProvider.currentNote?.content
```

Không thay đổi AI code.

### 14.3 Member 2 → Member 4

```dart
Note.outgoingLinks
```

`updateContent()` parse lại outgoing links và gọi `notifyListeners()`.

Graph rendering vẫn thuộc Member 4.

---

## 15. Cross-ownership decisions

### 15.1 `lib/main.dart`

Conceptual change:

```dart
kUseMock
    ? MockNoteRepository()
    : LocalNoteRepository()
```

Implementation này đúng kỹ thuật nhưng `main.dart` là composition root của Member 4.

Recommendation:

```text
MOVE TO INTEGRATION/MEMBER 4
```

Member 2 giữ ownership của `LocalNoteRepository`; Member 4 quyết định wiring final.

### 15.2 `lib/screens/shell_screen.dart`

Member 2 placeholder đã được thay bằng `NoteEditorScreen`.

Recommendation:

- giữ `NoteEditorScreen` trong ownership Member 2;
- Member 4 review và quyết định final shell placement;
- không để Member 2 tiếp tục redesign shared shell.

### 15.3 Missing note creation

Recommendation:

- Member 1 sở hữu `VaultService.createNote` và filesystem creation;
- Member 2 sở hữu dialog/intent và mở note sau khi create thành công.

---

## 16. Automated test inventory

| # | Test | File | Type | Requirement |
|---:|---|---|---|---|
| 1 | App shell shows editor empty state | `test/widget_test.dart` | Widget | T2.4 |
| 2 | Extracts one Wiki-link | `test/mocks/mock_note_repository_test.dart` | Unit | T2.2/T2.5 |
| 3 | Extracts multiple links in source order | same | Unit | T2.2/T2.5 |
| 4 | Removes duplicates case-insensitively | same | Unit | T2.2/T2.5 |
| 5 | Trims title whitespace | same | Unit | T2.2/T2.5 |
| 6 | Note snapshots link collections | `test/models/note_test.dart` | Unit | T2.1 |
| 7 | Opens note and refreshes backlinks | `test/providers/note_provider_test.dart` | Unit | T2.3 |
| 8 | Updates outgoing links and manual save | same | Unit | T2.3 |
| 9 | Saves after one second inactivity | same | Unit | T2.3 |
| 10 | Exposes open-note error | same | Unit | T2.3 |
| 11 | Saves and reads UTF-8 Markdown | `test/repositories/local_note_repository_test.dart` | Filesystem | T2.6 |
| 12 | Case-insensitive backlinks and self exclusion | same | Filesystem | T2.6 |
| 13 | Loads note into editor | `test/screens/editor/note_editor_screen_test.dart` | Widget | T2.4 |
| 14 | Edit/Preview and rendered Markdown | same | Widget | T2.4/T2.5 |
| 15 | Existing Wiki-link and Backlinks panel | same | Widget | T2.5/T2.6 |

### 16.1 Important behavior not yet tested

- Ctrl+S keyboard event;
- missing Wiki-link dialog/Create action;
- save failure;
- backlink refresh failure;
- A → B switch before debounce;
- same-path reload;
- file missing and directory missing exceptions;
- permission errors;
- duplicate titles;
- hidden folder behavior;
- real Vault → editor integration;
- end-to-end Windows UI persistence.

---

## 17. Verification results

Environment baseline đã được xác nhận:

```text
Flutter 3.47.2 stable
Dart 3.13.2 stable
Visual Studio C++ Desktop workload available
Windows desktop device detected
```

Implementation verification cuối:

```text
flutter analyze
No issues found!

flutter test
15 tests passed
```

`dart format .` từng format nhiều baseline files ngoài scope. Các thay đổi formatter ngoài Member 2 đã được khôi phục. Các file implementation sau đó được format theo phạm vi cụ thể.

Không có generated/native files dirty tại checkpoint.

### Manual verification

Baseline trước implementation đã chạy thành công bằng:

```text
flutter run -d windows
```

Code Member 2 mới chưa được chạy manual sau implementation.

Status:

```text
NOT YET MANUALLY VERIFIED
```

---

## 18. Risk register

| Priority | Risk | Impact | Current evidence |
|---|---|---|---|
| HIGH | Switch note trước debounce làm mất unsaved content | Data loss | `openNote` cancel timer mà không save/prompt |
| HIGH | Create missing Wiki-link chưa tạo file | Incomplete user flow | Button hiện chỉ show SnackBar |
| HIGH | Real Vault integration chưa có | Không demo được full project flow | Member 1 sidebar còn placeholder |
| MEDIUM | Autosave scan toàn Vault | Performance trên Vault lớn | Save gọi full backlinks refresh |
| MEDIUM | Concurrent save dùng cùng temp filename | File contention | Temp path cố định |
| MEDIUM | Parser đọc code blocks như links | Incorrect graph/backlinks | Regex không Markdown-aware |
| MEDIUM | Duplicate titles ambiguous | Mở sai target | Title uniqueness chưa enforce |
| MEDIUM | Cross-ownership `main.dart`/shell | Merge conflict | Member 4 ownership |
| MEDIUM | Same-path reload giữ stale content | UI inconsistency | Controller sync dựa trên path |
| LOW | Cursor reset khi đổi note | UX | Selection đặt offset 0 |
| LOW | Hidden folders được scan | Extra I/O | Không có exclude rule |
| LOW | `flutter_markdown` discontinued | Future maintenance | Dependency hiện tại vẫn build/test pass |

---

## 19. Decisions required before commit

Team cần thống nhất các điểm sau:

1. Ai sở hữu wiring `LocalNoteRepository` trong `main.dart`?
2. Member 4 có chấp nhận thay placeholder shell bằng `NoteEditorScreen` ở branch này không?
3. Member 1 sẽ expose create-note flow như thế nào để missing Wiki-link tạo file thật?
4. Khi switch note có dirty content, app nên save ngay, chặn switch hay hiển thị confirmation?
5. Backlinks có chấp nhận full Vault scan mỗi autosave trong Lab MVP không?
6. Hidden folders có cần exclude khỏi Vault scan không?
7. Team có tiếp tục assumption note title globally unique không?

---

## 20. Recommended ownership split

### Keep in Member 2

- `Note` immutability;
- `WikilinkParser`;
- `MockNoteRepository` behavior;
- `NoteProvider`;
- `NoteEditorScreen`;
- `MarkdownPreview`;
- `BacklinksPanel`;
- `LocalNoteRepository`;
- Member 2 tests.

### Review/move during integration

- `lib/main.dart` wiring → Member 4/integration;
- `lib/screens/shell_screen.dart` placement → Member 4/integration;
- `test/widget_test.dart` shared smoke expectations → team/integration;
- missing note filesystem creation → Member 1;
- graph refresh implementation → Member 4;
- AI consumption implementation → Member 3.

---

## 21. Final checkpoint status

### A. Chắc chắn hoàn thành

- Environment Gate cho Flutter Windows Desktop.
- Branch `feature/editor-md`.
- Note model immutability.
- Basic Wiki-link parser.
- MockNoteRepository parsing/backlinks support.
- NoteProvider state và autosave.
- LocalNoteRepository implementation.
- Editor/preview/backlinks component code.
- Automated analysis và 15 tests.

### B. Implemented nhưng chưa integration

- real Vault backlinks;
- local repository app wiring;
- existing Wiki-link navigation trên Vault thật;
- AI current-note consumption trong UI flow;
- Graph refresh trong final app flow.

### C. Chưa hoàn thành

- missing Wiki-link tạo file thật;
- Member 1 sidebar integration;
- manual Windows verification sau implementation;
- unsaved-change protection khi switch note.

### D. Recommendation

```text
KEEP implementation core của Member 2.
REVIEW cross-ownership changes trước commit.
DO NOT mark toàn bộ Task 2 DONE cho đến khi integration và manual Windows verification hoàn tất.
```

---

## 22. Suggested next checkpoint after team review

Sau khi leader review báo cáo này, checkpoint tiếp theo nên giới hạn ở:

1. quyết định ownership của `main.dart` và `shell_screen.dart`;
2. bổ sung tests cho các risk quan trọng;
3. tích hợp Vault root và create-note flow với Member 1;
4. chạy manual Windows Desktop end-to-end;
5. chạy lại `dart format`, `flutter analyze`, `flutter test`;
6. review diff lần cuối trước khi xin phép commit.

Không nên mở rộng sang AI, Graph rendering, RAG, database hoặc routing framework trong Task 2.
