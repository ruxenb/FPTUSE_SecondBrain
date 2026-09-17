import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../contracts/note_repository.dart';
import '../../core/utils/wikilink_parser.dart';
import '../../models/note.dart';
import '../../providers/note_provider.dart';
import 'widgets/backlinks_panel.dart';
import 'widgets/markdown_preview.dart';

enum EditorView { edit, preview, split }

typedef MissingNoteCreator = Future<String?> Function(String title);

class NoteEditorScreen extends StatefulWidget {
  final MissingNoteCreator? onCreateMissingNote;

  const NoteEditorScreen({this.onCreateMissingNote, super.key});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _controller = TextEditingController();
  EditorView _view = EditorView.edit;
  String? _displayedPath;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoteProvider>();
    final note = provider.currentNote;
    _syncController(note);

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              context.read<NoteProvider>().saveCurrentNote();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: _buildBody(context, provider, note),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NoteProvider provider, Note? note) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.hasError && note == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(provider.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (note == null) {
      return const Center(
        child: Text('Select a Markdown note from the Vault to start editing.'),
      );
    }

    return Column(
      children: [
        _EditorToolbar(
          note: note,
          view: _view,
          isDirty: provider.isDirty,
          isSaving: provider.isSaving,
          onViewChanged: (view) => setState(() => _view = view),
          onSave: provider.saveCurrentNote,
        ),
        if (provider.hasError)
          MaterialBanner(
            content: Text(provider.errorMessage!),
            actions: [
              TextButton(
                onPressed: provider.refreshBacklinks,
                child: const Text('Retry'),
              ),
            ],
          ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildEditorArea(context, provider, note)),
              BacklinksPanel(
                backlinks: note.backlinks,
                onOpenBacklink: _openWikiLink,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditorArea(
    BuildContext context,
    NoteProvider provider,
    Note note,
  ) {
    final editor = TextField(
      key: const Key('markdown-editor'),
      controller: _controller,
      onChanged: provider.updateContent,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontFamily: 'Consolas', fontSize: 14, height: 1.5),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(20),
      ),
    );
    final preview = MarkdownPreview(
      markdown: note.content,
      onOpenWikiLink: _openWikiLink,
    );

    return switch (_view) {
      EditorView.edit => editor,
      EditorView.preview => preview,
      EditorView.split => Row(
        children: [
          Expanded(child: editor),
          const VerticalDivider(width: 1),
          Expanded(child: preview),
        ],
      ),
    };
  }

  Future<void> _openWikiLink(String title) async {
    final provider = context.read<NoteProvider>();
    final repository = context.read<NoteRepository>();
    final notes = await repository.getAllNotes(provider.vaultRootPath ?? '');
    Note? target;
    for (final note in notes) {
      if (WikilinkParser.titlesEqual(note.title, title)) {
        target = note;
        break;
      }
    }

    if (!mounted) {
      return;
    }
    if (target != null) {
      await provider.openNote(target.path);
      return;
    }

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note not found'),
        content: Text('"$title" does not exist in the current Vault.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create note'),
          ),
        ],
      ),
    );
    if (shouldCreate != true || !mounted) {
      return;
    }

    final createMissingNote = widget.onCreateMissingNote;
    if (createMissingNote == null) {
      _showCreateError(title);
      return;
    }
    final createdPath = await createMissingNote(title);
    if (!mounted) {
      return;
    }
    if (createdPath == null) {
      _showCreateError(title);
      return;
    }
    await provider.openNote(createdPath);
  }

  void _showCreateError(String title) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not create note "$title".')));
  }

  void _syncController(Note? note) {
    if (note == null || note.path == _displayedPath) {
      return;
    }
    _displayedPath = note.path;
    _controller.value = TextEditingValue(
      text: note.content,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }
}

class _EditorToolbar extends StatelessWidget {
  final Note note;
  final EditorView view;
  final bool isDirty;
  final bool isSaving;
  final ValueChanged<EditorView> onViewChanged;
  final VoidCallback onSave;

  const _EditorToolbar({
    required this.note,
    required this.view,
    required this.isDirty,
    required this.isSaving,
    required this.onViewChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final wordCount = note.content.trim().isEmpty
        ? 0
        : note.content.trim().split(RegExp(r'\s+')).length;
    final status = isSaving
        ? 'Saving…'
        : isDirty
        ? 'Unsaved changes'
        : 'Saved';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              note.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            '$wordCount words',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
          Text(
            status,
            key: const Key('save-status'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Save (Ctrl+S)',
            onPressed: isSaving ? null : onSave,
            icon: const Icon(Icons.save_outlined),
          ),
          SegmentedButton<EditorView>(
            segments: const [
              ButtonSegment(
                value: EditorView.edit,
                label: Text('Edit'),
                icon: Icon(Icons.edit_outlined),
              ),
              ButtonSegment(
                value: EditorView.preview,
                label: Text('Preview'),
                icon: Icon(Icons.visibility_outlined),
              ),
              ButtonSegment(
                value: EditorView.split,
                label: Text('Split'),
                icon: Icon(Icons.vertical_split),
              ),
            ],
            selected: {view},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onViewChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}
