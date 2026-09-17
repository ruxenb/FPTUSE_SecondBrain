import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/mocks/mock_note_repository.dart';

void main() {
  late MockNoteRepository repository;

  setUp(() {
    repository = MockNoteRepository();
  });

  group('MockNoteRepository.extractWikilinks', () {
    test('extracts one Wiki-link', () {
      expect(repository.extractWikilinks('Learn [[Flutter]].'), ['Flutter']);
    });

    test('extracts multiple Wiki-links in source order', () {
      expect(
        repository.extractWikilinks('[[Flutter]] with [[Provider Pattern]].'),
        ['Flutter', 'Provider Pattern'],
      );
    });

    test('removes duplicate Wiki-links case-insensitively', () {
      expect(
        repository.extractWikilinks('[[Flutter]], [[flutter]], [[ FLUTTER ]]'),
        ['Flutter'],
      );
    });

    test('trims whitespace around a Wiki-link title', () {
      expect(
        repository.extractWikilinks('Read [[  Provider Pattern  ]] today.'),
        ['Provider Pattern'],
      );
    });
  });
}
