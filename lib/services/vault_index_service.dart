import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../contracts/note_repository.dart';
import '../core/constants/ai_runtime_config.dart';
import '../models/note.dart';
import '../models/note_chunk.dart';
import 'gemini_embedding_service.dart';

/// Metadata header cho index file, hỗ trợ schema versioning.
class _IndexMeta {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String embeddingModel;
  final DateTime builtAt;

  const _IndexMeta({
    required this.schemaVersion,
    required this.embeddingModel,
    required this.builtAt,
  });

  factory _IndexMeta.fromJson(Map<String, dynamic> json) {
    return _IndexMeta(
      schemaVersion: (json['schemaVersion'] as int?) ?? 0,
      embeddingModel: (json['embeddingModel'] as String?) ?? '',
      builtAt: DateTime.tryParse(json['builtAt'] as String? ?? '') ??
          DateTime(2000),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'embeddingModel': embeddingModel,
        'builtAt': builtAt.toIso8601String(),
      };

  bool isCompatibleWith(String currentModel) =>
      schemaVersion == currentSchemaVersion &&
      embeddingModel == currentModel;
}

/// Service quản lý vector index cho toàn vault.
///
/// Responsibilities:
/// - Chunk notes thành đoạn ~500 ký tự (chia theo heading/paragraph, overlap ~80 ký tự)
/// - Gọi Gemini Embedding API để tạo vectors
/// - Lưu index vào `{vault}/.secondbrain/index.json`
/// - Incremental indexing: chỉ re-index notes có lastModified mới hơn
/// - Cosine similarity search: tìm top-k chunks gần nhất với query
/// - Dọn stale entries khi note bị xoá/đổi tên
class VaultIndexService {
  VaultIndexService({
    required this.noteRepository,
    required this.embeddingService,
    required this.config,
  });

  final NoteRepository noteRepository;
  final GeminiEmbeddingService embeddingService;
  final AIRuntimeConfig config;

  List<NoteChunk> _chunks = [];
  _IndexMeta? _meta;
  bool _isIndexing = false;
  String? _indexedVaultPath;

  /// Write queue để serialize các lần ghi, tránh race condition.
  Future<void>? _pendingWrite;

  // ─── Public API ───

  bool get isIndexed => _chunks.isNotEmpty;
  bool get isIndexing => _isIndexing;
  int get indexedNoteCount {
    final notePaths = <String>{};
    for (final chunk in _chunks) {
      notePaths.add(chunk.notePath);
    }
    return notePaths.length;
  }

  int get indexedChunkCount => _chunks.length;

  /// Full rebuild: index toàn bộ vault.
  Future<void> buildIndex(String vaultRootPath) async {
    if (_isIndexing) return;
    _isIndexing = true;
    _indexedVaultPath = vaultRootPath;

    try {
      // Kiểm tra index hiện tại có compatible không
      await _loadIndexFromDisk(vaultRootPath);
      if (_meta != null && _meta!.isCompatibleWith(config.embeddingModel)) {
        // Index tồn tại và compatible → chạy incremental thay vì full rebuild
        await _incrementalUpdate(vaultRootPath);
        return;
      }

      // Full rebuild
      final notes = await noteRepository.getAllNotes(vaultRootPath);
      final allChunks = <NoteChunk>[];

      for (final note in notes) {
        final chunks = _chunkNote(note);
        allChunks.addAll(chunks);
      }

      // Embed theo batch, throttle để tránh rate limit
      final embedded = await _embedChunksInBatches(allChunks);
      _chunks = embedded;
      _meta = _IndexMeta(
        schemaVersion: _IndexMeta.currentSchemaVersion,
        embeddingModel: config.embeddingModel,
        builtAt: DateTime.now(),
      );

      await _saveIndexToDisk(vaultRootPath);
      debugPrint(
        '[VaultIndex] Full rebuild complete: '
        '${_chunks.length} chunks from ${notes.length} notes',
      );
    } catch (e, st) {
      debugPrint('[VaultIndex] Error building index: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isIndexing = false;
    }
  }

  /// Incremental update: chỉ re-index 1 note đã thay đổi.
  Future<void> updateIndex(String notePath) async {
    final vaultPath = _indexedVaultPath;
    if (vaultPath == null || !isIndexed) return;

    try {
      // Xoá chunks cũ của note này
      _chunks.removeWhere((c) => c.notePath == notePath);

      // Đọc và chunk note mới
      final note = await noteRepository.getNote(notePath);
      final newChunks = _chunkNote(note);
      final embedded = await _embedChunksInBatches(newChunks);
      _chunks.addAll(embedded);

      await _saveIndexToDisk(vaultPath);
      debugPrint(
        '[VaultIndex] Updated index for: ${note.title} '
        '(${embedded.length} chunks)',
      );
    } catch (e) {
      debugPrint('[VaultIndex] Error updating index for $notePath: $e');
    }
  }

  /// Xoá entries của note đã bị xoá khỏi vault.
  Future<void> removeFromIndex(String notePath) async {
    final vaultPath = _indexedVaultPath;
    if (vaultPath == null) return;

    final before = _chunks.length;
    _chunks.removeWhere((c) => c.notePath == notePath);
    if (_chunks.length != before) {
      await _saveIndexToDisk(vaultPath);
      debugPrint('[VaultIndex] Removed stale entries for: $notePath');
    }
  }

  /// Semantic search: tìm top-k chunks gần nhất với query.
  Future<List<NoteChunk>> search(String query, {int? topK}) async {
    final k = topK ?? config.maxRagChunks;
    if (_chunks.isEmpty || query.trim().isEmpty) return const [];

    final queryEmbedding = await embeddingService.embedText(query);
    if (queryEmbedding.isEmpty) return const [];

    // Brute-force cosine similarity (đủ nhanh cho ~1000 chunks)
    final scored = <_ScoredChunk>[];
    for (final chunk in _chunks) {
      if (chunk.embedding == null || chunk.embedding!.isEmpty) continue;
      final sim = GeminiEmbeddingService.cosineSimilarity(
        queryEmbedding,
        chunk.embedding!,
      );
      scored.add(_ScoredChunk(chunk: chunk, score: sim));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).map((s) => s.chunk).toList();
  }

  /// Dọn stale: so sánh index với vault thực tế, xoá entries trỏ đến file không tồn tại.
  Future<void> cleanStaleEntries(String vaultRootPath) async {
    final existingNotes = await noteRepository.getAllNotes(vaultRootPath);
    final existingPaths = existingNotes.map((n) => n.path).toSet();

    final before = _chunks.length;
    _chunks.removeWhere(
      (c) =>
          path.isWithin(vaultRootPath, c.notePath) &&
          !existingPaths.contains(c.notePath),
    );
    if (_chunks.length != before) {
      await _saveIndexToDisk(vaultRootPath);
      debugPrint(
        '[VaultIndex] Cleaned ${before - _chunks.length} stale chunks',
      );
    }
  }

  // ─── Chunking ───

  /// Chia note thành chunks theo heading/paragraph, với overlap.
  List<NoteChunk> _chunkNote(Note note) {
    final content = note.content.trim();
    if (content.isEmpty) return const [];

    final lines = content.split('\n');
    final chunks = <NoteChunk>[];
    final chunkSize = config.chunkSizeChars;
    final overlap = config.chunkOverlapChars;

    var buffer = StringBuffer();
    var chunkStartLine = 1;
    var currentLine = 1;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      currentLine = i + 1;

      // Nếu gặp heading mới và buffer đã có nội dung, flush chunk
      if (line.startsWith('#') && buffer.length > 100) {
        _addChunk(chunks, note, buffer.toString(), chunkStartLine, currentLine - 1);

        // Overlap: lấy phần cuối buffer
        final bufferStr = buffer.toString();
        buffer = StringBuffer();
        if (overlap > 0 && bufferStr.length > overlap) {
          buffer.write(bufferStr.substring(bufferStr.length - overlap));
        }
        chunkStartLine = currentLine;
      }

      buffer.writeln(line);

      // Nếu buffer vượt chunkSize, flush
      if (buffer.length >= chunkSize) {
        _addChunk(chunks, note, buffer.toString(), chunkStartLine, currentLine);

        // Overlap
        final bufferStr = buffer.toString();
        buffer = StringBuffer();
        if (overlap > 0 && bufferStr.length > overlap) {
          buffer.write(bufferStr.substring(bufferStr.length - overlap));
        }
        chunkStartLine = currentLine + 1;
      }
    }

    // Flush remaining
    if (buffer.length > 10) {
      _addChunk(chunks, note, buffer.toString(), chunkStartLine, currentLine);
    }

    return chunks;
  }

  void _addChunk(
    List<NoteChunk> chunks,
    Note note,
    String content,
    int startLine,
    int endLine,
  ) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    chunks.add(NoteChunk(
      noteTitle: note.title,
      notePath: note.path,
      content: trimmed,
      startLine: startLine,
      endLine: endLine,
      indexedAt: DateTime.now(),
    ));
  }

  // ─── Embedding ───

  /// Embed chunks theo batch, với delay giữa các batch để tránh rate limit.
  Future<List<NoteChunk>> _embedChunksInBatches(List<NoteChunk> chunks) async {
    if (chunks.isEmpty) return const [];

    final result = <NoteChunk>[];
    final batchSize = config.embeddingBatchSize;

    for (var i = 0; i < chunks.length; i += batchSize) {
      final end = math.min(i + batchSize, chunks.length);
      final batch = chunks.sublist(i, end);
      final texts = batch.map((c) => c.content).toList();

      try {
        final embeddings = await embeddingService.embedBatch(texts);
        for (var j = 0; j < batch.length; j++) {
          result.add(batch[j].copyWith(
            embedding: j < embeddings.length ? embeddings[j] : null,
          ));
        }
      } catch (e) {
        debugPrint('[VaultIndex] Embedding batch failed: $e');
        // Thêm chunks không có embedding (vẫn searchable bằng text)
        result.addAll(batch);
      }

      // Throttle: chờ 1 giây giữa các batch để tránh rate limit
      if (end < chunks.length) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return result;
  }

  // ─── Incremental Update ───

  Future<void> _incrementalUpdate(String vaultRootPath) async {
    final notes = await noteRepository.getAllNotes(vaultRootPath);
    await _rebasePathsIfMoved(vaultRootPath, notes);

    // Tìm notes cần re-index (mới hơn index)
    final indexedPaths = <String, DateTime>{};
    for (final chunk in _chunks) {
      final existing = indexedPaths[chunk.notePath];
      if (existing == null || chunk.indexedAt.isAfter(existing)) {
        indexedPaths[chunk.notePath] = chunk.indexedAt;
        final fn = path.basename(chunk.notePath).toLowerCase();
        indexedPaths[fn] = chunk.indexedAt;
      }
    }

    final notesToReindex = <Note>[];
    final currentPaths = <String>{};
    for (final note in notes) {
      currentPaths.add(note.path);
      final noteFn = path.basename(note.path).toLowerCase();
      final indexedAt = indexedPaths[note.path] ?? indexedPaths[noteFn];
      if (indexedAt == null || note.lastModified.isAfter(indexedAt)) {
        notesToReindex.add(note);
      }
    }

    // Dọn stale entries (chỉ dọn note thực sự thuộc vaultRootPath hiện tại và đã bị xoá)
    _chunks.removeWhere(
      (c) =>
          path.isWithin(vaultRootPath, c.notePath) &&
          !currentPaths.contains(c.notePath),
    );

    if (notesToReindex.isEmpty) {
      debugPrint('[VaultIndex] Incremental: no changes detected');
      return;
    }

    // Xoá chunks cũ của notes cần re-index
    final reindexPaths = notesToReindex.map((n) => n.path).toSet();
    final reindexFilenames =
        notesToReindex.map((n) => path.basename(n.path).toLowerCase()).toSet();
    _chunks.removeWhere((c) =>
        reindexPaths.contains(c.notePath) ||
        (path.isWithin(vaultRootPath, c.notePath) &&
            reindexFilenames.contains(path.basename(c.notePath).toLowerCase())));

    // Chunk và embed notes mới
    final newChunks = <NoteChunk>[];
    for (final note in notesToReindex) {
      newChunks.addAll(_chunkNote(note));
    }
    final embedded = await _embedChunksInBatches(newChunks);
    _chunks.addAll(embedded);

    await _saveIndexToDisk(vaultRootPath);
    debugPrint(
      '[VaultIndex] Incremental update: '
      '${notesToReindex.length} notes re-indexed, '
      '${embedded.length} new chunks',
    );
  }

  /// Tự động cập nhật notePath của các chunks khi vault được copy/chuyển sang máy khác
  /// hoặc đổi thư mục gốc. Tránh việc re-index lại toàn bộ từ đầu gây tốn quota API.
  Future<void> _rebasePathsIfMoved(
    String vaultRootPath,
    List<Note> notes,
  ) async {
    if (_chunks.isEmpty || notes.isEmpty) return;

    final firstPath = _chunks.first.notePath;
    if (File(firstPath).existsSync() && path.isWithin(vaultRootPath, firstPath)) {
      return;
    }

    final noteMapByTitle = <String, Note>{};
    final noteMapByFilename = <String, Note>{};
    for (final note in notes) {
      noteMapByTitle[note.title.toLowerCase()] = note;
      noteMapByFilename[path.basename(note.path).toLowerCase()] = note;
    }

    var rebasedCount = 0;
    for (var i = 0; i < _chunks.length; i++) {
      final chunk = _chunks[i];
      final chunkFilename = path.basename(chunk.notePath).toLowerCase();
      final matchedNote = noteMapByTitle[chunk.noteTitle.toLowerCase()] ??
          noteMapByFilename[chunkFilename];
      if (matchedNote != null && chunk.notePath != matchedNote.path) {
        _chunks[i] = chunk.copyWith(notePath: matchedNote.path);
        rebasedCount++;
      }
    }

    if (rebasedCount > 0) {
      debugPrint(
        '[VaultIndex] Rebased $rebasedCount chunks to local vault path: $vaultRootPath',
      );
      await _saveIndexToDisk(vaultRootPath);
    }
  }

  // ─── Persistence (JSON file-based) ───

  String _indexPath(String vaultRootPath) {
    // 1. Cấu hình cụ thể từ config / .env (RAG_INDEX_PATH)
    final configuredPath = config.ragIndexPath?.trim();
    if (configuredPath != null && configuredPath.isNotEmpty) {
      final directFile = File(configuredPath);
      if (directFile.existsSync()) {
        return directFile.absolute.path;
      }
      final relativeFromVault = path.join(vaultRootPath, configuredPath);
      if (File(relativeFromVault).existsSync()) {
        return File(relativeFromVault).absolute.path;
      }
    }

    // 2. Tự động kiểm tra file index lớn tại wiki/.secondbrain/index.json
    final candidateWikiIndex =
        File(path.join('wiki', '.secondbrain', 'index.json'));
    if (candidateWikiIndex.existsSync()) {
      final localVaultIndex =
          File(path.join(vaultRootPath, '.secondbrain', 'index.json'));
      if (!localVaultIndex.existsSync() ||
          localVaultIndex.lengthSync() < candidateWikiIndex.lengthSync()) {
        return candidateWikiIndex.absolute.path;
      }
    }

    return path.join(vaultRootPath, '.secondbrain', 'index.json');
  }

  Future<void> _loadIndexFromDisk(String vaultRootPath) async {
    try {
      final resolvedPath = _indexPath(vaultRootPath);
      final file = File(resolvedPath);
      if (!await file.exists()) {
        _chunks = [];
        _meta = null;
        return;
      }

      debugPrint('[VaultIndex] Loading vector index from: $resolvedPath');
      final content = await file.readAsString(encoding: utf8);
      final decoded = jsonDecode(content) as Map<String, dynamic>;

      _meta = decoded.containsKey('meta')
          ? _IndexMeta.fromJson(decoded['meta'] as Map<String, dynamic>)
          : null;

      final chunksJson = decoded['chunks'] as List<dynamic>? ?? [];
      _chunks = chunksJson
          .whereType<Map<String, dynamic>>()
          .map(NoteChunk.fromJson)
          .toList();

      debugPrint(
        '[VaultIndex] Loaded ${_chunks.length} chunks from disk '
        '(built: ${_meta?.builtAt}, model: ${_meta?.embeddingModel})',
      );
    } catch (e) {
      debugPrint('[VaultIndex] Error loading index: $e');
      _chunks = [];
      _meta = null;
    }
  }

  /// Write-queue để serialize ghi file, tránh race condition.
  Future<void> _saveIndexToDisk(String vaultRootPath) async {
    // Chờ pending write xong trước khi bắt đầu write mới
    while (_pendingWrite != null) {
      await _pendingWrite;
    }
    _pendingWrite = _performSave(vaultRootPath);
    try {
      await _pendingWrite;
    } finally {
      _pendingWrite = null;
    }
  }

  Future<void> _performSave(String vaultRootPath) async {
    try {
      final filePath = _indexPath(vaultRootPath);
      final dir = Directory(path.dirname(filePath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final data = {
        'meta': (_meta ?? _IndexMeta(
          schemaVersion: _IndexMeta.currentSchemaVersion,
          embeddingModel: config.embeddingModel,
          builtAt: DateTime.now(),
        )).toJson(),
        'chunks': _chunks.map((c) => c.toJson()).toList(),
      };

      // Atomic write: ghi vào temp file rồi rename
      final tempPath = '$filePath.tmp';
      final tempFile = File(tempPath);
      await tempFile.writeAsString(
        jsonEncode(data),
        encoding: utf8,
        flush: true,
      );
      await tempFile.rename(filePath);
    } catch (e) {
      debugPrint('[VaultIndex] Error saving index: $e');
    }
  }
}

class _ScoredChunk {
  final NoteChunk chunk;
  final double score;
  const _ScoredChunk({required this.chunk, required this.score});
}
