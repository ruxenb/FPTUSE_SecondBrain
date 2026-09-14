# 02. ARCHITECTURE, SYSTEM CONTRACTS & CODE TEMPLATES
## Dự án: FPTU SE Knowledge (Flutter Desktop Architecture)

---

## 1. TECH STACK & DEPENDENCIES (`pubspec.yaml`)

Dưới đây là file `pubspec.yaml` tinh gọn, đã được kiểm tra tính tương thích trên Flutter Desktop (Windows / macOS). Không thêm các thư viện thừa thãi gây phình to dự án.

```yaml
name: fptu_se_second_brain
description: "A lean Obsidian-like Second Brain for FPTU SE Students built with Flutter Desktop."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Quản lý trạng thái (State Management)
  provider: ^6.1.2

  # Hộp thoại chọn thư mục làm Vault trên máy tính
  file_picker: ^8.0.0

  # Xử lý đường dẫn tập tin đa nền tảng (Windows / macOS / Linux)
  path: ^1.9.0

  # Render nội dung Markdown thời gian thực
  flutter_markdown: ^0.7.2

  # Trực quan hóa liên kết đồ thị (Knowledge Graph)
  graphview: ^1.2.0

  # Tích hợp Google Gemini AI
  google_generative_ai: ^0.4.0

  # Các biểu tượng giao diện hiện đại
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
```

---

## 2. CẤU TRÚC THƯ MỤC CHUẨN (FEATURE-FIRST & CLEAN LEAN)

Cấu trúc thư mục được thiết kế theo nguyên tắc phân quyền trách nhiệm tuyệt đối giữa 4 thành viên, cô lập rủi ro xung đột mã nguồn (Merge Conflicts).

```
lib/
├── main.dart                          # Điểm khởi chạy ứng dụng, cấu hình MultiProvider & Dependency Injection
│
├── core/                              # Nền tảng chia sẻ toàn ứng dụng
│   ├── constants/
│   │   ├── app_colors.dart            # Bảng màu Dark Mode phong cách Obsidian / GitHub Dark
│   │   └── app_constants.dart         # Chuỗi hằng số, Regex Wikilinks, Prompt AI mặc định
│   └── theme/
│       └── app_theme.dart             # Cấu hình ThemeData (Dark Theme tối ưu Desktop)
│
├── models/                            # Dữ liệu thuần túy (Immutable Data Classes)
│   ├── vault_item.dart                # Biểu diễn File / Folder trong Sidebar Explorer (Member 1)
│   ├── note.dart                      # Biểu diễn bài Note Markdown và các liên kết (Member 2)
│   └── chat_message.dart              # Biểu diễn tin nhắn trao đổi với Gemini AI (Member 3)
│
├── contracts/                         # TẦNG GIAO KÈO TRỪU TƯỢNG (Abstract Interfaces) - Committed Day 1
│   ├── vault_service.dart             # Quản lý hệ thống tệp tin và cấu trúc thư mục
│   ├── note_repository.dart           # Đọc, ghi và phân tích liên kết nội dung Note
│   └── ai_service.dart                # Giao tiếp với mô hình trí tuệ nhân tạo Gemini
│
├── services/                          # TẦNG TRIỂN KHAI THỰC TẾ (Real Implementations - Tuần 2)
│   ├── local_vault_service.dart       # Đọc/ghi đĩa bằng 'dart:io' và 'path' (Member 1)
│   ├── local_note_repository.dart     # Phân tích cú pháp [[...]] và ghi file Markdown (Member 2)
│   └── gemini_ai_service.dart         # Tương tác với Google Gemini API thật (Member 3)
│
├── mocks/                             # TẦNG DỮ LIỆU GIẢ LẬP (Mock Implementations - Hoàn thành Day 2)
│   ├── mock_vault_service.dart        # Trả về cây thư mục môn học giả lập (PRM393, SWE201...)
│   ├── mock_note_repository.dart      # Lưu trữ in-memory Map các bài Note kèm liên kết
│   └── mock_ai_service.dart           # Phản hồi tức thì tóm tắt mà không tốn token/API Key
│
├── providers/                         # TẦNG QUẢN LÝ TRẠNG THÁI (Business Logic / State)
│   ├── vault_provider.dart            # Trạng thái cây thư mục, đường dẫn Vault đang chọn (Member 1)
│   ├── note_provider.dart             # Trạng thái Note đang mở, dirty state, backlinks (Member 2)
│   ├── ai_provider.dart               # Lịch sử chat, trạng thái loading AI (Member 3)
│   └── graph_provider.dart            # Thuật toán chuyển đổi danh sách Note thành Nodes & Edges (Member 4)
│
└── screens/                           # TẦNG GIAO DIỆN (UI Presentation)
    ├── shell_screen.dart              # Khung 3 cột chính Resizable Splitter (Member 4)
    ├── sidebar/
    │   ├── sidebar_explorer.dart      # Cây thư mục Folder Tree View (Member 1)
    │   └── context_menu.dart          # Menu chuột phải Tạo mới / Đổi tên / Xóa (Member 1)
    ├── editor/
    │   ├── note_editor_screen.dart    # Khung soạn thảo Markdown và Split Preview (Member 2)
    │   └── backlinks_panel.dart       # Danh sách các note trỏ tới note hiện tại (Member 2)
    ├── ai/
    │   └── ai_chat_panel.dart         # Khung chat và bong bóng hội thoại AI (Member 3)
    └── graph/
        └── knowledge_graph_screen.dart# Màn hình mạng lưới liên kết bằng GraphView (Member 4)
```

---

## 3. SƠ ĐỒ LUỒNG DỮ LIỆU KIẾN TRÚC (DATA FLOW DIAGRAM)

Nguyên tắc bất di bất dịch: **Widget UI tuyệt đối KHÔNG gọi trực tiếp `dart:io` hay Gemini API**.

```mermaid
flowchart TD
    subgraph UI_Layer ["Tầng Giao Diện (Presentation Layer)"]
        W1[Sidebar TreeView\nMember 1]
        W2[Markdown Editor & Preview\nMember 2]
        W3[AI Chat Panel\nMember 3]
        W4[Knowledge Graph Screen\nMember 4]
    end

    subgraph State_Layer ["Tầng Quản Lý Trạng Thái (Provider Layer)"]
        P1[VaultProvider]
        P2[NoteProvider]
        P3[AIProvider]
        P4[GraphProvider]
    end

    subgraph Interface_Layer ["Tầng Giao Kèo Trừu Tượng (Contracts)"]
        I1[<< abstract >>\nVaultService]
        I2[<< abstract >>\nNoteRepository]
        I3[<< abstract >>\nAIService]
    end

    subgraph Impl_Layer ["Tầng Triển Khai (Implementations)"]
        direction TB
        subgraph Real_Group ["Thực tế (Real - Tuần 2)"]
            R1[LocalVaultService\n'dart:io']
            R2[LocalNoteRepository\n'File IO + Regex']
            R3[GeminiAIService\n'Gemini API']
        end
        subgraph Mock_Group ["Giả lập (Mock - Day 2)"]
            M1[MockVaultService\nIn-Memory Tree]
            M2[MockNoteRepository\nIn-Memory Map]
            M3[MockAIService\nStatic DTOs]
        end
    end

    %% Flow connections
    W1 -->|notify / read| P1
    W2 -->|notify / read| P2
    W3 -->|notify / read| P3
    W4 -->|read nodes/edges| P4
    P4 -.->|depends on| P2

    P1 -->|invokes| I1
    P2 -->|invokes| I2
    P3 -->|invokes| I3

    I1 <|.. R1
    I1 <|.. M1
    I2 <|.. R2
    I2 <|.. M2
    I3 <|.. R3
    I3 <|.. M3
```

---

## 4. DART CODE MẪU CHI TIẾT (COPY-PASTE READY)

Tất cả các đoạn mã dưới đây được viết theo chuẩn **Dart 3.0+**, có thể sao chép và sử dụng ngay lập tức vào dự án.

### 4.1. CÁC LỚP MÔ HÌNH (MODELS)

#### File: `lib/models/vault_item.dart`
```dart
/// Đại diện cho một phần tử trong cây thư mục Vault (Tệp tin hoặc Thư mục).
class VaultItem {
  final String name;
  final String path;
  final bool isDirectory;
  final List<VaultItem> children;

  VaultItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });

  bool get isMarkdown => !isDirectory && name.toLowerCase().endsWith('.md');

  VaultItem copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    List<VaultItem>? children,
  }) {
    return VaultItem(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      children: children ?? this.children,
    );
  }
}
```

#### File: `lib/models/note.dart`
```dart
/// Đại diện cho một bài Note Markdown cùng các siêu dữ liệu liên kết.
class Note {
  final String path;
  final String title;
  final String content;
  final List<String> outgoingLinks; // Danh sách [[Tên Note]] mà note này trỏ tới
  final List<String> backlinks;     // Danh sách các note khác trích dẫn tới note này
  final DateTime lastModified;

  Note({
    required this.path,
    required this.title,
    required this.content,
    this.outgoingLinks = const [],
    this.backlinks = const [],
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Note copyWith({
    String? path,
    String? title,
    String? content,
    List<String>? outgoingLinks,
    List<String>? backlinks,
    DateTime? lastModified,
  }) {
    return Note(
      path: path ?? this.path,
      title: title ?? this.title,
      content: content ?? this.content,
      outgoingLinks: outgoingLinks ?? this.outgoingLinks,
      backlinks: backlinks ?? this.backlinks,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
```

#### File: `lib/models/chat_message.dart`
```dart
enum MessageSender { user, ai, system }

/// Đại diện cho một tin nhắn trong khung Chat AI hoặc phản hồi Summary.
class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
```

---

### 4.2. CÁC GIAO DIỆN TRỪU TƯỢNG (ABSTRACT CONTRACTS)

#### File: `lib/contracts/vault_service.dart`
```dart
import '../models/vault_item.dart';

/// Interface quản lý cấu trúc cây thư mục trên hệ thống tệp tin cục bộ.
abstract class VaultService {
  /// Quét toàn bộ thư mục gốc và trả về cấu trúc cây phân cấp
  Future<VaultItem> loadVaultHierarchy(String rootPath);

  /// Tạo một thư mục con mới bên trong đường dẫn cha
  Future<VaultItem> createFolder(String parentPath, String folderName);

  /// Tạo một file note Markdown mới (.md)
  Future<VaultItem> createNote(String parentPath, String noteName);

  /// Đổi tên file hoặc thư mục
  Future<void> renameItem(String oldPath, String newName);

  /// Xóa file hoặc thư mục khỏi ổ cứng
  Future<void> deleteItem(String targetPath);
}
```

#### File: `lib/contracts/note_repository.dart`
```dart
import '../models/note.dart';

/// Interface xử lý nội dung chi tiết của Note và phân tích liên kết hai chiều.
abstract class NoteRepository {
  /// Đọc nội dung bài note từ đường dẫn và trích xuất các outgoing links
  Future<Note> getNote(String filePath);

  /// Lưu nội dung note xuống ổ đĩa
  Future<void> saveNote(Note note);

  /// Lấy danh sách tất cả các bài note trong Vault để phục vụ Graph & Backlinks
  Future<List<Note>> getAllNotes(String vaultRootPath);

  /// Trích xuất danh sách tên các liên kết dạng [[Tên Note]] từ văn bản
  List<String> extractWikilinks(String markdownContent);

  /// Tìm kiếm danh sách các note có chứa liên kết trỏ về note mục tiêu
  Future<List<String>> getBacklinksForNote(String noteTitle, String vaultRootPath);
}
```

#### File: `lib/contracts/ai_service.dart`
```dart
import '../models/chat_message.dart';

/// Interface cung cấp năng lực AI hỗ trợ học tập (Gemini API).
abstract class AIService {
  /// Tóm tắt nội dung bài note thành 3-5 gạch đầu dòng cốt lõi
  Future<String> summarizeNote(String noteTitle, String noteContent);

  /// Trò chuyện tự do với AI theo ngữ cảnh bài học
  Future<String> sendChatMessage(String prompt, List<ChatMessage> conversationHistory);
}
```

---

### 4.3. CÁC LỚP GIẢ LẬP ĐẦY ĐỦ (MOCK IMPLEMENTATIONS - SẴN SÀNG CHO DAY 2)

#### File: `lib/mocks/mock_vault_service.dart`
```dart
import '../contracts/vault_service.dart';
import '../models/vault_item.dart';

/// Triển khai giả lập dữ liệu cây thư mục môn học SE tại FPTU trong bộ nhớ.
class MockVaultService implements VaultService {
  @override
  Future<VaultItem> loadVaultHierarchy(String rootPath) async {
    // Giả lập độ trễ mạng/đĩa 300ms
    await Future.delayed(const Duration(milliseconds: 300));

    return VaultItem(
      name: 'FPTU_SE_Notes',
      path: '/vault',
      isDirectory: true,
      children: [
        VaultItem(
          name: 'PRM393_Mobile',
          path: '/vault/PRM393_Mobile',
          isDirectory: true,
          children: [
            VaultItem(
              name: 'Flutter_Architecture.md',
              path: '/vault/PRM393_Mobile/Flutter_Architecture.md',
              isDirectory: false,
            ),
            VaultItem(
              name: 'Provider_Pattern.md',
              path: '/vault/PRM393_Mobile/Provider_Pattern.md',
              isDirectory: false,
            ),
          ],
        ),
        VaultItem(
          name: 'SWE201_Software_Process',
          path: '/vault/SWE201_Software_Process',
          isDirectory: true,
          children: [
            VaultItem(
              name: 'Agile_Scrum_Overview.md',
              path: '/vault/SWE201_Software_Process/Agile_Scrum_Overview.md',
              isDirectory: false,
            ),
          ],
        ),
        VaultItem(
          name: 'Quick_Ideas.md',
          path: '/vault/Quick_Ideas.md',
          isDirectory: false,
        ),
      ],
    );
  }

  @override
  Future<VaultItem> createFolder(String parentPath, String folderName) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return VaultItem(
      name: folderName,
      path: '$parentPath/$folderName',
      isDirectory: true,
      children: [],
    );
  }

  @override
  Future<VaultItem> createNote(String parentPath, String noteName) async {
    final fileName = noteName.endsWith('.md') ? noteName : '$noteName.md';
    await Future.delayed(const Duration(milliseconds: 150));
    return VaultItem(
      name: fileName,
      path: '$parentPath/$fileName',
      isDirectory: false,
    );
  }

  @override
  Future<void> renameItem(String oldPath, String newName) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> deleteItem(String targetPath) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }
}
```

#### File: `lib/mocks/mock_note_repository.dart`
```dart
import '../contracts/note_repository.dart';
import '../models/note.dart';

/// Triển khai giả lập lưu trữ ghi chú và phân tích liên kết In-Memory.
class MockNoteRepository implements NoteRepository {
  final Map<String, Note> _memoryNotes = {
    '/vault/PRM393_Mobile/Flutter_Architecture.md': Note(
      path: '/vault/PRM393_Mobile/Flutter_Architecture.md',
      title: 'Flutter_Architecture',
      content: '''# Kiến Trúc Ứng Dụng Flutter Desktop

Trong môn PRM393, việc phân tách các tầng là bắt buộc:
1. **Presentation Layer**: Widgets và UI Screens.
2. **State Management**: Sử dụng [[Provider_Pattern]] để quản lý trạng thái.
3. **Data Layer**: Tách biệt giữa Service và Repository.

Tham khảo thêm quy trình phát triển tại [[Agile_Scrum_Overview]].
''',
      outgoingLinks: ['Provider_Pattern', 'Agile_Scrum_Overview'],
      backlinks: ['Quick_Ideas'],
    ),
    '/vault/PRM393_Mobile/Provider_Pattern.md': Note(
      path: '/vault/PRM393_Mobile/Provider_Pattern.md',
      title: 'Provider_Pattern',
      content: '''# Quản Lý Trạng Thái Với Provider

Provider là thư viện bao bọc quanh InheritedWidget.
- Dùng `ChangeNotifierProvider` cho các dữ liệu cần lắng nghe thay đổi.
- Tham chiếu kiến trúc tổng thể tại [[Flutter_Architecture]].
''',
      outgoingLinks: ['Flutter_Architecture'],
      backlinks: ['Flutter_Architecture'],
    ),
    '/vault/SWE201_Software_Process/Agile_Scrum_Overview.md': Note(
      path: '/vault/SWE201_Software_Process/Agile_Scrum_Overview.md',
      title: 'Agile_Scrum_Overview',
      content: '''# Tổng Quan Về Agile & Scrum

Mô hình phát triển phần mềm lặp (Iterative):
- Sprint Planning & Daily Standup.
- Deliverable sau mỗi Sprint là một bản MVP hoàn chỉnh.
''',
      outgoingLinks: [],
      backlinks: ['Flutter_Architecture'],
    ),
  };

  @override
  Future<Note> getNote(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_memoryNotes.containsKey(filePath)) {
      return _memoryNotes[filePath]!;
    }
    // Tạo note rỗng nếu chưa tồn tại
    final title = filePath.split('/').last.replaceAll('.md', '');
    return Note(
      path: filePath,
      title: title,
      content: '# $title\n\nBắt đầu ghi chú bài học mới tại đây...',
      outgoingLinks: [],
      backlinks: [],
    );
  }

  @override
  Future<void> saveNote(Note note) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final links = extractWikilinks(note.content);
    _memoryNotes[note.path] = note.copyWith(outgoingLinks: links);
  }

  @override
  Future<List<Note>> getAllNotes(String vaultRootPath) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _memoryNotes.values.toList();
  }

  @override
  List<String> extractWikilinks(String markdownContent) {
    // Regex bắt cú pháp [[Tên Note]]
    final regex = RegExp(r'\[\[(.*?)\]\]');
    final matches = regex.allMatches(markdownContent);
    return matches.map((m) => m.group(1)?.trim() ?? '').where((s) => s.isNotEmpty).toSet().toList();
  }

  @override
  Future<List<String>> getBacklinksForNote(String noteTitle, String vaultRootPath) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final backlinks = <String>[];
    for (final entry in _memoryNotes.entries) {
      if (entry.value.title.toLowerCase() != noteTitle.toLowerCase()) {
        final links = extractWikilinks(entry.value.content);
        if (links.any((link) => link.toLowerCase() == noteTitle.toLowerCase())) {
          backlinks.add(entry.value.title);
        }
      }
    }
    return backlinks;
  }
}
```

#### File: `lib/mocks/mock_ai_service.dart`
```dart
import '../contracts/ai_service.dart';
import '../models/chat_message.dart';

/// Triển khai giả lập phản hồi của Gemini AI để kiểm tra UI ngay Day 2 mà không cần API Key.
class MockAIService implements AIService {
  @override
  Future<String> summarizeNote(String noteTitle, String noteContent) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Giả lập độ trễ AI
    return '''### ⚡ Tóm Tắt Trọng Tâm Note: `$noteTitle`
* **Kiến trúc cốt lõi:** Phân định rõ 3 tầng (UI, Provider, Services). Không gọi trực tiếp File I/O trong Widget.
* **State Management:** Khuyến nghị dùng Provider để tối ưu vòng đời widget.
* **Liên kết tri thức:** Sử dụng cú pháp `[[WikiLinks]]` để định hình mạng lưới Second Brain.
* **Lưu ý thi Lab:** Đảm bảo mock implementations hoạt động ổn định trước khi cắm real API.''';
  }

  @override
  Future<String> sendChatMessage(String prompt, List<ChatMessage> conversationHistory) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return 'Chào bạn sinh viên FPTU! Mình đã nhận được câu hỏi: "$prompt". Trong mô hình Second Brain, kiến thức của bạn đang được liên kết rất chặt chẽ!';
  }
}
```

---

### 4.4. CẤU HÌNH DEPENDENCY INJECTION VÀ MULTI-PROVIDER TẠI `main.dart`

File này chứng minh cách chuyển đổi giữa **Mock (Day 2)** và **Real (Tuần 2)** chỉ bằng một hằng số cờ `kUseMock`.

#### File: `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Contracts
import 'contracts/vault_service.dart';
import 'contracts/note_repository.dart';
import 'contracts/ai_service.dart';

// Mocks
import 'mocks/mock_vault_service.dart';
import 'mocks/mock_note_repository.dart';
import 'mocks/mock_ai_service.dart';

// Real Implementations (sẽ uncomment khi hoàn thành Tuần 2)
// import 'services/local_vault_service.dart';
// import 'services/local_note_repository.dart';
// import 'services/gemini_ai_service.dart';

// Providers
import 'providers/vault_provider.dart';
import 'providers/note_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/graph_provider.dart';

// Screen Shell
import 'screens/shell_screen.dart';
import 'core/theme/app_theme.dart';

/// CỜ ĐIỀU KHIỂN: Đặt `true` khi nhóm đang phát triển Day 2-7 bằng Mock.
/// Đặt `false` khi tích hợp dịch vụ thật vào Tuần 2.
const bool kUseMock = true;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FPTUSecondBrainApp());
}

class FPTUSecondBrainApp extends StatelessWidget {
  const FPTUSecondBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Khởi tạo tầng Services (Phụ thuộc vào cờ kUseMock)
        Provider<VaultService>(
          create: (_) => kUseMock ? MockVaultService() : MockVaultService(), // Thay bằng LocalVaultService() ở Tuần 2
        ),
        Provider<NoteRepository>(
          create: (_) => kUseMock ? MockNoteRepository() : MockNoteRepository(), // Thay bằng LocalNoteRepository()
        ),
        Provider<AIService>(
          create: (_) => kUseMock ? MockAIService() : MockAIService(), // Thay bằng GeminiAIService(apiKey: '...')
        ),

        // 2. Khởi tạo tầng Business Logic Providers
        ChangeNotifierProvider<VaultProvider>(
          create: (ctx) => VaultProvider(vaultService: ctx.read<VaultService>()),
        ),
        ChangeNotifierProvider<NoteProvider>(
          create: (ctx) => NoteProvider(noteRepository: ctx.read<NoteRepository>()),
        ),
        ChangeNotifierProvider<AIProvider>(
          create: (ctx) => AIProvider(aiService: ctx.read<AIService>()),
        ),
        ChangeNotifierProxyProvider<NoteProvider, GraphProvider>(
          create: (ctx) => GraphProvider(noteRepository: ctx.read<NoteRepository>()),
          update: (ctx, noteProvider, graphProvider) =>
              graphProvider!..updateFromNoteProvider(noteProvider),
        ),
      ],
      child: MaterialApp(
        title: 'FPTU SE Knowledge - Second Brain',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ShellScreen(),
      ),
    );
  }
}
```
