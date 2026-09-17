import 'package:flutter_test/flutter_test.dart';
import 'package:fptu_se_second_brain/models/note.dart';

void main() {
  test('Note snapshots link collections at creation time', () {
    final links = ['Flutter'];
    final note = Note(
      path: 'C:\\vault\\Flutter.md',
      title: 'Flutter',
      content: 'Content',
      outgoingLinks: links,
    );

    links.add('Provider');

    expect(note.outgoingLinks, ['Flutter']);
    expect(() => note.outgoingLinks.add('SQLite'), throwsUnsupportedError);
  });
}
