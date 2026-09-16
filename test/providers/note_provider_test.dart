import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/contracts/note_repository.dart';
import 'package:fptu_se_second_brain/core/utils/wikilink_parser.dart';
import 'package:fptu_se_second_brain/models/note.dart';
import 'package:fptu_se_second_brain/providers/note_provider.dart';

void main() {
  late _FakeNoteRepository repository;
  late NoteProvider provider;

  setUp(() {
    repository = _FakeNoteRepository();
    provider = NoteProvider(noteRepository: repository);
  });

  tearDown(() {
    provider.dispose();
  });

  test('opens a note and refreshes its backlinks', () async {
    repository.backlinks = ['Provider'];

    await provider.openNote(
      _FakeNoteRepository.notePath,
      vaultRoot: _FakeNoteRepository.vaultPath,
    );

    expect(provider.currentNote?.title, 'Flutter');
    expect(provider.currentNote?.backlinks, ['Provider']);
    expect(provider.isLoading, isFalse);
    expect(provider.hasError, isFalse);
  });

  test('updates outgoing links and saves manually', () async {
    await provider.openNote(_FakeNoteRepository.notePath);

    provider.updateContent('Study [[Provider Pattern]].');

    expect(provider.isDirty, isTrue);
    expect(provider.currentNote?.outgoingLinks, ['Provider Pattern']);

    await provider.saveCurrentNote();

    expect(repository.savedNotes, hasLength(1));
    expect(repository.savedNotes.single.content, 'Study [[Provider Pattern]].');
    expect(provider.isDirty, isFalse);
    expect(provider.isSaving, isFalse);
  });

  test('saves after one second of inactivity', () async {
    await provider.openNote(_FakeNoteRepository.notePath);

    provider.updateContent('Auto-save [[Flutter]].');
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    expect(repository.savedNotes, hasLength(1));
    expect(provider.isDirty, isFalse);
  });

  test('exposes an error when opening a note fails', () async {
    repository.getNoteError = StateError('missing file');

    await provider.openNote(_FakeNoteRepository.notePath);

    expect(provider.currentNote, isNull);
    expect(provider.errorMessage, contains('Could not open note'));
  });

  test('saves a dirty note before opening another note', () async {
    await provider.openNote(_FakeNoteRepository.notePath);
    provider.updateContent('Unsaved content from A');

    await provider.openNote(_FakeNoteRepository.secondNotePath);

    expect(repository.savedNotes, hasLength(1));
    expect(repository.savedNotes.single.path, _FakeNoteRepository.notePath);
    expect(repository.savedNotes.single.content, 'Unsaved content from A');
    expect(provider.currentNote?.path, _FakeNoteRepository.secondNotePath);
    expect(provider.isDirty, isFalse);
  });

  test('keeps the dirty note open when save before switching fails', () async {
    await provider.openNote(_FakeNoteRepository.notePath);
    provider.updateContent('Content that must not be lost');
    repository.saveNoteError = StateError('disk write failed');

    await provider.openNote(_FakeNoteRepository.secondNotePath);

    expect(
      repository.requestedNotePaths,
      isNot(contains(_FakeNoteRepository.secondNotePath)),
    );
    expect(provider.currentNote?.path, _FakeNoteRepository.notePath);
    expect(provider.currentNote?.content, 'Content that must not be lost');
    expect(provider.isDirty, isTrue);
    expect(provider.errorMessage, contains('Could not save note'));
  });
}

class _FakeNoteRepository implements NoteRepository {
  static const vaultPath = r'C:\vault';
  static const notePath = r'C:\vault\Flutter.md';
  static const secondNotePath = r'C:\vault\Provider.md';

  final savedNotes = <Note>[];
  final requestedNotePaths = <String>[];
  List<String> backlinks = const [];
  Object? getNoteError;
  Object? saveNoteError;

  @override
  List<String> extractWikilinks(String markdownContent) {
    return WikilinkParser.extract(markdownContent);
  }

  @override
  Future<List<String>> getBacklinksForNote(
    String noteTitle,
    String vaultRootPath,
  ) async {
    return backlinks;
  }

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async => const [];

  @override
  Future<Note> getNote(String filePath) async {
    requestedNotePaths.add(filePath);
    if (getNoteError != null) {
      throw getNoteError!;
    }
    return Note(
      path: filePath,
      title: filePath == notePath ? 'Flutter' : 'Provider',
      content: 'Original content',
      outgoingLinks: const [],
    );
  }

  @override
  Future<void> saveNote(Note note) async {
    if (saveNoteError != null) {
      throw saveNoteError!;
    }
    savedNotes.add(note);
  }
}
