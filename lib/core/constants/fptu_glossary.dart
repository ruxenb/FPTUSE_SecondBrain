import 'dart:convert';
import 'dart:io';

/// Một mục trong bộ từ điển thuật ngữ FPTU.
class FptuGlossaryEntry {
  const FptuGlossaryEntry({
    required this.term,
    required this.definition,
    required this.category,
    this.aliases = const [],
  });

  final String term;
  final String definition;
  final String category;
  final List<String> aliases;

  /// Tạo từ JSON (dùng cho custom glossary overlay).
  factory FptuGlossaryEntry.fromJson(Map<String, dynamic> json) {
    return FptuGlossaryEntry(
      term: (json['term'] as String?)?.trim() ?? '',
      definition: (json['definition'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? 'general',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => (e as String).trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'term': term,
        'definition': definition,
        'category': category,
        if (aliases.isNotEmpty) 'aliases': aliases,
      };
}

/// Bộ từ điển thuật ngữ đặc thù FPTU SE.
///
/// Hỗ trợ:
/// - Tra cứu nhanh theo term/alias
/// - Tìm tất cả thuật ngữ xuất hiện trong đoạn text
/// - Tạo context string để inject vào AI prompt
/// - Mở rộng bằng custom overlay file (`.secondbrain/custom_glossary.json`)
class FptuGlossary {
  FptuGlossary._();

  // ─── Lookup index (lazy-built) ───

  static Map<String, FptuGlossaryEntry>? _lookupCache;
  static List<FptuGlossaryEntry>? _mergedEntries;
  static String? _lastCustomPath;

  static Map<String, FptuGlossaryEntry> get _lookup {
    if (_lookupCache != null) return _lookupCache!;
    _lookupCache = <String, FptuGlossaryEntry>{};
    for (final entry in _builtinEntries) {
      _lookupCache![entry.term.toLowerCase()] = entry;
      for (final alias in entry.aliases) {
        _lookupCache![alias.toLowerCase()] = entry;
      }
    }
    return _lookupCache!;
  }

  /// Danh sách tất cả entries (builtin + custom nếu đã load).
  static List<FptuGlossaryEntry> get entries => _mergedEntries ?? _builtinEntries;

  /// Tra cứu nhanh theo term hoặc alias (case-insensitive).
  static FptuGlossaryEntry? lookup(String term) {
    return _lookup[term.trim().toLowerCase()];
  }

  /// Tìm tất cả thuật ngữ xuất hiện trong [text].
  static List<FptuGlossaryEntry> findMentionedTerms(String text) {
    final lowerText = text.toLowerCase();
    final found = <String, FptuGlossaryEntry>{};

    for (final entry in entries) {
      if (found.containsKey(entry.term.toLowerCase())) continue;
      if (lowerText.contains(entry.term.toLowerCase())) {
        found[entry.term.toLowerCase()] = entry;
        continue;
      }
      for (final alias in entry.aliases) {
        if (lowerText.contains(alias.toLowerCase())) {
          found[entry.term.toLowerCase()] = entry;
          break;
        }
      }
    }

    return found.values.toList();
  }

  /// Tạo context string từ danh sách entries để inject vào prompt.
  static String buildContextString(List<FptuGlossaryEntry> matchedEntries) {
    if (matchedEntries.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('<fptu_glossary>');
    buffer.writeln(
      'Dưới đây là thuật ngữ đặc thù của FPT University liên quan đến câu hỏi:',
    );
    for (final entry in matchedEntries) {
      buffer.write('- **${entry.term}**');
      if (entry.aliases.isNotEmpty) {
        buffer.write(' (${entry.aliases.join(', ')})');
      }
      buffer.writeln(': ${entry.definition}');
    }
    buffer.writeln('</fptu_glossary>');
    return buffer.toString();
  }

  /// Load custom glossary overlay từ file JSON và merge với builtin.
  ///
  /// File phải là JSON array: `[{"term": "...", "definition": "...", ...}]`.
  /// Entries custom sẽ ghi đè entries builtin có cùng term (case-insensitive).
  static Future<void> loadCustomOverlay(String vaultRootPath) async {
    final customPath = '$vaultRootPath/.secondbrain/custom_glossary.json';
    if (_lastCustomPath == customPath && _mergedEntries != null) return;

    try {
      final file = File(customPath);
      if (!await file.exists()) {
        _mergedEntries = _builtinEntries;
        _lastCustomPath = customPath;
        _rebuildLookup();
        return;
      }

      final content = await file.readAsString(encoding: utf8);
      final decoded = jsonDecode(content);
      if (decoded is! List) {
        _mergedEntries = _builtinEntries;
        _lastCustomPath = customPath;
        _rebuildLookup();
        return;
      }

      final customEntries = decoded
          .whereType<Map<String, dynamic>>()
          .map(FptuGlossaryEntry.fromJson)
          .where((e) => e.term.isNotEmpty && e.definition.isNotEmpty)
          .toList();

      // Merge: custom overrides builtin for matching terms
      final merged = <String, FptuGlossaryEntry>{};
      for (final entry in _builtinEntries) {
        merged[entry.term.toLowerCase()] = entry;
      }
      for (final entry in customEntries) {
        merged[entry.term.toLowerCase()] = entry;
      }

      _mergedEntries = merged.values.toList();
      _lastCustomPath = customPath;
      _rebuildLookup();
    } catch (_) {
      _mergedEntries = _builtinEntries;
      _lastCustomPath = customPath;
      _rebuildLookup();
    }
  }

  /// Xoá cache để reload.
  static void invalidateCache() {
    _lookupCache = null;
    _mergedEntries = null;
    _lastCustomPath = null;
  }

  static void _rebuildLookup() {
    _lookupCache = <String, FptuGlossaryEntry>{};
    for (final entry in entries) {
      _lookupCache![entry.term.toLowerCase()] = entry;
      for (final alias in entry.aliases) {
        _lookupCache![alias.toLowerCase()] = entry;
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  //  BUILTIN ENTRIES (~60 thuật ngữ đặc thù FPTU SE)
  // ═══════════════════════════════════════════════════════

  static const List<FptuGlossaryEntry> _builtinEntries = [
    // ─── Academic / Học vụ ───
    FptuGlossaryEntry(
      term: 'Slot',
      definition:
          'Đơn vị buổi học tại FPTU, mỗi slot kéo dài 90 phút. '
          'Một môn thường có 30 slot/kỳ (Block 5: 15 tuần × 2 slot/tuần).',
      category: 'academic',
      aliases: ['tiết học', 'buổi học'],
    ),
    FptuGlossaryEntry(
      term: 'FLM',
      definition:
          'Funix Learning Materials — hệ thống bài giảng trực tuyến '
          'chứa video, slide, reading materials cho từng slot.',
      category: 'infrastructure',
      aliases: ['Funix', 'learning materials'],
    ),
    FptuGlossaryEntry(
      term: 'CMS',
      definition:
          'Course Management System — hệ thống quản lý môn học của FPTU, '
          'nơi sinh viên nộp bài, xem điểm, nhận thông báo.',
      category: 'infrastructure',
    ),
    FptuGlossaryEntry(
      term: 'FE',
      definition:
          'Final Exam — bài thi cuối kỳ, thường chiếm 30-40% tổng điểm.',
      category: 'academic',
      aliases: ['Final Exam', 'thi cuối kỳ'],
    ),
    FptuGlossaryEntry(
      term: 'PE',
      definition:
          'Practical Exam — bài thi thực hành, thường gặp ở các môn lập trình. '
          'Sinh viên code trực tiếp trong thời gian giới hạn.',
      category: 'academic',
      aliases: ['Practical Exam', 'thi thực hành'],
    ),
    FptuGlossaryEntry(
      term: 'PT',
      definition:
          'Progress Test — bài kiểm tra giữa kỳ, thường có 2 bài PT mỗi môn.',
      category: 'academic',
      aliases: ['Progress Test', 'kiểm tra giữa kỳ'],
    ),
    FptuGlossaryEntry(
      term: 'GPA',
      definition:
          'Grade Point Average — điểm trung bình tích lũy theo thang 10 tại FPTU. '
          'GPA >= 5.0 để tốt nghiệp, >= 7.0 loại khá, >= 8.5 loại giỏi.',
      category: 'academic',
    ),
    FptuGlossaryEntry(
      term: 'Block 5',
      definition:
          'Hệ đào tạo theo block 5 môn/kỳ, mỗi kỳ 15 tuần. '
          'Sinh viên học tối đa 5 môn chuyên ngành cùng lúc.',
      category: 'academic',
      aliases: ['block5'],
    ),
    FptuGlossaryEntry(
      term: 'Block 10',
      definition:
          'Chế độ học rút gọn: 1 kỳ chia 2 nửa (mỗi nửa 7.5 tuần), '
          'mỗi nửa học tối đa 5 môn. Tổng tối đa 10 môn/kỳ.',
      category: 'academic',
      aliases: ['block10'],
    ),
    FptuGlossaryEntry(
      term: 'Retake',
      definition:
          'Thi lại — sinh viên không đạt điểm qua môn có thể đăng ký thi lại '
          'mà không cần học lại toàn bộ.',
      category: 'academic',
      aliases: ['thi lại'],
    ),
    FptuGlossaryEntry(
      term: 'Re-learn',
      definition:
          'Học lại — sinh viên phải đăng ký học lại từ đầu nếu trượt quá '
          'số lần thi lại cho phép hoặc bị điểm F.',
      category: 'academic',
      aliases: ['học lại'],
    ),
    FptuGlossaryEntry(
      term: 'Prerequisite',
      definition:
          'Môn tiên quyết — phải đạt môn này trước khi được đăng ký môn tiếp theo.',
      category: 'academic',
      aliases: ['môn tiên quyết'],
    ),
    FptuGlossaryEntry(
      term: 'Elective',
      definition:
          'Môn tự chọn — sinh viên chọn theo sở thích trong danh sách cho phép, '
          'chia thành tự chọn chuyên ngành và tự chọn tự do.',
      category: 'academic',
      aliases: ['môn tự chọn'],
    ),

    // ─── Milestones / Cột mốc đào tạo ───
    FptuGlossaryEntry(
      term: 'OJT',
      definition:
          'On-the-Job Training — thực tập tại doanh nghiệp (Semester 6-7), '
          'kéo dài 4 tháng, yêu cầu báo cáo thực tập.',
      category: 'process',
      aliases: ['thực tập', 'On-the-Job Training'],
    ),
    FptuGlossaryEntry(
      term: 'Capstone',
      definition:
          'Đồ án tốt nghiệp theo nhóm (SEP490/SET490), kéo dài 1-2 kỳ. '
          'Nhóm 4-6 người xây dựng sản phẩm phần mềm hoàn chỉnh.',
      category: 'process',
      aliases: ['đồ án tốt nghiệp', 'graduation project'],
    ),
    FptuGlossaryEntry(
      term: 'Thesis',
      definition:
          'Luận văn tốt nghiệp (SET490) — hình thức thay thế Capstone, '
          'thiên về nghiên cứu hơn là phát triển sản phẩm.',
      category: 'process',
      aliases: ['luận văn', 'graduation thesis'],
    ),
    FptuGlossaryEntry(
      term: 'Lab',
      definition:
          'Bài thực hành trên máy tính, thường đi kèm mỗi slot lý thuyết. '
          'Kết quả Lab thường tính vào Assignment hoặc Progress Test.',
      category: 'academic',
      aliases: ['bài lab', 'thực hành'],
    ),
    FptuGlossaryEntry(
      term: 'Assignment',
      definition:
          'Bài tập cá nhân hoặc nhóm, nộp qua CMS. '
          'Thường chiếm 10-20% tổng điểm mỗi môn.',
      category: 'academic',
      aliases: ['bài tập', 'ASM'],
    ),

    // ─── Infrastructure / Hệ thống ───
    FptuGlossaryEntry(
      term: 'FAP',
      definition:
          'FPT Academic Portal — cổng thông tin học vụ: xem lịch học, '
          'lịch thi, điểm, đăng ký môn.',
      category: 'infrastructure',
      aliases: ['Academic Portal', 'FPT Academic Portal'],
    ),
    FptuGlossaryEntry(
      term: 'EOS',
      definition:
          'Edunext Online System — hệ thống quản lý học tập trực tuyến, '
          'chứa tài liệu, assignment, quiz.',
      category: 'infrastructure',
      aliases: ['Edunext'],
    ),
    FptuGlossaryEntry(
      term: 'Canvas',
      definition:
          'Nền tảng LMS dùng cho một số cơ sở FPTU, '
          'tương tự chức năng EOS.',
      category: 'infrastructure',
    ),
    FptuGlossaryEntry(
      term: 'GitHub Classroom',
      definition:
          'Công cụ nộp bài qua GitHub dùng trong các môn lập trình '
          '(PRF192, PRO192, SWP391). Tự động tạo repo cho mỗi sinh viên.',
      category: 'infrastructure',
    ),

    // ─── Course Codes (Major SE) ───
    FptuGlossaryEntry(
      term: 'PRF192',
      definition: 'Programming Fundamentals — môn lập trình căn bản bằng C.',
      category: 'course',
      aliases: ['Programming Fundamentals'],
    ),
    FptuGlossaryEntry(
      term: 'PRO192',
      definition: 'Object-Oriented Programming — lập trình hướng đối tượng bằng Java.',
      category: 'course',
      aliases: ['Object-Oriented Programming', 'OOP'],
    ),
    FptuGlossaryEntry(
      term: 'CSD201',
      definition: 'Data Structures and Algorithms — cấu trúc dữ liệu và giải thuật.',
      category: 'course',
      aliases: ['Data Structures and Algorithms', 'DSA'],
    ),
    FptuGlossaryEntry(
      term: 'DBI202',
      definition: 'Database Systems — hệ quản trị cơ sở dữ liệu, SQL và thiết kế database.',
      category: 'course',
      aliases: ['Database Systems'],
    ),
    FptuGlossaryEntry(
      term: 'SWE201c',
      definition: 'Introduction to Software Engineering — nhập môn kỹ nghệ phần mềm.',
      category: 'course',
      aliases: ['Software Engineering'],
    ),
    FptuGlossaryEntry(
      term: 'SWP391',
      definition:
          'Software Development Project — đồ án phần mềm theo nhóm, '
          'áp dụng Agile/Scrum. Nhóm 4-5 người trong 15 tuần.',
      category: 'course',
      aliases: ['Software Development Project'],
    ),
    FptuGlossaryEntry(
      term: 'SWD392',
      definition:
          'Software Architecture and Design — kiến trúc và thiết kế phần mềm, '
          'design patterns, microservices.',
      category: 'course',
      aliases: ['Software Architecture'],
    ),
    FptuGlossaryEntry(
      term: 'SWR302',
      definition: 'Software Requirements — phân tích và đặc tả yêu cầu phần mềm.',
      category: 'course',
      aliases: ['Software Requirements'],
    ),
    FptuGlossaryEntry(
      term: 'SWT301',
      definition: 'Software Testing — kiểm thử phần mềm, test case design, automation testing.',
      category: 'course',
      aliases: ['Software Testing'],
    ),
    FptuGlossaryEntry(
      term: 'PRJ301',
      definition: 'Java Web Development — phát triển web bằng Java Servlet/JSP.',
      category: 'course',
      aliases: ['Java Web'],
    ),
    FptuGlossaryEntry(
      term: 'PRN212',
      definition: 'Cross-Platform Programming with .NET — lập trình đa nền tảng với C# và .NET.',
      category: 'course',
      aliases: ['Cross-Platform .NET'],
    ),
    FptuGlossaryEntry(
      term: 'FER202',
      definition: 'Front-End Web Development — phát triển giao diện web với ReactJS.',
      category: 'course',
      aliases: ['Front-End', 'ReactJS'],
    ),
    FptuGlossaryEntry(
      term: 'SDN302',
      definition: 'Server-side Development with NodeJS — phát triển backend bằng NodeJS/Express.',
      category: 'course',
      aliases: ['NodeJS Backend'],
    ),
    FptuGlossaryEntry(
      term: 'PRM393',
      definition: 'Mobile Programming — lập trình ứng dụng di động (Android/Flutter).',
      category: 'course',
      aliases: ['Mobile Programming'],
    ),
    FptuGlossaryEntry(
      term: 'SEP490',
      definition: 'SE Capstone Project — đồ án tốt nghiệp ngành Kỹ thuật phần mềm.',
      category: 'course',
      aliases: ['Capstone Project', 'SE Capstone'],
    ),
    FptuGlossaryEntry(
      term: 'MAE101',
      definition: 'Mathematics for Engineering — giải tích cho kỹ sư.',
      category: 'course',
      aliases: ['Calculus'],
    ),
    FptuGlossaryEntry(
      term: 'MAD101',
      definition: 'Discrete Mathematics — toán rời rạc.',
      category: 'course',
      aliases: ['Discrete Math'],
    ),
    FptuGlossaryEntry(
      term: 'MAS291',
      definition: 'Statistics and Probability — xác suất thống kê.',
      category: 'course',
      aliases: ['Statistics'],
    ),
    FptuGlossaryEntry(
      term: 'NWC204',
      definition: 'Computer Networking — mạng máy tính.',
      category: 'course',
      aliases: ['Networking'],
    ),
    FptuGlossaryEntry(
      term: 'OSG202',
      definition: 'Operating Systems — hệ điều hành.',
      category: 'course',
      aliases: ['Operating Systems', 'OS'],
    ),

    // ─── SE Concepts / Khái niệm SE phổ biến ───
    FptuGlossaryEntry(
      term: 'Sprint',
      definition:
          'Chu kỳ phát triển ngắn trong Scrum (thường 2 tuần), '
          'nhóm hoàn thành một tập hợp user stories.',
      category: 'se_concept',
    ),
    FptuGlossaryEntry(
      term: 'Scrum Master',
      definition:
          'Vai trò điều phối quy trình Scrum, loại bỏ impediments, '
          'đảm bảo nhóm tuân thủ Agile practices.',
      category: 'se_concept',
      aliases: ['SM'],
    ),
    FptuGlossaryEntry(
      term: 'Product Backlog',
      definition:
          'Danh sách ưu tiên các user stories/features cần phát triển, '
          'do Product Owner quản lý.',
      category: 'se_concept',
      aliases: ['backlog'],
    ),
    FptuGlossaryEntry(
      term: 'CI/CD',
      definition:
          'Continuous Integration / Continuous Delivery — tích hợp và '
          'triển khai liên tục, tự động build/test/deploy.',
      category: 'se_concept',
      aliases: ['Continuous Integration', 'Continuous Delivery'],
    ),
    FptuGlossaryEntry(
      term: 'Clean Architecture',
      definition:
          'Kiến trúc phần mềm tách biệt business logic khỏi framework, '
          'UI và database thông qua dependency inversion.',
      category: 'se_concept',
    ),
    FptuGlossaryEntry(
      term: 'SOLID',
      definition:
          '5 nguyên tắc thiết kế OOP: Single Responsibility, Open-Closed, '
          'Liskov Substitution, Interface Segregation, Dependency Inversion.',
      category: 'se_concept',
    ),
    FptuGlossaryEntry(
      term: 'Design Pattern',
      definition:
          'Mẫu thiết kế giải quyết các vấn đề phổ biến trong OOP: '
          'Singleton, Factory, Observer, Strategy, v.v.',
      category: 'se_concept',
      aliases: ['mẫu thiết kế'],
    ),
    FptuGlossaryEntry(
      term: 'Agile',
      definition:
          'Phương pháp phát triển phần mềm linh hoạt, ưu tiên phản hồi '
          'nhanh và thích ứng thay đổi thay vì theo kế hoạch cứng nhắc.',
      category: 'se_concept',
    ),
    FptuGlossaryEntry(
      term: 'User Story',
      definition:
          'Đơn vị yêu cầu chức năng theo dạng: '
          '"As a [role], I want [feature] so that [benefit]".',
      category: 'se_concept',
    ),
    FptuGlossaryEntry(
      term: 'EXE',
      definition:
          'Experiential Entrepreneurship — chuỗi môn khởi nghiệp '
          '(EXE101, EXE201), sinh viên lập nhóm ý tưởng startup.',
      category: 'course',
      aliases: ['EXE101', 'EXE201'],
    ),

    // ─── General FPTU ───
    FptuGlossaryEntry(
      term: 'FPTU',
      definition:
          'FPT University — trường đại học FPT, '
          'đào tạo CNTT, kinh doanh, ngôn ngữ, du lịch.',
      category: 'general',
      aliases: ['FPT University', 'Đại học FPT'],
    ),
    FptuGlossaryEntry(
      term: 'SE',
      definition:
          'Software Engineering — ngành Kỹ thuật phần mềm, '
          'chương trình 9 kỳ (4.5 năm) tại FPTU.',
      category: 'general',
      aliases: ['Software Engineering', 'Kỹ thuật phần mềm'],
    ),
    FptuGlossaryEntry(
      term: 'Semester',
      definition:
          'Một học kỳ tại FPTU kéo dài khoảng 4 tháng. '
          'Chương trình SE gồm 9 semester (kể cả OJT).',
      category: 'academic',
      aliases: ['kỳ học', 'học kỳ'],
    ),
    FptuGlossaryEntry(
      term: 'Curriculum',
      definition:
          'Chương trình đào tạo — danh sách các môn học bắt buộc và '
          'tự chọn, cùng điều kiện tiên quyết, xếp theo kỳ.',
      category: 'academic',
      aliases: ['chương trình đào tạo', 'CTDT'],
    ),
    FptuGlossaryEntry(
      term: 'Major',
      definition:
          'Chuyên ngành chính: SE, AI, IA (Information Assurance), '
          'hoặc các ngành ngoài IT.',
      category: 'academic',
      aliases: ['chuyên ngành'],
    ),
  ];
}
